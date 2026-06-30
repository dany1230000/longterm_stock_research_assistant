from __future__ import annotations

import argparse
import json
import os
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[2]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from backend.app.config import settings  # noqa: E402
from backend.scripts.public_backend_status_00631l import (  # noqa: E402
    DEFAULT_BACKEND_URL,
    run_public_backend_status,
)


def run_public_backend_deploy_drift_check(
    *,
    base_url: str = DEFAULT_BACKEND_URL,
    timeout_seconds: int = 30,
    expected_release_tag: str | None = None,
    expected_git_sha: str | None = None,
    dry_run: bool = False,
) -> dict[str, Any]:
    checked_at = _now_iso()
    resolved_expected_tag = resolve_expected_release_tag(expected_release_tag)
    resolved_expected_sha = (
        expected_git_sha
        if expected_git_sha is not None
        else os.getenv("EXPECTED_00631L_GIT_SHA")
        or settings.backend_git_sha
        or _git_head_sha()
    ).strip()

    if dry_run:
        return {
            "sourceContract": "00631l_public_backend_deploy_drift",
            "checkedAt": checked_at,
            "dryRun": True,
            "overallStatus": "PASS",
            "summary": {
                "baseUrl": _normalize_base_url(base_url),
                "expectedReleaseTag": resolved_expected_tag,
                "expectedGitSha": resolved_expected_sha,
            },
            "steps": [
                {
                    "name": "public_backend_status",
                    "status": "PASS",
                    "message": "planned",
                },
                {
                    "name": "release_metadata_compare",
                    "status": "PASS",
                    "message": "planned",
                },
            ],
            "warnings": [],
            "failures": [],
            "actionItems": [],
        }

    public_status = run_public_backend_status(
        base_url=base_url,
        timeout_seconds=max(1, timeout_seconds),
    )
    return check_public_backend_deploy_drift(
        public_status=public_status,
        expected_release_tag=resolved_expected_tag,
        expected_git_sha=resolved_expected_sha,
        checked_at=checked_at,
    )


