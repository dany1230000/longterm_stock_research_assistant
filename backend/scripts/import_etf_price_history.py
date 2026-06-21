from __future__ import annotations

import argparse
from datetime import date, datetime, timezone
import json
from pathlib import Path
import sys


ROOT = Path(__file__).resolve().parents[2]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from backend.app.config import settings  # noqa: E402
from backend.app.etf_catalog import load_etf_catalog  # noqa: E402
from backend.app.etf_price_history import (  # noqa: E402
    DEFAULT_ETF_HISTORY_CODES,
    EtfPriceHistoryStore,
    catalog_codes,
    fetch_etf_price_history,
    parse_code_list,
)
from backend.app.fetcher import fetch_text  # noqa: E402
from backend.app.price_history import utc_now_iso  # noqa: E402


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Import TWSE STOCK_DAY price history for ETF catalog symbols.",
    )
    parser.add_argument("--codes", default=",".join(DEFAULT_ETF_HISTORY_CODES))
    parser.add_argument("--from-catalog", action="store_true")
    parser.add_argument("--catalog-path", default=settings.etf_catalog_path)
    parser.add_argument(
        "--limit",
        type=int,
        default=0,
        help="Maximum catalog symbols to import. 0 means all catalog symbols.",
    )
    parser.add_argument("--start-date", default="")
    parser.add_argument("--end-date", default="")
    parser.add_argument(
        "--full-refresh",
        action="store_true",
        help="Fetch from 2019-01-01 instead of each ETF's latest cached month.",
    )
    parser.add_argument("--output-dir", default=settings.etf_price_history_dir)
    parser.add_argument("--status-only", action="store_true")
    parser.add_argument(
        "--summary-only",
        action="store_true",
        help="With --status-only, print a compact index summary without every ETF item.",
    )
    parser.add_argument(
        "--allow-partial",
        action="store_true",
        help=(
            "Treat per-symbol fetch failures as warnings for broad catalog "
            "backfills. Validation failures still fail the command."
        ),
    )
    args = parser.parse_args()

    store = EtfPriceHistoryStore(args.output_dir)
    if args.status_only:
        index_payload = store.index_response(fetched_at=utc_now_iso())
        payload = (
            build_status_summary_response(index_payload)
            if args.summary_only
            else index_payload
        )
        print(json.dumps(payload, ensure_ascii=False, indent=2, sort_keys=True))
        validation_failures = int(index_payload.get("validationFailureCount") or 0)
        print(
            "[summary] "
            f"overallStatus={'FAIL' if validation_failures else 'PASS' if index_payload.get('readyCount', 0) else 'WARN'} "
            f"symbols={index_payload.get('rowCount', 0)} "
            f"ready={index_payload.get('readyCount', 0)} "
            f"validationFailures={validation_failures}"
        )
        return 1 if validation_failures else 0

    codes = _resolve_codes(args)
    if not codes:
        print("FAIL no ETF codes were resolved for import.")
        return 1

    default_start = date(2019, 1, 1)
    explicit_start = (
        datetime.strptime(args.start_date, "%Y-%m-%d").date()
        if args.start_date
        else None
    )
    end = (
        datetime.strptime(args.end_date, "%Y-%m-%d").date()
        if args.end_date
        else datetime.now(timezone.utc).date()
    )
    now = utc_now_iso()
    items: list[dict[str, object]] = []
    warnings: list[str] = []
    fetch_failures: list[str] = []
    validation_failures: list[str] = []
    for code in codes:
        if explicit_start is not None:
            start = explicit_start
            update_mode = "custom"
        elif args.full_refresh:
            start = default_start
            update_mode = "full"
        else:
            start = store.default_incremental_start_date(
                code,
                default_start=default_start,
            )
            update_mode = "incremental"
        try:
            fetched = fetch_etf_price_history(
                code=code,
                fetcher=fetch_text,
                url_template=settings.twse_price_history_url_template,
                start_date=start,
                end_date=end,
                timeout_seconds=settings.request_timeout_seconds,
            )
            saved = store.save_points(code, fetched["points"])
            normalized_rows = store.normalize_saved_records(code)
            status = store.status(code, fetched_at=now)
            if fetched.get("sourceStatus") != "official":
                fetch_failures.append(f"{code}: {fetched.get('errorMessage')}")
            warnings.extend(f"{code}: {warning}" for warning in fetched.get("warnings", []))
            validation = status.get("validation") or {}
            warnings.extend(
                f"{code}: validation: {warning}"
                for warning in validation.get("warnings", [])
            )
            validation_failures.extend(
                f"{code}: validation: {failure}"
                for failure in validation.get("failures", [])
            )
            items.append(
                {
                    "code": code,
                    "sourceStatus": fetched.get("sourceStatus"),
                    "requestedMonths": fetched.get("requestedMonths"),
                    "fetchedRows": fetched.get("rowCount"),
                    "savedRows": saved,
                    "normalizedRows": normalized_rows,
                    "updateMode": update_mode,
                    "coverageStart": status.get("coverageStart"),
                    "coverageEnd": status.get("coverageEnd"),
                    "rowCount": status.get("rowCount"),
                    "priceField": status.get("priceField"),
                    "validationStatus": status.get("validationStatus"),
                    "validationFailureCount": status.get("validationFailureCount"),
                    "validationWarningCount": status.get("validationWarningCount"),
                    "errorMessage": fetched.get("errorMessage"),
                }
            )
        except Exception as error:  # noqa: BLE001 - CLI should keep importing others.
            fetch_failures.append(f"{code}: {error}")
            items.append(
                {
                    "code": code,
                    "sourceStatus": "error",
                    "requestedMonths": 0,
                    "fetchedRows": 0,
                    "savedRows": 0,
                    "coverageStart": None,
                    "coverageEnd": None,
                    "rowCount": 0,
                    "errorMessage": str(error),
                }
            )

    if args.allow_partial and fetch_failures:
        warnings.extend(f"partialFetchFailure={failure}" for failure in fetch_failures)
    failures = validation_failures + ([] if args.allow_partial else fetch_failures)
    index = store.index_response(fetched_at=now)
    payload = {
        "sourceStatus": "error" if failures else "cached",
        "sourceContract": "twse_multi_etf_price_history_import",
        "sourceUrl": settings.twse_price_history_url_template,
        "fetchedAt": now,
        "sourceUpdatedAt": index.get("sourceUpdatedAt"),
        "dataTime": index.get("dataTime"),
        "requestedCodes": codes,
        "readyCount": index.get("readyCount", 0),
        "validationFailureCount": index.get("validationFailureCount", 0),
        "validationWarningCount": index.get("validationWarningCount", 0),
        "items": items,
        "warnings": warnings,
        "failures": failures,
        "errorMessage": "; ".join(failures) if failures else None,
    }
    print(json.dumps(payload, ensure_ascii=False, indent=2, sort_keys=True))
    print(
        "[summary] "
        f"overallStatus={'FAIL' if failures else 'PASS'} "
        f"symbols={len(codes)} ready={payload['readyCount']} "
        f"warnings={len(warnings)} failures={len(failures)}"
    )
    return 1 if failures else 0


