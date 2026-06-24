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

from backend.scripts.check_pages_deploy_status_00631l import (  # noqa: E402
    DEFAULT_REPO,
    DEFAULT_WORKFLOW,
    run_pages_deploy_status_check,
)
from backend.scripts.check_public_pages_00631l import (  # noqa: E402
    DEFAULT_ROOT_URL,
    DEFAULT_STATIC_BASE_URL,
    run_public_pages_check,
)


def main() -> int:
    args = _parse_args()
    expected_sha = (args.expected_sha or _git_head_sha()).strip()
    public_pages = run_public_pages_check(
        root_url=args.root_url,
        static_base_url=args.static_base_url,
        timeout=args.timeout,
        min_row_count=args.min_row_count,
        expected_sha=expected_sha,
    )
    deploy_status = (
        _skipped_deploy_status(
            repo=args.repo,
            workflow=args.workflow,
            branch=args.branch,
            expected_sha=expected_sha,
            root_url=args.root_url,
            static_base_url=args.static_base_url,
        )
        if args.skip_github_api
        else run_pages_deploy_status_check(
            repo=args.repo,
            workflow=args.workflow,
            branch=args.branch,
            root_url=args.root_url,
            static_base_url=args.static_base_url,
            expected_sha=args.expected_sha,
            timeout=args.timeout,
        )
    )
    payload = build_public_pages_checkup(
        public_pages=public_pages,
        deploy_status=deploy_status,
        expected_sha=expected_sha,
        github_api_mode="skipped" if args.skip_github_api else "checked",
    )
    print(json.dumps(payload, ensure_ascii=False, indent=2, sort_keys=True))
    summary = payload.get("summary") if isinstance(payload.get("summary"), dict) else {}
    print(
        "[summary] "
        f"overallStatus={payload['overallStatus']} "
        f"warnings={payload['warningCount']} "
        f"failures={payload['failureCount']} "
        f"rows={summary.get('staticRowCount') or 0} "
        f"coverage={summary.get('coverageStart') or '-'}..{summary.get('coverageEnd') or '-'} "
        f"workflow={summary.get('latestRunStatus') or 'unknown'}/{summary.get('latestRunConclusion') or 'unknown'} "
        f"githubApi={summary.get('githubApiMode') or 'checked'}"
    )
    return 0 if args.soft_fail or payload["overallStatus"] != "FAIL" else 1


