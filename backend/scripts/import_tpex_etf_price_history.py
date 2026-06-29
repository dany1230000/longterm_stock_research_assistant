from __future__ import annotations

import argparse
from datetime import datetime, timezone
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
    import_attempt_gap_reason,
    parse_code_list,
)
from backend.app.tpex_etf_price_history import (  # noqa: E402
    TPEX_ETF_PRICE_HISTORY_IMPORT_CONTRACT,
    fetch_tpex_etf_price_history,
)
from backend.app.price_history import utc_now_iso  # noqa: E402
from backend.scripts.import_etf_price_history import (  # noqa: E402
    build_import_summary_response,
    build_status_summary_response,
    filter_missing_codes,
)


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Import official TPEx ETF daily price history for ETF symbols.",
    )
    parser.add_argument("--codes", default=",".join(DEFAULT_ETF_HISTORY_CODES))
    parser.add_argument("--from-catalog", action="store_true")
    parser.add_argument("--catalog-path", default=settings.etf_catalog_path)
    parser.add_argument("--limit", type=int, default=0)
    parser.add_argument("--offset", type=int, default=0)
    parser.add_argument("--missing-only", action="store_true")
    parser.add_argument(
        "--official-empty-only",
        action="store_true",
        help=(
            "Only import codes whose last official price-history attempt is "
            "classified as official_empty."
        ),
    )
    parser.add_argument("--start-date", default="")
    parser.add_argument("--end-date", default="")
    parser.add_argument("--output-dir", default=settings.etf_price_history_dir)
    parser.add_argument("--seed-dir", default=settings.etf_price_history_seed_dir)
    parser.add_argument("--url", default=settings.tpex_etf_price_history_url)
    parser.add_argument("--status-only", action="store_true")
    parser.add_argument("--summary-only", action="store_true")
    parser.add_argument("--allow-partial", action="store_true")
    parser.add_argument("--progress-every", type=int, default=0)
    args = parser.parse_args()

    store = EtfPriceHistoryStore(args.output_dir, seed_dir=args.seed_dir)
    if args.status_only:
        fetched_at = utc_now_iso()
        catalog_payload = load_etf_catalog(args.catalog_path, fetched_at=fetched_at)
        status_codes = catalog_codes(catalog_payload, limit=None) if args.from_catalog else None
        index_payload = store.index_response(fetched_at=fetched_at, codes=status_codes)
        payload = (
            build_status_summary_response(
                index_payload,
                catalog_row_count=int(catalog_payload.get("rowCount") or 0),
            )
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

    codes = select_tpex_import_codes(args, store)
    now = utc_now_iso()
    if not codes:
        payload = {
            "sourceStatus": "cached",
            "sourceContract": TPEX_ETF_PRICE_HISTORY_IMPORT_CONTRACT,
            "sourceUrl": args.url,
            "fetchedAt": now,
            "sourceUpdatedAt": None,
            "dataTime": None,
            "requestedCodes": [],
            "missingOnly": bool(args.missing_only),
            "officialEmptyOnly": bool(args.official_empty_only),
            "readyCount": store.index_response(fetched_at=now).get("readyCount", 0),
            "validationFailureCount": 0,
            "validationWarningCount": 0,
            "items": [],
            "warnings": ["No ETF codes require TPEx import after filters."],
            "failures": [],
            "errorMessage": None,
        }
        output = build_import_summary_response(payload) if args.summary_only else payload
        print(json.dumps(output, ensure_ascii=False, indent=2, sort_keys=True))
        print(
            "[summary] overallStatus=PASS symbols=0 "
            f"ready={payload['readyCount']} warnings=1 failures=0"
        )
        return 0

    start = (
        datetime.strptime(args.start_date, "%Y-%m-%d").date()
        if args.start_date
        else datetime.now(timezone.utc).date().replace(day=1)
    )
    end = (
        datetime.strptime(args.end_date, "%Y-%m-%d").date()
        if args.end_date
        else datetime.now(timezone.utc).date()
    )
    if args.progress_every:
        print(
            f"[progress] tpex_etf_price_history_import symbols={len(codes)} "
            f"range={start.isoformat()}..{end.isoformat()}",
            file=sys.stderr,
            flush=True,
        )

    fetched = fetch_tpex_etf_price_history(
        codes=codes,
        start_date=start,
        end_date=end,
        url=args.url,
        timeout_seconds=settings.request_timeout_seconds,
    )
    points_by_code = fetched.get("pointsByCode") if isinstance(fetched.get("pointsByCode"), dict) else {}
    items: list[dict[str, object]] = []
    warnings = [str(item) for item in fetched.get("warnings") or []]
    fetch_failures = [str(item) for item in fetched.get("failures") or []]
    validation_failures: list[str] = []

    for position, code in enumerate(codes, start=1):
        if _should_emit_progress(position, len(codes), args.progress_every):
            print(
                f"[progress] tpex_etf_price_history_import {position}/{len(codes)} code={code}",
                file=sys.stderr,
                flush=True,
            )
        points = [
            point
            for point in points_by_code.get(code, [])
            if isinstance(point, dict)
        ]
        store.record_import_attempt(
            code,
            {
                "attemptedAt": now,
                "sourceStatus": "official" if points else fetched.get("sourceStatus"),
                "sourceContract": "tpex_etf_price_history_import_attempt",
                "sourceUrl": args.url,
                "requestedDays": fetched.get("requestedDays"),
                "rowCount": len(points),
                "warnings": [] if points else fetched.get("warnings", []),
                "errorMessage": None if points else fetched.get("errorMessage"),
                "updateMode": "tpex_fallback",
                "startDate": start.isoformat(),
                "endDate": end.isoformat(),
            },
        )
        saved = store.save_points(code, points)
        normalized_rows = store.normalize_saved_records(code)
        status = store.status(code, fetched_at=now)
        validation = status.get("validation") or {}
        validation_failures.extend(
            f"{code}: validation: {failure}"
            for failure in validation.get("failures", [])
        )
        items.append(
            {
                "code": code,
                "sourceStatus": "official" if points else fetched.get("sourceStatus"),
                "fetchedRows": len(points),
                "savedRows": saved,
                "normalizedRows": normalized_rows,
                "updateMode": "tpex_fallback",
                "coverageStart": status.get("coverageStart"),
                "coverageEnd": status.get("coverageEnd"),
                "rowCount": status.get("rowCount"),
                "priceField": status.get("priceField"),
                "validationStatus": status.get("validationStatus"),
                "validationFailureCount": status.get("validationFailureCount"),
                "validationWarningCount": status.get("validationWarningCount"),
                "errorMessage": status.get("errorMessage") if not points else None,
            }
        )

    if args.allow_partial and fetch_failures:
        warnings.extend(f"partialFetchFailure={failure}" for failure in fetch_failures)
    failures = validation_failures + ([] if args.allow_partial else fetch_failures)
    index = store.index_response(fetched_at=now)
    payload = {
        "sourceStatus": "error" if failures else "cached",
        "sourceContract": TPEX_ETF_PRICE_HISTORY_IMPORT_CONTRACT,
        "sourceUrl": args.url,
        "fetchedAt": now,
        "sourceUpdatedAt": index.get("sourceUpdatedAt"),
        "dataTime": index.get("dataTime"),
        "requestedCodes": codes,
        "requestedDays": fetched.get("requestedDays"),
        "missingOnly": bool(args.missing_only),
        "officialEmptyOnly": bool(args.official_empty_only),
        "readyCount": index.get("readyCount", 0),
        "validationFailureCount": index.get("validationFailureCount", 0),
        "validationWarningCount": index.get("validationWarningCount", 0),
        "items": items,
        "warnings": warnings,
        "failures": failures,
        "errorMessage": "; ".join(failures) if failures else None,
    }
    output = build_import_summary_response(payload) if args.summary_only else payload
    print(json.dumps(output, ensure_ascii=False, indent=2, sort_keys=True))
    print(
        "[summary] "
        f"overallStatus={'FAIL' if failures else 'PASS'} "
        f"symbols={len(codes)} ready={payload['readyCount']} "
        f"warnings={len(warnings)} failures={len(failures)}"
    )
    return 1 if failures else 0


def select_tpex_import_codes(
    args: argparse.Namespace,
    store: EtfPriceHistoryStore,
) -> list[str]:
    codes = _resolve_codes(args)
    if bool(getattr(args, "missing_only", False)):
        codes = filter_missing_codes(codes, store)
    if bool(getattr(args, "official_empty_only", False)):
        codes = filter_official_empty_codes(codes, store)
    return _slice_codes(codes, args)


def filter_official_empty_codes(
    codes: list[str],
    store: EtfPriceHistoryStore,
) -> list[str]:
    return [
        code
        for code in codes
        if import_attempt_gap_reason(store.import_attempt(code)) == "official_empty"
    ]


def _resolve_codes(args: argparse.Namespace) -> list[str]:
    if not args.from_catalog:
        return parse_code_list(str(args.codes or ""))
    payload = load_etf_catalog(args.catalog_path, fetched_at=utc_now_iso())
    return catalog_codes(payload, limit=None)


def _slice_codes(codes: list[str], args: argparse.Namespace) -> list[str]:
    offset = max(0, int(getattr(args, "offset", 0) or 0))
    limit = max(0, int(getattr(args, "limit", 0) or 0))
    sliced = codes[offset:]
    return sliced[:limit] if limit else sliced


def _should_emit_progress(position: int, total: int, every: int) -> bool:
    if every <= 0 or total <= 0 or position <= 0:
        return False
    return position == 1 or position == total or position % every == 0


if __name__ == "__main__":
    raise SystemExit(main())
