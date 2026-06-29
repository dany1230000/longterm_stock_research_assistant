from __future__ import annotations

import argparse
import json
import os
from pathlib import Path
import sys
from typing import Any, Callable
from urllib.error import URLError
from urllib.parse import quote
from urllib.request import Request, urlopen


ROOT = Path(__file__).resolve().parents[2]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from backend.app.config import settings  # noqa: E402
from backend.app.etf_price_history import (  # noqa: E402
    EtfPriceHistoryStore,
    normalize_etf_code,
)
from backend.app.price_history import utc_now_iso  # noqa: E402


DEFAULT_PUBLIC_STATIC_DATA_BASE_URL = (
    "https://dany1230000.github.io/"
    "longterm_stock_research_assistant/00631l-static-data"
)
FetchText = Callable[[str, float], str]


def main() -> int:
    parser = argparse.ArgumentParser(
        description=(
            "Restore previously deployed public static ETF price-history rows "
            "into the local ETF history store before a new Pages export."
        ),
    )
    parser.add_argument(
        "--base-url",
        default=os.getenv(
            "00631L_PUBLIC_STATIC_DATA_BASE_URL",
            DEFAULT_PUBLIC_STATIC_DATA_BASE_URL,
        ),
    )
    parser.add_argument("--index-url", default="")
    parser.add_argument("--output-dir", default=settings.etf_price_history_dir)
    parser.add_argument(
        "--timeout-seconds",
        type=float,
        default=float(settings.request_timeout_seconds),
    )
    parser.add_argument("--limit", type=int, default=0)
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--summary-only", action="store_true")
    args = parser.parse_args()

    payload = restore_public_etf_price_history(
        base_url=args.base_url,
        index_url=args.index_url,
        output_dir=args.output_dir,
        timeout_seconds=args.timeout_seconds,
        limit=args.limit,
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


def restore_public_etf_price_history(
    *,
    base_url: str,
    index_url: str = "",
    output_dir: str | Path,
    timeout_seconds: float,
    limit: int = 0,
    dry_run: bool = False,
    fetcher: FetchText | None = None,
) -> dict[str, Any]:
    checked_at = utc_now_iso()
    normalized_base_url = _base_url(base_url)
    url = index_url.strip() or _index_url(normalized_base_url)
    fetch = fetcher or _fetch_url_text
    try:
        raw_text = fetch(url, timeout_seconds)
        decoded = json.loads(raw_text)
    except (OSError, URLError, json.JSONDecodeError) as error:
        return {
            "sourceStatus": "unavailable",
            "sourceContract": "twse_multi_etf_public_history_restore",
            "checkedAt": checked_at,
            "sourceUrl": url,
            "outputDir": str(output_dir),
            "dryRun": dry_run,
            "limit": max(0, int(limit or 0)),
            "fetchedCount": 0,
            "restoredCount": 0,
            "savedRowCount": 0,
            "skippedCount": 0,
            "overallStatus": "WARN",
            "warnings": [f"Public ETF history index unavailable: {error}"],
            "failures": [],
            "errorMessage": str(error),
        }

    if not isinstance(decoded, dict):
        return _invalid_payload_response(
            checked_at=checked_at,
            url=url,
            output_dir=output_dir,
            dry_run=dry_run,
            limit=limit,
            message="Public ETF history index is not a JSON object.",
        )
    items = decoded.get("items")
    if not isinstance(items, list):
        return _invalid_payload_response(
            checked_at=checked_at,
            url=url,
            output_dir=output_dir,
            dry_run=dry_run,
            limit=limit,
            message="Public ETF history index has no items list.",
        )

    store = EtfPriceHistoryStore(output_dir)
    restored_codes: list[str] = []
    warnings: list[str] = []
    skipped_count = 0
    fetched_count = 0
    saved_rows_total = 0
    ready_items = [
        item
        for item in items
        if isinstance(item, dict)
        and int(item.get("rowCount") or 0) >= 2
        and not int(item.get("validationFailureCount") or 0)
    ]
    slice_end = max(0, int(limit or 0)) or None
    selected_items = ready_items[:slice_end]
    for item in selected_items:
        code = normalize_etf_code(str(item.get("code") or ""))
        if not code:
            skipped_count += 1
            continue
        history_url = _history_url(normalized_base_url, code)
        try:
            history_payload = json.loads(fetch(history_url, timeout_seconds))
        except (OSError, URLError, json.JSONDecodeError) as error:
            warnings.append(f"{code}: public history unavailable: {error}")
            skipped_count += 1
            continue
        if not isinstance(history_payload, dict):
            warnings.append(f"{code}: public history payload is not a JSON object")
            skipped_count += 1
            continue
        points = history_payload.get("items")
        if not isinstance(points, list) or len(points) < 2:
            warnings.append(f"{code}: public history payload has fewer than 2 rows")
            skipped_count += 1
            continue
        fetched_count += 1
        if not dry_run:
            saved_rows_total += store.save_points(code, _history_points(points))
        else:
            saved_rows_total += len(points)
        restored_codes.append(code)

    if not restored_codes:
        warnings.append("No public ETF price-history rows were restored.")
    return {
        "sourceStatus": "static_official",
        "sourceContract": "twse_multi_etf_public_history_restore",
        "checkedAt": checked_at,
        "sourceUrl": url,
        "baseUrl": normalized_base_url,
        "outputDir": str(output_dir),
        "dryRun": dry_run,
        "limit": max(0, int(limit or 0)),
        "publicReadyCount": int(decoded.get("readyCount") or len(ready_items)),
        "publicMissingCount": int(decoded.get("missingCount") or 0),
        "publicRowCount": int(decoded.get("rowCount") or len(items)),
        "selectedCount": len(selected_items),
        "fetchedCount": fetched_count,
        "restoredCount": len(restored_codes),
        "restoredCodesSample": restored_codes[:10],
        "savedRowCount": saved_rows_total,
        "skippedCount": skipped_count,
        "overallStatus": "WARN" if warnings else "PASS",
        "warnings": warnings[:50],
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
        "outputDir": payload.get("outputDir"),
        "dryRun": payload.get("dryRun", False),
        "limit": payload.get("limit", 0),
        "publicReadyCount": payload.get("publicReadyCount", 0),
        "selectedCount": payload.get("selectedCount", 0),
        "fetchedCount": payload.get("fetchedCount", 0),
        "restoredCount": payload.get("restoredCount", 0),
        "restoredCodesSample": payload.get("restoredCodesSample", []),
        "savedRowCount": payload.get("savedRowCount", 0),
        "skippedCount": payload.get("skippedCount", 0),
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
            f"publicReady={int(payload.get('publicReadyCount') or 0)}",
            f"selected={int(payload.get('selectedCount') or 0)}",
            f"fetched={int(payload.get('fetchedCount') or 0)}",
            f"restored={int(payload.get('restoredCount') or 0)}",
            f"savedRows={int(payload.get('savedRowCount') or 0)}",
            f"skipped={int(payload.get('skippedCount') or 0)}",
            f"warnings={int(payload.get('warningCount') or len(payload.get('warnings') or []))}",
            f"failures={len(payload.get('failures') or [])}",
        ],
    )


