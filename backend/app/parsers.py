from __future__ import annotations

from datetime import datetime, timedelta, timezone
import hashlib
import html
import json
import re
from typing import Any


def utc_now_iso() -> str:
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat()


def source_hash(source: str) -> str:
    return hashlib.sha256(source.encode("utf-8", errors="replace")).hexdigest()


def normalize_text(source: str) -> str:
    text = re.sub(r"<(script|style)\b[^>]*>.*?</\1>", "\n", source, flags=re.IGNORECASE | re.DOTALL)
    text = re.sub(r"<!--.*?-->", "\n", text, flags=re.DOTALL)
    text = re.sub(r"<[^>]+>", "\n", text)
    text = html.unescape(text)
    text = text.replace("\r", "\n")
    text = re.sub(r"\n{2,}", "\n", text)
    return text


def parse_profile(
    source: str,
    *,
    source_url: str,
    fetched_at: str,
    source_status: str = "official",
    error_message: str | None = None,
) -> dict[str, Any]:
    text = normalize_text(source)

    return {
        "symbol": "00631L",
        "fundName": _text_after(text, "Fund Name")
        or _text_between(text, "#", "00631L")
        or "元大台灣50單日正向2倍證券投資信託基金",
        "shortName": _text_after(text, "Fund Simple Name") or "元大台灣50正2",
        "trackingIndex": _text_after(text, "Benchmark Index") or "臺灣50指數",
        "inceptionDate": _date_string(_text_after(text, "Inception Date")) or "2014-10-23",
        "listingDate": _date_string(_text_after(text, "Listing Date")) or "2014-10-31",
        "distributesIncome": _bool_dividend(_text_after(text, "Dividends")),
        "riskLevel": _text_after(text, "Risk Level") or "RR5",
        "managementFeePercent": _parse_percent(_text_after(text, "Management Fee")) or 1.0,
        "custodianFeePercent": _parse_percent(_text_after(text, "Custodian Fee")) or 0.04,
        "leverageObjective": "追蹤臺灣50指數單日正向2倍報酬",
        "exposurePolicy": "主要投資上市股票與證券相關商品，整體曝險約為基金淨資產價值180%-220%",
        "primaryTradingMethod": "以做多臺股期貨為主要交易，搭配現貨持股與現金/保證金管理",
        "sourceStatus": source_status,
        "sourceContract": None,
        "sourceUrl": source_url,
        "fetchedAt": fetched_at,
        "sourceUpdatedAt": None,
        "dataTime": None,
        "isStale": False,
        "errorMessage": error_message,
    }


def parse_holdings(
    source: str,
    *,
    source_url: str,
    fetched_at: str,
    source_status: str = "official",
    error_message: str | None = None,
) -> dict[str, Any]:
    text = normalize_text(source)
    fund_asset = _section(text, "Fund Asset", "Asset Holdings")
    cash_section = _section(text, "Cash", "Stock Holdings")
    if cash_section == text:
        cash_section = _section(text, "Cash", "股票")
    stock_section = _section(text, "Stock Holdings", "Futures Holdings")
    futures_section = _section(text, "Futures Holdings", "Yuanta")
    if stock_section == text:
        stock_section = _section(text, "股票", "期貨")
    if futures_section == text:
        futures_section = _section(text, "期貨", "Yuanta")

    trade_date = _date_string(_text_after(text, "Trade Date:"))
    fund_net_asset_value = _money_after(text, "Fund Net Asset Value (NTD)")
    nav_per_unit = _money_after(text, "Net Asset Value Per Unit (NTD)")
    outstanding_units = _integer_after(text, "Outstanding Units (shares)")
    has_required = (
        trade_date is not None
        and fund_net_asset_value is not None
        and nav_per_unit is not None
        and outstanding_units is not None
    )

    resolved_status = source_status if has_required else "error"
    resolved_error = error_message
    if not has_required and resolved_error is None:
        resolved_error = "Unable to parse required 00631L holdings fields"

    source_updated_at = f"{trade_date}T00:00:00+00:00" if trade_date else fetched_at
    return {
        "tradeDate": trade_date or "1970-01-01",
        "fundNetAssetValue": fund_net_asset_value or 0.0,
        "navPerUnit": nav_per_unit or 0.0,
        "outstandingUnits": outstanding_units or 0,
        "assetValues": {
            "stock": _money_after(fund_asset, "Stock") or 0.0,
            "etf": _money_after(fund_asset, "ETF") or 0.0,
            "bond": _money_after(fund_asset, "Bond") or 0.0,
            "futures": _money_after(fund_asset, "Futures") or 0.0,
        },
        "cashHoldings": _parse_cash_lines(cash_section),
        "stockHoldings": _parse_security_lines(stock_section, include_contract_month=False),
        "futuresHoldings": _parse_security_lines(futures_section, include_contract_month=True),
        "sourceStatus": resolved_status,
        "sourceContract": None,
        "sourceUrl": source_url,
        "fetchedAt": fetched_at,
        "sourceUpdatedAt": source_updated_at,
        "dataTime": source_updated_at,
        "sourceHash": source_hash(source),
        "isStale": _is_stale_trade_date(trade_date),
        "errorMessage": resolved_error,
    }


