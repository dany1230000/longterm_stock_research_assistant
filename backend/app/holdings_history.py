from __future__ import annotations

from copy import deepcopy
import json
from pathlib import Path
from typing import Any


class HoldingsHistoryStore:
    def __init__(self, path: str | Path) -> None:
        self.path = Path(path)

    def save_official_snapshot(self, snapshot: dict[str, Any]) -> bool:
        if snapshot.get("sourceStatus") != "official":
            return False

        trade_date = str(snapshot.get("tradeDate") or "")
        if not trade_date or trade_date == "1970-01-01":
            return False

        record = _history_record(snapshot)
        records = self._read_records()
        for index, existing in enumerate(records):
            if existing.get("tradeDate") != trade_date:
                continue
            if existing.get("sourceHash") == record.get("sourceHash"):
                return False
            records[index] = record
            self._write_records(records)
            return True

        records.append(record)
        self._write_records(records)
        return True

    def history_response(self, *, limit: int, fetched_at: str) -> dict[str, Any]:
        items = self.recent(limit)
        return _response_payload(items, limit=limit, fetched_at=fetched_at, summary=False)

    def summary_response(self, *, limit: int, fetched_at: str) -> dict[str, Any]:
        items = [_summary_item(record) for record in self.recent(limit)]
        return _response_payload(items, limit=limit, fetched_at=fetched_at, summary=True)

    def recent(self, limit: int) -> list[dict[str, Any]]:
        normalized_limit = max(1, min(limit, 365))
        records = sorted(
            self._read_records(),
            key=lambda item: str(item.get("tradeDate") or ""),
            reverse=True,
        )
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
        ordered = sorted(
            records,
            key=lambda item: str(item.get("tradeDate") or ""),
        )
        body = "".join(
            json.dumps(record, ensure_ascii=False, sort_keys=True) + "\n"
            for record in ordered
        )
        temp_path = self.path.with_suffix(self.path.suffix + ".tmp")
        temp_path.write_text(body, encoding="utf-8")
        temp_path.replace(self.path)


def empty_history_response(
    *,
    limit: int,
    fetched_at: str,
    error_message: str,
) -> dict[str, Any]:
    return {
        "items": [],
        "limit": limit,
        "sourceStatus": "error",
        "sourceContract": "local_jsonl_history",
        "sourceUrl": "local://00631l-holdings-history",
        "fetchedAt": fetched_at,
        "sourceUpdatedAt": None,
        "dataTime": None,
        "isStale": True,
        "errorMessage": error_message,
    }


def _response_payload(
    items: list[dict[str, Any]],
    *,
    limit: int,
    fetched_at: str,
    summary: bool,
) -> dict[str, Any]:
    latest = items[0] if items else {}
    source_updated_at = latest.get("sourceUpdatedAt") or latest.get("dataTime")
    return {
        "items": items,
        "limit": limit,
        "sourceStatus": "cached" if items else "unavailable",
        "sourceContract": "local_jsonl_history_summary" if summary else "local_jsonl_history",
        "sourceUrl": "local://00631l-holdings-history",
        "fetchedAt": fetched_at,
        "sourceUpdatedAt": source_updated_at,
        "dataTime": source_updated_at,
        "isStale": not items,
        "errorMessage": None if items else "No holdings history snapshots are available",
    }


def _history_record(snapshot: dict[str, Any]) -> dict[str, Any]:
    record = deepcopy(snapshot)
    cash_breakdown = _cash_breakdown(record.get("cashHoldings"))
    record["cashBreakdown"] = cash_breakdown
    record["cash"] = cash_breakdown["cash"]
    record["margin"] = cash_breakdown["margin"]
    record["repo"] = cash_breakdown["repo"]
    record["receivable"] = cash_breakdown["receivable"]
    record["payable"] = cash_breakdown["payable"]
    return record


def _cash_breakdown(lines_value: Any) -> dict[str, float]:
    lines = lines_value if isinstance(lines_value, list) else []
    amounts: list[float] = []
    for line in lines:
        if not isinstance(line, dict):
            continue
        amounts.append(_float(line.get("amount")))

    margin = amounts[0] if len(amounts) > 0 else 0.0
    cash = amounts[1] if len(amounts) > 1 else 0.0
    repo = amounts[2] if len(amounts) > 2 else 0.0
    tail = amounts[3:] if len(amounts) > 3 else []
    receivable = sum(amount for amount in tail if amount > 0)
    payable = sum(amount for amount in tail if amount < 0)
    return {
        "cash": cash,
        "margin": margin,
        "repo": repo,
        "receivable": receivable,
        "payable": payable,
    }


def _summary_item(record: dict[str, Any]) -> dict[str, Any]:
    fund_nav = _float(record.get("fundNetAssetValue"))
    asset_values = record.get("assetValues") if isinstance(record.get("assetValues"), dict) else {}
    cash_breakdown = (
        record.get("cashBreakdown")
        if isinstance(record.get("cashBreakdown"), dict)
        else _cash_breakdown(record.get("cashHoldings"))
    )
    cash_and_margin = (
        _float(cash_breakdown.get("cash"))
        + _float(cash_breakdown.get("margin"))
        + _float(cash_breakdown.get("repo"))
    )

    return {
        "tradeDate": record.get("tradeDate"),
        "txWeightPct": _holding_weight(record.get("futuresHoldings"), "TX"),
        "tsmcWeightPct": _holding_weight(record.get("stockHoldings"), "2330"),
        "stockExposurePct": _pct(_float(asset_values.get("stock")), fund_nav),
        "futuresExposurePct": _pct(_float(asset_values.get("futures")), fund_nav),
        "cashAndMarginPct": _pct(cash_and_margin, fund_nav),
        "navPerUnit": _float(record.get("navPerUnit")),
        "fundNetAssetValue": fund_nav,
        "outstandingUnits": _int(record.get("outstandingUnits")),
        "sourceStatus": record.get("sourceStatus"),
        "sourceUrl": record.get("sourceUrl"),
        "sourceHash": record.get("sourceHash"),
        "fetchedAt": record.get("fetchedAt"),
        "sourceUpdatedAt": record.get("sourceUpdatedAt"),
        "isStale": record.get("isStale"),
    }


def _holding_weight(lines_value: Any, code: str) -> float:
    lines = lines_value if isinstance(lines_value, list) else []
    total = 0.0
    for line in lines:
        if isinstance(line, dict) and str(line.get("code") or "") == code:
            total += _float(line.get("weightPct"))
    return total


def _pct(value: float, denominator: float) -> float:
    if denominator == 0:
        return 0.0
    return value / denominator * 100


def _float(value: Any) -> float:
    if isinstance(value, (int, float)):
        return float(value)
    if value is None:
        return 0.0
    try:
        return float(str(value).replace(",", "").strip())
    except ValueError:
        return 0.0


def _int(value: Any) -> int:
    if isinstance(value, int):
        return value
    if isinstance(value, float):
        return int(value)
    if value is None:
        return 0
    try:
        return int(str(value).replace(",", "").strip())
    except ValueError:
        return 0