def _base_url(base_url: str) -> str:
    base = base_url.strip().rstrip("/")
    return base or DEFAULT_PUBLIC_STATIC_DATA_BASE_URL


def _index_url(base_url: str) -> str:
    return f"{_base_url(base_url)}/etf_price_history_index.json"


def _history_url(base_url: str, code: str) -> str:
    return f"{_base_url(base_url)}/etf_price_history/{quote(code)}.json"


def _fetch_url_text(url: str, timeout_seconds: float) -> str:
    request = Request(
        url,
        headers={"User-Agent": "00631l-lab-public-history-restore/1.0"},
    )
    with urlopen(request, timeout=max(1.0, timeout_seconds)) as response:
        return response.read().decode("utf-8")


def _history_points(points: list[Any]) -> list[dict[str, Any]]:
    return [point for point in points if isinstance(point, dict)]


def _invalid_payload_response(
    *,
    checked_at: str,
    url: str,
    output_dir: str | Path,
    dry_run: bool,
    limit: int,
    message: str,
) -> dict[str, Any]:
    return {
        "sourceStatus": "error",
        "sourceContract": "twse_multi_etf_public_history_restore",
        "checkedAt": checked_at,
        "sourceUrl": url,
        "outputDir": str(output_dir),
        "dryRun": dry_run,
        "limit": max(0, int(limit or 0)),
        "fetchedCount": 0,
        "restoredCount": 0,
        "savedRowCount": 0,
        "skippedCount": 0,
        "overallStatus": "FAIL",
        "warnings": [],
        "warningCount": 0,
        "failures": [message],
        "errorMessage": message,
    }


if __name__ == "__main__":
    raise SystemExit(main())
