from __future__ import annotations

import argparse
import json
import os
from pathlib import Path
import sys
from typing import Any, Callable
from urllib.error import URLError
from urllib.request import Request, urlopen


ROOT = Path(__file__).resolve().parents[2]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from backend.app.config import settings  # noqa: E402
from backend.app.price_history import PriceHistoryStore, utc_now_iso  # noqa: E402


DEFAULT_PUBLIC_STATIC_DATA_BASE_URL = (
    "https://dany1230000.github.io/"
    "longterm_stock_research_assistant/00631l-static-data"
)
FetchText = Callable[[str, float], str]


def main() -> int:
    parser = argparse.ArgumentParser(
        description=(
            "Restore the deployed public 00631L static price history into the "
            "local primary 00631L history store before exporting a new Pages build."
        ),
    )
    parser.add_argument(
        "--base-url",
        default=os.getenv(
            "00631L_PUBLIC_STATIC_DATA_BASE_URL",
            DEFAULT_PUBLIC_STATIC_DATA_BASE_URL,
        ),
    )
    parser.add_argument("--price-url", default="")
    parser.add_argument("--output-path", default=settings.price_history_path)
    parser.add_argument(
        "--timeout-seconds",
        type=float,
        default=float(settings.request_timeout_seconds),
    )
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--summary-only", action="store_true")
    args = parser.parse_args()

    payload = restore_public_00631l_price_history(
        base_url=args.base_url,
        price_url=args.price_url,
        output_path=args.output_path,
        timeout_seconds=args.timeout_seconds,
        dry_run=args.dry_run,
    )
    print(
        json.dumps(
            compact_restore_response(payload) if args.summary_only else payload,
            ensure_ascii=False,
            indent=2,
            sort_keys=True,
        ),
    )
    print(build_restore_summary_line(payload))
    return 1 if payload["overallStatus"] == "FAIL" else 0


def restore_public_00631l_price_history(
    *,
    base_url: str,
    price_url: str = "",
    output_path: str | Path,
    timeout_seconds: float,
    dry_run: bool = False,
    fetcher: FetchText | None = None,
) -> dict[str, Any]:
    checked_at = utc_now_iso()
    normalized_base_url = _base_url(base_url)
    url = price_url.strip() or f"{normalized_base_url}/price_history.json"
    fetch = fetcher or _fetch_url_text
    try:
        decoded = json.loads(fetch(url, timeout_seconds))
    except (OSError, URLError, json.JSONDecodeError) as error:
        return {
            "sourceStatus": "unavailable",
            "sourceContract": "00631l_public_price_history_restore",
            "checkedAt": checked_at,
            "sourceUrl": url,
            "outputPath": str(output_path),
            "dryRun": dry_run,
            "localRowCount": 0,
            "localCoverageEnd": None,
            "publicRowCount": 0,
            "publicCoverageEnd": None,
            "restoreNeeded": False,
            "savedRowCount": 0,
            "overallStatus": "WARN",
            "warnings": [f"Public 00631L price history unavailable: {error}"],
            "warningCount": 1,
            "failures": [],
            "errorMessage": str(error),
        }

    if not isinstance(decoded, dict):
        return _invalid_payload_response(
            checked_at=checked_at,
            url=url,
            output_path=output_path,
            dry_run=dry_run,
            message="Public 00631L price history is not a JSON object.",
        )
    points = decoded.get("items")
    if not isinstance(points, list) or len(points) < 2:
        return _invalid_payload_response(
            checked_at=checked_at,
            url=url,
            output_path=output_path,
            dry_run=dry_run,
            message="Public 00631L price history has fewer than 2 rows.",
        )

    public_points = [point for point in points if isinstance(point, dict)]
    public_row_count = int(decoded.get("rowCount") or len(public_points))
    public_coverage_end = _last_date(public_points) or _text_or_none(
        decoded.get("coverageEnd"),
    )

    store = PriceHistoryStore(output_path)
    local_status = store.status_response(fetched_at=checked_at)
    local_row_count = int(local_status.get("rowCount") or 0)
    local_coverage_end = _text_or_none(local_status.get("coverageEnd"))
    restore_needed = _public_is_newer_or_larger(
        public_coverage_end=public_coverage_end,
        public_row_count=public_row_count,
        local_coverage_end=local_coverage_end,
        local_row_count=local_row_count,
    )

    saved_rows = 0
    if restore_needed:
        saved_rows = len(public_points) if dry_run else store.save_points(public_points)

    warnings: list[str] = []
    if not restore_needed:
        warnings.append("Public 00631L price history is not newer than local data.")
    return {
        "sourceStatus": "static_official",
        "sourceContract": "00631l_public_price_history_restore",
        "checkedAt": checked_at,
        "sourceUrl": url,
        "baseUrl": normalized_base_url,
        "outputPath": str(output_path),
        "dryRun": dry_run,
        "localRowCount": local_row_count,
        "localCoverageEnd": local_coverage_end,
        "publicRowCount": public_row_count,
        "publicCoverageEnd": public_coverage_end,
        "restoreNeeded": restore_needed,
        "savedRowCount": saved_rows,
        "overallStatus": "WARN" if warnings else "PASS",
        "warnings": warnings,
        "warningCount": len(warnings),
        "failures": [],
        "errorMessage": None,
    }


