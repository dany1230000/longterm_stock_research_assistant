from __future__ import annotations

import json
from datetime import datetime
from pathlib import Path
from typing import Any

from .etf_price_history import (
    DEFAULT_ETF_HISTORY_CODES,
    LONG_TERM_COVERAGE_MIN_ROWS,
    LONG_TERM_COVERAGE_START_CUTOFF,
    EtfPriceHistoryStore,
)
from .price_history import PriceHistoryStore, utc_now_iso


STATIC_SOURCE_CONTRACT = "00631l_static_public_data"


def export_static_00631l_data(
    *,
    output_dir: str | Path,
    price_history_store: PriceHistoryStore,
    etf_price_history_store: EtfPriceHistoryStore | None = None,
    etf_price_history_codes: list[str] | tuple[str, ...] | None = None,
    etf_catalog_payload: dict[str, Any] | None = None,
    strict: bool = False,
    minimum_row_count: int = 2,
    minimum_catalog_row_count: int = 0,
    warnings: list[str] | None = None,
    release_metadata: dict[str, Any] | None = None,
) -> dict[str, Any]:
    generated_at = utc_now_iso()
    output = Path(output_dir)
    output.mkdir(parents=True, exist_ok=True)
    warnings = list(warnings or [])

    price_history = price_history_store.price_response(
        limit=5000,
        fetched_at=generated_at,
    )
    performance = price_history_store.performance_response(fetched_at=generated_at)
    status = price_history_store.status_response(fetched_at=generated_at)
    row_count = int(status.get("rowCount") or 0)
    required_rows = max(2, int(minimum_row_count))
    failures: list[str] = []
    is_ready = row_count >= required_rows
    if not is_ready:
        message = (
            f"Official price history has {row_count} rows; static public "
            f"history/backtest data requires at least {required_rows} rows."
        )
        warnings.append(message)
        if strict:
            failures.append(message)

    catalog_payload = _normalize_static_catalog_payload(
        etf_catalog_payload=etf_catalog_payload,
        output_dir=output,
        generated_at=generated_at,
    )
    etf_history_payload = _export_static_etf_price_history(
        output_dir=output,
        store=etf_price_history_store,
        codes=etf_price_history_codes or DEFAULT_ETF_HISTORY_CODES,
        generated_at=generated_at,
        warnings=warnings,
        failures=failures,
        strict=strict,
    )
    catalog_payload = _reconcile_catalog_with_history_index(
        catalog_payload=catalog_payload,
        etf_history_payload=etf_history_payload,
        generated_at=generated_at,
        warnings=warnings,
    )
    catalog_row_count = int(catalog_payload.get("rowCount") or 0)
    etf_history_row_count = int(etf_history_payload["rowCount"])
    etf_history_source_contract_counts = etf_history_payload.get(
        "historySourceContractCounts",
        etf_history_payload.get("sourceContractCounts", {}),
    )
    etf_out_of_catalog_count = _out_of_catalog_code_count(
        catalog_payload=catalog_payload,
        etf_history_payload=etf_history_payload,
    )
    catalog_min_rows = max(0, int(minimum_catalog_row_count))
    catalog_ready = catalog_min_rows == 0 or catalog_row_count >= catalog_min_rows
    if catalog_min_rows > 0 and not catalog_ready:
        message = (
            f"ETF catalog has {catalog_row_count} rows; static public ETF "
            f"catalog requires at least {catalog_min_rows} rows."
        )
        warnings.append(message)
        if strict:
            failures.append(message)

    release_payload = _normalize_release_metadata(
        release_metadata=release_metadata,
        generated_at=generated_at,
    )

    status_payload = {
        **status,
        "sourceStatus": "static_official" if is_ready else "unavailable",
        "sourceContract": STATIC_SOURCE_CONTRACT,
        "generatedAt": generated_at,
        "outputDir": str(output),
        "minimumRowCount": required_rows,
        "etfCatalogRowCount": catalog_row_count,
        "etfCatalogDataTime": catalog_payload.get("dataTime"),
        "etfPriceHistoryMissingCount": etf_history_payload.get("missingCount", 0),
        "etfPriceHistoryAttemptedCount": etf_history_payload.get("attemptedCount", 0),
        "etfPriceHistoryOutOfCatalogCount": etf_out_of_catalog_count,
        "etfPriceHistorySourceContractCounts": etf_history_source_contract_counts,
        "etfPriceHistoryGapReasonCounts": etf_history_payload.get(
            "gapReasonCounts",
            {},
        ),
        "etfPriceHistoryGapReasonSamples": etf_history_payload.get(
            "gapReasonSamples",
            {},
        ),
        "minimumCatalogRowCount": catalog_min_rows,
        "warnings": warnings,
        "failures": failures,
        "strict": strict,
    }
    price_payload = {
        **price_history,
        "sourceStatus": "static_official" if is_ready else "unavailable",
        "sourceContract": "00631l_static_price_history",
        "generatedAt": generated_at,
        "rowCount": row_count,
        "minimumRowCount": required_rows,
        "errorMessage": None if is_ready else status.get("errorMessage"),
    }
    performance_payload = {
        **performance,
        "sourceStatus": "static_official" if is_ready else "unavailable",
        "sourceContract": "00631l_static_price_performance",
        "generatedAt": generated_at,
        "minimumRowCount": required_rows,
        "errorMessage": None if is_ready else status.get("errorMessage"),
    }
    manifest_payload = {
        "sourceStatus": status_payload["sourceStatus"],
        "sourceContract": STATIC_SOURCE_CONTRACT,
        "generatedAt": generated_at,
        "files": {
            "priceHistory": "price_history.json",
            "performance": "performance.json",
            "status": "status.json",
            "etfCatalog": "etf_catalog.json",
            "etfPriceHistoryIndex": "etf_price_history_index.json",
            "etfPriceHistoryGaps": "etf_price_history_gaps.json",
            "release": "release.json",
        },
        "release": release_payload,
        "rowCount": row_count,
        "minimumRowCount": required_rows,
        "etfCatalogRowCount": catalog_row_count,
        "etfCatalogDataTime": catalog_payload.get("dataTime"),
        "etfPriceHistoryRowCount": etf_history_row_count,
        "etfPriceHistoryReadyCount": etf_history_payload["readyCount"],
        "etfPriceHistoryMissingCount": etf_history_payload.get("missingCount", 0),
        "etfPriceHistoryGapDetailCount": etf_history_payload.get(
            "gapDetailCount",
            0,
        ),
        "etfPriceHistoryAttemptedCount": etf_history_payload.get("attemptedCount", 0),
        "etfPriceHistoryOutOfCatalogCount": etf_out_of_catalog_count,
        "etfPriceHistoryDataTime": etf_history_payload["dataTime"],
        "etfPriceHistoryCoverageTierCounts": etf_history_payload.get(
            "coverageTierCounts",
            {},
        ),
        "etfPriceHistorySourceContractCounts": etf_history_source_contract_counts,
        "etfPriceHistoryGapReasonCounts": etf_history_payload.get(
            "gapReasonCounts",
            {},
        ),
        "etfPriceHistoryGapReasonSamples": etf_history_payload.get(
            "gapReasonSamples",
            {},
        ),
        "minimumCatalogRowCount": catalog_min_rows,
        "coverageStart": status.get("coverageStart"),
        "coverageEnd": status.get("coverageEnd"),
        "isCompleteFromListing": status.get("isCompleteFromListing"),
        "priceField": status.get("priceField"),
        "priceAdjustment": status.get("priceAdjustment"),
        "warnings": warnings,
        "failures": failures,
    }

    _write_json(output / "price_history.json", price_payload)
    _write_json(output / "performance.json", performance_payload)
    _write_json(output / "status.json", status_payload)
    _write_json(output / "etf_catalog.json", catalog_payload)
    _write_json(output / "manifest.json", manifest_payload)
    _write_json(output / "release.json", release_payload)

    return {
        "sourceStatus": status_payload["sourceStatus"],
        "sourceContract": STATIC_SOURCE_CONTRACT,
        "generatedAt": generated_at,
        "outputDir": str(output),
        "rowCount": row_count,
        "coverageStart": status.get("coverageStart"),
        "coverageEnd": status.get("coverageEnd"),
        "isCompleteFromListing": status.get("isCompleteFromListing"),
        "minimumRowCount": required_rows,
        "etfCatalogRowCount": catalog_row_count,
        "etfCatalogDataTime": catalog_payload.get("dataTime"),
        "etfPriceHistoryRowCount": etf_history_row_count,
        "etfPriceHistoryReadyCount": etf_history_payload["readyCount"],
        "etfPriceHistoryMissingCount": etf_history_payload.get("missingCount", 0),
        "etfPriceHistoryGapDetailCount": etf_history_payload.get(
            "gapDetailCount",
            0,
        ),
        "etfPriceHistoryAttemptedCount": etf_history_payload.get("attemptedCount", 0),
        "etfPriceHistoryOutOfCatalogCount": etf_out_of_catalog_count,
        "etfPriceHistoryDataTime": etf_history_payload["dataTime"],
        "etfPriceHistoryCoverageTierCounts": etf_history_payload.get(
            "coverageTierCounts",
            {},
        ),
        "etfPriceHistorySourceContractCounts": etf_history_source_contract_counts,
        "etfPriceHistoryGapReasonCounts": etf_history_payload.get(
            "gapReasonCounts",
            {},
        ),
        "etfPriceHistoryGapReasonSamples": etf_history_payload.get(
            "gapReasonSamples",
            {},
        ),
        "minimumCatalogRowCount": catalog_min_rows,
        "release": release_payload,
        "warnings": warnings,
        "failures": failures,
        "overallStatus": "FAIL" if failures else "PASS" if is_ready else "WARN",
        "files": manifest_payload["files"],
    }


