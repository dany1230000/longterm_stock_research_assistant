from __future__ import annotations

import argparse
from datetime import datetime, timezone
import json
from pathlib import Path
import sys
from typing import Any
from urllib.error import URLError
from urllib.request import Request, urlopen


ROOT = Path(__file__).resolve().parents[2]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from backend.app.static_export import static_export_status  # noqa: E402


DEFAULT_STATIC_BASE_URL = (
    "https://dany1230000.github.io/"
    "longterm_stock_research_assistant/00631l-static-data/"
)


def run_static_public_regression_guard(
    *,
    local_dir: str | Path,
    public_base_url: str = DEFAULT_STATIC_BASE_URL,
    timeout_seconds: int = 20,
    remote_status: dict[str, Any] | None = None,
    local_status: dict[str, Any] | None = None,
    dry_run: bool = False,
) -> dict[str, Any]:
    checked_at = _now_iso()
    if dry_run:
        return {
            "sourceContract": "00631l_static_public_regression_guard",
            "checkedAt": checked_at,
            "dryRun": True,
            "overallStatus": "PASS",
            "warnings": [],
            "failures": [],
            "summary": {},
        }

    resolved_local = local_status or static_export_status(Path(local_dir))
    warnings: list[str] = []
    failures: list[str] = []
    resolved_remote: dict[str, Any] | None = remote_status
    if resolved_remote is None:
        try:
            resolved_remote = _fetch_remote_status(public_base_url, timeout_seconds)
        except Exception as error:  # noqa: BLE001 - unavailable public status should not block local validation.
            warnings.append(f"publicStatusUnavailable={error}")
            resolved_remote = None

    local_end = _text_or_none(resolved_local.get("coverageEnd"))
    local_rows = _int(resolved_local.get("rowCount"))
    local_etf_ready = _int(resolved_local.get("etfPriceHistoryReadyCount"))
    local_release = _release_dict(resolved_local)

    remote_end = _text_or_none(resolved_remote.get("coverageEnd")) if resolved_remote else None
    remote_rows = _int(resolved_remote.get("rowCount")) if resolved_remote else 0
    remote_etf_ready = (
        _int(resolved_remote.get("etfPriceHistoryReadyCount")) if resolved_remote else 0
    )
    remote_release = _release_dict(resolved_remote) if resolved_remote else {}
    local_release_id = _release_id(local_release)
    remote_release_id = _release_id(remote_release)
    local_release_matches_public = bool(
        local_release_id and remote_release_id and local_release_id == remote_release_id
    )
    local_release_differs_from_public = bool(
        local_release_id and remote_release_id and local_release_id != remote_release_id
    )
    if resolved_remote and local_release_differs_from_public:
        warnings.append(
            "local static export release differs from public; regenerate static data "
            f"before deploy: local={local_release_id}, public={remote_release_id}"
        )

    if resolved_remote:
        local_day = _parse_day(local_end)
        remote_day = _parse_day(remote_end)
        if local_day is not None and remote_day is not None and local_day < remote_day:
            _add_regression(
                failures,
                f"localCoverageEnd {local_end} is older than public {remote_end}",
            )
        elif local_day == remote_day and local_rows < remote_rows:
            _add_regression(
                failures,
                f"local rowCount {local_rows} is lower than public {remote_rows}",
            )
        if local_etf_ready < remote_etf_ready:
            _add_regression(
                failures,
                "local ETF ready count "
                f"{local_etf_ready} is lower than public {remote_etf_ready}",
            )

    overall = "FAIL" if failures else "WARN" if warnings else "PASS"
    return {
        "sourceContract": "00631l_static_public_regression_guard",
        "checkedAt": checked_at,
        "dryRun": False,
        "overallStatus": overall,
        "warnings": warnings,
        "failures": failures,
        "summary": {
            "localCoverageEnd": local_end,
            "localRowCount": local_rows,
            "localEtfReadyCount": local_etf_ready,
            "localReleaseTag": local_release.get("releaseTag"),
            "localGitSha": local_release.get("gitSha"),
            "localReleaseMatchesPublic": local_release_matches_public,
            "publicCoverageEnd": remote_end,
            "publicRowCount": remote_rows,
            "publicEtfReadyCount": remote_etf_ready,
            "publicReleaseTag": remote_release.get("releaseTag"),
            "publicGitSha": remote_release.get("gitSha"),
        },
    }


def _add_regression(
    failures: list[str],
    message: str,
) -> None:
    failures.append(message)


def _release_id(release: dict[str, Any]) -> str | None:
    git_sha = _text_or_none(release.get("gitSha"))
    release_tag = _text_or_none(release.get("releaseTag"))
    if git_sha:
        return git_sha
    return release_tag


def _fetch_remote_status(public_base_url: str, timeout_seconds: int) -> dict[str, Any]:
    base = public_base_url.rstrip("/") + "/"
    status_payload = _fetch_remote_json(base + "status.json", timeout_seconds)
    try:
        manifest_payload = _fetch_remote_json(base + "manifest.json", timeout_seconds)
    except Exception:
        manifest_payload = {}
    if isinstance(manifest_payload, dict):
        merged = dict(status_payload)
        for key in (
            "etfCatalogRowCount",
            "etfPriceHistoryReadyCount",
            "etfPriceHistoryMissingCount",
            "etfPriceHistoryRowCount",
            "etfPriceHistoryCoverageTierCounts",
            "release",
        ):
            if key in manifest_payload:
                merged[key] = manifest_payload[key]
        return merged
    return status_payload


def _fetch_remote_json(url: str, timeout_seconds: int) -> dict[str, Any]:
    request = Request(url, headers={"User-Agent": "00631l-static-guard"})
    with urlopen(request, timeout=max(1, timeout_seconds)) as response:
        data = response.read()
    if not data:
        raise URLError(f"empty public response: {url}")
    payload = json.loads(data.decode("utf-8"))
    if not isinstance(payload, dict):
        raise ValueError(f"public response is not an object: {url}")
    return payload


def _release_dict(payload: dict[str, Any] | None) -> dict[str, Any]:
    if not isinstance(payload, dict):
        return {}
    release = payload.get("release")
    return release if isinstance(release, dict) else {}


def _parse_day(value: str | None):
    if not value:
        return None
    try:
        return datetime.strptime(value[:10], "%Y-%m-%d").date()
    except ValueError:
        return None


def _text_or_none(value: Any) -> str | None:
    text = str(value or "").strip()
    return text or None


def _int(value: Any) -> int:
    try:
        return int(value or 0)
    except (TypeError, ValueError):
        return 0


def _now_iso() -> str:
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat()


def _parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Fail when a local static export would regress current public data.",
    )
    parser.add_argument("--local-dir", default=str(ROOT / "web" / "00631l-static-data"))
    parser.add_argument("--public-base-url", default=DEFAULT_STATIC_BASE_URL)
    parser.add_argument("--timeout-seconds", type=int, default=20)
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--soft-fail", action="store_true")
    return parser.parse_args()


def main() -> int:
    args = _parse_args()
    payload = run_static_public_regression_guard(
        local_dir=args.local_dir,
        public_base_url=args.public_base_url,
        timeout_seconds=args.timeout_seconds,
        dry_run=args.dry_run,
    )
    print(json.dumps(payload, ensure_ascii=True, indent=2, sort_keys=True))
    summary = payload.get("summary") or {}
    print(
        "[summary] "
        f"overallStatus={payload['overallStatus']} "
        f"warnings={len(payload['warnings'])} "
        f"failures={len(payload['failures'])} "
        f"localEnd={summary.get('localCoverageEnd') or 'unknown'} "
        f"publicEnd={summary.get('publicCoverageEnd') or 'unknown'} "
        f"localRows={summary.get('localRowCount') or 0} "
        f"publicRows={summary.get('publicRowCount') or 0} "
        f"localEtfReady={summary.get('localEtfReadyCount') or 0} "
        f"publicEtfReady={summary.get('publicEtfReadyCount') or 0}"
    )
    return 0 if args.soft_fail or payload["overallStatus"] != "FAIL" else 1


if __name__ == "__main__":
    raise SystemExit(main())
