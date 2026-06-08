from __future__ import annotations

import time
from typing import Any, Callable

from .parsers import utc_now_iso


SleepFn = Callable[[float], None]


def collect_00631l_snapshot(
    service: Any,
    *,
    include_profile: bool = True,
    include_holdings: bool = True,
    include_intraday: bool = True,
    intraday_samples: int = 1,
    interval_seconds: float = 15.0,
    sleep_fn: SleepFn = time.sleep,
) -> dict[str, Any]:
    started_at = utc_now_iso()
    warnings: list[str] = []
    failures: list[str] = []
    result: dict[str, Any] = {
        "collector": "00631l_snapshot_collector",
        "startedAt": started_at,
        "finishedAt": None,
        "overallStatus": None,
        "warnings": warnings,
        "failures": failures,
        "profile": None,
        "holdings": None,
        "holdingsHistorySummary": None,
        "intradaySamples": [],
        "intradayHistorySummary": None,
    }

    if include_profile:
        profile = service.profile()
        result["profile"] = _profile_summary(profile)
        _assess_source(
            profile,
            label="profile",
            warnings=warnings,
            failures=failures,
            required=False,
        )

    if include_holdings:
        holdings = service.holdings()
        result["holdings"] = _holdings_summary(holdings)
        _assess_source(
            holdings,
            label="holdings",
            warnings=warnings,
            failures=failures,
            required=True,
        )
        result["holdingsHistorySummary"] = _history_summary(
            service.holdings_history_summary(limit=1),
            item_key="tradeDate",
        )

    if include_intraday:
        sample_count = max(0, intraday_samples)
        for index in range(sample_count):
            nav = service.intraday_nav()
            result["intradaySamples"].append(_intraday_summary(nav, sample_index=index + 1))
            _assess_source(
                nav,
                label=f"intraday sample {index + 1}",
                warnings=warnings,
                failures=failures,
                required=False,
            )
            if index < sample_count - 1 and interval_seconds > 0:
                sleep_fn(interval_seconds)

        latest_date = _latest_intraday_date(result["intradaySamples"])
        result["intradayHistorySummary"] = _intraday_history_summary(
            service.intraday_nav_history_summary(date=latest_date)
        )

    result["finishedAt"] = utc_now_iso()
    result["overallStatus"] = "FAIL" if failures else "WARN" if warnings else "PASS"
    return result


def _assess_source(
    payload: dict[str, Any],
    *,
    label: str,
    warnings: list[str],
    failures: list[str],
    required: bool,
) -> None:
    source_status = payload.get("sourceStatus")
    if source_status in {"official", "cached"}:
        return

    message = f"{label} sourceStatus={source_status}"
    error_message = payload.get("errorMessage")
    if error_message:
        message = f"{message}: {error_message}"

    if required:
        failures.append(message)
    else:
        warnings.append(message)


def _profile_summary(payload: dict[str, Any]) -> dict[str, Any]:
    return {
        "sourceStatus": payload.get("sourceStatus"),
        "sourceUrl": payload.get("sourceUrl"),
        "fetchedAt": payload.get("fetchedAt"),
        "sourceUpdatedAt": payload.get("sourceUpdatedAt"),
        "isStale": payload.get("isStale"),
        "fundName": payload.get("fundName"),
        "errorMessage": payload.get("errorMessage"),
    }


def _holdings_summary(payload: dict[str, Any]) -> dict[str, Any]:
    return {
        "sourceStatus": payload.get("sourceStatus"),
        "sourceUrl": payload.get("sourceUrl"),
        "fetchedAt": payload.get("fetchedAt"),
        "sourceUpdatedAt": payload.get("sourceUpdatedAt"),
        "dataTime": payload.get("dataTime"),
        "isStale": payload.get("isStale"),
        "tradeDate": payload.get("tradeDate"),
        "sourceHash": payload.get("sourceHash"),
        "fundNetAssetValue": payload.get("fundNetAssetValue"),
        "navPerUnit": payload.get("navPerUnit"),
        "outstandingUnits": payload.get("outstandingUnits"),
        "stockLineCount": len(payload.get("stockHoldings") or []),
        "futuresLineCount": len(payload.get("futuresHoldings") or []),
        "cashLineCount": len(payload.get("cashHoldings") or []),
        "errorMessage": payload.get("errorMessage"),
    }


def _intraday_summary(payload: dict[str, Any], *, sample_index: int) -> dict[str, Any]:
    return {
        "sampleIndex": sample_index,
        "sourceStatus": payload.get("sourceStatus"),
        "sourceContract": payload.get("sourceContract"),
        "sourceUrl": payload.get("sourceUrl"),
        "fetchedAt": payload.get("fetchedAt"),
        "sourceUpdatedAt": payload.get("sourceUpdatedAt"),
        "dataDate": payload.get("dataDate"),
        "dataTime": payload.get("dataTime"),
        "isStale": payload.get("isStale"),
        "marketPrice": payload.get("marketPrice"),
        "estimatedNav": payload.get("estimatedNav"),
        "premiumDiscountPct": payload.get("premiumDiscountPct"),
        "errorMessage": payload.get("errorMessage"),
    }


def _history_summary(payload: dict[str, Any], *, item_key: str) -> dict[str, Any]:
    items = payload.get("items") if isinstance(payload.get("items"), list) else []
    latest = items[0] if items else {}
    return {
        "sourceStatus": payload.get("sourceStatus"),
        "sourceContract": payload.get("sourceContract"),
        "sourceUrl": payload.get("sourceUrl"),
        "fetchedAt": payload.get("fetchedAt"),
        "sourceUpdatedAt": payload.get("sourceUpdatedAt"),
        "dataTime": payload.get("dataTime"),
        "isStale": payload.get("isStale"),
        "itemCount": len(items),
        "latestKey": latest.get(item_key),
        "errorMessage": payload.get("errorMessage"),
    }


def _intraday_history_summary(payload: dict[str, Any]) -> dict[str, Any]:
    return {
        **_history_summary(payload, item_key="dataTime"),
        "sampleCount": payload.get("sampleCount"),
        "highestPremiumDiscountPct": payload.get("highestPremiumDiscountPct"),
        "lowestPremiumDiscountPct": payload.get("lowestPremiumDiscountPct"),
        "averagePremiumDiscountPct": payload.get("averagePremiumDiscountPct"),
        "firstDataTime": payload.get("firstDataTime"),
        "lastDataTime": payload.get("lastDataTime"),
        "date": payload.get("date"),
    }


def _latest_intraday_date(samples: list[dict[str, Any]]) -> str | None:
    dates = [
        str(sample.get("dataDate"))
        for sample in samples
        if sample.get("dataDate")
    ]
    if not dates:
        return None
    return sorted(dates)[-1]
