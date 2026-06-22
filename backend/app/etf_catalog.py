from __future__ import annotations

import json
from pathlib import Path
from typing import Any

from .parsers import _combine_date_time, _compact_date, _parse_float, _parse_int, _twse_intraday_rows


def parse_twse_etf_catalog(source: str, *, source_url: str, fetched_at: str) -> dict[str, Any]:
    decoded = json.loads(source)
    if not isinstance(decoded, dict):
        return _catalog_error(source_url, fetched_at, "Invalid TWSE ETF catalog JSON shape")
    rows, issuer_meta = _twse_intraday_rows(decoded)
    if not isinstance(rows, list):
        return _catalog_error(source_url, fetched_at, "TWSE ETF catalog JSON has no rows")

    items = []
    for row in rows:
        if not isinstance(row, dict):
            continue
        code = str(row.get("a") or "").strip()
        if not code:
            continue
        data_date = _compact_date(str(row.get("i") or ""))
        data_time = _combine_date_time(data_date, str(row.get("j") or ""))
        premium = _parse_float(str(row.get("g") or ""))
        items.append(
            {
                "code": code,
                "name": str(row.get("b") or "").strip(),
                "outstandingUnits": _parse_int(str(row.get("c") or "")),
                "outstandingUnitsDelta": _parse_int(str(row.get("d") or "")),
                "marketPrice": _parse_float(str(row.get("e") or "")),
                "estimatedNav": _parse_float(str(row.get("f") or "")),
                "premiumDiscountPct": premium,
                "previousNav": _parse_float(str(row.get("h") or "")),
                "dataDate": data_date,
                "dataTime": data_time,
                "targetType": str(row.get("k") or "").strip(),
            }
        )

    items.sort(key=lambda item: str(item["code"]))
    user_delay = _parse_int(str(issuer_meta.get("userDelay") or decoded.get("userDelay") or "")) or 15000
    latest_time = max((item["dataTime"] for item in items if item.get("dataTime")), default=None)
    return {
        "sourceStatus": "official" if items else "unavailable",
        "sourceContract": "twse_all_etf_catalog",
        "sourceUrl": source_url,
        "fetchedAt": fetched_at,
        "sourceUpdatedAt": latest_time,
        "dataTime": latest_time,
        "isStale": latest_time is None,
        "userDelayMs": user_delay,
        "rowCount": len(items),
        "items": items,
        "errorMessage": None if items else "TWSE ETF catalog returned no ETF rows",
    }


def save_etf_catalog(payload: dict[str, Any], path: str | Path) -> None:
    target = Path(path)
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(json.dumps(payload, ensure_ascii=False, indent=2), encoding="utf-8")


def load_etf_catalog(
    path: str | Path,
    *,
    fetched_at: str,
    seed_path: str | Path | None = None,
) -> dict[str, Any]:
    target = Path(path)
    if not target.exists():
        seed_payload = _load_seed_catalog(seed_path, fetched_at=fetched_at)
        if seed_payload is not None:
            return seed_payload
        return _catalog_error(
            f"local://{target}",
            fetched_at,
            "ETF catalog has not been imported yet.",
            source_status="unavailable",
        )
    try:
        decoded = json.loads(target.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return _catalog_error(
            f"local://{target}",
            fetched_at,
            f"ETF catalog read failed: {error}",
            source_status="error",
        )
    if not isinstance(decoded, dict):
        return _catalog_error(
            f"local://{target}",
            fetched_at,
            "ETF catalog file is not a JSON object.",
            source_status="error",
        )
    if not decoded.get("items"):
        seed_payload = _load_seed_catalog(seed_path, fetched_at=fetched_at)
        if seed_payload is not None:
            return seed_payload
    payload = dict(decoded)
    payload["sourceStatus"] = "cached" if payload.get("items") else "unavailable"
    payload["fetchedAt"] = fetched_at
    payload.setdefault("sourceContract", "twse_all_etf_catalog")
    payload.setdefault("sourceUrl", f"local://{target}")
    payload.setdefault("rowCount", len(payload.get("items") or []))
    payload.setdefault("errorMessage", None)
    return payload


def etf_catalog_status(
    path: str | Path,
    *,
    fetched_at: str,
    seed_path: str | Path | None = None,
) -> dict[str, Any]:
    payload = load_etf_catalog(path, fetched_at=fetched_at, seed_path=seed_path)
    return {
        "sourceStatus": payload.get("sourceStatus"),
        "sourceContract": payload.get("sourceContract"),
        "sourceUrl": payload.get("sourceUrl"),
        "fetchedAt": fetched_at,
        "sourceUpdatedAt": payload.get("sourceUpdatedAt"),
        "dataTime": payload.get("dataTime"),
        "isStale": payload.get("isStale", True),
        "rowCount": payload.get("rowCount", 0),
        "errorMessage": payload.get("errorMessage"),
    }


def _load_seed_catalog(
    seed_path: str | Path | None,
    *,
    fetched_at: str,
) -> dict[str, Any] | None:
    if not seed_path:
        return None
    target = Path(seed_path)
    if not target.exists():
        return None
    try:
        decoded = json.loads(target.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError):
        return None
    if not isinstance(decoded, dict) or not decoded.get("items"):
        return None
    payload = dict(decoded)
    payload["sourceStatus"] = "static_official"
    payload["sourceContract"] = payload.get("sourceContract") or "twse_all_etf_catalog"
    payload["sourceUrl"] = f"seed://twse-etf-catalog"
    payload["fetchedAt"] = fetched_at
    payload["rowCount"] = int(payload.get("rowCount") or len(payload.get("items") or []))
    payload["errorMessage"] = None
    return payload


def _catalog_error(
    source_url: str,
    fetched_at: str,
    message: str,
    *,
    source_status: str = "error",
) -> dict[str, Any]:
    return {
        "sourceStatus": source_status,
        "sourceContract": "twse_all_etf_catalog",
        "sourceUrl": source_url,
        "fetchedAt": fetched_at,
        "sourceUpdatedAt": None,
        "dataTime": None,
        "isStale": True,
        "userDelayMs": 15000,
        "rowCount": 0,
        "items": [],
        "errorMessage": message,
    }
