from __future__ import annotations

from collections import Counter
from datetime import date, datetime, timezone, timedelta
import json
from pathlib import Path
from typing import Any


HOLDINGS_REQUIRED_FIELDS = [
    "tradeDate",
    "fundNetAssetValue",
    "navPerUnit",
    "outstandingUnits",
    "assetValues",
    "stockHoldings",
    "futuresHoldings",
    "cashHoldings",
    "sourceStatus",
    "sourceUrl",
    "fetchedAt",
    "sourceHash",
]

INTRADAY_REQUIRED_FIELDS = [
    "dataDate",
    "dataTime",
    "marketPrice",
    "estimatedNav",
    "premiumDiscountPct",
    "sourceContract",
    "sourceStatus",
    "sourceUrl",
    "fetchedAt",
]


def check_00631l_data_integrity(
    *,
    holdings_history_path: str | Path,
    intraday_history_path: str | Path,
    output_path: str | Path | None = None,
) -> dict[str, Any]:
    holdings_records = _read_jsonl(Path(holdings_history_path))
    intraday_records = _read_jsonl(Path(intraday_history_path))

    failures: list[str] = []
    warnings: list[str] = []
    holdings_result = _check_holdings(holdings_records, failures, warnings)
    intraday_result = _check_intraday(intraday_records, failures, warnings)

    overall_status = "FAIL" if failures else "WARN" if warnings else "PASS"
    payload = {
        "sourceStatus": "cached" if holdings_records or intraday_records else "unavailable",
        "sourceContract": "00631l_data_integrity",
        "checkedAt": _utc_now_iso(),
        "overallStatus": overall_status,
        "holdings": holdings_result,
        "intraday": intraday_result,
        "warnings": warnings,
        "failures": failures,
        "warningCount": len(warnings),
        "failureCount": len(failures),
    }
    if output_path is not None:
        path = Path(output_path)
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(
            json.dumps(payload, ensure_ascii=False, indent=2, sort_keys=True),
            encoding="utf-8",
        )
    return payload


def integrity_status(path: str | Path) -> dict[str, Any]:
    status_path = Path(path)
    if not status_path.exists():
        return {
            "sourceStatus": "unavailable",
            "sourceContract": "00631l_data_integrity",
            "checkedAt": None,
            "overallStatus": "missing",
            "warningCount": 0,
            "failureCount": 0,
            "warnings": [],
            "failures": [],
            "isStale": True,
            "errorMessage": "No data integrity status file found.",
        }
    try:
        decoded = json.loads(status_path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return {
            "sourceStatus": "error",
            "sourceContract": "00631l_data_integrity",
            "checkedAt": None,
            "overallStatus": "error",
            "warningCount": 0,
            "failureCount": 1,
            "warnings": [],
            "failures": [f"Integrity status read failed: {error}"],
            "isStale": True,
            "errorMessage": f"Integrity status read failed: {error}",
        }
    if isinstance(decoded, dict):
        return {**decoded, "isStale": False, "errorMessage": decoded.get("errorMessage")}
    return {
        "sourceStatus": "error",
        "sourceContract": "00631l_data_integrity",
        "checkedAt": None,
        "overallStatus": "error",
        "warningCount": 0,
        "failureCount": 1,
        "warnings": [],
        "failures": ["Integrity status payload is not an object."],
        "isStale": True,
        "errorMessage": "Integrity status payload is not an object.",
    }


def _check_holdings(
    records: list[dict[str, Any]],
    failures: list[str],
    warnings: list[str],
) -> dict[str, Any]:
    trade_dates = [str(record.get("tradeDate") or "") for record in records]
    duplicates = sorted(date_text for date_text, count in Counter(trade_dates).items() if date_text and count > 1)
    missing_fields = _missing_fields(records, HOLDINGS_REQUIRED_FIELDS, "tradeDate")
    abnormal_sources = [
        str(record.get("tradeDate") or f"row{index}")
        for index, record in enumerate(records)
        if record.get("sourceStatus") != "official"
    ]
    missing_weekdays = _missing_weekdays(trade_dates)

    for item in duplicates:
        failures.append(f"holdings duplicate tradeDate {item}")
    for item in missing_fields:
        failures.append(f"holdings missing required field {item}")
    for item in abnormal_sources:
        warnings.append(f"holdings sourceStatus is not official at {item}")
    for item in missing_weekdays:
        warnings.append(f"holdings has weekday gap {item}")

    return {
        "recordCount": len(records),
        "latestTradeDate": max(trade_dates) if trade_dates else None,
        "duplicateTradeDates": duplicates,
        "missingRequiredFields": missing_fields,
        "missingWeekdays": missing_weekdays,
        "abnormalSourceRecords": abnormal_sources,
    }


def _check_intraday(
    records: list[dict[str, Any]],
    failures: list[str],
    warnings: list[str],
) -> dict[str, Any]:
    keys = [
        f"{record.get('sourceContract') or ''}|{record.get('dataTime') or ''}"
        for record in records
    ]
    duplicates = sorted(key for key, count in Counter(keys).items() if key != "|" and count > 1)
    missing_fields = _missing_fields(records, INTRADAY_REQUIRED_FIELDS, "dataTime")
    abnormal_sources = [
        str(record.get("dataTime") or f"row{index}")
        for index, record in enumerate(records)
        if record.get("sourceStatus") != "official"
    ]

    for item in duplicates:
        failures.append(f"intraday duplicate sourceContract/dataTime {item}")
    for item in missing_fields:
        failures.append(f"intraday missing required field {item}")
    for item in abnormal_sources:
        warnings.append(f"intraday sourceStatus is not official at {item}")

    data_times = [str(record.get("dataTime") or "") for record in records if record.get("dataTime")]
    return {
        "recordCount": len(records),
        "latestDataTime": max(data_times) if data_times else None,
        "duplicateKeys": duplicates,
        "missingRequiredFields": missing_fields,
        "abnormalSourceRecords": abnormal_sources,
    }


def _missing_fields(
    records: list[dict[str, Any]],
    required_fields: list[str],
    key_field: str,
) -> list[str]:
    missing: list[str] = []
    for index, record in enumerate(records):
        record_key = record.get(key_field) or f"row{index}"
        for field in required_fields:
            value = record.get(field)
            if value is None or value == "" or value == [] or value == {}:
                missing.append(f"{record_key}.{field}")
    return missing


def _missing_weekdays(date_texts: list[str]) -> list[str]:
    parsed = sorted({_parse_date(text) for text in date_texts if _parse_date(text)})
    parsed_dates = [item for item in parsed if item is not None]
    if len(parsed_dates) < 2:
        return []
    present = set(parsed_dates)
    current = parsed_dates[0]
    end = parsed_dates[-1]
    missing: list[str] = []
    while current <= end:
        if current.weekday() < 5 and current not in present:
            missing.append(current.isoformat())
        current += timedelta(days=1)
    return missing


def _parse_date(value: str) -> date | None:
    try:
        return date.fromisoformat(value[:10])
    except ValueError:
        return None


def _read_jsonl(path: Path) -> list[dict[str, Any]]:
    if not path.exists():
        return []
    records: list[dict[str, Any]] = []
    for line in path.read_text(encoding="utf-8").splitlines():
        if not line.strip():
            continue
        try:
            decoded = json.loads(line)
        except json.JSONDecodeError:
            continue
        if isinstance(decoded, dict):
            records.append(decoded)
    return records


def _utc_now_iso() -> str:
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat()