def build_public_pages_checkup(
    *,
    public_pages: dict[str, Any],
    deploy_status: dict[str, Any],
    expected_sha: str,
    github_api_mode: str = "checked",
) -> dict[str, Any]:
    checked_at = _now_iso()
    deploy_summary = (
        deploy_status.get("summary") if isinstance(deploy_status.get("summary"), dict) else {}
    )
    failures: list[str] = []
    warnings: list[str] = []
    action_items: list[str] = []

    if public_pages.get("overallStatus") == "FAIL":
        failures.extend(f"public_pages: {item}" for item in public_pages.get("failures") or [])
        if not failures:
            failures.append("public_pages: public PWA smoke failed")
    elif public_pages.get("overallStatus") == "WARN":
        warnings.extend(f"public_pages: {item}" for item in public_pages.get("warnings") or [])

    github_api_skipped = github_api_mode == "skipped"

    if deploy_status.get("overallStatus") == "FAIL":
        failures.extend(f"deploy_status: {item}" for item in deploy_status.get("failures") or [])
        if not failures:
            failures.append("deploy_status: Pages deployment status failed")
    elif deploy_status.get("overallStatus") == "WARN":
        warnings.extend(f"deploy_status: {item}" for item in deploy_status.get("warnings") or [])

    latest_sha = str(deploy_summary.get("latestRunHeadSha") or "")
    latest_status = str(deploy_summary.get("latestRunStatus") or "")
    latest_conclusion = str(deploy_summary.get("latestRunConclusion") or "")
    if github_api_skipped:
        latest_status = "skipped"
        latest_conclusion = "skipped"
    elif expected_sha and latest_sha and not latest_sha.startswith(expected_sha[:12]):
        warnings.append(
            "latest Pages workflow does not match local HEAD: "
            f"workflow={latest_sha[:12]} local={expected_sha[:12]}"
        )
        action_items.append("Run scripts\\00631l_wait_pages_deploy.cmd after pushing the latest commit.")
    elif latest_status != "completed" or latest_conclusion != "success":
        warnings.append(
            "latest Pages workflow is not completed successfully: "
            f"status={latest_status or 'unknown'} conclusion={latest_conclusion or 'unknown'}"
        )
        action_items.append("Wait for GitHub Pages to finish, then rerun scripts\\00631l_public_pages_checkup.cmd.")

    row_count = int(public_pages.get("rowCount") or 0)
    if row_count < 2:
        warnings.append("static public data has fewer than 2 rows")
        action_items.append("Run scripts\\00631l_export_static_data.cmd --update before building Pages.")

    if _looks_rate_limited(deploy_status):
        action_items.append(
            "GitHub API is rate-limited; use scripts\\00631l_public_pages_checkup.cmd --skip-github-api "
            "for a public PWA/static-data check."
        )

    return {
        "sourceContract": "00631l_public_pages_checkup",
        "checkedAt": checked_at,
        "overallStatus": "FAIL" if failures else "WARN" if warnings else "PASS",
        "summary": {
            "githubApiMode": github_api_mode,
            "publicUrl": public_pages.get("rootUrl") or DEFAULT_ROOT_URL,
            "hashUrl": public_pages.get("hashUrl"),
            "staticBaseUrl": public_pages.get("staticBaseUrl") or DEFAULT_STATIC_BASE_URL,
            "staticRowCount": row_count,
            "coverageStart": public_pages.get("coverageStart"),
            "coverageEnd": public_pages.get("coverageEnd"),
            "latestRunStatus": latest_status,
            "latestRunConclusion": latest_conclusion,
            "latestRunHeadSha": latest_sha,
            "latestRunUrl": deploy_summary.get("latestRunUrl"),
            "expectedSha": expected_sha,
        },
        "publicPages": public_pages,
        "deployStatus": deploy_status,
        "warnings": _dedupe(warnings),
        "failures": _dedupe(failures),
        "warningCount": len(_dedupe(warnings)),
        "failureCount": len(_dedupe(failures)),
        "actionItems": _dedupe(action_items),
    }


def _skipped_deploy_status(
    *,
    repo: str,
    workflow: str,
    branch: str,
    expected_sha: str,
    root_url: str,
    static_base_url: str,
) -> dict[str, Any]:
    return {
        "sourceContract": "00631l_pages_deploy_status",
        "checkedAt": _now_iso(),
        "repo": repo,
        "workflow": workflow,
        "branch": branch,
        "dryRun": False,
        "overallStatus": "PASS",
        "checks": [
            {
                "name": "github_api",
                "status": "PASS",
                "message": "skipped by --skip-github-api",
            }
        ],
        "summary": {
            "expectedSha": expected_sha,
            "latestRunStatus": "skipped",
            "latestRunConclusion": "skipped",
            "latestRunHeadSha": "",
            "latestRunUrl": None,
            "staticRowCount": None,
            "coverageStart": None,
            "coverageEnd": None,
            "rootUrl": root_url,
            "staticBaseUrl": static_base_url,
        },
        "warnings": [],
        "failures": [],
        "warningCount": 0,
        "failureCount": 0,
    }


def _looks_rate_limited(payload: dict[str, Any]) -> bool:
    text = json.dumps(payload, ensure_ascii=False).lower()
    return "rate limit" in text or "api rate limit" in text or "http 403" in text


def _dedupe(items: list[str]) -> list[str]:
    seen: set[str] = set()
    output: list[str] = []
    for item in items:
        if item in seen:
            continue
        seen.add(item)
        output.append(item)
    return output


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
        description="Run a concise public 00631L Pages checkup for phone usage.",
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
    parser.add_argument("--min-row-count", type=int, default=2800)
    parser.add_argument(
        "--skip-github-api",
        "--public-only",
        action="store_true",
        help="Only check the public PWA/static data and skip GitHub workflow API calls.",
    )
    parser.add_argument("--soft-fail", action="store_true")
    return parser.parse_args()


if __name__ == "__main__":
    raise SystemExit(main())
