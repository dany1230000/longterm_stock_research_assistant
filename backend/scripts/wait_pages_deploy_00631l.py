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
from backend.scripts.wait_public_release_marker_00631l import (  # noqa: E402
    run_public_release_marker_wait,
)


StatusChecker = Callable[..., dict[str, Any]]
PublicChecker = Callable[..., dict[str, Any]]


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
        mode=args.mode,
    )
    printable_payload = (
        compact_pages_deploy_wait_payload(payload, include_attempts=args.include_attempts)
        if args.summary_only or args.include_attempts
        else payload
    )
    print(json.dumps(printable_payload, ensure_ascii=False, indent=2, sort_keys=True))
    summary = payload.get("summary") if isinstance(payload.get("summary"), dict) else {}
    print(
        "[summary] "
        f"overallStatus={payload['overallStatus']} "
        f"warnings={payload['warningCount']} "
        f"failures={payload['failureCount']} "
        f"mode={payload.get('mode') or '-'} "
        f"matched={summary.get('matchedExpectedSha')} "
        f"completed={summary.get('completedSuccessfully')} "
        f"attempts={summary.get('sampleCount')}"
    )
    return 0 if args.soft_fail or payload["overallStatus"] != "FAIL" else 1


def compact_pages_deploy_wait_payload(
    payload: dict[str, Any],
    *,
    include_attempts: bool = False,
) -> dict[str, Any]:
    compact = {key: value for key, value in payload.items() if key != "samples"}
    sample_summaries = _sample_summaries(payload.get("samples") or [])
    compact["attemptSummary"] = _attempt_summary(sample_summaries)
    if include_attempts:
        compact["sampleSummaries"] = sample_summaries
    return compact


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
    mode: str = "public-marker",
    checker: StatusChecker = run_pages_deploy_status_check,
    public_checker: PublicChecker | None = None,
) -> dict[str, Any]:
    checked_at = _now_iso()
    resolved_expected_sha = (expected_sha or _git_head_sha()).strip()
    if mode == "public-marker":
        marker_kwargs: dict[str, Any] = {
            "root_url": root_url,
            "static_base_url": static_base_url,
            "timeout": timeout,
            "expected_sha": resolved_expected_sha,
            "attempts": attempts,
            "interval_seconds": interval_seconds,
            "dry_run": dry_run,
        }
        if public_checker is not None:
            marker_kwargs["checker"] = public_checker
        marker_payload = run_public_release_marker_wait(**marker_kwargs)
        return _build_marker_wait_payload(
            checked_at=checked_at,
            repo=repo,
            workflow=workflow,
            branch=branch,
            expected_sha=resolved_expected_sha,
            marker_payload=marker_payload,
        )
    if mode != "github-api":
        return _build_invalid_mode_payload(
            checked_at=checked_at,
            repo=repo,
            workflow=workflow,
            branch=branch,
            expected_sha=resolved_expected_sha,
            mode=mode,
        )
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
            mode=mode,
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
        mode=mode,
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
    mode: str,
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
        "mode": mode,
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


def _build_marker_wait_payload(
    *,
    checked_at: str,
    repo: str,
    workflow: str,
    branch: str,
    expected_sha: str,
    marker_payload: dict[str, Any],
) -> dict[str, Any]:
    marker_summary = (
        marker_payload.get("summary") if isinstance(marker_payload.get("summary"), dict) else {}
    )
    matched = bool(marker_summary.get("matchedExpectedSha"))
    latest_sha = marker_summary.get("latestReleaseGitSha")
    return {
        "sourceContract": "00631l_pages_deploy_wait",
        "checkedAt": checked_at,
        "repo": repo,
        "workflow": workflow,
        "branch": branch,
        "dryRun": marker_payload.get("dryRun", False),
        "mode": "public-marker",
        "overallStatus": marker_payload.get("overallStatus", "WARN"),
        "summary": {
            "expectedSha": expected_sha,
            "sampleCount": marker_summary.get("sampleCount"),
            "matchedExpectedSha": matched,
            "completedSuccessfully": matched,
            "latestRunStatus": "public-marker",
            "latestRunConclusion": "success" if matched else "waiting",
            "latestRunHeadSha": latest_sha,
            "latestRunUrl": None,
            "staticRowCount": marker_summary.get("staticRowCount"),
            "coverageStart": marker_summary.get("coverageStart"),
            "coverageEnd": marker_summary.get("coverageEnd"),
            "latestReleaseTag": marker_summary.get("latestReleaseTag"),
            "latestReleaseGitSha": latest_sha,
            "latestReleaseAppVersion": marker_summary.get("latestReleaseAppVersion"),
        },
        "samples": marker_payload.get("samples") or [],
        "warnings": marker_payload.get("warnings") or [],
        "failures": marker_payload.get("failures") or [],
        "warningCount": marker_payload.get("warningCount", 0),
        "failureCount": marker_payload.get("failureCount", 0),
        "actionItems": marker_payload.get("actionItems") or [],
    }


