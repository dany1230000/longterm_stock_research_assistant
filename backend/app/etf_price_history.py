from __future__ import annotations

import json
import re
from datetime import date, datetime, timezone
from pathlib import Path
from typing import Any

from .fetcher import fetch_text
from .price_history import (
    FetchText,
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


class EtfPriceHistoryStore:
    def __init__(self, root_dir: str | Path) -> None:
        self.root_dir = Path(root_dir)

    def path_for(self, code: str) -> Path:
        normalized = normalize_etf_code(code)
        if not normalized:
            raise ValueError("ETF code is required")
        return self.root_dir / f"{normalized}.jsonl"

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

    def all(self, code: str) -> list[dict[str, Any]]:
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
                records.append(_record(normalize_etf_code(code), decoded))
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
            "priceField": "close",
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
            "priceField": "close",
            "errorMessage": status["errorMessage"],
        }

    def status(self, code: str, *, fetched_at: str) -> dict[str, Any]:
        normalized = normalize_etf_code(code)
        records = self.all(normalized)
        if not records:
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
                "priceField": "close",
                "errorMessage": "No local ETF price history is saved for this code.",
            }
        coverage_start = str(records[0].get("date"))
        coverage_end = str(records[-1].get("date"))
        end_date = _parse_iso_date(coverage_end)
        today = datetime.now(timezone.utc).date()
        return {
            "code": normalized,
            "sourceStatus": "cached",
            "sourceContract": "twse_multi_etf_price_history_status",
            "sourceUrl": f"local://etf-price-history/{normalized}",
            "fetchedAt": fetched_at,
            "sourceUpdatedAt": coverage_end,
            "dataTime": coverage_end,
            "coverageStart": coverage_start,
            "coverageEnd": coverage_end,
            "rowCount": len(records),
            "isStale": True if end_date is None else (today - end_date).days > 7,
            "priceField": "close",
            "errorMessage": None,
        }

    def index_response(self, *, fetched_at: str) -> dict[str, Any]:
        items = [
            self.status(path.stem, fetched_at=fetched_at)
            for path in sorted(self.root_dir.glob("*.jsonl"))
        ]
        ready_items = [item for item in items if int(item.get("rowCount") or 0) >= 2]
        latest = max(
            (str(item.get("coverageEnd")) for item in ready_items if item.get("coverageEnd")),
            default=None,
        )
        return {
            "sourceStatus": "cached" if ready_items else "unavailable",
            "sourceContract": "twse_multi_etf_price_history_index",
            "sourceUrl": f"local://{self.root_dir}",
            "fetchedAt": fetched_at,
            "sourceUpdatedAt": latest,
            "dataTime": latest,
            "isStale": not bool(ready_items),
            "rowCount": len(items),
            "readyCount": len(ready_items),
            "items": items,
            "errorMessage": None if ready_items else "No multi-ETF price history is saved yet.",
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
    return fetch_twse_stock_day_range(
        fetcher=fetcher,
        url_template=url_template,
        start_date=start_date,
        end_date=end_date,
        timeout_seconds=timeout_seconds,
        symbol=normalized,
        adjust_for_00631l_split=False,
    )


def _record(code: str, point: dict[str, Any]) -> dict[str, Any]:
    close = _float(point.get("close")) or 0.0
    return {
        "code": normalize_etf_code(code),
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


def _with_performance_fields(records: list[dict[str, Any]]) -> list[dict[str, Any]]:
    ordered = sorted(records, key=lambda item: str(item.get("date") or ""))
    if not ordered:
        return []
    first_close = _float(ordered[0].get("close")) or 0.0
    peak = first_close
    previous_close: float | None = None
    enriched: list[dict[str, Any]] = []
    for record in ordered:
        close = _float(record.get("close")) or 0.0
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
