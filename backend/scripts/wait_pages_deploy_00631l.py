from __future__ import annotations

import argparse
import json
import os
import subprocess
import sys
import time
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Callable


ROOT = Path(__file__).resolve().parents[2]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from backend.scripts.check_pages_deploy_status_00631l import (  # noqa: E402
    DEFAULT_REPO,
    DEFAULT_WORKFLOW,
    run_pages_deploy_status_check,
)
from backend.scripts.check_public_pages_00631l import (  # noqa: E402
    DEFAULT_ROOT_URL,
    DEFAULT_STATIC_BASE_URL,
)


StatusChecker = Callable[..., dict[str, Any]]


def main() -> int:
    args = _parse_args()
    payload = run_pages_deploy_wait(
        repo=args.repo,
        workflow=args.workflow,
        branch=args.branch,
        root_url=args.root_url,
        static_base_url=args.static_base_url,
        expected_sha=args.expected_sha,
        timeout=args.timeout,
        attempts=args.attempts,
        interval_seconds=args.interval_seconds,
        dry_run=args.dry_run,
    )
    print(json.dumps(payload, ensure_ascii=False, indent=2, sort_keys=True))
    summary = payload.get("summary") if isinstance(payload.get("summary"), dict) else {}
    print(
        "[summary] "
        f"overallStatus={payload['overallStatus']} "
        f"warnings={payload['warningCount']} "
        f"failures={payload['failureCount']} "
        f"matched={summary.get('matchedExpectedSha')} "
        f"completed={summary.get('completedSuccessfully')} "
        f"attempts={summary.get('sampleCount')}"
    )
    return 0 if args.soft_fail or payload["overallStatus"] != "FAIL" else 1


def run_pages_deploy_wait(
    *,
    repo: str = DEFAULT_REPO,
    workflow: str = DEFAULT_WORKFLOW,
    branch: str = "main",
    root_url: str = DEFAULT_ROOT_URL,
    static_base_url: str = DEFAULT_STATIC_BASE_URL,
    expected_sha: str | None = None,
    timeout: float = 15.0,
    attempts: int = 20,
    interval_seconds: int = 15,
    dry_run: bool = False,
    checker: StatusChecker = run_pages_deploy_status_check,
) -> dict[str, Any]:
    checked_at = _now_iso()
    resolved_expected_sha = (expected_sha or _git_head_sha()).strip()
    if dry_run:
        sample = _planned_sample(resolved_expected_sha)
        return _build_wait_payload(
            checked_at=checked_at,
            repo=repo,
            workflow=workflow,
            branch=branch,
            expected_sha=resolved_expected_sha,
            samples=[sample],
            dry_run=True,
        )

    samples: list[dict[str, Any]] = []
    total_attempts = max(1, int(attempts or 1))
    interval = max(0, int(interval_seconds or 0))
    for index in range(total_attempts):
        sample = checker(
            repo=repo,
            workflow=workflow,
            branch=branch,
            root_url=root_url,
            static_base_url=static_base_url,
            expected_sha=resolved_expected_sha,
            timeout=timeout,
        )
        samples.append(sample)
        if _sample_is_complete(sample, resolved_expected_sha):
            break
        if index < total_attempts - 1 and interval:
            time.sleep(interval)

    return _build_wait_payload(
        checked_at=checked_at,
        repo=repo,
        workflow=workflow,
        branch=branch,
        expected_sha=resolved_expected_sha,
        samples=samples,
        dry_run=False,
    )


