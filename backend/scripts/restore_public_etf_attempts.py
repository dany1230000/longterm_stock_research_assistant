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
            "Restore public static ETF import-attempt evidence into the local "
            "ETF history store before running a missing-only probe."
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
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--summary-only", action="store_true")
    args = parser.parse_args()

    payload = restore_public_etf_attempts(
        base_url=args.base_url,
        index_url=args.index_url,
        output_dir=args.output_dir,
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


def restore_public_etf_attempts(
    *,
    base_url: str,
    index_url: str = "",
    output_dir: str | Path,
    timeout_seconds: float,
    dry_run: bool = False,
    fetcher: FetchText | None = None,
) -> dict[str, Any]:
    checked_at = utc_now_iso()
    url = index_url.strip() or _index_url(base_url)
    fetch = fetcher or _fetch_url_text
    try:
        raw_text = fetch(url, timeout_seconds)
        decoded = json.loads(raw_text)
    except (OSError, URLError, json.JSONDecodeError) as error:
        return {
            "sourceStatus": "unavailable",
            "sourceContract": "twse_multi_etf_public_attempt_restore",
            "checkedAt": checked_at,
            "sourceUrl": url,
            "outputDir": str(output_dir),
            "dryRun": dry_run,
            "restoredCount": 0,
            "skippedCount": 0,
            "overallStatus": "WARN",
            "warnings": [f"Public ETF attempt index unavailable: {error}"],
            "failures": [],
            "errorMessage": str(error),
        }

    if not isinstance(decoded, dict):
        return _invalid_payload_response(
            checked_at=checked_at,
            url=url,
            output_dir=output_dir,
            dry_run=dry_run,
            message="Public ETF attempt index is not a JSON object.",
        )
    items = decoded.get("items")
    if not isinstance(items, list):
        return _invalid_payload_response(
            checked_at=checked_at,
            url=url,
            output_dir=output_dir,
            dry_run=dry_run,
            message="Public ETF attempt index has no items list.",
        )

    store = EtfPriceHistoryStore(output_dir)
    restored_codes: list[str] = []
    skipped_count = 0
    for item in items:
        if not isinstance(item, dict):
            skipped_count += 1
            continue
        attempt = item.get("lastImportAttempt")
        if not isinstance(attempt, dict) or not attempt:
            skipped_count += 1
            continue
        code = normalize_etf_code(str(item.get("code") or attempt.get("code") or ""))
        if not code:
            skipped_count += 1
            continue
        if not dry_run:
            store.record_import_attempt(code, attempt)
        restored_codes.append(code)

    warnings = []
    if not restored_codes:
        warnings.append("No public ETF import-attempt evidence was restored.")
    return {
        "sourceStatus": "static_official",
        "sourceContract": "twse_multi_etf_public_attempt_restore",
        "checkedAt": checked_at,
        "sourceUrl": url,
        "outputDir": str(output_dir),
        "dryRun": dry_run,
        "restoredCount": len(restored_codes),
        "restoredCodesSample": restored_codes[:10],
        "skippedCount": skipped_count,
        "publicReadyCount": int(decoded.get("readyCount") or 0),
        "publicAttemptedCount": int(decoded.get("attemptedCount") or 0),
        "publicMissingCount": int(decoded.get("missingCount") or 0),
        "overallStatus": "WARN" if warnings else "PASS",
        "warnings": warnings,
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
        "restoredCount": payload.get("restoredCount", 0),
        "restoredCodesSample": payload.get("restoredCodesSample", []),
        "skippedCount": payload.get("skippedCount", 0),
        "publicAttemptedCount": payload.get("publicAttemptedCount", 0),
        "warningCount": len(payload.get("warnings") or []),
        "failureCount": len(payload.get("failures") or []),
        "failures": payload.get("failures") or [],
    }


def build_restore_summary_line(payload: dict[str, Any]) -> str:
    return " ".join(
        [
            "[summary]",
            f"overallStatus={payload.get('overallStatus', 'UNKNOWN')}",
            f"restored={int(payload.get('restoredCount') or 0)}",
            f"publicAttempted={int(payload.get('publicAttemptedCount') or 0)}",
            f"skipped={int(payload.get('skippedCount') or 0)}",
            f"failures={len(payload.get('failures') or [])}",
        ],
    )


def _index_url(base_url: str) -> str:
    base = base_url.strip().rstrip("/")
    if not base:
        base = DEFAULT_PUBLIC_STATIC_DATA_BASE_URL
    return f"{base}/etf_price_history_index.json"


def _fetch_url_text(url: str, timeout_seconds: float) -> str:
    request = Request(
        url,
        headers={"User-Agent": "00631l-lab-public-attempt-restore/1.0"},
    )
    with urlopen(request, timeout=max(1.0, timeout_seconds)) as response:
        return response.read().decode("utf-8")


def _invalid_payload_response(
    *,
    checked_at: str,
    url: str,
    output_dir: str | Path,
    dry_run: bool,
    message: str,
) -> dict[str, Any]:
    return {
        "sourceStatus": "error",
        "sourceContract": "twse_multi_etf_public_attempt_restore",
        "checkedAt": checked_at,
        "sourceUrl": url,
        "outputDir": str(output_dir),
        "dryRun": dry_run,
        "restoredCount": 0,
        "skippedCount": 0,
        "overallStatus": "FAIL",
        "warnings": [],
        "failures": [message],
        "errorMessage": message,
    }


if __name__ == "__main__":
    raise SystemExit(main())
