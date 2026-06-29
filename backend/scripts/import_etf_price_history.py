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
    ETF_PRICE_HISTORY_EARLIEST_START_DATE,
    EtfPriceHistoryStore,
    catalog_codes,
    fetch_etf_price_history,
    import_attempt_gap_reason,
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
    parser.add_argument(
        "--offset",
        type=int,
        default=0,
        help="Catalog symbol offset when --from-catalog is used.",
    )
    parser.add_argument(
        "--missing-only",
        action="store_true",
        help="Skip ETF codes that already have ready price-history rows.",
    )
    parser.add_argument(
        "--skip-attempted",
        action="store_true",
        help=(
            "When used with --missing-only, also skip codes that already have "
            "local import-attempt evidence."
        ),
    )
    parser.add_argument(
        "--retry-source-errors",
        action="store_true",
        help=(
            "When used with --skip-attempted, retry codes whose last import "
            "attempt was a source_error while still skipping official empty "
            "attempts."
        ),
    )
    parser.add_argument("--start-date", default="")
    parser.add_argument("--end-date", default="")
    parser.add_argument(
        "--full-refresh",
        action="store_true",
        help=(
            "Fetch from the earliest supported ETF history start instead of "
            "each ETF's latest cached month."
        ),
    )
    parser.add_argument("--output-dir", default=settings.etf_price_history_dir)
    parser.add_argument("--seed-dir", default=settings.etf_price_history_seed_dir)
    parser.add_argument("--status-only", action="store_true")
    parser.add_argument(
        "--summary-only",
        action="store_true",
        help="Print a compact summary without every ETF item.",
    )
    parser.add_argument(
        "--allow-partial",
        action="store_true",
        help=(
            "Treat per-symbol fetch failures as warnings for broad catalog "
            "backfills. Validation failures still fail the command."
        ),
    )
    parser.add_argument(
        "--progress-every",
        type=int,
        default=0,
        help="Print a compact progress line every N symbols. 0 disables progress.",
    )
    args = parser.parse_args()

    store = EtfPriceHistoryStore(args.output_dir, seed_dir=args.seed_dir)
    if args.status_only:
        fetched_at = utc_now_iso()
        catalog_payload = load_etf_catalog(args.catalog_path, fetched_at=fetched_at)
        status_codes = catalog_codes(catalog_payload, limit=None) if args.from_catalog else None
        index_payload = store.index_response(fetched_at=fetched_at, codes=status_codes)
        catalog_row_count = int(catalog_payload.get("rowCount") or 0)
        ready_count = int(index_payload.get("readyCount") or 0)
        history_row_count = int(index_payload.get("rowCount") or 0)
        completion_total = max(catalog_row_count, history_row_count, ready_count)
        completion_gap = max(0, completion_total - ready_count)
        payload = (
            build_status_summary_response(
                index_payload,
                catalog_row_count=catalog_row_count,
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
        f"catalogSymbols={catalog_row_count} "
        f"attempted={index_payload.get('attemptedCount', 0)} "
        f"gap={completion_gap} "
            f"validationFailures={validation_failures}"
        )
        return 1 if validation_failures else 0

    codes = select_import_codes(args, store)
    if not codes:
        now = utc_now_iso()
        payload = {
            "sourceStatus": "cached",
            "sourceContract": "twse_multi_etf_price_history_import",
            "sourceUrl": settings.twse_price_history_url_template,
            "fetchedAt": now,
            "sourceUpdatedAt": None,
            "dataTime": None,
            "requestedCodes": [],
            "missingOnly": bool(args.missing_only),
            "skipAttempted": bool(args.skip_attempted),
            "retrySourceErrors": bool(args.retry_source_errors),
            "readyCount": store.index_response(fetched_at=now).get("readyCount", 0),
            "validationFailureCount": 0,
            "validationWarningCount": 0,
            "items": [],
            "warnings": ["No ETF codes require import after filters."],
            "failures": [],
            "errorMessage": None,
        }
        output_payload = build_import_summary_response(payload) if args.summary_only else payload
        print(json.dumps(output_payload, ensure_ascii=False, indent=2, sort_keys=True))
        print("[summary] overallStatus=PASS symbols=0 ready=" f"{payload['readyCount']} warnings=1 failures=0")
        return 0

    default_start = ETF_PRICE_HISTORY_EARLIEST_START_DATE
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
    total_codes = len(codes)
    for position, code in enumerate(codes, start=1):
        if should_emit_progress(position, total_codes, args.progress_every):
            print(
                f"[progress] etf_price_history_import {position}/{total_codes} code={code}",
                file=sys.stderr,
                flush=True,
            )
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
            store.record_import_attempt(
                code,
                {
                    "attemptedAt": now,
                    "sourceStatus": fetched.get("sourceStatus"),
                    "sourceUrl": fetched.get("sourceUrl"),
                    "requestedMonths": fetched.get("requestedMonths"),
                    "rowCount": fetched.get("rowCount"),
                    "warnings": fetched.get("warnings", []),
                    "errorMessage": fetched.get("errorMessage"),
                    "updateMode": update_mode,
                    "startDate": start.isoformat(),
                    "endDate": end.isoformat(),
                },
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
            store.record_import_attempt(
                code,
                {
                    "attemptedAt": now,
                    "sourceStatus": "error",
                    "sourceUrl": settings.twse_price_history_url_template,
                    "requestedMonths": 0,
                    "rowCount": 0,
                    "warnings": [],
                    "errorMessage": str(error),
                    "updateMode": "custom" if explicit_start is not None else "full" if args.full_refresh else "incremental",
                    "startDate": start.isoformat() if "start" in locals() else None,
                    "endDate": end.isoformat(),
                },
            )
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
        "missingOnly": bool(args.missing_only),
        "skipAttempted": bool(args.skip_attempted),
        "retrySourceErrors": bool(args.retry_source_errors),
        "readyCount": index.get("readyCount", 0),
        "validationFailureCount": index.get("validationFailureCount", 0),
        "validationWarningCount": index.get("validationWarningCount", 0),
        "items": items,
        "warnings": warnings,
        "failures": failures,
        "errorMessage": "; ".join(failures) if failures else None,
    }
    output_payload = build_import_summary_response(payload) if args.summary_only else payload
    print(json.dumps(output_payload, ensure_ascii=False, indent=2, sort_keys=True))
    print(
        "[summary] "
        f"overallStatus={'FAIL' if failures else 'PASS'} "
        f"symbols={len(codes)} ready={payload['readyCount']} "
        f"warnings={len(warnings)} failures={len(failures)}"
    )
    return 1 if failures else 0


def select_import_codes(
    args: argparse.Namespace,
    store: EtfPriceHistoryStore,
) -> list[str]:
    if bool(getattr(args, "missing_only", False)) and bool(
        getattr(args, "from_catalog", False)
    ):
        all_codes = _resolve_codes(args, apply_slice=False)
        missing_codes = filter_missing_codes(all_codes, store)
        if bool(getattr(args, "skip_attempted", False)):
            missing_codes = filter_attempted_codes(
                missing_codes,
                store,
                retry_source_errors=bool(getattr(args, "retry_source_errors", False)),
            )
        return _slice_codes(missing_codes, args)
    codes = _resolve_codes(args)
    if bool(getattr(args, "missing_only", False)):
        missing_codes = filter_missing_codes(codes, store)
        return (
            filter_attempted_codes(
                missing_codes,
                store,
                retry_source_errors=bool(getattr(args, "retry_source_errors", False)),
            )
            if bool(getattr(args, "skip_attempted", False))
            else missing_codes
        )
    return codes


def _resolve_codes(
    args: argparse.Namespace,
    *,
    apply_slice: bool = True,
) -> list[str]:
    if not args.from_catalog:
        return parse_code_list(args.codes)
    payload = load_etf_catalog(args.catalog_path, fetched_at=utc_now_iso())
    all_codes = catalog_codes(payload, limit=None)
    if not apply_slice:
        return all_codes
    return _slice_codes(all_codes, args)


def _slice_codes(codes: list[str], args: argparse.Namespace) -> list[str]:
    offset = max(0, int(getattr(args, "offset", 0) or 0))
    limit = max(0, int(getattr(args, "limit", 0) or 0))
    sliced = codes[offset:]
    return sliced[:limit] if limit else sliced


def filter_missing_codes(
    codes: list[str],
    store: EtfPriceHistoryStore,
) -> list[str]:
    index = store.index_response(fetched_at=utc_now_iso())
    ready_codes = {
        str(item.get("code") or "").strip().upper()
        for item in index.get("items", [])
        if isinstance(item, dict)
        and str(item.get("sourceStatus") or "") not in {"unavailable", "error"}
        and int(item.get("rowCount") or 0) >= 2
        and int(item.get("validationFailureCount") or 0) == 0
    }
    return [
        code
        for code in codes
        if code.strip().upper() not in ready_codes
    ]


def filter_attempted_codes(
    codes: list[str],
    store: EtfPriceHistoryStore,
    *,
    retry_source_errors: bool = False,
) -> list[str]:
    remaining = []
    for code in codes:
        attempt = store.import_attempt(code.strip().upper())
        if attempt is None:
            remaining.append(code)
            continue
        if retry_source_errors and import_attempt_gap_reason(attempt) == "source_error":
            remaining.append(code)
    return remaining


def should_emit_progress(position: int, total: int, every: int) -> bool:
    if every <= 0 or total <= 0 or position <= 0:
        return False
    return position == 1 or position == total or position % every == 0


def build_import_summary_response(
    payload: dict[str, object],
    *,
    sample_size: int = 5,
) -> dict[str, object]:
    items = [item for item in payload.get("items", []) if isinstance(item, dict)]
    warnings = [
        str(warning)
        for warning in payload.get("warnings", [])
        if warning is not None
    ]
    failures = [
        str(failure)
        for failure in payload.get("failures", [])
        if failure is not None
    ]
    requested_codes = [
        str(code)
        for code in payload.get("requestedCodes", [])
        if code is not None
    ]
    return {
        "sourceStatus": payload.get("sourceStatus"),
        "sourceContract": payload.get("sourceContract"),
        "sourceUrl": payload.get("sourceUrl"),
        "fetchedAt": payload.get("fetchedAt"),
        "sourceUpdatedAt": payload.get("sourceUpdatedAt"),
        "dataTime": payload.get("dataTime"),
        "requestedCodeCount": len(requested_codes),
        "requestedCodesSample": requested_codes[: max(sample_size, 0)],
        "missingOnly": payload.get("missingOnly", False),
        "skipAttempted": payload.get("skipAttempted", False),
        "retrySourceErrors": payload.get("retrySourceErrors", False),
        "readyCount": payload.get("readyCount", 0),
        "validationFailureCount": payload.get("validationFailureCount", 0),
        "validationWarningCount": payload.get("validationWarningCount", 0),
        "itemCount": len(items),
        "sampleItems": [
            _compact_import_item(item)
            for item in items[: max(sample_size, 0)]
        ],
        "warningCount": len(warnings),
        "warningsSample": [
            _truncate_text(warning)
            for warning in warnings[: max(sample_size, 0)]
        ],
        "failureCount": len(failures),
        "failures": [_truncate_text(failure, limit=240) for failure in failures],
        "errorMessage": payload.get("errorMessage"),
    }


def build_status_summary_response(
    payload: dict[str, object],
    *,
    catalog_row_count: int = 0,
    sample_size: int = 5,
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
    tier_counts = payload.get("coverageTierCounts")
    if not isinstance(tier_counts, dict):
        tier_counts = _coverage_tier_counts(items)
    else:
        tier_counts = dict(tier_counts)
    gap_reason_counts = payload.get("gapReasonCounts")
    if not isinstance(gap_reason_counts, dict):
        gap_reason_counts = _gap_reason_counts(items)
    else:
        gap_reason_counts = dict(gap_reason_counts)
    ready_count = int(payload.get("readyCount") or 0)
    history_row_count = int(payload.get("rowCount") or 0)
    completion_total = max(catalog_row_count, history_row_count, ready_count)
    completion_gap = max(0, completion_total - ready_count)
    catalog_only_missing_count = max(0, catalog_row_count - history_row_count)
    if catalog_only_missing_count:
        tier_counts["unavailable"] = (
            int(tier_counts.get("unavailable") or 0) + catalog_only_missing_count
        )
    classified_gap_count = sum(int(value or 0) for value in gap_reason_counts.values())
    unclassified_gap_count = max(0, completion_gap - classified_gap_count)
    if unclassified_gap_count:
        gap_reason_counts["not_saved"] = (
            int(gap_reason_counts.get("not_saved") or 0) + unclassified_gap_count
        )
    return {
        "sourceStatus": payload.get("sourceStatus"),
        "sourceContract": payload.get("sourceContract"),
        "sourceUrl": payload.get("sourceUrl"),
        "fetchedAt": payload.get("fetchedAt"),
        "sourceUpdatedAt": payload.get("sourceUpdatedAt"),
        "dataTime": payload.get("dataTime"),
        "rowCount": payload.get("rowCount", 0),
        "readyCount": payload.get("readyCount", 0),
        "attemptedCount": payload.get("attemptedCount", 0),
        "catalogRowCount": catalog_row_count,
        "completionTotal": completion_total,
        "completionGap": completion_gap,
        "coverageStart": min(starts) if starts else None,
        "coverageEnd": max(ends) if ends else None,
        "validationFailureCount": payload.get("validationFailureCount", 0),
        "validationWarningCount": payload.get("validationWarningCount", 0),
        "validationFailures": payload.get("validationFailures", []),
        "coverageTierCounts": tier_counts,
        "gapReasonCounts": gap_reason_counts,
        "sampleCodes": [str(item.get("code")) for item in sample_items if item.get("code")],
        "suppressedItemCount": max(len(items) - len(sample_items), 0),
    }


def _coverage_tier_counts(items: list[dict[str, object]]) -> dict[str, int]:
    counts = {"long_term": 0, "recent": 0, "unavailable": 0, "error": 0}
    for item in items:
        tier = str(item.get("coverageTier") or "unavailable")
        counts[tier] = counts.get(tier, 0) + 1
    return counts


def _gap_reason_counts(items: list[dict[str, object]]) -> dict[str, int]:
    counts = {
        "official_empty": 0,
        "not_saved": 0,
        "insufficient_rows": 0,
        "validation_error": 0,
        "source_error": 0,
        "not_ready": 0,
    }
    for item in items:
        row_count = int(item.get("rowCount") or 0)
        validation_failure_count = int(item.get("validationFailureCount") or 0)
        if row_count >= 2 and validation_failure_count == 0:
            continue
        reason = str(item.get("gapReason") or "")
        if not reason:
            if validation_failure_count > 0:
                reason = "validation_error"
            elif str(item.get("sourceStatus") or "").lower() == "error":
                reason = "source_error"
            elif row_count <= 0:
                reason = "not_saved"
            elif row_count < 2:
                reason = "insufficient_rows"
            else:
                reason = "not_ready"
        counts[reason] = counts.get(reason, 0) + 1
    return counts


def _compact_import_item(item: dict[str, object]) -> dict[str, object]:
    return {
        "code": item.get("code"),
        "sourceStatus": item.get("sourceStatus"),
        "coverageEnd": item.get("coverageEnd"),
        "rowCount": item.get("rowCount"),
        "savedRows": item.get("savedRows"),
        "validationStatus": item.get("validationStatus"),
        "errorMessage": _truncate_text(item.get("errorMessage"), limit=160)
        if item.get("errorMessage")
        else None,
    }


def _truncate_text(value: object, *, limit: int = 160) -> str:
    text = str(value or "")
    if len(text) <= limit:
        return text
    return f"{text[: max(limit - 3, 0)]}..."


if __name__ == "__main__":
    raise SystemExit(main())