def _build_wait_payload(
    *,
    checked_at: str,
    repo: str,
    workflow: str,
    branch: str,
    expected_sha: str,
    samples: list[dict[str, Any]],
    dry_run: bool,
) -> dict[str, Any]:
    latest = samples[-1] if samples else {}
    latest_summary = latest.get("summary") if isinstance(latest.get("summary"), dict) else {}
    matched = any(_sample_matches_expected_sha(sample, expected_sha) for sample in samples)
    completed = any(_sample_is_complete(sample, expected_sha) for sample in samples)
    failures: list[str] = []
    warnings: list[str] = []
    action_items: list[str] = []

    for sample in samples:
        failures.extend(str(item) for item in sample.get("failures") or [])

    if not samples:
        warnings.append("No Pages deployment samples were collected.")
    elif not completed:
        run_status = str(latest_summary.get("latestRunStatus") or "unknown")
        run_conclusion = str(latest_summary.get("latestRunConclusion") or "unknown")
        warnings.append(
            "Pages deployment has not completed for the expected commit: "
            f"status={run_status} conclusion={run_conclusion}"
        )
        action_items.append(
            "Rerun scripts\\00631l_wait_pages_deploy.cmd after the GitHub Pages workflow finishes."
        )

    return {
        "sourceContract": "00631l_pages_deploy_wait",
        "checkedAt": checked_at,
        "repo": repo,
        "workflow": workflow,
        "branch": branch,
        "dryRun": dry_run,
        "overallStatus": "FAIL" if failures else "PASS" if completed else "WARN",
        "summary": {
            "expectedSha": expected_sha,
            "sampleCount": len(samples),
            "matchedExpectedSha": matched,
            "completedSuccessfully": completed,
            "latestRunStatus": latest_summary.get("latestRunStatus"),
            "latestRunConclusion": latest_summary.get("latestRunConclusion"),
            "latestRunHeadSha": latest_summary.get("latestRunHeadSha"),
            "latestRunUrl": latest_summary.get("latestRunUrl"),
            "staticRowCount": latest_summary.get("staticRowCount"),
            "coverageStart": latest_summary.get("coverageStart"),
            "coverageEnd": latest_summary.get("coverageEnd"),
        },
        "samples": samples,
        "warnings": warnings,
        "failures": failures,
        "warningCount": len(warnings),
        "failureCount": len(failures),
        "actionItems": action_items,
    }


def _sample_is_complete(sample: dict[str, Any], expected_sha: str) -> bool:
    summary = sample.get("summary") if isinstance(sample.get("summary"), dict) else {}
    return (
        _sample_matches_expected_sha(sample, expected_sha)
        and str(summary.get("latestRunStatus") or "") == "completed"
        and str(summary.get("latestRunConclusion") or "") == "success"
        and str(sample.get("overallStatus") or "") == "PASS"
    )


def _sample_matches_expected_sha(sample: dict[str, Any], expected_sha: str) -> bool:
    summary = sample.get("summary") if isinstance(sample.get("summary"), dict) else {}
    head_sha = str(summary.get("latestRunHeadSha") or "")
    return bool(expected_sha and head_sha.startswith(expected_sha[:12]))


def _planned_sample(expected_sha: str) -> dict[str, Any]:
    return {
        "overallStatus": "PASS",
        "summary": {
            "latestRunStatus": "completed",
            "latestRunConclusion": "success",
            "latestRunHeadSha": expected_sha,
            "staticRowCount": 2800,
            "coverageStart": "2014-10-31",
            "coverageEnd": "planned",
        },
        "warnings": [],
        "failures": [],
        "dryRun": True,
    }


def _git_head_sha() -> str:
    try:
        result = subprocess.run(
            ["git", "rev-parse", "HEAD"],
            text=True,
            capture_output=True,
            check=False,
            cwd=ROOT,
        )
    except OSError:
        return ""
    return result.stdout.strip() if result.returncode == 0 else ""


def _now_iso() -> str:
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat()


def _parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Wait for the GitHub Pages workflow to deploy the expected 00631L app commit.",
    )
    parser.add_argument("--repo", default=os.getenv("00631L_GITHUB_REPO", DEFAULT_REPO))
    parser.add_argument("--workflow", default=os.getenv("00631L_PAGES_WORKFLOW", DEFAULT_WORKFLOW))
    parser.add_argument("--branch", default=os.getenv("00631L_PAGES_BRANCH", "main"))
    parser.add_argument("--root-url", default=os.getenv("00631L_PUBLIC_PAGES_URL", DEFAULT_ROOT_URL))
    parser.add_argument(
        "--static-base-url",
        default=os.getenv("00631L_PUBLIC_STATIC_BASE_URL", DEFAULT_STATIC_BASE_URL),
    )
    parser.add_argument("--expected-sha", default=os.getenv("EXPECTED_00631L_GIT_SHA", ""))
    parser.add_argument("--timeout", type=float, default=15.0)
    parser.add_argument("--attempts", type=int, default=20)
    parser.add_argument("--interval-seconds", type=int, default=15)
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--soft-fail", action="store_true")
    return parser.parse_args()


if __name__ == "__main__":
    raise SystemExit(main())