def parse_intraday_nav(
    source: str,
    *,
    source_url: str,
    fetched_at: str,
    source_status: str = "official",
    error_message: str | None = None,
) -> dict[str, Any]:
    decoded = json.loads(source)
    if not isinstance(decoded, dict):
        return unavailable_intraday_nav(
            source_url,
            fetched_at,
            "Invalid TWSE NAV JSON shape",
            source_contract="twse_a_k_json",
        )

    rows, issuer_meta = _twse_intraday_rows(decoded)
    if not isinstance(rows, list):
        return unavailable_intraday_nav(
            source_url,
            fetched_at,
            "TWSE NAV JSON has no msgArray/data list",
            source_contract="twse_a_k_json",
        )

    item = next((row for row in rows if isinstance(row, dict) and str(row.get("a")) == "00631L"), None)
    if item is None:
        return unavailable_intraday_nav(
            source_url,
            fetched_at,
            "00631L was not present in TWSE NAV JSON",
            source_contract="twse_a_k_json",
        )

    data_date = _compact_date(str(item.get("i") or ""))
    data_time = _combine_date_time(data_date, str(item.get("j") or ""))
    user_delay_ms = _parse_int(str(issuer_meta.get("userDelay") or decoded.get("userDelay") or "")) or 15000
    previous_nav_text = str(item.get("h") or "")
    previous_nav = _parse_float(previous_nav_text)
    premium = _parse_float(str(item.get("g") or ""))

    return {
        "code": str(item.get("a") or ""),
        "symbol": str(item.get("a") or ""),
        "name": str(item.get("b") or ""),
        "outstandingUnits": _parse_int(str(item.get("c") or "")),
        "outstandingUnitsDelta": _parse_int(str(item.get("d") or "")),
        "marketPrice": _parse_float(str(item.get("e") or "")),
        "estimatedNav": _parse_float(str(item.get("f") or "")),
        "premiumDiscountPct": premium,
        "estimatedPremiumDiscountPct": premium,
        "previousNav": previous_nav,
        "previousBusinessDayNav": previous_nav,
        "previousBusinessDayNavText": previous_nav_text,
        "dataDate": data_date,
        "dataTime": data_time,
        "targetType": str(item.get("k") or ""),
        "userDelayMs": user_delay_ms,
        "sourceStatus": source_status,
        "sourceContract": "twse_a_k_json",
        "sourceUrl": source_url,
        "fetchedAt": fetched_at,
        "sourceUpdatedAt": data_time,
        "isStale": data_time is None,
        "errorMessage": error_message,
    }