def check_public_backend_deploy_drift(
    *,
    public_status: dict[str, Any],
    expected_release_tag: str,
    expected_git_sha: str | None = None,
    checked_at: str,
) -> dict[str, Any]:
    summary = (
        public_status.get("summary")
        if isinstance(public_status.get("summary"), dict)
        else {}
    )
    public_overall = str(public_status.get("overallStatus") or "WARN")
    public_release_tag = str(summary.get("releaseTag") or "")
    public_git_sha = str(summary.get("gitSha") or "")
    public_git_sha_status = "present" if public_git_sha else "missing"
    public_backend_version = str(summary.get("backendVersion") or "")
    expected_git_sha = (expected_git_sha or "").strip()

    failures: list[str] = []
    warnings: list[str] = []
    action_items: list[str] = []

    if public_overall == "FAIL":
        failures.extend(str(item) for item in public_status.get("failures") or [])
        if not failures:
            failures.append("public backend status check failed")
    elif public_overall == "WARN":
        warnings.append("public backend status check returned WARN")

    if expected_release_tag and public_release_tag != expected_release_tag:
        warnings.append(
            "public backend release tag differs: "
            f"public={public_release_tag or 'unknown'} expected={expected_release_tag}"
        )
        action_items.append(
            "Redeploy the public backend from the latest main branch, then rerun "
            "scripts\\00631l_public_deploy_drift.cmd."
        )

    if expected_git_sha and public_git_sha and public_git_sha != expected_git_sha:
        warnings.append(
            "public backend git sha differs: "
            f"public={public_git_sha} expected={expected_git_sha}"
        )
    elif (
        expected_git_sha
        and not public_git_sha
        and public_release_tag != expected_release_tag
    ):
        warnings.append(
            "public backend git sha is not exposed; set 00631L_BACKEND_GIT_SHA during deploy."
        )

    steps = [
        {
            "name": "public_backend_status",
            "status": public_overall if public_overall in {"PASS", "WARN", "FAIL"} else "WARN",
            "message": public_overall,
        },
        {
            "name": "release_metadata_compare",
            "status": "FAIL" if failures else "WARN" if warnings else "PASS",
            "message": "release metadata compared",
        },
    ]
    return {
        "sourceContract": "00631l_public_backend_deploy_drift",
        "checkedAt": checked_at,
        "dryRun": False,
        "overallStatus": "FAIL" if failures else "WARN" if warnings else "PASS",
        "summary": {
            "baseUrl": public_status.get("baseUrl"),
            "publicBackendVersion": public_backend_version,
            "publicReleaseTag": public_release_tag,
            "publicGitSha": public_git_sha,
            "publicGitShaStatus": public_git_sha_status,
            "expectedReleaseTag": expected_release_tag,
            "expectedGitSha": expected_git_sha,
        },
        "steps": steps,
        "warnings": warnings,
        "failures": failures,
        "actionItems": _dedupe(action_items),
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


def resolve_expected_release_tag(explicit_release_tag: str | None = None) -> str:
    return (
        explicit_release_tag
        or os.getenv("EXPECTED_00631L_RELEASE_TAG")
        or _git_exact_release_tag()
        or settings.backend_release_tag
    ).strip()


def _git_exact_release_tag() -> str:
    try:
        result = subprocess.run(
            ["git", "tag", "--points-at", "HEAD", "--list", "00631l-lab-v*"],
            cwd=ROOT,
            text=True,
            capture_output=True,
            check=False,
        )
    except OSError:
        return ""
    if result.returncode != 0:
        return ""
    tags = sorted(item.strip() for item in result.stdout.splitlines() if item.strip())
    return tags[-1] if tags else ""


def _git_head_sha() -> str:
    try:
        result = subprocess.run(
            ["git", "rev-parse", "HEAD"],
            cwd=ROOT,
            text=True,
            capture_output=True,
            check=False,
        )
    except OSError:
        return ""
    return result.stdout.strip() if result.returncode == 0 else ""


def _normalize_base_url(value: str) -> str:
    return (value.strip() or DEFAULT_BACKEND_URL).rstrip("/")


def _now_iso() -> str:
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat()


def _parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Check whether the public 00631L backend is deployed from the expected release.",
    )
    parser.add_argument(
        "--base-url",
        default=os.getenv("PUBLIC_BACKEND_URL")
        or os.getenv("00631L_PUBLIC_BACKEND_URL")
        or DEFAULT_BACKEND_URL,
    )
    parser.add_argument("--timeout-seconds", type=int, default=30)
    parser.add_argument(
        "--expected-release-tag",
        default=resolve_expected_release_tag(),
    )
    parser.add_argument(
        "--expected-git-sha",
        default=os.getenv("EXPECTED_00631L_GIT_SHA")
        or settings.backend_git_sha
        or _git_head_sha(),
    )
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--soft-fail", action="store_true")
    return parser.parse_args()


def main() -> int:
    args = _parse_args()
    payload = run_public_backend_deploy_drift_check(
        base_url=args.base_url,
        timeout_seconds=max(1, args.timeout_seconds),
        expected_release_tag=args.expected_release_tag,
        expected_git_sha=args.expected_git_sha,
        dry_run=args.dry_run,
    )
    print(json.dumps(payload, ensure_ascii=True, indent=2, sort_keys=True))
    summary = payload.get("summary") if isinstance(payload.get("summary"), dict) else {}
    print(
        "[summary] "
        f"overallStatus={payload['overallStatus']} "
        f"warnings={len(payload['warnings'])} "
        f"failures={len(payload['failures'])} "
        f"publicTag={summary.get('publicReleaseTag') or 'unknown'} "
        f"expectedTag={summary.get('expectedReleaseTag') or 'unknown'}"
    )
    return 0 if args.soft_fail or payload["overallStatus"] != "FAIL" else 1


if __name__ == "__main__":
    raise SystemExit(main())
