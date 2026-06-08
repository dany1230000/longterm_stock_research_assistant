from __future__ import annotations

from copy import deepcopy
from datetime import datetime, timezone, timedelta
import json
from pathlib import Path
from typing import Any


TAIPEI_TZ = timezone(timedelta(hours=8))


class IntradayNavHistoryStore:
    def __init__(self, path: str | Path) -> None:
        self.path = Path(path)

    def save_official_nav(self, nav: dict[str, Any]) -> bool:
        if nav.get("sourceStatus") != "official":
            return False
        if not nav.get("dataTime"):
            return False

        record = _history_record(nav)
        record_key = _record_key(record)
        records = self._read_records()
        if any(_record_key(existing) == record_key for existing in records):
            return False

        records.append(record)
        self._write_records(records)
        return True

    def history_response(
        self,
        *,
        date: str | None,
        limit: int,
        fetched_at: str,
    ) -> dict[str, Any]:
        items = self.records_for_date(date=date, limit=limit)
        return _response_payload(items, limit=limit, fetched_at=fetched_at, summary=False)

    def summary_response(
        self,
        *,
        date: str | None,
        fetched_at: str,
    ) -> dict[str, Any]:
        items = self.records_for_date(date=date, limit=1000)
        summary = _summary(items)
        return {
            **_response_payload(items, limit=len(items), fetched_at=fetched_at, summary=True),
            **summary,
        }

    def records_for_date(self, *, date: str | None, limit: int) -> list[dict[str, Any]]:
        records = self._read_records()
        target_date = date or _latest_data_date(records)
        if target_date:
            records = [record for record in records if record.get("dataDate") == target_date]

        records = sorted(
            records,
            key=lambda item: str(item.get("dataTime") or ""),
            reverse=True,
        )
        normalized_limit = max(1, min(limit, 2000))
        return records[:normalized_limit]

    def _read_records(self) -> list[dict[str, Any]]:
        if not self.path.exists():
            return []

        records: list[dict[str, Any]] = []
        for line in self.path.read_text(encoding="utf-8").splitlines():
            if not line.strip():
                continue
            try:
                decoded = json.loads(line)
            except json.JSONDecodeError:
                continue
            if isinstance(decoded, dict):
                records.append(decoded)
        return records

    def _write_records(self, records: list[dict[str, Any]]) -> None:
        self.path.parent.mkdir(parents=True, exist_ok=True)
        ordered = sorted(records, key=lambda item: str(item.get("dataTime") or ""))
        body = "".join(
            json.dumps(record, ensure_ascii=False, sort_keys=True) + "\n"
            for record in ordered
        )
        temp_path = self.path.with_suffix(self.path.suffix + ".tmp")
        temp_path.write_text(body, encoding="utf-8")
        temp_path.replace(self.path)


def empty_intraday_history_response(
    *,
    fetched_at: str,
    error_message: str,
) -> dict[str, Any]:
    return {
        "items": [],
        "sourceStatus": "error",
        "sourceContract": "local_jsonl_intraday_nav_history",
        "sourceUrl": "local://00631l-intraday-nav-history",
        "fetchedAt": fetched_at,
        "sourceUpdatedAt": None,
        "dataTime": None,
        "isStale": True,
        "errorMessage": error_message,
    }


def _history_record(nav: dict[str, Any]) -> dict[str, Any]:
    record = deepcopy(nav)
    record["code"] = record.get("code") or record.get("symbol") or "00631L"
    record["symbol"] = record.get("symbol") or record.get("code") or "00631L"
    record["premiumDiscountPct"] = record.get("premiumDiscountPct") or record.get(
        "estimatedPremiumDiscountPct"
    )
    return record


def _response_payload(
    items: list[dict[str, Any]],
    *,
    limit: int,
    fetched_at: str,
    summary: bool,
) -> dict[str, Any]:
    latest = items[0] if items else {}
    data_time = latest.get("dataTime")
    return {
        "items": items,
        "limit": limit,
        "sourceStatus": "cached" if items else "unavailable",
        "sourceContract": (
            "local_jsonl_intraday_nav_history_summary"
            if summary
            else "local_jsonl_intraday_nav_history"
        ),
        "sourceUrl": "local://00631l-intraday-nav-history",
        "fetchedAt": fetched_at,
        "sourceUpdatedAt": data_time,
        "dataTime": data_time,
        "isStale": not items,
        "errorMessage": None if items else "No intraday NAV history records are available",
    }


def _summary(items: list[dict[str, Any]]) -> dict[str, Any]:
    values = [_float(item.get("premiumDiscountPct")) for item in items]
    values = [value for value in values if value is not None]
    ordered = sorted(items, key=lambda item: str(item.get("dataTime") or ""))
    latest = ordered[-1] if ordered else {}
    return {
        "sampleCount": len(values),
        "highestPremiumDiscountPct": max(values) if values else None,
        "lowestPremiumDiscountPct": min(values) if values else None,
        "averagePremiumDiscountPct": (
            sum(values) / len(values) if values else None
        ),
        "firstDataTime": ordered[0].get("dataTime") if ordered else None,
        "lastDataTime": ordered[-1].get("dataTime") if ordered else None,
        "latestMarketPrice": _float(latest.get("marketPrice")),
        "latestEstimatedNav": _float(latest.get("estimatedNav")),
        "date": latest.get("dataDate") or _latest_data_date(items),
    }


def _record_key(record: dict[str, Any]) -> tuple[str, str]:
    return (
        str(record.get("sourceContract") or ""),
        str(record.get("dataTime") or ""),
    )


def _latest_data_date(records: list[dict[str, Any]]) -> str | None:
    dates = sorted(
        {str(record.get("dataDate") or "") for record in records if record.get("dataDate")},
        reverse=True,
    )
    if dates:
        return dates[0]
    return datetime.now(TAIPEI_TZ).date().isoformat()


def _float(value: Any) -> float | None:
    if isinstance(value, (int, float)):
        return float(value)
    if value is None:
        return None
    try:
        return float(str(value).replace(",", "").strip())
    except ValueError:
        return None
