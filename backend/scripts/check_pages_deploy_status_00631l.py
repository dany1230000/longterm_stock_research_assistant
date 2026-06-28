from __future__ import annotations

import argparse
import json
import os
import socket
import subprocess
import sys
import urllib.error
import urllib.parse
import urllib.request
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Callable


ROOT = Path(__file__).resolve().parents[2]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from backend.scripts.check_public_pages_00631l import (
    DEFAULT_ROOT_URL,
    DEFAULT_STATIC_BASE_URL,
    run_public_pages_check,
)


DEFAULT_REPO = "dany1230000/longterm_stock_research_assistant"
DEFAULT_WORKFLOW = "deploy_web.yml"

FetchJson = Callable[[str, float], dict[str, Any]]


def main() -> int:
    args = _parse_args()
    payload = run_pages_deploy_status_check(
        repo=args.repo,
        workflow=args.workflow,
        branch=args.branch,
        root_url=args.root_url,
        static_base_url=args.static_base_url,
        expected_sha=args.expected_sha,
        timeout=args.timeout,
        dry_run=args.dry_run,
        strict_workflow=args.strict_workflow,
    )
    print(json.dumps(payload, ensure_ascii=False, indent=2, sort_keys=True))
    summary = payload.get("summary") if isinstance(payload.get("summary"), dict) else {}
    print(
        "[summary] "
        f"overallStatus={payload['overallStatus']} "
        f"warnings={payload['warningCount']} "
        f"failures={payload['failureCount']} "
        f"runStatus={summary.get('latestRunStatus') or 'unknown'} "
        f"runConclusion={summary.get('latestRunConclusion') or 'unknown'} "
        f"rows={summary.get('staticRowCount') or 0}"
    )
    return 0 if args.soft_fail or payload["overallStatus"] != "FAIL" else 1


def run_pages_deploy_status_check(
    *,
    repo: str = DEFAULT_REPO,
    workflow: str = DEFAULT_WORKFLOW,
    branch: str = "main",
    root_url: str = DEFAULT_ROOT_URL,
    static_base_url: str = DEFAULT_STATIC_BASE_URL,
    expected_sha: str | None = None,
    timeout: float = 15.0,
    dry_run: bool = False,
    strict_workflow: bool = False,
    fetch_json: FetchJson | None = None,
    public_pages_payload: dict[str, Any] | None = None,
) -> dict[str, Any]:
    checked_at = _now_iso()
    resolved_expected_sha = (expected_sha or _git_head_sha()).strip()
    if dry_run:
        return _payload(
            checked_at=checked_at,
            repo=repo,
            workflow=workflow,
            branch=branch,
            dry_run=True,
            checks=[
                _check("pages_settings", "PASS", "planned"),
                _check("workflow_runs", "PASS", "planned"),
                _check("public_pages_smoke", "PASS", "planned"),
            ],
            summary={
                "expectedSha": resolved_expected_sha,
                "rootUrl": root_url,
                "staticBaseUrl": static_base_url,
            },
        )

    fetch = fetch_json or _fetch_json
    checks = [
        _pages_settings_check(fetch, repo, timeout),
        _workflow_runs_check(
            fetch,
            repo,
            workflow,
            branch,
            resolved_expected_sha,
            timeout,
            strict_workflow=strict_workflow,
        ),
    ]
    pages_payload = public_pages_payload or run_public_pages_check(
        root_url=root_url,
        static_base_url=static_base_url,
        timeout=timeout,
        expected_sha=resolved_expected_sha,
    )
    checks.append(_public_pages_check(pages_payload))
    _downgrade_pages_settings_warning_when_public_smoke_passes(checks)
    _downgrade_workflow_warning_when_public_release_matches(
        checks,
        pages_payload,
        resolved_expected_sha,
    )
    return _payload(
        checked_at=checked_at,
        repo=repo,
        workflow=workflow,
        branch=branch,
        dry_run=False,
        checks=checks,
        summary=_summary(checks, pages_payload, resolved_expected_sha),
    )


def _pages_settings_check(fetch: FetchJson, repo: str, timeout: float) -> dict[str, Any]:
    url = f"https://api.github.com/repos/{repo}/pages"
    response = _safe_fetch_json(fetch, url, timeout)
    if response["status"] != "PASS":
        return response | {"name": "pages_settings"}
    payload = response.get("payload") if isinstance(response.get("payload"), dict) else {}
    html_url = str(payload.get("html_url") or payload.get("url") or "")
    status = str(payload.get("status") or "")
    if not html_url:
        return _check(
            "pages_settings",
            "WARN",
            "GitHub Pages settings responded but html_url is missing.",
            url=url,
            githubPagesStatus=status,
        )
    return _check(
        "pages_settings",
        "PASS",
        "ok",
        url=url,
        htmlUrl=html_url,
        githubPagesStatus=status,
    )