def compact_restore_response(payload: dict[str, Any]) -> dict[str, Any]:
    return {
        "sourceStatus": payload.get("sourceStatus"),
        "sourceContract": payload.get("sourceContract"),
        "overallStatus": payload.get("overallStatus"),
        "sourceUrl": payload.get("sourceUrl"),
        "checkedAt": payload.get("checkedAt"),
        "outputPath": payload.get("outputPath"),
        "dryRun": payload.get("dryRun", False),
        "localRowCount": payload.get("localRowCount", 0),
        "localCoverageEnd": payload.get("localCoverageEnd"),
        "publicRowCount": payload.get("publicRowCount", 0),
        "publicCoverageEnd": payload.get("publicCoverageEnd"),
        "restoreNeeded": payload.get("restoreNeeded", False),
        "savedRowCount": payload.get("savedRowCount", 0),
        "warningCount": int(
            payload.get("warningCount") or len(payload.get("warnings") or []),
        ),
        "failureCount": len(payload.get("failures") or []),
        "failures": payload.get("failures") or [],
    }


def build_restore_summary_line(payload: dict[str, Any]) -> str:
    return " ".join(
        [
            "[summary]",
            f"overallStatus={payload.get('overallStatus', 'UNKNOWN')}",
            f"localRows={int(payload.get('localRowCount') or 0)}",
            f"localEnd={payload.get('localCoverageEnd') or 'unknown'}",
            f"publicRows={int(payload.get('publicRowCount') or 0)}",
            f"publicEnd={payload.get('publicCoverageEnd') or 'unknown'}",
            f"restoreNeeded={str(bool(payload.get('restoreNeeded'))).lower()}",
            f"savedRows={int(payload.get('savedRowCount') or 0)}",
            f"warnings={int(payload.get('warningCount') or len(payload.get('warnings') or []))}",
            f"failures={len(payload.get('failures') or [])}",
        ],
    )


def _public_is_newer_or_larger(
    *,
    public_coverage_end: str | None,
    public_row_count: int,
    local_coverage_end: str | None,
    local_row_count: int,
) -> bool:
    if public_row_count < 2:
        return False
    if not local_coverage_end:
        return True
    if public_coverage_end and public_coverage_end > local_coverage_end:
        return True
    return public_coverage_end == local_coverage_end and public_row_count > local_row_count


def _base_url(base_url: str) -> str:
    base = base_url.strip().rstrip("/")
    return base or DEFAULT_PUBLIC_STATIC_DATA_BASE_URL


def _fetch_url_text(url: str, timeout_seconds: float) -> str:
    request = Request(
        url,
        headers={"User-Agent": "00631l-lab-public-00631l-history-restore/1.0"},
    )
    with urlopen(request, timeout=max(1.0, timeout_seconds)) as response:
        return response.read().decode("utf-8")


def _last_date(points: list[dict[str, Any]]) -> str | None:
    dates = sorted(str(point.get("date") or "") for point in points if point.get("date"))
    return dates[-1] if dates else None


def _text_or_none(value: Any) -> str | None:
    text = str(value or "").strip()
    return text or None


def _invalid_payload_response(
    *,
    checked_at: str,
    url: str,
    output_path: str | Path,
    dry_run: bool,
    message: str,
) -> dict[str, Any]:
    return {
        "sourceStatus": "error",
        "sourceContract": "00631l_public_price_history_restore",
        "checkedAt": checked_at,
        "sourceUrl": url,
        "outputPath": str(output_path),
        "dryRun": dry_run,
        "localRowCount": 0,
        "localCoverageEnd": None,
        "publicRowCount": 0,
        "publicCoverageEnd": None,
        "restoreNeeded": False,
        "savedRowCount": 0,
        "overallStatus": "FAIL",
        "warnings": [],
        "warningCount": 0,
        "failures": [message],
        "errorMessage": message,
    }


if __name__ == "__main__":
    raise SystemExit(main())