def _resolve_codes(args: argparse.Namespace) -> list[str]:
    if not args.from_catalog:
        return parse_code_list(args.codes)
    payload = load_etf_catalog(args.catalog_path, fetched_at=utc_now_iso())
    return catalog_codes(payload, limit=args.limit)


def build_status_summary_response(
    payload: dict[str, object],
    *,
    sample_size: int = 12,
) -> dict[str, object]:
    items = [item for item in payload.get("items", []) if isinstance(item, dict)]
    starts = [
        str(item.get("coverageStart"))
        for item in items
        if item.get("coverageStart")
    ]
    ends = [
        str(item.get("coverageEnd"))
        for item in items
        if item.get("coverageEnd")
    ]
    sample_items = items[: max(sample_size, 0)]
    return {
        "sourceStatus": payload.get("sourceStatus"),
        "sourceContract": payload.get("sourceContract"),
        "sourceUrl": payload.get("sourceUrl"),
        "fetchedAt": payload.get("fetchedAt"),
        "sourceUpdatedAt": payload.get("sourceUpdatedAt"),
        "dataTime": payload.get("dataTime"),
        "rowCount": payload.get("rowCount", 0),
        "readyCount": payload.get("readyCount", 0),
        "coverageStart": min(starts) if starts else None,
        "coverageEnd": max(ends) if ends else None,
        "validationFailureCount": payload.get("validationFailureCount", 0),
        "validationWarningCount": payload.get("validationWarningCount", 0),
        "validationFailures": payload.get("validationFailures", []),
        "sampleCodes": [str(item.get("code")) for item in sample_items if item.get("code")],
        "suppressedItemCount": max(len(items) - len(sample_items), 0),
    }


if __name__ == "__main__":
    raise SystemExit(main())