def parse_yuanta_intraday_nav(
    source: str,
    *,
    source_url: str,
    fetched_at: str,
    source_status: str = "official",
    error_message: str | None = None,
) -> dict[str, Any]:
    decoded = json.loads(source)
    if not isinstance(decoded, dict):
        return unavailable_intraday_nav(
            source_url,
            fetched_at,
            "Invalid Yuanta INAV JSON shape",
            source_contract="yuanta_inav",
        )

    if decoded.get("ResultCode") not in (0, "0", None):
        return unavailable_intraday_nav(
            source_url,
            fetched_at,
            f"Yuanta INAV returned ResultCode={decoded.get('ResultCode')}: {decoded.get('ResultMsg')}",
            source_contract="yuanta_inav",
            source_status="error",
        )

    rows = decoded.get("Data")
    if not isinstance(rows, list):
        return unavailable_intraday_nav(
            source_url,
            fetched_at,
            "Yuanta INAV JSON has no Data list",
            source_contract="yuanta_inav",
        )

    item = next((row for row in rows if isinstance(row, dict) and str(row.get("ETF_ID")) == "00631L"), None)
    if item is None:
        return unavailable_intraday_nav(
            source_url,
            fetched_at,
            "00631L was not present in Yuanta INAV JSON",
            source_contract="yuanta_inav",
        )

    market_price = _parse_float(str(item.get("NOW_PRICE") or ""))
    estimated_nav = _parse_float(str(item.get("NOW_NAV") or ""))
    previous_nav_text = str(item.get("NAV") or item.get("YEST_NAV") or "")
    previous_nav = _parse_float(previous_nav_text)
    premium = None
    if market_price is not None and estimated_nav not in (None, 0):
        premium = round((market_price - estimated_nav) / estimated_nav * 100, 2)
    update_time = _yuanta_update_time(str(item.get("UPDATE_T") or ""))
    data_date = update_time[:10] if update_time else _compact_date(str(item.get("NAV_DATE") or ""))

    return {
        "code": "00631L",
        "symbol": "00631L",
        "name": "元大台灣50正2",
        "outstandingUnits": _parse_int(str(item.get("iOS_UNIT") or "")),
        "outstandingUnitsDelta": None,
        "marketPrice": market_price,
        "estimatedNav": estimated_nav,
        "premiumDiscountPct": premium,
        "estimatedPremiumDiscountPct": premium,
        "previousNav": previous_nav,
        "previousBusinessDayNav": previous_nav,
        "previousBusinessDayNavText": previous_nav_text,
        "dataDate": data_date,
        "dataTime": update_time,
        "targetType": str(item.get("INAV_TYPE") or ""),
        "userDelayMs": 15000,
        "sourceStatus": source_status,
        "sourceContract": "yuanta_inav",
        "sourceUrl": source_url,
        "fetchedAt": fetched_at,
        "sourceUpdatedAt": update_time,
        "isStale": update_time is None,
        "errorMessage": error_message,
    }


def unavailable_intraday_nav(
    source_url: str,
    fetched_at: str,
    error_message: str,
    *,
    source_status: str = "unavailable",
    source_contract: str | None = None,
) -> dict[str, Any]:
    return {
        "code": "00631L",
        "symbol": "00631L",
        "name": "",
        "outstandingUnits": None,
        "outstandingUnitsDelta": None,
        "marketPrice": None,
        "estimatedNav": None,
        "premiumDiscountPct": None,
        "estimatedPremiumDiscountPct": None,
        "previousNav": None,
        "previousBusinessDayNav": None,
        "previousBusinessDayNavText": "",
        "dataDate": None,
        "dataTime": None,
        "targetType": "",
        "userDelayMs": 15000,
        "sourceStatus": source_status,
        "sourceContract": source_contract,
        "sourceUrl": source_url,
        "fetchedAt": fetched_at,
        "sourceUpdatedAt": None,
        "isStale": True,
        "errorMessage": error_message,
    }


def _twse_intraday_rows(decoded: dict[str, Any]) -> tuple[list[Any] | None, dict[str, Any]]:
    rows = decoded.get("msgArray")
    if isinstance(rows, list):
        return rows, decoded

    rows = decoded.get("data")
    if isinstance(rows, list):
        return rows, decoded

    groups = decoded.get("a1")
    if not isinstance(groups, list):
        return None, {}

    flattened: list[Any] = []
    issuer_meta: dict[str, Any] = {}
    for group in groups:
        if not isinstance(group, dict):
            continue
        group_rows = group.get("msgArray")
        if not isinstance(group_rows, list):
            continue
        if any(isinstance(row, dict) and str(row.get("a")) == "00631L" for row in group_rows):
            issuer_meta = group
        flattened.extend(group_rows)
    return flattened, issuer_meta


def _yuanta_update_time(value: str) -> str | None:
    match = re.match(r"^(\d{4})-(\d{2})-(\d{2})[T\s](\d{1,2}):(\d{2}):(\d{2})", value.strip())
    if not match:
        return None
    year, month, day, hour, minute, second = match.groups()
    return f"{year}-{month}-{day}T{int(hour):02d}:{minute}:{second}+08:00"


def empty_holdings_response(
    *,
    source_url: str,
    fetched_at: str,
    error_message: str,
) -> dict[str, Any]:
    return {
        "tradeDate": "1970-01-01",
        "fundNetAssetValue": 0.0,
        "navPerUnit": 0.0,
        "outstandingUnits": 0,
        "assetValues": {"stock": 0.0, "etf": 0.0, "bond": 0.0, "futures": 0.0},
        "cashHoldings": [],
        "stockHoldings": [],
        "futuresHoldings": [],
        "sourceStatus": "error",
        "sourceContract": None,
        "sourceUrl": source_url,
        "fetchedAt": fetched_at,
        "sourceUpdatedAt": None,
        "dataTime": None,
        "sourceHash": "",
        "isStale": True,
        "errorMessage": error_message,
    }


def mark_cached(payload: dict[str, Any], *, fetched_at: str, error_message: str | None = None) -> dict[str, Any]:
    clone = dict(payload)
    clone["sourceStatus"] = "cached"
    clone["fetchedAt"] = fetched_at
    if error_message:
        clone["errorMessage"] = error_message
    return clone


def _section(text: str, start: str, end: str) -> str:
    start_index = text.find(start)
    if start_index < 0:
        return text
    end_index = text.find(end, start_index + len(start))
    if end_index < 0:
        return text[start_index:]
    return text[start_index:end_index]


def _lines(text: str) -> list[str]:
    return [line.strip() for line in text.splitlines() if line.strip()]


def _text_after(text: str, label: str) -> str | None:
    lines = _lines(text)
    for index, line in enumerate(lines):
        if line == label or line == f"{label}:":
            if index + 1 < len(lines):
                return lines[index + 1].strip()
        if label in line:
            suffix = line.split(label, 1)[1].lstrip(" :：")
            if suffix:
                return suffix.strip()
            if index + 1 < len(lines):
                return lines[index + 1].strip()
        if line.startswith(f"{label} "):
            return line[len(label) :].strip()
        if line.startswith(f"{label}:"):
            return line[len(label) + 1 :].strip()
    return None


def _text_between(text: str, start: str, end: str) -> str | None:
    start_index = text.find(start)
    if start_index < 0:
        return None
    end_index = text.find(end, start_index + len(start))
    if end_index < 0:
        return None
    return text[start_index + len(start) : end_index].strip()


def _date_string(value: str | None) -> str | None:
    if not value:
        return None
    match = re.search(r"(\d{4})[/-](\d{1,2})[/-](\d{1,2})", value)
    if not match:
        return None
    year, month, day = (int(part) for part in match.groups())
    return f"{year:04d}-{month:02d}-{day:02d}"


def _compact_date(value: str) -> str | None:
    match = re.fullmatch(r"(\d{4})(\d{2})(\d{2})", value.strip())
    if not match:
        return None
    return f"{match.group(1)}-{match.group(2)}-{match.group(3)}"


def _combine_date_time(date_value: str | None, time_value: str) -> str | None:
    if not date_value:
        return None
    if not re.fullmatch(r"\d{1,2}:\d{2}:\d{2}", time_value):
        return None
    hour, minute, second = (int(part) for part in time_value.split(":"))
    return f"{date_value}T{hour:02d}:{minute:02d}:{second:02d}+08:00"


def _money_after(text: str, label: str) -> float | None:
    label_index = text.find(label)
    if label_index < 0:
        return None
    window = text[label_index : label_index + 240]
    match = re.search(r"NTD\s*\$?\s*(-?[\d,]+(?:\.\d+)?)", window)
    return _parse_float(match.group(1)) if match else None


def _integer_after(text: str, label: str) -> int | None:
    label_index = text.find(label)
    if label_index < 0:
        return None
    window = text[label_index + len(label) : label_index + len(label) + 160]
    match = re.search(r"(-?[\d,]+)", window)
    return _parse_int(match.group(1)) if match else None


def _parse_cash_lines(section: str) -> list[dict[str, Any]]:
    items = ["保證金", "現金", "附買回債券", "應收利息", "應收申購款", "應付申購預收款", "應付款項"]
    rows: list[dict[str, Any]] = []
    for item in items:
        amount = _money_after(section, item)
        if amount is not None:
            rows.append({"item": item, "amount": amount})
    return rows


def _parse_security_lines(section: str, *, include_contract_month: bool) -> list[dict[str, Any]]:
    rows: list[dict[str, Any]] = []
    for line in _lines(section):
        parts = re.split(r"\s+", line)
        if include_contract_month and len(parts) >= 5:
            code, name, quantity, weight, contract_month = (
                parts[0],
                " ".join(parts[1:-3]),
                parts[-3],
                parts[-2],
                parts[-1],
            )
            parsed_quantity = _parse_int(quantity)
            parsed_weight = _parse_float(weight)
            if parsed_quantity is not None and parsed_weight is not None:
                rows.append(
                    {
                        "code": code,
                        "name": name,
                        "quantity": parsed_quantity,
                        "weightPct": parsed_weight,
                        "contractMonth": contract_month,
                    }
                )
        elif not include_contract_month and len(parts) >= 4:
            code, name, quantity, weight = parts[0], " ".join(parts[1:-2]), parts[-2], parts[-1]
            parsed_quantity = _parse_int(quantity)
            parsed_weight = _parse_float(weight)
            if parsed_quantity is not None and parsed_weight is not None:
                rows.append(
                    {
                        "code": code,
                        "name": name,
                        "quantity": parsed_quantity,
                        "weightPct": parsed_weight,
                    }
                )
    return rows


def _parse_percent(value: str | None) -> float | None:
    if not value:
        return None
    return _parse_float(value.replace("%", ""))


def _parse_float(value: str | None) -> float | None:
    if value is None:
        return None
    try:
        return float(value.replace(",", "").strip())
    except ValueError:
        return None


def _parse_int(value: str | None) -> int | None:
    if value is None:
        return None
    try:
        normalized = value.replace(",", "").strip()
        if re.fullmatch(r"-?\d+\.0+", normalized):
            return int(float(normalized))
        return int(normalized)
    except ValueError:
        return None


def _bool_dividend(value: str | None) -> bool:
    if value is None:
        return False
    return value.strip().upper() in {"YES", "Y", "TRUE", "1", "是"}


def _is_stale_trade_date(trade_date: str | None) -> bool:
    if not trade_date:
        return True
    try:
        parsed = datetime.strptime(trade_date, "%Y-%m-%d").date()
    except ValueError:
        return True
    today = datetime.now(timezone.utc).date()
    days = 0
    cursor = parsed
    while cursor < today:
        cursor += timedelta(days=1)
        if cursor.weekday() < 5:
            days += 1
    return days > 1


# Yuanta's live pages are Nuxt SSR HTML. These final definitions keep the
# fixture-oriented parser behavior, then add the Chinese labels present in the
# rendered official pages.
def parse_profile(
    source: str,
    *,
    source_url: str,
    fetched_at: str,
    source_status: str = "official",
    error_message: str | None = None,
) -> dict[str, Any]:
    text = normalize_text(source)
    maintenance_message = _yuanta_maintenance_message(source)
    resolved_status = "unavailable" if maintenance_message else source_status
    resolved_error = error_message or maintenance_message
    title_fund_name = _regex_text(source, r"<title>\(00631L\)(.*?)\s+-")
    fund_name = (
        _clean_inline(title_fund_name)
        or _text_after(text, "Fund Name")
        or _line_containing(text, "台灣50單日正向2倍證券投資信託基金")
        or "元大ETF傘型證券投資信託基金之台灣50單日正向2倍證券投資信託基金"
    )
    short_name = (
        _text_after(text, "Fund Simple Name")
        or _text_after(text, "基金簡稱")
        or _line_containing(text, "元大台灣50正2")
        or "元大台灣50正2"
    )
    tracking_index = (
        _text_after(text, "Benchmark Index")
        or _text_after(text, "標的指數")
        or _text_after(text, "指數名稱")
        or "臺灣50指數"
    )
    return {
        "symbol": "00631L",
        "fundName": _clean_inline(fund_name),
        "shortName": _clean_inline(short_name),
        "trackingIndex": _clean_inline(tracking_index),
        "inceptionDate": _date_string(_text_after(text, "Inception Date") or _text_after(text, "成立日期"))
        or "2014-10-23",
        "listingDate": _date_string(_text_after(text, "Listing Date") or _text_after(text, "掛牌日期"))
        or "2014-10-31",
        "distributesIncome": _bool_dividend(_text_after(text, "Dividends") or _text_after(text, "收益分配")),
        "riskLevel": _text_after(text, "Risk Level") or _text_after(text, "風險報酬等級") or "RR5",
        "managementFeePercent": _parse_percent(_text_after(text, "Management Fee") or _text_after(text, "經理費"))
        or 1.0,
        "custodianFeePercent": _parse_percent(_text_after(text, "Custodian Fee") or _text_after(text, "保管費"))
        or 0.04,
        "leverageObjective": "追蹤臺灣50指數單日正向2倍報酬之績效表現。",
        "exposurePolicy": "主要投資國內上市股票及證券相關商品，整體曝險約為基金淨資產價值180%-220%。",
        "primaryTradingMethod": "以做多期貨為主要交易，搭配上市股票與現金/保證金部位。",
        "sourceStatus": resolved_status,
        "sourceContract": "yuanta_maintenance" if maintenance_message else None,
        "sourceUrl": source_url,
        "fetchedAt": fetched_at,
        "sourceUpdatedAt": None,
        "dataTime": None,
        "isStale": bool(maintenance_message),
        "errorMessage": resolved_error,
    }