def _build_invalid_mode_payload(
    *,
    checked_at: str,
    repo: str,
    workflow: str,
    branch: str,
    expected_sha: str,
    mode: str,
) -> dict[str, Any]:
    message = f"Unsupported Pages deploy wait mode: {mode}"
    return {
        "sourceContract": "00631l_pages_deploy_wait",
        "checkedAt": checked_at,
        "repo": repo,
        "workflow": workflow,
        "branch": branch,
        "dryRun": False,
        "mode": mode,
        "overallStatus": "FAIL",
        "summary": {
            "expectedSha": expected_sha,
            "sampleCount": 0,
            "matchedExpectedSha": False,
            "completedSuccessfully": False,
        },
        "samples": [],
        "warnings": [],
        "failures": [message],
        "warningCount": 0,
        "failureCount": 1,
        "actionItems": ["Use --mode public-marker or --mode github-api."],
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


def _sample_summaries(samples: list[dict[str, Any]]) -> list[dict[str, Any]]:
    summaries: list[dict[str, Any]] = []
    for index, sample in enumerate(samples, start=1):
        summary = sample.get("summary") if isinstance(sample.get("summary"), dict) else {}
        summaries.append(
            {
                "attempt": index,
                "overallStatus": sample.get("overallStatus"),
                "releaseTag": sample.get("releaseTag") or summary.get("latestReleaseTag"),
                "releaseGitSha": (
                    sample.get("releaseGitSha")
                    or summary.get("latestReleaseGitSha")
                    or summary.get("latestRunHeadSha")
                ),
                "releaseAppVersion": sample.get("releaseAppVersion")
                or summary.get("latestReleaseAppVersion"),
                "latestRunStatus": summary.get("latestRunStatus"),
                "latestRunConclusion": summary.get("latestRunConclusion"),
                "rowCount": sample.get("rowCount") or summary.get("staticRowCount"),
                "coverageStart": sample.get("coverageStart") or summary.get("coverageStart"),
                "coverageEnd": sample.get("coverageEnd") or summary.get("coverageEnd"),
                "warningCount": len(sample.get("warnings") or []),
                "failureCount": len(sample.get("failures") or []),
            }
        )
    return summaries


def _attempt_summary(sample_summaries: list[dict[str, Any]]) -> dict[str, Any]:
    first = sample_summaries[0] if sample_summaries else {}
    latest = sample_summaries[-1] if sample_summaries else {}
    transitions = 0
    previous_sha = ""
    for sample in sample_summaries:
        release_sha = str(sample.get("releaseGitSha") or "")
        if previous_sha and release_sha != previous_sha:
            transitions += 1
        previous_sha = release_sha
    return {
        "sampleCount": len(sample_summaries),
        "first": first,
        "latest": latest,
        "releaseShaTransitionCount": transitions,
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
    parser.add_argument(
        "--summary-only",
        action="store_true",
        help="Print compact attempt summaries instead of the full sampled payloads.",
    )
    parser.add_argument(
        "--include-attempts",
        action="store_true",
        help="Print compact attempt rows; implies compact output.",
    )
    parser.add_argument(
        "--mode",
        choices=["public-marker", "github-api"],
        default=os.getenv("00631L_PAGES_DEPLOY_WAIT_MODE", "public-marker"),
        help=(
            "public-marker checks GitHub Pages release.json without GitHub API; "
            "github-api keeps the older workflow API based check."
        ),
    )
    return parser.parse_args()


if __name__ == "__main__":
    raise SystemExit(main())
