from __future__ import annotations

import argparse
import json
import subprocess
import sys
import time
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Callable


ROOT = Path(__file__).resolve().parents[2]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from backend.scripts.check_public_pages_00631l import (  # noqa: E402
    DEFAULT_MIN_ROW_COUNT,
    DEFAULT_ROOT_URL,
    DEFAULT_STATIC_BASE_URL,
    run_public_pages_check,
)


PublicChecker = Callable[..., dict[str, Any]]


def main() -> int:
    args = _parse_args()
    payload = run_public_release_marker_wait(
        root_url=args.root_url,
        static_base_url=args.static_base_url,
        timeout=args.timeout,
        min_row_count=args.min_row_count,
        expected_sha=args.expected_sha,
        attempts=args.attempts,
        interval_seconds=args.interval_seconds,
        dry_run=args.dry_run,
    )
    printable_payload = (
        compact_public_release_marker_wait_payload(payload)
        if args.summary_only
        else payload
    )
    print(json.dumps(printable_payload, ensure_ascii=False, indent=2, sort_keys=True))
    _print_summary_line(payload)
    return 0 if args.soft_fail or payload["overallStatus"] != "FAIL" else 1


def run_public_release_marker_wait(
    *,
    root_url: str = DEFAULT_ROOT_URL,
    static_base_url: str = DEFAULT_STATIC_BASE_URL,
    timeout: float = 15.0,
    min_row_count: int = DEFAULT_MIN_ROW_COUNT,
    expected_sha: str | None = None,
    attempts: int = 20,
    interval_seconds: int = 15,
    dry_run: bool = False,
    checker: PublicChecker = run_public_pages_check,
) -> dict[str, Any]:
    checked_at = _now_iso()
    resolved_expected_sha = (expected_sha or _git_head_sha()).strip()
    if dry_run:
        return _build_wait_payload(
            checked_at=checked_at,
            root_url=root_url,
            static_base_url=static_base_url,
            expected_sha=resolved_expected_sha,
            attempts=attempts,
            interval_seconds=interval_seconds,
            samples=[_planned_sample(resolved_expected_sha)],
            dry_run=True,
        )

    samples: list[dict[str, Any]] = []
    total_attempts = max(1, int(attempts or 1))
    interval = max(0, int(interval_seconds or 0))
    for index in range(total_attempts):
        sample = checker(
            root_url=root_url,
            static_base_url=static_base_url,
            timeout=timeout,
            min_row_count=min_row_count,
            expected_sha=resolved_expected_sha,
        )
        samples.append(sample)
        if _sample_matches_expected_sha(sample, resolved_expected_sha):
            break
        if index < total_attempts - 1 and interval:
            time.sleep(interval)

    return _build_wait_payload(
        checked_at=checked_at,
        root_url=root_url,
        static_base_url=static_base_url,
        expected_sha=resolved_expected_sha,
        attempts=total_attempts,
        interval_seconds=interval,
        samples=samples,
        dry_run=False,
    )


def compact_public_release_marker_wait_payload(payload: dict[str, Any]) -> dict[str, Any]:
    compact = {key: value for key, value in payload.items() if key != "samples"}
    sample_summaries: list[dict[str, Any]] = []
    for index, sample in enumerate(payload.get("samples") or [], start=1):
        sample_summaries.append(
            {
                "attempt": index,
                "overallStatus": sample.get("overallStatus"),
                "releaseTag": sample.get("releaseTag"),
                "releaseGitSha": sample.get("releaseGitSha"),
                "releaseAppVersion": sample.get("releaseAppVersion"),
                "rowCount": sample.get("rowCount"),
                "coverageStart": sample.get("coverageStart"),
                "coverageEnd": sample.get("coverageEnd"),
                "warningCount": len(sample.get("warnings") or []),
                "failureCount": len(sample.get("failures") or []),
            }
        )
    compact["sampleSummaries"] = sample_summaries
    return compact