def _workflow_runs_check(
    fetch: FetchJson,
    repo: str,
    workflow: str,
    branch: str,
    expected_sha: str,
    timeout: float,
    *,
    strict_workflow: bool,
) -> dict[str, Any]:
    params = urllib.parse.urlencode({"branch": branch, "per_page": "1"})
    url = f"https://api.github.com/repos/{repo}/actions/workflows/{workflow}/runs?{params}"
    response = _safe_fetch_json(fetch, url, timeout)
    if response["status"] != "PASS":
        return response | {"name": "workflow_runs"}
    payload = response.get("payload") if isinstance(response.get("payload"), dict) else {}
    runs = payload.get("workflow_runs")
    if not isinstance(runs, list) or not runs:
        return _check(
            "workflow_runs",
            "WARN",
            "No GitHub Pages workflow runs were returned.",
            url=url,
        )
    latest = runs[0] if isinstance(runs[0], dict) else {}
    status = str(latest.get("status") or "")
    conclusion = str(latest.get("conclusion") or "")
    head_sha = str(latest.get("head_sha") or "")
    run_url = str(latest.get("html_url") or "")
    warnings: list[str] = []
    failures: list[str] = []

    if status != "completed":
        warnings.append(f"latest Pages workflow is {status or 'unknown'}")
    elif conclusion and conclusion != "success":
        message = f"latest Pages workflow conclusion is {conclusion}"
        if strict_workflow:
            failures.append(message)
        else:
            warnings.append(message)
    if expected_sha and head_sha and not head_sha.startswith(expected_sha[:12]):
        warnings.append(
            "latest Pages workflow head sha differs from local HEAD: "
            f"workflow={head_sha[:12]} local={expected_sha[:12]}"
        )
    status_value = "FAIL" if failures else "WARN" if warnings else "PASS"
    return _check(
        "workflow_runs",
        status_value,
        "; ".join([*failures, *warnings]) if status_value != "PASS" else "ok",
        url=url,
        latestRunStatus=status,
        latestRunConclusion=conclusion,
        latestRunHeadSha=head_sha,
        latestRunUrl=run_url,
    )


def _public_pages_check(payload: dict[str, Any]) -> dict[str, Any]:
    status = str(payload.get("overallStatus") or "WARN")
    message = (
        "ok"
        if status == "PASS"
        else "; ".join(str(item) for item in payload.get("failures") or payload.get("warnings") or [])
        or status
    )
    return _check(
        "public_pages_smoke",
        status if status in {"PASS", "WARN", "FAIL"} else "WARN",
        message,
        rowCount=payload.get("rowCount"),
        coverageStart=payload.get("coverageStart"),
        coverageEnd=payload.get("coverageEnd"),
        rootUrl=payload.get("rootUrl"),
    )


def _safe_fetch_json(fetch: FetchJson, url: str, timeout: float) -> dict[str, Any]:
    try:
        return _check("fetch", "PASS", "ok", url=url, payload=fetch(url, timeout))
    except urllib.error.HTTPError as error:
        return _check(
            "fetch",
            "WARN",
            f"{url} unavailable: HTTP {error.code}",
            url=url,
            httpStatus=error.code,
            errorMessage=str(error),
        )
    except (OSError, urllib.error.URLError, socket.timeout, json.JSONDecodeError) as error:
        return _check(
            "fetch",
            "WARN",
            f"{url} unavailable: {error}",
            url=url,
            errorMessage=str(error),
        )


def _downgrade_pages_settings_warning_when_public_smoke_passes(checks: list[dict[str, Any]]) -> None:
    pages = _find_check(checks, "pages_settings")
    workflow = _find_check(checks, "workflow_runs")
    public_pages = _find_check(checks, "public_pages_smoke")
    if (
        pages.get("status") == "WARN"
        and int(pages.get("httpStatus") or 0) == 404
        and workflow.get("status") == "PASS"
        and public_pages.get("status") == "PASS"
    ):
        pages["status"] = "PASS"
        pages["message"] = "GitHub Pages settings API returned 404, but workflow and public smoke passed."


