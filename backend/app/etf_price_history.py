from __future__ import annotations

import json
import re
from datetime import date, datetime, timezone
from pathlib import Path
from typing import Any

from .fetcher import fetch_text
from .price_history import (
    FetchText,
    PRICE_ADJUSTMENT_FIELD,
    fetch_twse_stock_day_range,
    performance_summary,
    utc_now_iso,
)


DEFAULT_ETF_HISTORY_CODES = (
    "00631L",
    "0050",
    "0056",
    "006208",
    "00692",
    "00713",
    "00757",
    "00850",
    "00878",
    "00881",
    "00919",
    "00922",
    "00923",
    "00929",
    "00940",
)
ETF_PRICE_HISTORY_CONTRACT = "twse_multi_etf_stock_day"
ETF_PRICE_VALIDATION_CONTRACT = "twse_multi_etf_price_history_validation"
ETF_PRICE_ADJUSTMENT_METHOD = "known_etf_split_events"
ETF_PRICE_ADJUSTMENT_EVENTS_BY_CODE: dict[str, list[dict[str, Any]]] = {
    "0050": [
        {
            "effectiveDate": "2025-06-18",
            "ratio": 4.0,
            "description": "0050 beneficial certificate split, 1 old unit to 4 new units.",
        },
    ],
    "00631L": [
        {
            "effectiveDate": "2026-03-31",
            "ratio": 22.0,
            "description": "00631L beneficial certificate split, 1 old unit to 22 new units.",
        },
    ],
}


class EtfPriceHistoryStore:
    def __init__(self, root_dir: str | Path) -> None:
        self.root_dir = Path(root_dir)

    def path_for(self, code: str) -> Path:
        normalized = normalize_etf_code(code)
        if not normalized:
            raise ValueError("ETF code is required")
        return self.root_dir / f"{normalized}.jsonl"

    def codes(self) -> list[str]:
        if not self.root_dir.exists():
            return []
        return sorted(
            normalize_etf_code(path.stem)
            for path in self.root_dir.glob("*.jsonl")
            if normalize_etf_code(path.stem)
        )

    def save_points(self, code: str, points: list[dict[str, Any]]) -> int:
        normalized = normalize_etf_code(code)
        if not normalized:
            return 0
        records = {str(record.get("date")): record for record in self.all(normalized)}
        changed = 0
        for point in points:
            day = str(point.get("date") or "")
            if not day:
                continue
            record = _record(normalized, point)
            if records.get(day) != record:
                changed += 1
            records[day] = record
        if changed:
            self._write_records(normalized, list(records.values()))
        return changed

    def normalize_saved_records(self, code: str) -> int:
        normalized = normalize_etf_code(code)
        if not normalized:
            return 0
        raw_records = self._read_raw_records(normalized)
        normalized_records = [_record(normalized, record) for record in raw_records]
        if raw_records != normalized_records:
            self._write_records(normalized, normalized_records)
            return len(normalized_records)
        return 0

    def all(self, code: str) -> list[dict[str, Any]]:
        records = [
            _record(normalize_etf_code(code), decoded)
            for decoded in self._read_raw_records(code)
        ]
        return sorted(records, key=lambda item: str(item.get("date") or ""))

    def recent(self, code: str, limit: int = 5000) -> list[dict[str, Any]]:
        normalized_limit = max(1, min(int(limit), 5000))
        return list(reversed(self.all(code)))[0:normalized_limit]

    def price_response(
        self,
        *,
        code: str,
        limit: int,
        fetched_at: str,
    ) -> dict[str, Any]:
        normalized = normalize_etf_code(code)
        records = list(reversed(self.recent(normalized, limit)))
        status = self.status(normalized, fetched_at=fetched_at)
        return {
            "code": normalized,
            "items": _with_performance_fields(records),
            "limit": limit,
            "sourceStatus": status["sourceStatus"],
            "sourceContract": ETF_PRICE_HISTORY_CONTRACT,
            "sourceUrl": status["sourceUrl"],
            "fetchedAt": fetched_at,
            "sourceUpdatedAt": status["coverageEnd"],
            "dataTime": status["coverageEnd"],
            "coverageStart": status["coverageStart"],
            "coverageEnd": status["coverageEnd"],
            "rowCount": status["rowCount"],
            "isStale": status["isStale"],
            "priceField": status["priceField"],
            "priceAdjustment": status["priceAdjustment"],
            "validation": status["validation"],
            "errorMessage": status["errorMessage"],
        }

    def performance_response(self, *, code: str, fetched_at: str) -> dict[str, Any]:
        normalized = normalize_etf_code(code)
        records = self.all(normalized)
        status = self.status(normalized, fetched_at=fetched_at)
        return {
            "code": normalized,
            **performance_summary(records),
            "sourceStatus": status["sourceStatus"],
            "sourceContract": "twse_multi_etf_price_performance",
            "sourceUrl": status["sourceUrl"],
            "fetchedAt": fetched_at,
            "sourceUpdatedAt": status["coverageEnd"],
            "dataTime": status["coverageEnd"],
            "coverageStart": status["coverageStart"],
            "coverageEnd": status["coverageEnd"],
            "isStale": status["isStale"],
            "priceField": status["priceField"],
            "priceAdjustment": status["priceAdjustment"],
            "validation": status["validation"],
            "errorMessage": status["errorMessage"],
        }

    def status(self, code: str, *, fetched_at: str) -> dict[str, Any]:
        normalized = normalize_etf_code(code)
        records = self.all(normalized)
        if not records:
            validation = validate_etf_price_records(normalized, records)
            return {
                "code": normalized,
                "sourceStatus": "unavailable",
                "sourceContract": "twse_multi_etf_price_history_status",
                "sourceUrl": f"local://etf-price-history/{normalized}",
                "fetchedAt": fetched_at,
                "sourceUpdatedAt": None,
                "dataTime": None,
                "coverageStart": None,
                "coverageEnd": None,
                "rowCount": 0,
                "isStale": True,
                "priceField": _price_field_for_code(normalized),
                "priceAdjustment": _price_adjustment_for_code(normalized),
                "validation": validation,
                "validationStatus": validation["overallStatus"],
                "validationFailureCount": validation["failureCount"],
                "validationWarningCount": validation["warningCount"],
                "errorMessage": "No local ETF price history is saved for this code.",
            }
        coverage_start = str(records[0].get("date"))
        coverage_end = str(records[-1].get("date"))
        end_date = _parse_iso_date(coverage_end)
        today = datetime.now(timezone.utc).date()
        validation = validate_etf_price_records(normalized, records)
        return {
            "code": normalized,
            "sourceStatus": "error"
            if validation["failureCount"]
            else "cached",
            "sourceContract": "twse_multi_etf_price_history_status",
            "sourceUrl": f"local://etf-price-history/{normalized}",
            "fetchedAt": fetched_at,
            "sourceUpdatedAt": coverage_end,
            "dataTime": coverage_end,
            "coverageStart": coverage_start,
            "coverageEnd": coverage_end,
            "rowCount": len(records),
            "isStale": True if end_date is None else (today - end_date).days > 7,
            "priceField": _price_field_for_code(normalized),
            "priceAdjustment": _price_adjustment_for_code(normalized),
            "validation": validation,
            "validationStatus": validation["overallStatus"],
            "validationFailureCount": validation["failureCount"],
            "validationWarningCount": validation["warningCount"],
            "errorMessage": "; ".join(validation["failures"])
            if validation["failureCount"]
            else None,
        }

    def index_response(self, *, fetched_at: str) -> dict[str, Any]:
        items = [
            self.status(path.stem, fetched_at=fetched_at)
            for path in sorted(self.root_dir.glob("*.jsonl"))
        ]
        ready_items = [
            item
            for item in items
            if int(item.get("rowCount") or 0) >= 2
            and int(item.get("validationFailureCount") or 0) == 0
        ]
        latest = max(
            (str(item.get("coverageEnd")) for item in ready_items if item.get("coverageEnd")),
            default=None,
        )
        validation_failure_count = sum(
            int(item.get("validationFailureCount") or 0) for item in items
        )
        validation_warning_count = sum(
            int(item.get("validationWarningCount") or 0) for item in items
        )
        validation_failures = [
            f"{item.get('code')}: {failure}"
            for item in items
            for failure in (item.get("validation") or {}).get("failures", [])
        ]
        return {
            "sourceStatus": "error"
            if validation_failure_count
            else "cached" if ready_items else "unavailable",
            "sourceContract": "twse_multi_etf_price_history_index",
            "sourceUrl": f"local://{self.root_dir}",
            "fetchedAt": fetched_at,
            "sourceUpdatedAt": latest,
            "dataTime": latest,
            "isStale": not bool(ready_items),
            "rowCount": len(items),
            "readyCount": len(ready_items),
            "validationFailureCount": validation_failure_count,
            "validationWarningCount": validation_warning_count,
            "validationFailures": validation_failures,
            "items": items,
            "errorMessage": "; ".join(validation_failures)
            if validation_failures
            else None
            if ready_items
            else "No multi-ETF price history is saved yet.",
        }

    def _write_records(self, code: str, records: list[dict[str, Any]]) -> None:
        self.root_dir.mkdir(parents=True, exist_ok=True)
        ordered = sorted(records, key=lambda item: str(item.get("date") or ""))
        body = "".join(
            json.dumps(record, ensure_ascii=False, sort_keys=True) + "\n"
            for record in ordered
        )
        path = self.path_for(code)
        temp_path = path.with_suffix(path.suffix + ".tmp")
        temp_path.write_text(body, encoding="utf-8")
        temp_path.replace(path)

    def _read_raw_records(self, code: str) -> list[dict[str, Any]]:
        path = self.path_for(code)
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


def normalize_etf_code(value: str) -> str:
    text = str(value or "").strip().upper()
    return text if re.fullmatch(r"[0-9A-Z]{4,8}", text) else ""


def parse_code_list(value: str) -> list[str]:
    seen: set[str] = set()
    codes: list[str] = []
    for raw in re.split(r"[,;\s]+", value.strip()):
        code = normalize_etf_code(raw)
        if code and code not in seen:
            seen.add(code)
            codes.append(code)
    return codes


def catalog_codes(payload: dict[str, Any], *, limit: int | None = None) -> list[str]:
    items = payload.get("items")
    if not isinstance(items, list):
        return []
    codes = []
    for item in items:
        if isinstance(item, dict):
            code = normalize_etf_code(str(item.get("code") or ""))
            if code:
                codes.append(code)
    unique = list(dict.fromkeys(codes))
    return unique if limit is None or limit <= 0 else unique[:limit]


def fetch_etf_price_history(
    *,
    code: str,
    fetcher: FetchText = fetch_text,
    url_template: str,
    start_date: date,
    end_date: date,
    timeout_seconds: float,
) -> dict[str, Any]:
    normalized = normalize_etf_code(code)
    if not normalized:
        raise ValueError(f"Invalid ETF code: {code}")
    payload = fetch_twse_stock_day_range(
        fetcher=fetcher,
        url_template=url_template,
        start_date=start_date,
        end_date=end_date,
        timeout_seconds=timeout_seconds,
        symbol=normalized,
        adjust_for_00631l_split=False,
    )
    payload["points"] = [_record(normalized, point) for point in payload["points"]]
    return payload


def _record(code: str, point: dict[str, Any]) -> dict[str, Any]:
    normalized = normalize_etf_code(code)
    close = _float(point.get("close")) or 0.0
    record = {
        "code": normalized,
        "date": str(point.get("date") or ""),
        "open": _float(point.get("open")),
        "high": _float(point.get("high")),
        "low": _float(point.get("low")),
        "close": close,
        "adjustedOpen": _float(point.get("open")),
        "adjustedHigh": _float(point.get("high")),
        "adjustedLow": _float(point.get("low")),
        "adjustedClose": close,
        "adjustmentFactor": 1.0,
        "volume": _int(point.get("volume")),
        "nav": _float(point.get("nav")),
        "premiumDiscountPct": _float(point.get("premiumDiscountPct")),
        "sourceStatus": str(point.get("sourceStatus") or "official"),
        "sourceContract": str(point.get("sourceContract") or "twse_stock_day_json"),
        "sourceUrl": str(point.get("sourceUrl") or ""),
    }
    if _has_known_price_adjustment(normalized):
        factor = _adjustment_factor_for_code_date(normalized, record["date"])
        record = {
            **record,
            "adjustedOpen": _adjust_price(record["open"], factor),
            "adjustedHigh": _adjust_price(record["high"], factor),
            "adjustedLow": _adjust_price(record["low"], factor),
            "adjustedClose": _adjust_price(record["close"], factor) or 0.0,
            "adjustmentFactor": factor,
        }
    return record


def _with_performance_fields(records: list[dict[str, Any]]) -> list[dict[str, Any]]:
    ordered = sorted(records, key=lambda item: str(item.get("date") or ""))
    if not ordered:
        return []
    first_close = _price_for_returns(ordered[0]) or 0.0
    peak = first_close
    previous_close: float | None = None
    enriched: list[dict[str, Any]] = []
    for record in ordered:
        close = _price_for_returns(record) or 0.0
        peak = max(peak, close)
        daily_return = None
        if previous_close and previous_close > 0:
            daily_return = (close / previous_close - 1) * 100
        cumulative = None if first_close <= 0 else (close / first_close - 1) * 100
        drawdown = None if peak <= 0 else (close / peak - 1) * 100
        enriched.append(
            {
                **record,
                "dailyReturnPct": daily_return,
                "cumulativeReturnPct": cumulative,
                "drawdownPct": drawdown,
            }
        )
        previous_close = close
    return enriched


def validate_etf_price_records(code: str, records: list[dict[str, Any]]) -> dict[str, Any]:
    normalized = normalize_etf_code(code)
    failures: list[str] = []
    warnings: list[str] = []
    seen_dates: set[str] = set()
    duplicate_dates: list[str] = []
    non_positive_close = 0
    invalid_ohlc = 0
    suspicious_moves: list[str] = []

    ordered = sorted(records, key=lambda item: str(item.get("date") or ""))
    previous: dict[str, Any] | None = None
    for record in ordered:
        day = str(record.get("date") or "")
        if not day:
            failures.append("missing date")
            continue
        if day in seen_dates:
            duplicate_dates.append(day)
        seen_dates.add(day)

        close = _float(record.get("close"))
        if close is None or close <= 0:
            non_positive_close += 1

        low = _float(record.get("low"))
        high = _float(record.get("high"))
        open_price = _float(record.get("open"))
        if low is not None and high is not None and high < low:
            invalid_ohlc += 1
        if close is not None and low is not None and high is not None:
            if close < low * 0.999 or close > high * 1.001:
                invalid_ohlc += 1
        if open_price is not None and low is not None and high is not None:
            if open_price < low * 0.999 or open_price > high * 1.001:
                invalid_ohlc += 1

        if previous is not None:
            previous_price = _price_for_returns(previous)
            current_price = _price_for_returns(record)
            if previous_price and current_price:
                daily_return = current_price / previous_price - 1
                if abs(daily_return) > 0.45:
                    suspicious_moves.append(f"{day}:{daily_return * 100:.2f}%")
        previous = record

    if duplicate_dates:
        failures.append(f"duplicate dates: {', '.join(duplicate_dates[:5])}")
    if non_positive_close:
        failures.append(f"non-positive close rows: {non_positive_close}")
    if invalid_ohlc:
        failures.append(f"invalid OHLC rows: {invalid_ohlc}")
    if suspicious_moves:
        warnings.append(
            "large adjusted daily moves: " + ", ".join(suspicious_moves[:5])
        )
    warnings.extend(_split_adjustment_warnings(normalized, ordered))
    failures.extend(_split_adjustment_failures(normalized, ordered))

    return {
        "sourceStatus": "error" if failures else "cached",
        "sourceContract": ETF_PRICE_VALIDATION_CONTRACT,
        "code": normalized,
        "overallStatus": "FAIL" if failures else "WARN" if warnings else "PASS",
        "failureCount": len(failures),
        "warningCount": len(warnings),
        "failures": failures,
        "warnings": warnings,
        "checkedRows": len(records),
        "priceField": _price_field_for_code(normalized),
        "priceAdjustment": _price_adjustment_for_code(normalized),
    }


def _split_adjustment_failures(
    code: str,
    ordered: list[dict[str, Any]],
) -> list[str]:
    events = _price_adjustment_events_for_code(code)
    if not events or not ordered:
        return []
    failures: list[str] = []
    for event in events:
        effective_date = str(event.get("effectiveDate") or "")
        ratio = _float(event.get("ratio")) or 1.0
        if not effective_date or ratio <= 0:
            continue
        before = [
            record for record in ordered if str(record.get("date") or "") < effective_date
        ]
        after = [
            record
            for record in ordered
            if str(record.get("date") or "") >= effective_date
        ]
        if not before or not after:
            continue
        expected_before_factor = _adjustment_factor_for_code_date(
            code,
            str(before[-1].get("date") or ""),
        )
        expected_after_factor = _adjustment_factor_for_code_date(
            code,
            str(after[0].get("date") or ""),
        )
        bad_before = [
            str(record.get("date"))
            for record in before
            if abs(
                (_float(record.get("adjustmentFactor")) or 1.0)
                - expected_before_factor
            )
            > 0.000001
        ]
        bad_after = [
            str(record.get("date"))
            for record in after
            if abs(
                (_float(record.get("adjustmentFactor")) or 1.0)
                - expected_after_factor
            )
            > 0.000001
        ]
        if bad_before:
            failures.append(
                f"{code} pre-split adjustmentFactor must be {expected_before_factor:.8f} before {effective_date}"
            )
        if bad_after:
            failures.append(
                f"{code} post-split adjustmentFactor must be {expected_after_factor:.8f} from {effective_date}"
            )
    return failures


def _split_adjustment_warnings(
    code: str,
    ordered: list[dict[str, Any]],
) -> list[str]:
    events = _price_adjustment_events_for_code(code)
    if not events or not ordered:
        return []
    warnings: list[str] = []
    for event in events:
        effective_date = str(event.get("effectiveDate") or "")
        ratio = _float(event.get("ratio")) or 1.0
        before = [
            record for record in ordered if str(record.get("date") or "") < effective_date
        ]
        after = [
            record
            for record in ordered
            if str(record.get("date") or "") >= effective_date
        ]
        if not before or not after:
            warnings.append(
                f"{code} split coverage does not cross {effective_date}; split validation is partial."
            )
            continue
        last_before = before[-1]
        first_after = after[0]
        raw_before = _float(last_before.get("close"))
        raw_after = _float(first_after.get("close"))
        adjusted_before = _price_for_returns(last_before)
        adjusted_after = _price_for_returns(first_after)
        if not raw_before or not raw_after or not adjusted_before or not adjusted_after:
            warnings.append(f"{code} split boundary could not be ratio-checked.")
            continue
        raw_ratio = raw_before / raw_after
        adjusted_ratio = adjusted_before / adjusted_after
        if raw_ratio < max(2.0, ratio * 0.45):
            warnings.append(
                f"{code} raw split boundary ratio is lower than expected; verify source rows."
            )
        if adjusted_ratio <= 0 or adjusted_ratio > 2.0 or adjusted_ratio < 0.5:
            warnings.append(
                f"{code} adjusted split boundary ratio is outside validation range."
            )
    return warnings


def _price_for_returns(record: dict[str, Any]) -> float | None:
    adjusted = _float(record.get(PRICE_ADJUSTMENT_FIELD))
    if adjusted is not None:
        return adjusted
    return _float(record.get("close"))


def _has_known_price_adjustment(code: str) -> bool:
    return bool(_price_adjustment_events_for_code(code))


def _price_field_for_code(code: str) -> str:
    return PRICE_ADJUSTMENT_FIELD if _has_known_price_adjustment(code) else "close"


def _price_adjustment_for_code(code: str) -> dict[str, Any]:
    events = _price_adjustment_events_for_code(code)
    if events:
        return {
            "method": ETF_PRICE_ADJUSTMENT_METHOD,
            "priceFieldForReturns": PRICE_ADJUSTMENT_FIELD,
            "events": events,
            "note": (
                "Raw TWSE OHLC prices are preserved. Performance, charts, "
                "comparison, and backtest calculations use split-adjusted prices."
            ),
        }
    return {
        "method": "none",
        "priceFieldForReturns": "close",
        "events": [],
        "note": "No known split adjustment is registered for this ETF code.",
    }


def _price_adjustment_events_for_code(code: str) -> list[dict[str, Any]]:
    return list(ETF_PRICE_ADJUSTMENT_EVENTS_BY_CODE.get(normalize_etf_code(code), []))


def _adjustment_factor_for_code_date(code: str, date_text: str) -> float:
    parsed = _parse_iso_date(date_text)
    if parsed is None:
        return 1.0
    factor = 1.0
    for event in _price_adjustment_events_for_code(code):
        event_date = _parse_iso_date(str(event.get("effectiveDate") or ""))
        ratio = _float(event.get("ratio")) or 1.0
        if event_date is not None and parsed < event_date and ratio > 0:
            factor /= ratio
    return factor


def _adjust_price(value: float | None, factor: float) -> float | None:
    if value is None:
        return None
    return round(value * factor, 6)


def _parse_iso_date(value: str) -> date | None:
    try:
        return datetime.strptime(value, "%Y-%m-%d").date()
    except ValueError:
        return None


def _float(value: Any) -> float | None:
    if isinstance(value, (int, float)):
        return float(value)
    if value is None:
        return None
    text = str(value).replace(",", "").strip()
    if text in {"", "--", "X"}:
        return None
    try:
        return float(text)
    except ValueError:
        return None


def _int(value: Any) -> int | None:
    number = _float(value)
    return None if number is None else int(number)