def _build_wait_payload(
    *,
    checked_at: str,
    root_url: str,
    static_base_url: str,
    expected_sha: str,
    attempts: int,
    interval_seconds: int,
    samples: list[dict[str, Any]],
    dry_run: bool,
) -> dict[str, Any]:
    latest = samples[-1] if samples else {}
    matched = any(_sample_matches_expected_sha(sample, expected_sha) for sample in samples)
    failures: list[str] = []
    warnings: list[str] = []
    action_items: list[str] = []

    for sample in samples:
        if sample.get("overallStatus") == "FAIL":
            failures.extend(f"public_pages: {item}" for item in sample.get("failures") or [])

    if not samples:
        warnings.append("No public release marker samples were collected.")
    elif not matched:
        latest_sha = str(latest.get("releaseGitSha") or "")
        warnings.append(
            "Public Pages release marker has not reached the expected commit: "
            f"public={latest_sha[:12] or 'missing'} expected={expected_sha[:12]}"
        )
        action_items.append(
            "Wait for GitHub Pages deployment, then rerun "
            "scripts\\00631l_wait_public_release_marker.cmd."
        )

    if latest.get("overallStatus") == "WARN":
        for item in latest.get("warnings") or []:
            if "public release SHA differs" in str(item) and not matched:
                continue
            warnings.append(str(item))

    return {
        "sourceContract": "00631l_public_release_marker_wait",
        "checkedAt": checked_at,
        "rootUrl": root_url,
        "staticBaseUrl": static_base_url,
        "dryRun": dry_run,
        "overallStatus": "FAIL" if failures else "PASS" if matched else "WARN",
        "summary": {
            "expectedSha": expected_sha,
            "sampleCount": len(samples),
            "attempts": attempts,
            "intervalSeconds": interval_seconds,
            "matchedExpectedSha": matched,
            "latestReleaseTag": latest.get("releaseTag"),
            "latestReleaseGitSha": latest.get("releaseGitSha"),
            "latestReleaseAppVersion": latest.get("releaseAppVersion"),
            "staticRowCount": latest.get("rowCount"),
            "coverageStart": latest.get("coverageStart"),
            "coverageEnd": latest.get("coverageEnd"),
        },
        "samples": samples,
        "warnings": _dedupe(warnings),
        "failures": _dedupe(failures),
        "warningCount": len(_dedupe(warnings)),
        "failureCount": len(_dedupe(failures)),
        "actionItems": _dedupe(action_items),
    }


def _sample_matches_expected_sha(sample: dict[str, Any], expected_sha: str) -> bool:
    release_sha = str(sample.get("releaseGitSha") or "")
    return bool(expected_sha and release_sha.startswith(expected_sha[:12]))


def _planned_sample(expected_sha: str) -> dict[str, Any]:
    return {
        "overallStatus": "PASS",
        "rootUrl": DEFAULT_ROOT_URL,
        "staticBaseUrl": DEFAULT_STATIC_BASE_URL,
        "rowCount": DEFAULT_MIN_ROW_COUNT,
        "coverageStart": "2014-10-31",
        "coverageEnd": "planned",
        "releaseTag": "planned",
        "releaseGitSha": expected_sha,
        "releaseAppVersion": "planned",
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


def _dedupe(items: list[str]) -> list[str]:
    seen: set[str] = set()
    output: list[str] = []
    for item in items:
        if item in seen:
            continue
        seen.add(item)
        output.append(item)
    return output


def _now_iso() -> str:
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat()


def _print_summary_line(payload: dict[str, Any]) -> None:
    summary = payload.get("summary") if isinstance(payload.get("summary"), dict) else {}
    print(
        "[summary] "
        f"overallStatus={payload['overallStatus']} "
        f"warnings={payload['warningCount']} "
        f"failures={payload['failureCount']} "
        f"matched={summary.get('matchedExpectedSha')} "
        f"attempts={summary.get('sampleCount')} "
        f"release={summary.get('latestReleaseTag') or '-'} "
        f"sha={str(summary.get('latestReleaseGitSha') or '-')[:12]}"
    )


def _parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            "Wait for the public GitHub Pages release.json marker to match "
            "the expected 00631L app commit without using the GitHub API."
        ),
    )
    parser.add_argument("--root-url", default=DEFAULT_ROOT_URL)
    parser.add_argument("--static-base-url", default=DEFAULT_STATIC_BASE_URL)
    parser.add_argument("--expected-sha", default="")
    parser.add_argument("--timeout", type=float, default=15.0)
    parser.add_argument("--min-row-count", type=int, default=DEFAULT_MIN_ROW_COUNT)
    parser.add_argument("--attempts", type=int, default=20)
    parser.add_argument("--interval-seconds", type=int, default=15)
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--soft-fail", action="store_true")
    parser.add_argument(
        "--summary-only",
        action="store_true",
        help="Print compact attempt summaries instead of the full sampled payloads.",
    )
    return parser.parse_args()


if __name__ == "__main__":
    raise SystemExit(main())