def _downgrade_workflow_warning_when_public_release_matches(
    checks: list[dict[str, Any]],
    public_pages_payload: dict[str, Any],
    expected_sha: str,
) -> None:
    if not expected_sha:
        return
    workflow = _find_check(checks, "workflow_runs")
    public_pages = _find_check(checks, "public_pages_smoke")
    if workflow.get("status") != "WARN" or public_pages.get("status") != "PASS":
        return
    release_sha = str(public_pages_payload.get("releaseGitSha") or "")
    if not release_sha or not release_sha.startswith(expected_sha[:12]):
        return
    workflow["status"] = "PASS"
    workflow["message"] = (
        "Latest workflow run is not the deciding signal because the public release marker "
        "matches expected HEAD."
    )
    workflow["publicReleaseGitSha"] = release_sha


def _fetch_json(url: str, timeout: float) -> dict[str, Any]:
    headers = {
        "Accept": "application/vnd.github+json",
        "User-Agent": "00631l-pages-deploy-status/1.0",
        "X-GitHub-Api-Version": "2022-11-28",
    }
    token = os.getenv("GITHUB_TOKEN", "").strip()
    if token:
        headers["Authorization"] = f"Bearer {token}"
    request = urllib.request.Request(url, headers=headers)
    with urllib.request.urlopen(request, timeout=timeout) as response:
        body = response.read().decode("utf-8", errors="replace")
        return json.loads(body) if body.strip() else {}


def _payload(
    *,
    checked_at: str,
    repo: str,
    workflow: str,
    branch: str,
    dry_run: bool,
    checks: list[dict[str, Any]],
    summary: dict[str, Any],
) -> dict[str, Any]:
    failures = [
        f"{check['name']}: {check['message']}"
        for check in checks
        if check.get("status") == "FAIL"
    ]
    warnings = [
        f"{check['name']}: {check['message']}"
        for check in checks
        if check.get("status") == "WARN"
    ]
    return {
        "sourceContract": "00631l_pages_deploy_status",
        "checkedAt": checked_at,
        "repo": repo,
        "workflow": workflow,
        "branch": branch,
        "dryRun": dry_run,
        "overallStatus": "FAIL" if failures else "WARN" if warnings else "PASS",
        "checks": [_strip_payload(check) for check in checks],
        "summary": summary,
        "warnings": warnings,
        "failures": failures,
        "warningCount": len(warnings),
        "failureCount": len(failures),
    }


def _summary(
    checks: list[dict[str, Any]],
    public_pages_payload: dict[str, Any],
    expected_sha: str,
) -> dict[str, Any]:
    workflow = _find_check(checks, "workflow_runs")
    pages = _find_check(checks, "pages_settings")
    return {
        "expectedSha": expected_sha,
        "pagesUrl": pages.get("htmlUrl"),
        "githubPagesStatus": pages.get("githubPagesStatus"),
        "latestRunStatus": workflow.get("latestRunStatus"),
        "latestRunConclusion": workflow.get("latestRunConclusion"),
        "latestRunHeadSha": workflow.get("latestRunHeadSha"),
        "latestRunUrl": workflow.get("latestRunUrl"),
        "staticRowCount": public_pages_payload.get("rowCount"),
        "coverageStart": public_pages_payload.get("coverageStart"),
        "coverageEnd": public_pages_payload.get("coverageEnd"),
        "rootUrl": public_pages_payload.get("rootUrl"),
        "publicReleaseGitSha": public_pages_payload.get("releaseGitSha"),
        "publicReleaseTag": public_pages_payload.get("releaseTag"),
    }


def _find_check(checks: list[dict[str, Any]], name: str) -> dict[str, Any]:
    return next((check for check in checks if check.get("name") == name), {})


def _strip_payload(check: dict[str, Any]) -> dict[str, Any]:
    stripped = dict(check)
    stripped.pop("payload", None)
    return stripped


def _check(name: str, status: str, message: str, **extra: Any) -> dict[str, Any]:
    payload = {"name": name, "status": status, "message": message}
    payload.update(extra)
    return payload


def _git_head_sha() -> str:
    try:
        result = subprocess.run(
            ["git", "rev-parse", "HEAD"],
            text=True,
            capture_output=True,
            check=False,
        )
    except OSError:
        return ""
    return result.stdout.strip() if result.returncode == 0 else ""


def _now_iso() -> str:
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat()


def _parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Check GitHub Pages deployment status and the public 00631L PWA smoke result.",
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
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--strict-workflow", action="store_true")
    parser.add_argument("--soft-fail", action="store_true")
    return parser.parse_args()


if __name__ == "__main__":
    raise SystemExit(main())
