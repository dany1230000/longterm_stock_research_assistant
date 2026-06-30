from __future__ import annotations

import argparse
import json
import os
import sys
import time
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[2]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from backend.app.config import settings  # noqa: E402
from backend.scripts.check_public_deploy_drift_00631l import (  # noqa: E402
    run_public_backend_deploy_drift_check,
)
from backend.scripts.compare_public_data_freshness_00631l import (  # noqa: E402
    run_public_data_freshness_check,
)
from backend.scripts.public_backend_status_00631l import DEFAULT_BACKEND_URL  # noqa: E402


def run_public_deploy_wait_check(
    *,
    base_url: str = DEFAULT_BACKEND_URL,
    timeout_seconds: int = 30,
    expected_release_tag: str | None = None,
    expected_git_sha: str | None = None,
    attempts: int = 12,
    interval_seconds: int = 10,
    dry_run: bool = False,
    include_freshness: bool = True,
) -> dict[str, Any]:
    checked_at = _now_iso()
    resolved_expected_tag = (
        expected_release_tag
        or os.getenv("EXPECTED_00631L_RELEASE_TAG")
        or settings.backend_release_tag
    ).strip()
    resolved_expected_sha = (
        expected_git_sha
        if expected_git_sha is not None
        else os.getenv("EXPECTED_00631L_GIT_SHA") or settings.backend_git_sha
    ).strip()

    if dry_run:
        return build_public_deploy_wait_status(
            base_url=_normalize_base_url(base_url),
            checked_at=checked_at,
            expected_release_tag=resolved_expected_tag,
            expected_git_sha=resolved_expected_sha,
            samples=[
                {
                    "overallStatus": "PASS",
                    "summary": {
                        "publicReleaseTag": resolved_expected_tag,
                        "expectedReleaseTag": resolved_expected_tag,
                    },
                    "warnings": [],
                    "failures": [],
                    "dryRun": True,
                }
            ],
            dry_run=True,
            freshness_status={
                "overallStatus": "PASS",
                "summary": {},
                "warnings": [],
                "failures": [],
                "actionItems": [],
                "dryRun": True,
            }
            if include_freshness
            else None,
        )

    samples: list[dict[str, Any]] = []
    total_attempts = max(1, int(attempts or 1))
    interval = max(0, int(interval_seconds or 0))
    for index in range(total_attempts):
        sample = run_public_backend_deploy_drift_check(
            base_url=base_url,
            timeout_seconds=max(1, timeout_seconds),
            expected_release_tag=resolved_expected_tag,
            expected_git_sha=resolved_expected_sha,
        )
        samples.append(sample)
        summary = sample.get("summary") if isinstance(sample.get("summary"), dict) else {}
        if summary.get("publicReleaseTag") == resolved_expected_tag:
            break
        if index < total_attempts - 1 and interval:
            time.sleep(interval)

    freshness_status = None
    if include_freshness:
        try:
            freshness_status = run_public_data_freshness_check(
                base_url=base_url,
                timeout_seconds=max(1, timeout_seconds),
            )
        except Exception as error:  # noqa: BLE001 - operational script summarizes.
            freshness_status = {
                "overallStatus": "WARN",
                "summary": {},
                "warnings": [f"public freshness check failed: {error}"],
                "failures": [],
                "actionItems": [
                    "Rerun scripts\\00631l_compare_public_freshness.cmd."
                ],
            }

    return build_public_deploy_wait_status(
        base_url=_normalize_base_url(base_url),
        checked_at=checked_at,
        expected_release_tag=resolved_expected_tag,
        expected_git_sha=resolved_expected_sha,
        samples=samples,
        freshness_status=freshness_status,
    )


def build_public_deploy_wait_status(
    *,
    base_url: str,
    checked_at: str,
    expected_release_tag: str,
    samples: list[dict[str, Any]],
    expected_git_sha: str | None = None,
    dry_run: bool = False,
    freshness_status: dict[str, Any] | None = None,
) -> dict[str, Any]:
    last_sample = samples[-1] if samples else {}
    last_summary = (
        last_sample.get("summary") if isinstance(last_sample.get("summary"), dict) else {}
    )
    release_tags = [
        str((sample.get("summary") or {}).get("publicReleaseTag") or "")
        for sample in samples
        if isinstance(sample.get("summary"), dict)
    ]
    matched_release = expected_release_tag in release_tags
    failures = [
        str(item)
        for sample in samples
        for item in (sample.get("failures") or [])
    ]
    warnings: list[str] = []
    action_items: list[str] = []

    if not samples:
        warnings.append("No public backend deploy samples were collected.")
    elif not matched_release:
        current_tag = str(last_summary.get("publicReleaseTag") or "unknown")
        warnings.append(
            "public backend deploy is not at expected release yet: "
            f"public={current_tag} expected={expected_release_tag}"
        )
        action_items.append(
            "Wait for the public backend deploy to finish, then rerun "
            "scripts\\00631l_wait_public_deploy.cmd."
        )
    if failures:
        warnings.append("One or more deploy drift samples returned failures.")
        action_items.append(
            "Check public backend health before continuing public ETF history batches."
        )
    freshness_summary = _freshness_summary(freshness_status)
    if freshness_status is not None:
        freshness_overall = str(freshness_status.get("overallStatus") or "WARN")
        freshness_failures = [
            str(item) for item in (freshness_status.get("failures") or [])
        ]
        if freshness_overall == "FAIL" or freshness_failures:
            warnings.append("public backend freshness check failed after deploy.")
        elif freshness_overall == "WARN":
            warnings.append("public backend data freshness needs attention after deploy.")
        action_items.extend(str(item) for item in (freshness_status.get("actionItems") or []))

    overall_status = "PASS" if matched_release and not failures else "WARN"
    if freshness_status is not None and str(freshness_status.get("overallStatus") or "") != "PASS":
        overall_status = "WARN"
    return {
        "sourceContract": "00631l_public_deploy_wait",
        "checkedAt": checked_at,
        "dryRun": dry_run,
        "baseUrl": _normalize_base_url(base_url),
        "overallStatus": overall_status,
        "summary": {
            "expectedReleaseTag": expected_release_tag,
            "expectedGitSha": (expected_git_sha or "").strip(),
            "currentPublicReleaseTag": last_summary.get("publicReleaseTag"),
            "matchedReleaseTag": matched_release,
            "sampleCount": len(samples),
            "publicReleaseTags": release_tags,
            "freshness": freshness_summary,
        },
        "samples": samples,
        "freshnessStatus": freshness_status,
        "warningCount": len(warnings),
        "warnings": warnings,
        "failureCount": 0,
        "failures": [],
        "actionItems": _dedupe(action_items),
    }


def _freshness_summary(freshness_status: dict[str, Any] | None) -> dict[str, Any]:
    if not isinstance(freshness_status, dict):
        return {}
    summary = (
        freshness_status.get("summary")
        if isinstance(freshness_status.get("summary"), dict)
        else {}
    )
    return {
        "overallStatus": freshness_status.get("overallStatus"),
        "publicCoverageEnd": summary.get("publicCoverageEnd"),
        "localCoverageEnd": summary.get("localCoverageEnd"),
        "staticCoverageEnd": summary.get("staticCoverageEnd"),
        "publicCoverageLagDaysVsLocal": summary.get("publicCoverageLagDaysVsLocal"),
        "publicCoverageLagDaysVsStatic": summary.get("publicCoverageLagDaysVsStatic"),
        "publicCatalogRowCount": summary.get("publicCatalogRowCount"),
        "staticCatalogRowCount": summary.get("staticCatalogRowCount"),
        "publicEtfHistoryReadyCount": summary.get("publicEtfHistoryReadyCount"),
        "staticEtfHistoryReadyCount": summary.get("staticEtfHistoryReadyCount"),
        "publicEtfCatalogGapCount": summary.get("publicEtfCatalogGapCount"),
    }


def _dedupe(items: list[str]) -> list[str]:
    seen: set[str] = set()
    output: list[str] = []
    for item in items:
        if item in seen:
            continue
        seen.add(item)
        output.append(item)
    return output


def _normalize_base_url(value: str) -> str:
    return (value.strip() or DEFAULT_BACKEND_URL).rstrip("/")


def _now_iso() -> str:
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat()


def _parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Wait until the public 00631L backend exposes the expected release tag.",
    )
    parser.add_argument(
        "--base-url",
        default=os.getenv("PUBLIC_BACKEND_URL")
        or os.getenv("00631L_PUBLIC_BACKEND_URL")
        or DEFAULT_BACKEND_URL,
    )
    parser.add_argument("--timeout-seconds", type=int, default=30)
    parser.add_argument("--attempts", type=int, default=12)
    parser.add_argument("--interval-seconds", type=int, default=10)
    parser.add_argument(
        "--skip-freshness",
        action="store_true",
        help="Only wait for release metadata; skip public/local/static freshness comparison.",
    )
    parser.add_argument(
        "--expected-release-tag",
        default=os.getenv("EXPECTED_00631L_RELEASE_TAG") or settings.backend_release_tag,
    )
    parser.add_argument(
        "--expected-git-sha",
        default=os.getenv("EXPECTED_00631L_GIT_SHA") or settings.backend_git_sha,
    )
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--soft-fail", action="store_true")
    return parser.parse_args()


def main() -> int:
    args = _parse_args()
    payload = run_public_deploy_wait_check(
        base_url=args.base_url,
        timeout_seconds=max(1, args.timeout_seconds),
        expected_release_tag=args.expected_release_tag,
        expected_git_sha=args.expected_git_sha,
        attempts=max(1, args.attempts),
        interval_seconds=max(0, args.interval_seconds),
        dry_run=args.dry_run,
        include_freshness=not args.skip_freshness,
    )
    print(json.dumps(payload, ensure_ascii=True, indent=2, sort_keys=True))
    summary = payload.get("summary") if isinstance(payload.get("summary"), dict) else {}
    print(
        "[summary] "
        f"overallStatus={payload['overallStatus']} "
        f"warnings={len(payload['warnings'])} "
        f"failures={len(payload['failures'])} "
        f"matched={summary.get('matchedReleaseTag')} "
        f"currentTag={summary.get('currentPublicReleaseTag') or 'unknown'} "
        f"expectedTag={summary.get('expectedReleaseTag') or 'unknown'} "
        f"freshness={(summary.get('freshness') or {}).get('overallStatus') or 'skipped'}"
    )
    return 0 if args.soft_fail or payload["overallStatus"] != "FAIL" else 1


if __name__ == "__main__":
    raise SystemExit(main())