def static_export_status(output_dir: str | Path) -> dict[str, Any]:
    checked_at = utc_now_iso()
    output = Path(output_dir)
    manifest_path = output / "manifest.json"
    status_path = output / "status.json"
    if not manifest_path.exists() or not status_path.exists():
        return {
            "sourceStatus": "unavailable",
            "sourceContract": STATIC_SOURCE_CONTRACT,
            "checkedAt": checked_at,
            "outputDir": str(output),
            "rowCount": 0,
            "coverageStart": None,
            "coverageEnd": None,
            "etfCatalogRowCount": 0,
            "etfCatalogDataTime": None,
            "etfPriceHistoryAttemptedCount": 0,
            "etfPriceHistoryGapDetailCount": 0,
            "etfPriceHistorySourceContractCounts": {},
            "etfPriceHistoryGapReasonSamples": {},
            "minimumCatalogRowCount": 0,
            "overallStatus": "WARN",
            "warnings": ["Static public data export does not exist yet."],
            "failures": [],
            "errorMessage": (
                "Run scripts\\00631l_export_static_data.cmd --update to "
                "generate web\\00631l-static-data."
            ),
        }
    try:
        manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
        status = json.loads(status_path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as error:
        return {
            "sourceStatus": "error",
            "sourceContract": STATIC_SOURCE_CONTRACT,
            "checkedAt": checked_at,
            "outputDir": str(output),
            "rowCount": 0,
            "coverageStart": None,
            "coverageEnd": None,
            "etfCatalogRowCount": 0,
            "etfCatalogDataTime": None,
            "etfPriceHistoryAttemptedCount": 0,
            "etfPriceHistoryGapDetailCount": 0,
            "etfPriceHistorySourceContractCounts": {},
            "etfPriceHistoryGapReasonSamples": {},
            "minimumCatalogRowCount": 0,
            "overallStatus": "FAIL",
            "warnings": [],
            "failures": [str(error)],
            "errorMessage": f"Static public data JSON is invalid: {error}",
        }
    row_count = int(manifest.get("rowCount") or status.get("rowCount") or 0)
    warnings = list(manifest.get("warnings") or [])
    failures = list(manifest.get("failures") or [])
    catalog_row_count = int(manifest.get("etfCatalogRowCount") or 0)
    etf_history_index = _read_optional_json(output / "etf_price_history_index.json")
    release_payload = manifest.get("release")
    if not isinstance(release_payload, dict) or not release_payload:
        release_payload = _read_optional_json(output / "release.json")
    etf_tier_counts = manifest.get("etfPriceHistoryCoverageTierCounts")
    etf_source_contract_counts = manifest.get("etfPriceHistorySourceContractCounts")
    etf_gap_reason_counts = manifest.get("etfPriceHistoryGapReasonCounts")
    etf_gap_reason_samples = manifest.get("etfPriceHistoryGapReasonSamples")
    legacy_etf_summary: dict[str, Any] = {}
    if not isinstance(etf_tier_counts, dict) or not etf_tier_counts:
        etf_tier_counts = etf_history_index.get("coverageTierCounts", {})
    if not isinstance(etf_source_contract_counts, dict) or not etf_source_contract_counts:
        etf_source_contract_counts = etf_history_index.get(
            "historySourceContractCounts",
            etf_history_index.get("sourceContractCounts", {}),
        )
    if not isinstance(etf_gap_reason_counts, dict) or not etf_gap_reason_counts:
        etf_gap_reason_counts = etf_history_index.get("gapReasonCounts", {})
    if not isinstance(etf_gap_reason_samples, dict) or not etf_gap_reason_samples:
        etf_gap_reason_samples = etf_history_index.get("gapReasonSamples", {})
    if not isinstance(etf_tier_counts, dict) or not etf_tier_counts:
        legacy_etf_summary = _derive_static_etf_summary(output)
        etf_tier_counts = legacy_etf_summary.get("coverageTierCounts", {})
    if (not isinstance(etf_gap_reason_counts, dict) or not etf_gap_reason_counts) and legacy_etf_summary:
        etf_gap_reason_counts = legacy_etf_summary.get("gapReasonCounts", {})
    etf_history_row_count = int(manifest.get("etfPriceHistoryRowCount") or 0)
    etf_history_ready_count = int(manifest.get("etfPriceHistoryReadyCount") or 0)
    etf_history_missing_count = int(manifest.get("etfPriceHistoryMissingCount") or 0)
    if legacy_etf_summary and int(legacy_etf_summary.get("rowCount") or 0) > etf_history_row_count:
        etf_history_row_count = int(legacy_etf_summary.get("rowCount") or 0)
        etf_history_ready_count = int(legacy_etf_summary.get("readyCount") or 0)
        etf_history_missing_count = max(
            0,
            etf_history_row_count - etf_history_ready_count,
        )
    return {
        "sourceStatus": manifest.get("sourceStatus", "unavailable"),
        "sourceContract": STATIC_SOURCE_CONTRACT,
        "checkedAt": checked_at,
        "generatedAt": manifest.get("generatedAt"),
        "outputDir": str(output),
        "rowCount": row_count,
        "coverageStart": manifest.get("coverageStart"),
        "coverageEnd": manifest.get("coverageEnd"),
        "isCompleteFromListing": manifest.get("isCompleteFromListing") is True,
        "etfCatalogRowCount": catalog_row_count,
        "etfCatalogDataTime": manifest.get("etfCatalogDataTime"),
        "etfPriceHistoryRowCount": etf_history_row_count,
        "etfPriceHistoryReadyCount": etf_history_ready_count,
        "etfPriceHistoryMissingCount": etf_history_missing_count,
        "etfPriceHistoryGapDetailCount": int(
            manifest.get("etfPriceHistoryGapDetailCount")
            or etf_history_index.get("gapDetailCount")
            or _read_optional_json(output / "etf_price_history_gaps.json").get("rowCount")
            or 0,
        ),
        "etfPriceHistoryOutOfCatalogCount": int(
            manifest.get("etfPriceHistoryOutOfCatalogCount")
            or max(0, etf_history_row_count - catalog_row_count)
        ),
        "etfPriceHistoryAttemptedCount": int(
            manifest.get("etfPriceHistoryAttemptedCount")
            or etf_history_index.get("attemptedCount")
            or legacy_etf_summary.get("attemptedCount")
            or 0,
        ),
        "etfPriceHistoryDataTime": manifest.get("etfPriceHistoryDataTime")
        or etf_history_index.get("dataTime")
        or legacy_etf_summary.get("dataTime"),
        "etfPriceHistoryCoverageTierCounts": etf_tier_counts,
        "etfPriceHistorySourceContractCounts": etf_source_contract_counts
        if isinstance(etf_source_contract_counts, dict)
        else {},
        "etfPriceHistoryGapReasonCounts": etf_gap_reason_counts,
        "etfPriceHistoryGapReasonSamples": etf_gap_reason_samples
        if isinstance(etf_gap_reason_samples, dict)
        else {},
        "minimumCatalogRowCount": int(manifest.get("minimumCatalogRowCount") or 0),
        "release": release_payload,
        "overallStatus": "FAIL" if failures else "PASS" if row_count >= 2 else "WARN",
        "warnings": warnings,
        "failures": failures,
        "errorMessage": None if row_count >= 2 else status.get("errorMessage"),
    }


def _normalize_static_catalog_payload(
    *,
    etf_catalog_payload: dict[str, Any] | None,
    output_dir: Path,
    generated_at: str,
) -> dict[str, Any]:
    if not etf_catalog_payload:
        return {
            "sourceStatus": "unavailable",
            "sourceContract": "twse_all_etf_catalog_static_public",
            "sourceUrl": "unavailable",
            "fetchedAt": generated_at,
            "generatedAt": generated_at,
            "sourceUpdatedAt": None,
            "dataTime": None,
            "isStale": True,
            "userDelayMs": 15000,
            "rowCount": 0,
            "items": [],
            "errorMessage": (
                "Static public ETF catalog is unavailable. Run "
                "scripts\\00631l_export_static_data.cmd --update."
            ),
        }

    items = list(etf_catalog_payload.get("items") or [])
    row_count = int(etf_catalog_payload.get("rowCount") or len(items))
    source_url = str(etf_catalog_payload.get("sourceUrl") or f"local://{output_dir}")
    return {
        **etf_catalog_payload,
        "sourceStatus": "static_official" if row_count else "unavailable",
        "sourceContract": "twse_all_etf_catalog_static_public",
        "sourceUrl": source_url,
        "fetchedAt": generated_at,
        "generatedAt": generated_at,
        "sourceUpdatedAt": etf_catalog_payload.get("sourceUpdatedAt")
        or etf_catalog_payload.get("dataTime"),
        "dataTime": etf_catalog_payload.get("dataTime")
        or etf_catalog_payload.get("sourceUpdatedAt"),
        "isStale": etf_catalog_payload.get("isStale") is True,
        "rowCount": row_count,
        "items": items,
        "errorMessage": None
        if row_count
        else etf_catalog_payload.get("errorMessage")
        or "Static public ETF catalog has no rows.",
    }


def _reconcile_catalog_with_history_index(
    *,
    catalog_payload: dict[str, Any],
    etf_history_payload: dict[str, Any],
    generated_at: str,
    warnings: list[str],
) -> dict[str, Any]:
    catalog_items = [
        dict(item) for item in catalog_payload.get("items") or [] if isinstance(item, dict)
    ]
    history_items = [
        item for item in etf_history_payload.get("items") or [] if isinstance(item, dict)
    ]
    if not history_items:
        return catalog_payload

    history_by_code = {
        _normalized_code(item.get("code")): item
        for item in history_items
        if _normalized_code(item.get("code"))
    }
    enriched_items: list[dict[str, Any]] = []
    enriched_count = 0
    for item in catalog_items:
        code = _normalized_code(item.get("code"))
        history_item = history_by_code.get(code)
        if history_item:
            item = {**item, **_catalog_history_fields(history_item)}
            enriched_count += 1
        enriched_items.append(item)

    seen_codes = {_normalized_code(item.get("code")) for item in enriched_items}
    seen_codes.discard("")
    additions: list[dict[str, Any]] = []
    for item in history_items:
        code = _normalized_code(item.get("code"))
        if not code or code in seen_codes:
            continue
        seen_codes.add(code)
        additions.append(_catalog_item_from_history_status(item, generated_at=generated_at))

    if not additions and not enriched_count:
        return catalog_payload

    merged_items = enriched_items + additions
    if additions:
        warnings.append(f"historyIndexCatalogMerged={len(additions)}")
    if enriched_count:
        warnings.append(f"historyIndexCatalogEnriched={enriched_count}")
    return {
        **catalog_payload,
        "items": merged_items,
        "rowCount": len(merged_items),
        "historyIndexMergedCount": int(catalog_payload.get("historyIndexMergedCount") or 0)
        + len(additions),
        "historyIndexEnrichedCount": int(
            catalog_payload.get("historyIndexEnrichedCount") or 0
        )
        + enriched_count,
    }


def _catalog_history_fields(item: dict[str, Any]) -> dict[str, Any]:
    row_count = int(item.get("rowCount") or 0)
    coverage_tier = str(item.get("coverageTier") or "")
    source_status = str(item.get("sourceStatus") or "")
    gap_reason = str(item.get("gapReason") or "")
    last_attempt = item.get("lastAttemptAt")
    error_message = item.get("errorMessage")
    price_adjustment = item.get("priceAdjustment")
    if not isinstance(price_adjustment, dict):
        price_adjustment = {}
    adjustment_events = price_adjustment.get("events")
    if not isinstance(adjustment_events, list):
        adjustment_events = []
    price_field = str(
        item.get("priceField")
        or price_adjustment.get("priceFieldForReturns")
        or ""
    )
    adjustment_method = str(price_adjustment.get("method") or "")
    if row_count >= 2 and coverage_tier != "unavailable":
        gap_reason = ""
        error_message = None
    return {
        "coverageStart": item.get("coverageStart"),
        "coverageEnd": item.get("coverageEnd"),
        "coverageTier": coverage_tier,
        "rowCount": row_count,
        "priceHistorySourceStatus": source_status,
        "priceHistoryGapReason": gap_reason,
        "priceHistoryLastAttemptAt": last_attempt,
        "priceHistoryErrorMessage": error_message,
        "priceHistoryPriceField": price_field,
        "priceHistoryAdjustmentMethod": adjustment_method,
        "priceHistoryAdjustmentEventCount": len(adjustment_events),
        "priceHistorySourceContractCounts": item.get("historySourceContractCounts")
        or item.get("sourceContractCounts")
        or {},
    }


def _catalog_item_from_history_status(
    item: dict[str, Any],
    *,
    generated_at: str,
) -> dict[str, Any]:
    code = _normalized_code(item.get("code"))
    return {
        "code": code,
        "name": str(item.get("name") or code),
        "outstandingUnits": None,
        "outstandingUnitsDelta": None,
        "marketPrice": None,
        "estimatedNav": None,
        "premiumDiscountPct": None,
        "previousNav": None,
        "dataDate": None,
        "dataTime": item.get("dataTime") or item.get("coverageEnd"),
        "targetType": "",
        "sourceStatus": "static_history_index",
        "sourceContract": item.get("sourceContract")
        or "twse_multi_etf_static_price_history_index",
        "sourceUrl": item.get("sourceUrl") or "static://etf-price-history-index",
        "fetchedAt": generated_at,
        "sourceUpdatedAt": item.get("sourceUpdatedAt")
        or item.get("coverageEnd")
        or item.get("dataTime"),
        **_catalog_history_fields(item),
    }


def _out_of_catalog_code_count(
    *,
    catalog_payload: dict[str, Any],
    etf_history_payload: dict[str, Any],
) -> int:
    catalog_codes = {
        _normalized_code(item.get("code"))
        for item in catalog_payload.get("items") or []
        if isinstance(item, dict)
    }
    catalog_codes.discard("")
    history_codes = {
        _normalized_code(item.get("code"))
        for item in etf_history_payload.get("items") or []
        if isinstance(item, dict)
    }
    history_codes.discard("")
    return len(history_codes - catalog_codes)


def _normalized_code(value: Any) -> str:
    return str(value or "").strip().upper()


def _export_static_etf_price_history(
    *,
    output_dir: Path,
    store: EtfPriceHistoryStore | None,
    codes: list[str] | tuple[str, ...],
    generated_at: str,
    warnings: list[str],
    failures: list[str],
    strict: bool,
) -> dict[str, Any]:
    history_dir = output_dir / "etf_price_history"
    history_dir.mkdir(parents=True, exist_ok=True)
    if store is None:
        gap_payload = {
            "sourceStatus": "unavailable",
            "sourceContract": "twse_multi_etf_static_price_history_gaps",
            "generatedAt": generated_at,
            "dataTime": None,
            "rowCount": len(codes),
            "reasonCounts": {"store_not_configured": len(codes)},
            "reasonSamples": {"store_not_configured": [str(code) for code in codes[:5]]},
            "items": [
                {
                    "code": str(code),
                    "gapReason": "store_not_configured",
                    "rowCount": 0,
                    "sourceStatus": "unavailable",
                    "errorMessage": "ETF price history store is not configured.",
                }
                for code in codes
            ],
        }
        payload = {
            "sourceStatus": "unavailable",
            "sourceContract": "twse_multi_etf_static_price_history_index",
            "generatedAt": generated_at,
            "dataTime": None,
            "rowCount": 0,
            "readyCount": 0,
            "missingCount": len(codes),
            "gapDetailCount": len(codes),
            "attemptedCount": 0,
            "historySourceContractCounts": {},
            "sourceContractCounts": {},
            "gapReasonCounts": {"store_not_configured": len(codes)},
            "gapReasonSamples": {"store_not_configured": [str(code) for code in codes[:5]]},
            "items": [],
            "errorMessage": "ETF price history store is not configured.",
        }
        _write_json(output_dir / "etf_price_history_index.json", payload)
        _write_json(output_dir / "etf_price_history_gaps.json", gap_payload)
        return payload

    items: list[dict[str, Any]] = []
    ready_count = 0
    latest: str | None = None
    missing_codes: list[str] = []
    for code in codes:
        status = store.status(code, fetched_at=generated_at)
        row_count = int(status.get("rowCount") or 0)
        if row_count >= 2:
            ready_count += 1
            latest_value = status.get("coverageEnd")
            if latest_value and (latest is None or str(latest_value) > latest):
                latest = str(latest_value)
            price_payload = store.price_response(
                code=code,
                limit=5000,
                fetched_at=generated_at,
            )
            static_payload = {
                **price_payload,
                "sourceStatus": "static_official",
                "sourceContract": "twse_multi_etf_static_price_history",
                "generatedAt": generated_at,
            }
            _write_json(history_dir / f"{code}.json", static_payload)
        else:
            missing_codes.append(code)
        items.append(status)

    tier_counts = _coverage_tier_counts(items)
    gap_reason_counts = _gap_reason_counts(items)
    gap_reason_samples = _gap_reason_samples(items)
    gap_detail_items = _gap_detail_items(items)
    source_contract_counts = _sum_source_contract_counts(items)
    if strict and codes and ready_count == 0:
        failures.append("No selected ETF price history is available for static export.")

    gap_payload = {
        "sourceStatus": "static_official" if items else "unavailable",
        "sourceContract": "twse_multi_etf_static_price_history_gaps",
        "generatedAt": generated_at,
        "dataTime": latest,
        "rowCount": len(gap_detail_items),
        "reasonCounts": gap_reason_counts,
        "reasonSamples": gap_reason_samples,
        "items": gap_detail_items,
    }
    payload = {
        "sourceStatus": "static_official" if ready_count else "unavailable",
        "sourceContract": "twse_multi_etf_static_price_history_index",
        "generatedAt": generated_at,
        "dataTime": latest,
        "rowCount": len(items),
        "readyCount": ready_count,
        "missingCount": len(missing_codes),
        "gapDetailCount": len(gap_detail_items),
        "attemptedCount": sum(1 for item in items if item.get("lastImportAttempt")),
        "missingSample": missing_codes[:10],
        "coverageTierCounts": tier_counts,
        "historySourceContractCounts": source_contract_counts,
        "sourceContractCounts": source_contract_counts,
        "gapReasonCounts": gap_reason_counts,
        "gapReasonSamples": gap_reason_samples,
        "items": items,
        "errorMessage": None if ready_count else "No selected ETF price history is available.",
    }
    _write_json(output_dir / "etf_price_history_index.json", payload)
    _write_json(output_dir / "etf_price_history_gaps.json", gap_payload)
    return payload


def _normalize_release_metadata(
    *,
    release_metadata: dict[str, Any] | None,
    generated_at: str,
) -> dict[str, Any]:
    source = release_metadata if isinstance(release_metadata, dict) else {}
    return {
        "sourceContract": "00631l_static_public_release_marker",
        "generatedAt": generated_at,
        "appVersion": str(source.get("appVersion") or ""),
        "releaseTag": str(source.get("releaseTag") or ""),
        "gitSha": str(source.get("gitSha") or ""),
        "buildTime": str(source.get("buildTime") or generated_at),
    }


def _coverage_tier_counts(items: list[dict[str, Any]]) -> dict[str, int]:
    counts = {"long_term": 0, "recent": 0, "unavailable": 0, "error": 0}
    for item in items:
        tier = str(item.get("coverageTier") or "unavailable")
        counts[tier] = counts.get(tier, 0) + 1
    return counts


def _sum_source_contract_counts(items: list[dict[str, Any]]) -> dict[str, int]:
    counts: dict[str, int] = {}
    for item in items:
        source_counts = item.get("historySourceContractCounts") or item.get(
            "sourceContractCounts"
        )
        if not isinstance(source_counts, dict):
            continue
        for key, value in source_counts.items():
            source = str(key or "").strip() or "unknown"
            try:
                count = int(value)
            except (TypeError, ValueError):
                count = 0
            if count > 0:
                counts[source] = counts.get(source, 0) + count
    return dict(sorted(counts.items()))


def _gap_reason_counts(items: list[dict[str, Any]]) -> dict[str, int]:
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
            reason = _gap_reason(
                row_count=row_count,
                source_status=str(item.get("sourceStatus") or ""),
                validation_failure_count=validation_failure_count,
            )
        counts[reason] = counts.get(reason, 0) + 1
    return counts


def _gap_reason_samples(
    items: list[dict[str, Any]],
    *,
    limit_per_reason: int = 5,
) -> dict[str, list[str]]:
    samples: dict[str, list[str]] = {}
    for item in items:
        row_count = int(item.get("rowCount") or 0)
        validation_failure_count = int(item.get("validationFailureCount") or 0)
        if row_count >= 2 and validation_failure_count == 0:
            continue
        reason = str(item.get("gapReason") or "")
        if not reason:
            reason = _gap_reason(
                row_count=row_count,
                source_status=str(item.get("sourceStatus") or ""),
                validation_failure_count=validation_failure_count,
            )
        code = str(item.get("code") or "").strip().upper()
        if not code:
            continue
        bucket = samples.setdefault(reason, [])
        if len(bucket) < limit_per_reason and code not in bucket:
            bucket.append(code)
    return samples


def _gap_detail_items(items: list[dict[str, Any]]) -> list[dict[str, Any]]:
    details: list[dict[str, Any]] = []
    for item in items:
        row_count = int(item.get("rowCount") or 0)
        validation_failure_count = int(item.get("validationFailureCount") or 0)
        if row_count >= 2 and validation_failure_count == 0:
            continue
        attempt = item.get("lastImportAttempt")
        if not isinstance(attempt, dict):
            attempt = {}
        reason = str(item.get("gapReason") or "")
        if not reason:
            reason = _gap_reason(
                row_count=row_count,
                source_status=str(item.get("sourceStatus") or ""),
                validation_failure_count=validation_failure_count,
            )
        details.append(
            {
                "code": str(item.get("code") or ""),
                "gapReason": reason,
                "coverageTier": str(item.get("coverageTier") or "unavailable"),
                "rowCount": row_count,
                "validationFailureCount": validation_failure_count,
                "sourceStatus": str(item.get("sourceStatus") or "unavailable"),
                "sourceUrl": str(item.get("sourceUrl") or ""),
                "lastAttemptAt": attempt.get("attemptedAt"),
                "requestedMonths": int(attempt.get("requestedMonths") or 0),
                "errorMessage": item.get("errorMessage")
                or attempt.get("errorMessage"),
            }
        )
    return sorted(details, key=lambda row: str(row.get("code") or ""))


def _gap_reason(
    *,
    row_count: int,
    source_status: str,
    validation_failure_count: int,
) -> str:
    if validation_failure_count > 0:
        return "validation_error"
    if str(source_status or "").lower() == "error":
        return "source_error"
    if row_count <= 0:
        return "not_saved"
    if row_count < 2:
        return "insufficient_rows"
    return "not_ready"


def _derive_static_etf_summary(output_dir: Path) -> dict[str, Any]:
    history_dir = output_dir / "etf_price_history"
    if not history_dir.exists():
        return {}
    items: list[dict[str, Any]] = []
    latest: str | None = None
    for path in sorted(history_dir.glob("*.json")):
        payload = _read_optional_json(path)
        if not payload:
            continue
        coverage_end = payload.get("coverageEnd")
        if coverage_end and (latest is None or str(coverage_end) > latest):
            latest = str(coverage_end)
        items.append(
            {
                "sourceStatus": payload.get("sourceStatus"),
                "coverageStart": payload.get("coverageStart"),
                "rowCount": int(payload.get("rowCount") or 0),
                "coverageTier": _derive_static_etf_tier(payload),
            }
        )
    if not items:
        return {}
    return {
        "rowCount": len(items),
        "readyCount": sum(1 for item in items if int(item.get("rowCount") or 0) >= 2),
        "attemptedCount": 0,
        "dataTime": latest,
        "coverageTierCounts": _coverage_tier_counts(items),
        "gapReasonCounts": _gap_reason_counts(items),
    }


def _derive_static_etf_tier(payload: dict[str, Any]) -> str:
    if payload.get("sourceStatus") == "error":
        return "error"
    row_count = int(payload.get("rowCount") or 0)
    if row_count < 2 or payload.get("sourceStatus") == "unavailable":
        return "unavailable"
    start = _parse_iso_date(str(payload.get("coverageStart") or ""))
    if (
        start is not None
        and start <= LONG_TERM_COVERAGE_START_CUTOFF
        and row_count >= LONG_TERM_COVERAGE_MIN_ROWS
    ):
        return "long_term"
    return "recent"


def _parse_iso_date(value: str):
    try:
        return datetime.strptime(value, "%Y-%m-%d").date()
    except ValueError:
        return None


def _read_optional_json(path: Path) -> dict[str, Any]:
    if not path.exists():
        return {}
    try:
        decoded = json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError:
        return {}
    return decoded if isinstance(decoded, dict) else {}


def _write_json(path: Path, payload: dict[str, Any]) -> None:
    path.write_text(
        json.dumps(payload, ensure_ascii=False, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )
