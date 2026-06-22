from __future__ import annotations

import json
import math
from datetime import date, datetime, timezone
from pathlib import Path
from typing import Any, Callable


FetchText = Callable[[str, float], str]

PRICE_ADJUSTMENT_FIELD = "adjustedClose"
PRICE_ADJUSTMENT_METHOD = "known_00631l_split_events"
PRICE_ADJUSTMENT_EVENTS = [
    {
        "effectiveDate": "2026-03-31",
        "ratio": 22.0,
        "description": "00631L beneficial certificate split, 1 old unit to 22 new units.",
    },
]


def utc_now_iso() -> str:
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat()


def price_adjustment_metadata() -> dict[str, Any]:
    return {
        "method": PRICE_ADJUSTMENT_METHOD,
        "priceFieldForReturns": PRICE_ADJUSTMENT_FIELD,
        "events": PRICE_ADJUSTMENT_EVENTS,
        "note": (
            "Raw TWSE OHLC prices are preserved. Performance and backtest "
            "calculations use split-adjusted prices."
        ),
    }


def normalize_price_record(point: dict[str, Any]) -> dict[str, Any]:
    return _price_record(point)


def apply_00631l_split_adjustments(records: list[dict[str, Any]]) -> list[dict[str, Any]]:
    return [_price_record(record) for record in records]


class PriceHistoryStore:
    def __init__(self, path: str | Path, *, seed_path: str | Path | None = None) -> None:
        self.path = Path(path)
        self.seed_path = Path(seed_path) if seed_path else None

    def save_points(self, points: list[dict[str, Any]]) -> int:
        if not points:
            return 0
        records = {str(record.get("date")): record for record in self._read_local_records()}
        changed = 0
        for point in points:
            day = str(point.get("date") or "")
            if not day:
                continue
            normalized = _price_record(point)
            if records.get(day) != normalized:
                changed += 1
            records[day] = normalized
        if changed:
            self._write_records(list(records.values()))
        return changed

    def recent(self, limit: int) -> list[dict[str, Any]]:
        normalized_limit = max(1, min(limit, 5000))
        return sorted(
            self._read_records(),
            key=lambda item: str(item.get("date") or ""),
            reverse=True,
        )[:normalized_limit]

    def all(self) -> list[dict[str, Any]]:
        return sorted(
            self._read_records(),
            key=lambda item: str(item.get("date") or ""),
        )

    def default_incremental_start_date(self, *, default_start: date) -> date:
        records = self.all()
        if not records:
            return default_start
        latest = _parse_iso_date(str(records[-1].get("date") or ""))
        if latest is None:
            return default_start
        return date(latest.year, latest.month, 1)

    def price_response(self, *, limit: int, fetched_at: str) -> dict[str, Any]:
        items = _with_performance_fields(list(reversed(self.recent(limit))))
        status = self.status_response(fetched_at=fetched_at)
        return {
            "items": items,
            "limit": limit,
            "sourceStatus": status["sourceStatus"],
            "sourceContract": "twse_stock_day_local_jsonl",
            "sourceUrl": status["sourceUrl"],
            "fetchedAt": fetched_at,
            "sourceUpdatedAt": status["coverageEnd"],
            "dataTime": status["coverageEnd"],
            "coverageStart": status["coverageStart"],
            "coverageEnd": status["coverageEnd"],
            "isCompleteFromListing": status["isCompleteFromListing"],
            "isStale": status["isStale"],
            "priceField": PRICE_ADJUSTMENT_FIELD,
            "priceAdjustment": price_adjustment_metadata(),
            "errorMessage": status["errorMessage"],
        }

    def performance_response(self, *, fetched_at: str) -> dict[str, Any]:
        records = self.all()
        summary = performance_summary(records)
        status = self.status_response(fetched_at=fetched_at)
        return {
            **summary,
            "sourceStatus": status["sourceStatus"],
            "sourceContract": "00631l_price_performance",
            "sourceUrl": status["sourceUrl"],
            "fetchedAt": fetched_at,
            "sourceUpdatedAt": status["coverageEnd"],
            "dataTime": status["coverageEnd"],
            "coverageStart": status["coverageStart"],
            "coverageEnd": status["coverageEnd"],
            "isCompleteFromListing": status["isCompleteFromListing"],
            "isStale": status["isStale"],
            "priceField": PRICE_ADJUSTMENT_FIELD,
            "priceAdjustment": price_adjustment_metadata(),
            "errorMessage": status["errorMessage"],
        }

    def status_response(self, *, fetched_at: str) -> dict[str, Any]:
        records = self.all()
        source_info = self._source_info()
        if not records:
            return {
                "sourceStatus": "unavailable",
                "sourceContract": "00631l_price_history_status",
                "sourceUrl": "local://00631l-price-history",
                "fetchedAt": fetched_at,
                "sourceUpdatedAt": None,
                "dataTime": None,
                "coverageStart": None,
                "coverageEnd": None,
                "rowCount": 0,
                "isCompleteFromListing": False,
                "isStale": True,
                "priceField": PRICE_ADJUSTMENT_FIELD,
                "priceAdjustment": price_adjustment_metadata(),
                "errorMessage": (
                    "No official price history is saved yet. Run the history "
                    "update script to populate local cache."
                ),
            }
        coverage_start = str(records[0].get("date"))
        coverage_end = str(records[-1].get("date"))
        today = datetime.now(timezone.utc).date()
        end_date = _parse_iso_date(coverage_end)
        is_stale = True if end_date is None else (today - end_date).days > 7
        return {
            "sourceStatus": source_info["sourceStatus"],
            "sourceContract": "00631l_price_history_status",
            "sourceUrl": source_info["sourceUrl"],
            "fetchedAt": fetched_at,
            "sourceUpdatedAt": coverage_end,
            "dataTime": coverage_end,
            "coverageStart": coverage_start,
            "coverageEnd": coverage_end,
            "rowCount": len(records),
            "isCompleteFromListing": coverage_start <= "2014-10-31",
            "isStale": is_stale,
            "priceField": PRICE_ADJUSTMENT_FIELD,
            "priceAdjustment": price_adjustment_metadata(),
            "errorMessage": None,
        }

    def _read_records(self) -> list[dict[str, Any]]:
        seed_records = self._read_seed_records()
        local_records = self._read_local_records()
        if not seed_records:
            return local_records
        if not local_records:
            return seed_records
        merged = {str(record.get("date")): record for record in seed_records}
        for record in local_records:
            day = str(record.get("date") or "")
            if day:
                merged[day] = record
        return sorted(merged.values(), key=lambda item: str(item.get("date") or ""))

    def _read_local_records(self) -> list[dict[str, Any]]:
        return self._read_jsonl_records(self.path)

    def _read_seed_records(self) -> list[dict[str, Any]]:
        if self.seed_path is None:
            return []
        return self._read_jsonl_records(self.seed_path)

    def _read_jsonl_records(self, path: Path) -> list[dict[str, Any]]:
        if not path.exists() or not path.is_file():
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
        return apply_00631l_split_adjustments(records)

    def _source_info(self) -> dict[str, str]:
        has_local = bool(self._read_local_records())
        has_seed = bool(self._read_seed_records())
        if has_local and has_seed:
            return {
                "sourceStatus": "cached",
                "sourceUrl": "local+seed://00631l-price-history",
            }
        if has_local:
            return {
                "sourceStatus": "cached",
                "sourceUrl": "local://00631l-price-history",
            }
        if has_seed:
            return {
                "sourceStatus": "static_official",
                "sourceUrl": "seed://00631l-price-history",
            }
        return {
            "sourceStatus": "unavailable",
            "sourceUrl": "local://00631l-price-history",
        }

    def _write_records(self, records: list[dict[str, Any]]) -> None:
        self.path.parent.mkdir(parents=True, exist_ok=True)
        ordered = sorted(records, key=lambda item: str(item.get("date") or ""))
        body = "".join(
            json.dumps(record, ensure_ascii=False, sort_keys=True) + "\n"
            for record in ordered
        )
        temp_path = self.path.with_suffix(self.path.suffix + ".tmp")
        temp_path.write_text(body, encoding="utf-8")
        temp_path.replace(self.path)


def fetch_twse_stock_day_range(
    *,
    fetcher: FetchText,
    url_template: str,
    start_date: date,
    end_date: date,
    timeout_seconds: float,
    symbol: str = "00631L",
    adjust_for_00631l_split: bool = True,
) -> dict[str, Any]:
    fetched_at = utc_now_iso()
    points: list[dict[str, Any]] = []
    failures: list[str] = []
    empty_month_count = 0
    urls: list[str] = []
    for month in _month_starts(start_date, end_date):
        url = url_template.format(
            yyyymmdd=f"{month.year:04d}{month.month:02d}01",
            year=month.year,
            month=f"{month.month:02d}",
            symbol=symbol,
        )
        if "{symbol}" not in url_template and symbol != "00631L":
            url = url.replace("stockNo=00631L", f"stockNo={symbol}")
        urls.append(url)
        try:
            source = fetcher(url, timeout_seconds)
            points.extend(
                parse_twse_stock_day(
                    source,
                    source_url=url,
                    adjust_for_00631l_split=adjust_for_00631l_split,
                )
            )
        except Exception as error:  # pragma: no cover - live network guard
            if "has no data list" in str(error):
                empty_month_count += 1
            else:
                failures.append(f"{month.isoformat()}: {error}")
    filtered = []
    for point in points:
        point_date = _parse_iso_date(str(point.get("date")))
        if point_date is not None and start_date <= point_date <= end_date:
            filtered.append(point)
    warnings = list(failures)
    if empty_month_count:
        warnings.append(f"emptyMonths={empty_month_count}")
    return {
        "points": filtered,
        "sourceStatus": "official" if filtered else "error",
        "sourceContract": "twse_stock_day_json",
        "sourceUrl": urls[-1] if urls else "",
        "symbol": symbol,
        "fetchedAt": fetched_at,
        "requestedMonths": len(urls),
        "rowCount": len(filtered),
        "warnings": warnings,
        "errorMessage": "; ".join(failures) if failures and not filtered else None,
    }


def parse_twse_stock_day(
    source: str,
    *,
    source_url: str,
    adjust_for_00631l_split: bool = True,
) -> list[dict[str, Any]]:
    decoded = json.loads(source)
    if not isinstance(decoded, dict):
        raise ValueError("TWSE STOCK_DAY payload is not an object")
    rows = decoded.get("data")
    if not isinstance(rows, list):
        raise ValueError("TWSE STOCK_DAY payload has no data list")
    points = []
    for row in rows:
        if not isinstance(row, list) or len(row) < 7:
            continue
        parsed_date = _parse_twse_date(str(row[0]))
        close = _float(row[6])
        if parsed_date is None or close is None:
            continue
        points.append(
            {
                "date": parsed_date.isoformat(),
                "volume": _int(row[1]),
                "open": _float(row[3]),
                "high": _float(row[4]),
                "low": _float(row[5]),
                "close": close,
                "nav": None,
                "premiumDiscountPct": None,
                "sourceStatus": "official",
                "sourceContract": "twse_stock_day_json",
                "sourceUrl": source_url,
            }
        )
    return apply_00631l_split_adjustments(points) if adjust_for_00631l_split else points


def performance_summary(records: list[dict[str, Any]]) -> dict[str, Any]:
    points = sorted(
        [record for record in records if _price_for_returns(record) is not None],
        key=lambda item: str(item.get("date") or ""),
    )
    if len(points) < 2:
        return {
            "totalReturnPct": None,
            "annualizedReturnPct": None,
            "annualizedVolatilityPct": None,
            "maxDrawdownPct": None,
            "bestDailyReturnPct": None,
            "worstDailyReturnPct": None,
            "rowCount": len(points),
            "priceField": PRICE_ADJUSTMENT_FIELD,
        }
    first_close = _price_for_returns(points[0]) or 0
    last_close = _price_for_returns(points[-1]) or 0
    first_date = _parse_iso_date(str(points[0].get("date")))
    last_date = _parse_iso_date(str(points[-1].get("date")))
    total_return = None if first_close <= 0 else (last_close / first_close - 1) * 100
    days = 0 if first_date is None or last_date is None else (last_date - first_date).days
    annualized_return = (
        None
        if total_return is None or days <= 0
        else (math.pow(last_close / first_close, 365 / days) - 1) * 100
    )
    returns: list[float] = []
    peak = first_close
    max_drawdown = 0.0
    for index in range(1, len(points)):
        previous = _price_for_returns(points[index - 1]) or 0
        current = _price_for_returns(points[index]) or 0
        if previous > 0:
            returns.append((current / previous - 1) * 100)
        if current > peak:
            peak = current
        if peak > 0:
            max_drawdown = min(max_drawdown, (current / peak - 1) * 100)
    return {
        "totalReturnPct": total_return,
        "annualizedReturnPct": annualized_return,
        "annualizedVolatilityPct": (
            None if len(returns) < 2 else _stdev(returns) * math.sqrt(252)
        ),
        "maxDrawdownPct": max_drawdown,
        "bestDailyReturnPct": max(returns) if returns else None,
        "worstDailyReturnPct": min(returns) if returns else None,
        "rowCount": len(points),
        "priceField": PRICE_ADJUSTMENT_FIELD,
    }


def _with_performance_fields(records: list[dict[str, Any]]) -> list[dict[str, Any]]:
    ordered = sorted(records, key=lambda item: str(item.get("date") or ""))
    if not ordered:
        return []
    first_close = _price_for_returns(ordered[0]) or 0
    peak = first_close
    previous_close: float | None = None
    enriched: list[dict[str, Any]] = []
    for record in ordered:
        close = _price_for_returns(record) or 0
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


def _price_record(point: dict[str, Any]) -> dict[str, Any]:
    record_date = str(point.get("date") or "")
    factor = _adjustment_factor_for_date(record_date)
    open_price = _float(point.get("open"))
    high_price = _float(point.get("high"))
    low_price = _float(point.get("low"))
    close_price = _float(point.get("close")) or 0.0
    return {
        "date": record_date,
        "open": open_price,
        "high": high_price,
        "low": low_price,
        "close": close_price,
        "adjustedOpen": _adjust_price(open_price, factor),
        "adjustedHigh": _adjust_price(high_price, factor),
        "adjustedLow": _adjust_price(low_price, factor),
        "adjustedClose": _adjust_price(close_price, factor) or 0.0,
        "adjustmentFactor": factor,
        "volume": _int(point.get("volume")),
        "nav": _float(point.get("nav")),
        "premiumDiscountPct": _float(point.get("premiumDiscountPct")),
        "sourceStatus": str(point.get("sourceStatus") or "official"),
        "sourceContract": str(point.get("sourceContract") or "twse_stock_day_json"),
        "sourceUrl": str(point.get("sourceUrl") or ""),
    }


def _price_for_returns(record: dict[str, Any]) -> float | None:
    adjusted = _float(record.get(PRICE_ADJUSTMENT_FIELD))
    if adjusted is not None:
        return adjusted
    close = _float(record.get("close"))
    if close is None:
        return None
    factor = _adjustment_factor_for_date(str(record.get("date") or ""))
    return _adjust_price(close, factor)


def _adjustment_factor_for_date(date_text: str) -> float:
    parsed = _parse_iso_date(date_text)
    if parsed is None:
        return 1.0
    factor = 1.0
    for event in PRICE_ADJUSTMENT_EVENTS:
        event_date = _parse_iso_date(str(event.get("effectiveDate") or ""))
        ratio = _float(event.get("ratio")) or 1.0
        if event_date is not None and parsed < event_date and ratio > 0:
            factor /= ratio
    return factor


def _adjust_price(value: float | None, factor: float) -> float | None:
    if value is None:
        return None
    return round(value * factor, 6)


def _month_starts(start_date: date, end_date: date) -> list[date]:
    cursor = date(start_date.year, start_date.month, 1)
    months: list[date] = []
    while cursor <= end_date:
        months.append(cursor)
        year = cursor.year + (1 if cursor.month == 12 else 0)
        month = 1 if cursor.month == 12 else cursor.month + 1
        cursor = date(year, month, 1)
    return months


def _parse_twse_date(value: str) -> date | None:
    parts = value.replace("-", "/").split("/")
    if len(parts) != 3:
        return None
    try:
        year = int(parts[0])
        if year < 1911:
            year += 1911
        return date(year, int(parts[1]), int(parts[2]))
    except ValueError:
        return None


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


def _stdev(values: list[float]) -> float:
    if len(values) < 2:
        return 0.0
    mean = sum(values) / len(values)
    variance = sum((value - mean) ** 2 for value in values) / (len(values) - 1)
    return math.sqrt(variance)
