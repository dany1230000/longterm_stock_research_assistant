from __future__ import annotations

import csv
import json
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


HOLDINGS_EXPORT_COLUMNS = [
    "tradeDate",
    "fundNetAssetValue",
    "navPerUnit",
    "outstandingUnits",
    "stockAssetValue",
    "futuresAssetValue",
    "cash",
    "margin",
    "repo",
    "receivable",
    "payable",
    "txWeightPct",
    "tsmcWeightPct",
    "stockExposurePct",
    "futuresExposurePct",
    "cashAndMarginPct",
    "sourceStatus",
    "sourceUrl",
    "fetchedAt",
    "sourceHash",
]

INTRADAY_EXPORT_COLUMNS = [
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

PRICE_EXPORT_COLUMNS = [
    "date",
    "open",
    "high",
    "low",
    "close",
    "volume",
    "nav",
    "premiumDiscountPct",
    "sourceStatus",
    "sourceContract",
    "sourceUrl",
]


def export_00631l_history(
    *,
    holdings_history_path: str | Path,
    intraday_history_path: str | Path,
    price_history_path: str | Path | None = None,
    output_dir: str | Path,
) -> dict[str, Any]:
    output = Path(output_dir)
    output.mkdir(parents=True, exist_ok=True)

    holdings_records = _read_jsonl(Path(holdings_history_path))
    intraday_records = _read_jsonl(Path(intraday_history_path))
    price_records = _read_jsonl(Path(price_history_path)) if price_history_path else []

    holdings_rows = [_holdings_row(record) for record in holdings_records]
    intraday_rows = [_intraday_row(record) for record in intraday_records]
    price_rows = [_price_row(record) for record in price_records]

    holdings_output = output / "00631l_holdings_history_summary.csv"
    intraday_output = output / "00631l_intraday_nav_history.csv"
    price_output = output / "00631l_price_history.csv"
    metadata_output = output / "00631l_history_export_metadata.json"

    _write_csv(holdings_output, HOLDINGS_EXPORT_COLUMNS, holdings_rows)
    _write_csv(intraday_output, INTRADAY_EXPORT_COLUMNS, intraday_rows)
    _write_csv(price_output, PRICE_EXPORT_COLUMNS, price_rows)

    exported_at = _utc_now_iso()
    metadata = {
        "sourceStatus": "cached" if holdings_rows or intraday_rows or price_rows else "unavailable",
        "sourceContract": "00631l_history_csv_export",
        "exportedAt": exported_at,
        "holdingsInputPath": str(holdings_history_path),
        "intradayInputPath": str(intraday_history_path),
        "priceInputPath": str(price_history_path) if price_history_path else None,
        "outputDir": str(output),
        "holdingsOutputPath": str(holdings_output),
        "intradayOutputPath": str(intraday_output),
        "priceOutputPath": str(price_output),
        "metadataOutputPath": str(metadata_output),
        "holdingsRowCount": len(holdings_rows),
        "intradayRowCount": len(intraday_rows),
        "priceRowCount": len(price_rows),
        "totalRowCount": len(holdings_rows) + len(intraday_rows) + len(price_rows),
        "sourceHistoryRange": _source_history_range(
            holdings_rows=holdings_rows,
            intraday_rows=intraday_rows,
            price_rows=price_rows,
        ),
    }
    metadata_output.write_text(
        json.dumps(metadata, ensure_ascii=False, indent=2, sort_keys=True),
        encoding="utf-8",
    )
    return metadata


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


def _write_csv(
    path: Path,
    fieldnames: list[str],
    rows: list[dict[str, Any]],
) -> None:
    with path.open("w", encoding="utf-8-sig", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=fieldnames)
        writer.writeheader()
        for row in rows:
            writer.writerow(row)


def _holdings_row(record: dict[str, Any]) -> dict[str, Any]:
    asset_values = record.get("assetValues") if isinstance(record.get("assetValues"), dict) else {}
    cash_breakdown = (
        record.get("cashBreakdown")
        if isinstance(record.get("cashBreakdown"), dict)
        else _cash_breakdown(record.get("cashHoldings"))
    )
    fund_nav = _float(record.get("fundNetAssetValue"))
    cash_and_margin = (
        _float(cash_breakdown.get("cash"))
        + _float(cash_breakdown.get("margin"))
        + _float(cash_breakdown.get("repo"))
    )
    return {
        "tradeDate": record.get("tradeDate"),
        "fundNetAssetValue": record.get("fundNetAssetValue"),
        "navPerUnit": record.get("navPerUnit"),
        "outstandingUnits": record.get("outstandingUnits"),
        "stockAssetValue": asset_values.get("stock"),
        "futuresAssetValue": asset_values.get("futures"),
        "cash": cash_breakdown.get("cash"),
        "margin": cash_breakdown.get("margin"),
        "repo": cash_breakdown.get("repo"),
        "receivable": cash_breakdown.get("receivable"),
        "payable": cash_breakdown.get("payable"),
        "txWeightPct": _holding_weight(record.get("futuresHoldings"), "TX"),
        "tsmcWeightPct": _holding_weight(record.get("stockHoldings"), "2330"),
        "stockExposurePct": _pct(_float(asset_values.get("stock")), fund_nav),
        "futuresExposurePct": _pct(_float(asset_values.get("futures")), fund_nav),
        "cashAndMarginPct": _pct(cash_and_margin, fund_nav),
        "sourceStatus": record.get("sourceStatus"),
        "sourceUrl": record.get("sourceUrl"),
        "fetchedAt": record.get("fetchedAt"),
        "sourceHash": record.get("sourceHash"),
    }


def _intraday_row(record: dict[str, Any]) -> dict[str, Any]:
    return {
        "dataDate": record.get("dataDate"),
        "dataTime": record.get("dataTime"),
        "marketPrice": record.get("marketPrice"),
        "estimatedNav": record.get("estimatedNav"),
        "premiumDiscountPct": record.get("premiumDiscountPct")
        or record.get("estimatedPremiumDiscountPct"),
        "sourceContract": record.get("sourceContract"),
        "sourceStatus": record.get("sourceStatus"),
        "sourceUrl": record.get("sourceUrl"),
        "fetchedAt": record.get("fetchedAt"),
    }


def _price_row(record: dict[str, Any]) -> dict[str, Any]:
    return {
        "date": record.get("date"),
        "open": record.get("open"),
        "high": record.get("high"),
        "low": record.get("low"),
        "close": record.get("close"),
        "volume": record.get("volume"),
        "nav": record.get("nav"),
        "premiumDiscountPct": record.get("premiumDiscountPct"),
        "sourceStatus": record.get("sourceStatus"),
        "sourceContract": record.get("sourceContract"),
        "sourceUrl": record.get("sourceUrl"),
    }


def _cash_breakdown(lines_value: Any) -> dict[str, float]:
    lines = lines_value if isinstance(lines_value, list) else []
    amounts: list[float] = []
    for line in lines:
        if isinstance(line, dict):
            amounts.append(_float(line.get("amount")))

    margin = amounts[0] if len(amounts) > 0 else 0.0
    cash = amounts[1] if len(amounts) > 1 else 0.0
    repo = amounts[2] if len(amounts) > 2 else 0.0
    tail = amounts[3:] if len(amounts) > 3 else []
    return {
        "cash": cash,
        "margin": margin,
        "repo": repo,
        "receivable": sum(amount for amount in tail if amount > 0),
        "payable": sum(amount for amount in tail if amount < 0),
    }


def _holding_weight(lines_value: Any, code: str) -> float:
    lines = lines_value if isinstance(lines_value, list) else []
    return sum(
        _float(line.get("weightPct"))
        for line in lines
        if isinstance(line, dict) and str(line.get("code") or "") == code
    )


def _source_history_range(
    *,
    holdings_rows: list[dict[str, Any]],
    intraday_rows: list[dict[str, Any]],
    price_rows: list[dict[str, Any]],
) -> dict[str, Any]:
    holding_dates = sorted(
        str(row.get("tradeDate") or "") for row in holdings_rows if row.get("tradeDate")
    )
    intraday_times = sorted(
        str(row.get("dataTime") or "") for row in intraday_rows if row.get("dataTime")
    )
    price_dates = sorted(
        str(row.get("date") or "") for row in price_rows if row.get("date")
    )
    return {
        "holdingsStartDate": holding_dates[0] if holding_dates else None,
        "holdingsEndDate": holding_dates[-1] if holding_dates else None,
        "intradayStartDataTime": intraday_times[0] if intraday_times else None,
        "intradayEndDataTime": intraday_times[-1] if intraday_times else None,
        "priceStartDate": price_dates[0] if price_dates else None,
        "priceEndDate": price_dates[-1] if price_dates else None,
    }


def _pct(value: float, denominator: float) -> float:
    if denominator == 0:
        return 0.0
    return value / denominator * 100


def _utc_now_iso() -> str:
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat()


def _float(value: Any) -> float:
    if isinstance(value, (int, float)):
        return float(value)
    if value is None:
        return 0.0
    try:
        return float(str(value).replace(",", "").strip())
    except ValueError:
        return 0.0