def parse_holdings(
    source: str,
    *,
    source_url: str,
    fetched_at: str,
    source_status: str = "official",
    error_message: str | None = None,
) -> dict[str, Any]:
    text = normalize_text(source)
    maintenance_message = _yuanta_maintenance_message(source)
    if maintenance_message:
        payload = empty_holdings_response(
            source_url=source_url,
            fetched_at=fetched_at,
            error_message=error_message or maintenance_message,
        )
        payload["sourceStatus"] = "unavailable"
        payload["sourceContract"] = "yuanta_maintenance"
        payload["sourceHash"] = source_hash(source)
        return payload

    live_asset_section = _section_between_any(text, ["資產金額"], ["非商品資產"])
    live_cash_section = _section_between_any(text, ["非商品資產"], ["基金權重-股票", "基金權重-ETF", "基金權重-期貨"])
    live_stock_section = _section_between_any(text, ["基金權重-股票"], ["基金權重-ETF", "基金權重-債券", "基金權重-期貨"])
    live_futures_section = _section_between_any(text, ["基金權重-期貨"], ["基金警語", "集團成員"])

    fund_asset = live_asset_section if live_asset_section != text else _section(text, "Fund Asset", "Asset Holdings")
    cash_section = live_cash_section if live_cash_section != text else _section(text, "Cash", "Stock Holdings")
    stock_section = live_stock_section if live_stock_section != text else _section(text, "Stock Holdings", "Futures Holdings")
    futures_section = live_futures_section if live_futures_section != text else _section(text, "Futures Holdings", "Yuanta")

    trade_date = _date_string(_text_after(text, "Trade Date:") or _text_after(text, "交易日期"))
    fund_net_asset_value = _money_after_any(text, ["Fund Net Asset Value (NTD)", "基金資產總淨值(新台幣)", "基金資產總淨值"])
    nav_per_unit = _money_after_any(text, ["Net Asset Value Per Unit (NTD)", "基金每單位淨值(新台幣)", "基金每單位淨值"])
    outstanding_units = _integer_after_any(text, ["Outstanding Units (shares)", "基金在外流通單位數(單位)", "基金在外流通單位數"])
    has_required = (
        trade_date is not None
        and fund_net_asset_value is not None
        and nav_per_unit is not None
        and outstanding_units is not None
    )

    resolved_status = source_status if has_required else "error"
    resolved_error = error_message
    if not has_required and resolved_error is None:
        resolved_error = "Unable to parse required 00631L holdings fields"

    source_updated_at = f"{trade_date}T00:00:00+00:00" if trade_date else fetched_at
    return {
        "tradeDate": trade_date or "1970-01-01",
        "fundNetAssetValue": fund_net_asset_value or 0.0,
        "navPerUnit": nav_per_unit or 0.0,
        "outstandingUnits": outstanding_units or 0,
        "assetValues": {
            "stock": _money_after_any(fund_asset, ["Stock", "股票"]) or 0.0,
            "etf": _money_after_any(fund_asset, ["ETF"]) or 0.0,
            "bond": _money_after_any(fund_asset, ["Bond", "債券"]) or 0.0,
            "futures": _money_after_any(fund_asset, ["Futures", "期貨"]) or 0.0,
        },
        "cashHoldings": _parse_live_cash_lines(cash_section),
        "stockHoldings": _parse_live_security_lines(stock_section, include_contract_month=False),
        "futuresHoldings": _parse_live_security_lines(futures_section, include_contract_month=True),
        "sourceStatus": resolved_status,
        "sourceContract": None,
        "sourceUrl": source_url,
        "fetchedAt": fetched_at,
        "sourceUpdatedAt": source_updated_at,
        "dataTime": source_updated_at,
        "sourceHash": source_hash(source),
        "isStale": _is_stale_trade_date(trade_date),
        "errorMessage": resolved_error,
    }


def _regex_text(source: str, pattern: str) -> str | None:
    match = re.search(pattern, source, flags=re.IGNORECASE | re.DOTALL)
    return html.unescape(match.group(1)).strip() if match else None


def _clean_inline(value: str | None) -> str:
    if value is None:
        return ""
    return re.sub(r"\s+", " ", value).strip()


def _line_containing(text: str, needle: str) -> str | None:
    for line in _lines(text):
        if needle in line:
            return line
    return None


def _yuanta_maintenance_message(source: str) -> str | None:
    text = normalize_text(source)
    raw_has_route = 'layout:"maintenance"' in source or 'routePath:"\\u002Fmaintenance"' in source
    text_has_notice = "停機公告" in text or ("主機系統維護" in text and "暫停服務" in text)
    if not raw_has_route and not text_has_notice:
        return None

    notice = (
        _line_containing(text, "公告：")
        or _line_containing(text, "主機系統維護")
        or _line_containing(text, "暫停服務")
        or "official maintenance page returned"
    )
    return f"Yuanta official page is in maintenance mode: {_clean_inline(notice)}"


def _section_between_any(text: str, starts: list[str], ends: list[str]) -> str:
    start_matches = [text.find(start) for start in starts if text.find(start) >= 0]
    if not start_matches:
        return text
    start_index = min(start_matches)
    end_matches = [
        text.find(end, start_index + 1)
        for end in ends
        if text.find(end, start_index + 1) >= 0
    ]
    if not end_matches:
        return text[start_index:]
    return text[start_index : min(end_matches)]


def _money_after_any(text: str, labels: list[str]) -> float | None:
    for label in labels:
        value = _money_after(text, label)
        if value is not None:
            return value
    return None


def _integer_after_any(text: str, labels: list[str]) -> int | None:
    for label in labels:
        value = _integer_after(text, label)
        if value is not None:
            return value
    return None


def _parse_live_cash_lines(section: str) -> list[dict[str, Any]]:
    rows: list[dict[str, Any]] = []
    seen: set[str] = set()
    for item in [
        "保證金",
        "現金",
        "附買回債券",
        "應收利息",
        "應付申購預收款",
        "應收股利",
        "應收申購款",
        "應付款項",
    ]:
        amount = _money_after(section, item)
        if amount is not None and item not in seen:
            seen.add(item)
            rows.append({"item": item, "amount": amount})
    if rows:
        return rows
    return _parse_cash_lines(section)


def _parse_live_security_lines(section: str, *, include_contract_month: bool) -> list[dict[str, Any]]:
    rows = _parse_security_lines(section, include_contract_month=include_contract_month)
    if rows:
        return rows

    table_labels = {
        "交易日期:",
        "商品代碼",
        "商品名稱",
        "商品數量",
        "商品權重",
        "商品年月",
    }
    lines = [line for line in _lines(section) if line not in table_labels]
    parsed: list[dict[str, Any]] = []
    for index, line in enumerate(lines):
        if include_contract_month:
            if not re.fullmatch(r"[A-Z]{1,4}[A-Z0-9]*", line):
                continue
            if index + 4 >= len(lines):
                continue
            quantity = _parse_int(lines[index + 2])
            weight = _parse_float(lines[index + 3])
            contract_month = lines[index + 4].strip()
            if quantity is not None and weight is not None and re.fullmatch(r"\d{6}", contract_month):
                parsed.append(
                    {
                        "code": line,
                        "name": _clean_inline(lines[index + 1]),
                        "quantity": quantity,
                        "weightPct": weight,
                        "contractMonth": contract_month,
                    }
                )
        else:
            if not re.fullmatch(r"\d{4}[A-Z]?", line):
                continue
            if index + 3 >= len(lines):
                continue
            quantity = _parse_int(lines[index + 2])
            weight = _parse_float(lines[index + 3])
            if quantity is not None and weight is not None:
                parsed.append(
                    {
                        "code": line,
                        "name": _clean_inline(lines[index + 1]),
                        "quantity": quantity,
                        "weightPct": weight,
                    }
                )
    return parsed
