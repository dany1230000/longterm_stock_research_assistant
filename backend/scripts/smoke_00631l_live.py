from __future__ import annotations

import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
from typing import Any
from datetime import datetime, time, timedelta, timezone


ROOT = Path(__file__).resolve().parents[2]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from backend.app.config import settings  # noqa: E402
from backend.app.parsers import (  # noqa: E402
    parse_holdings,
    parse_intraday_nav,
    parse_profile,
    parse_yuanta_intraday_nav,
    unavailable_intraday_nav,
    utc_now_iso,
)


HTTP_MARKER = "\n__00631L_SMOKE_HTTP_STATUS__:"
TAIPEI_TZ = timezone(timedelta(hours=8))


def main() -> int:
    results = {
        "yuanta_basic": _smoke_profile(settings.yuanta_profile_url),
        "yuanta_ratio": _smoke_holdings(settings.yuanta_holdings_url),
        "intraday_nav": _smoke_intraday_nav(),
    }
    for name, payload in results.items():
        _print_result(name, payload)

    overall = _assess_overall(results)
    _print_result("overall", overall)
    return 1 if overall["overallStatus"] == "FAIL" else 0


def _smoke_profile(url: str) -> dict[str, Any]:
    fetched_at = utc_now_iso()
    result = _fetch_url(url)
    if result["errorMessage"]:
        return _base_summary(url, result, source_status="error")

    try:
        payload = parse_profile(result["body"], source_url=url, fetched_at=fetched_at)
        return {
            **_base_summary(url, result, source_status=payload.get("sourceStatus")),
            "parseSuccess": payload.get("sourceStatus") not in {"error", "unavailable"},
            "fundName": payload.get("fundName"),
            "trackingIndex": payload.get("trackingIndex"),
            "sourceUpdatedAt": payload.get("sourceUpdatedAt"),
            "dataTime": payload.get("dataTime"),
            "isStale": payload.get("isStale"),
            "errorMessage": payload.get("errorMessage"),
        }
    except Exception as error:  # noqa: BLE001 - smoke output should capture parser failures.
        return {
            **_base_summary(url, result, source_status="error"),
            "parseSuccess": False,
            "errorMessage": f"profile parse failed: {error}",
        }


def _smoke_holdings(url: str) -> dict[str, Any]:
    fetched_at = utc_now_iso()
    result = _fetch_url(url)
    if result["errorMessage"]:
        return _base_summary(url, result, source_status="error")

    try:
        payload = parse_holdings(result["body"], source_url=url, fetched_at=fetched_at)
        return {
            **_base_summary(url, result, source_status=payload.get("sourceStatus")),
            "parseSuccess": payload.get("sourceStatus") != "error",
            "parsedTradeDate": payload.get("tradeDate"),
            "fundNetAssetValue": payload.get("fundNetAssetValue"),
            "navPerUnit": payload.get("navPerUnit"),
            "outstandingUnits": payload.get("outstandingUnits"),
            "stockLineCount": len(payload.get("stockHoldings") or []),
            "futuresLineCount": len(payload.get("futuresHoldings") or []),
            "cashLineCount": len(payload.get("cashHoldings") or []),
            "sourceUpdatedAt": payload.get("sourceUpdatedAt"),
            "dataTime": payload.get("dataTime"),
            "isStale": payload.get("isStale"),
            "errorMessage": payload.get("errorMessage"),
        }
    except Exception as error:  # noqa: BLE001 - smoke output should capture parser failures.
        return {
            **_base_summary(url, result, source_status="error"),
            "parseSuccess": False,
            "errorMessage": f"holdings parse failed: {error}",
        }


def _smoke_intraday_nav() -> dict[str, Any]:
    fetched_at = utc_now_iso()
    mode = settings.intraday_nav_source if settings.intraday_nav_source in {"twse", "yuanta", "auto"} else "auto"
    candidates: list[tuple[str, str, Any]] = []
    if mode in {"twse", "auto"} and settings.twse_intraday_nav_url:
        candidates.append(("twse", settings.twse_intraday_nav_url, parse_intraday_nav))
    if mode in {"yuanta", "auto"} and settings.yuanta_intraday_nav_url:
        candidates.append(("yuanta", settings.yuanta_intraday_nav_url, parse_yuanta_intraday_nav))

    base = {
        "intradaySourceMode": mode,
        "configuredTwseUrl": settings.twse_intraday_nav_url,
        "configuredYuantaUrl": settings.yuanta_intraday_nav_url,
    }
    if not candidates:
        payload = unavailable_intraday_nav(
            "",
            fetched_at,
            "No intraday NAV URL is configured for 00631L",
        )
        return {
            **base,
            "chosenSource": None,
            "requestUrl": "",
            "httpStatus": None,
            "contentLength": 0,
            "parseSuccess": False,
            "found00631L": False,
            "sourceContract": payload.get("sourceContract"),
            "cacheStatus": "not_used_direct_fetch",
            "fetchedAt": fetched_at,
            "intradayNavDataTime": payload.get("dataTime"),
            "marketPrice": payload.get("marketPrice"),
            "estimatedNav": payload.get("estimatedNav"),
            "premiumDiscountPct": payload.get("premiumDiscountPct"),
            "dataDate": payload.get("dataDate"),
            "sourceStatus": payload.get("sourceStatus"),
            "sourceUpdatedAt": payload.get("sourceUpdatedAt"),
            "dataTime": payload.get("dataTime"),
            "isStale": payload.get("isStale"),
            "errorMessage": payload.get("errorMessage"),
        }

    failures: list[dict[str, Any]] = []
    for chosen_source, url, parser in candidates:
        result = _fetch_url(url)
        if result["errorMessage"]:
            failures.append(
                {
                    **base,
                    **_base_summary(url, result, source_status="error"),
                    "chosenSource": chosen_source,
                    "sourceContract": None,
                    "found00631L": False,
                }
            )
            continue

        try:
            payload = parser(result["body"], source_url=url, fetched_at=fetched_at)
            success = payload.get("sourceStatus") not in {"error", "unavailable"}
            summary = {
                **base,
                **_base_summary(url, result, source_status=payload.get("sourceStatus")),
                "chosenSource": chosen_source,
                "sourceContract": payload.get("sourceContract"),
                "parseSuccess": success,
                "found00631L": success,
                "intradayNavDataTime": payload.get("dataTime"),
                "marketPrice": payload.get("marketPrice"),
                "estimatedNav": payload.get("estimatedNav"),
                "premiumDiscountPct": payload.get("premiumDiscountPct"),
                "estimatedPremiumDiscountPct": payload.get("estimatedPremiumDiscountPct"),
                "dataDate": payload.get("dataDate"),
                "sourceUpdatedAt": payload.get("sourceUpdatedAt"),
                "dataTime": payload.get("dataTime"),
                "isStale": payload.get("isStale"),
                "errorMessage": payload.get("errorMessage"),
            }
            if success:
                return summary
            failures.append(summary)
        except Exception as error:  # noqa: BLE001 - smoke output should capture parser failures.
            failures.append(
                {
                    **base,
                    **_base_summary(url, result, source_status="error"),
                    "chosenSource": chosen_source,
                    "sourceContract": "yuanta_inav" if chosen_source == "yuanta" else "twse_a_k_json",
                    "found00631L": False,
                    "parseSuccess": False,
                    "errorMessage": f"intraday NAV parse failed: {error}",
                }
            )

    if failures:
        failure = failures[-1]
        failure["fallbackAttempts"] = failures
        return failure
    return {**base, "parseSuccess": False, "errorMessage": "No intraday NAV candidates were attempted"}


def _fetch_url(url: str) -> dict[str, Any]:
    fetched_at = utc_now_iso()
    curl = shutil.which("curl.exe") or shutil.which("curl")
    if curl is None:
        return {
            "body": "",
            "httpStatus": None,
            "contentLength": 0,
            "fetchedAt": fetched_at,
            "errorMessage": "curl was not found on PATH",
        }

    timeout = str(max(1, int(settings.request_timeout_seconds)))
    try:
        completed = subprocess.run(
            [
                curl,
                "--location",
                "--max-time",
                timeout,
                "--silent",
                "--show-error",
                "--write-out",
                f"{HTTP_MARKER}%{{http_code}}\n",
                url,
            ],
            capture_output=True,
            check=False,
            timeout=settings.request_timeout_seconds + 5,
        )
    except (OSError, subprocess.TimeoutExpired) as error:
        return {
            "body": "",
            "httpStatus": None,
            "contentLength": 0,
            "fetchedAt": fetched_at,
            "errorMessage": f"curl execution failed: {error}",
        }

    output = completed.stdout.decode("utf-8", errors="replace")
    status: int | None = None
    body = output
    if HTTP_MARKER in output:
        body, status_text = output.rsplit(HTTP_MARKER, 1)
        try:
            status = int(status_text.strip().splitlines()[0])
        except (IndexError, ValueError):
            status = None

    stderr = completed.stderr.decode("utf-8", errors="replace").strip()
    error_message = None
    if completed.returncode != 0:
        error_message = f"curl exited {completed.returncode}: {stderr}"
    elif status is not None and status >= 400:
        error_message = f"HTTP {status}"

    return {
        "body": body,
        "httpStatus": status,
        "contentLength": len(body.encode("utf-8", errors="replace")),
        "fetchedAt": fetched_at,
        "errorMessage": error_message,
    }


def _base_summary(
    url: str,
    result: dict[str, Any],
    *,
    source_status: str | None,
) -> dict[str, Any]:
    return {
        "requestUrl": url,
        "httpStatus": result.get("httpStatus"),
        "contentLength": result.get("contentLength"),
        "parseSuccess": False,
        "sourceStatus": source_status or "error",
        "cacheStatus": "not_used_direct_fetch",
        "fetchedAt": result.get("fetchedAt"),
        "sourceUpdatedAt": None,
        "dataTime": None,
        "isStale": True,
        "errorMessage": result.get("errorMessage"),
    }


def _assess_overall(results: dict[str, dict[str, Any]]) -> dict[str, Any]:
    failures: list[str] = []
    warnings: list[str] = []

    basic = results["yuanta_basic"]
    ratio = results["yuanta_ratio"]
    intraday = results["intraday_nav"]

    if not basic.get("parseSuccess") or basic.get("sourceStatus") == "error":
        failures.append(f"Basic source failed: {basic.get('errorMessage')}")
    if not ratio.get("parseSuccess") or ratio.get("sourceStatus") == "error":
        failures.append(f"Ratio source failed: {ratio.get('errorMessage')}")

    if not intraday.get("parseSuccess"):
        if settings.twse_intraday_nav_url or settings.yuanta_intraday_nav_url:
            failures.append(f"Intraday NAV source failed: {intraday.get('errorMessage')}")
        else:
            warnings.append("Intraday NAV URL is not configured; endpoint will be unavailable.")

    trade_date = _parse_date(ratio.get("parsedTradeDate"))
    if trade_date is None:
        warnings.append("Holdings tradeDate was not parsed.")
    else:
        business_days = _business_days_between(trade_date, _taipei_now().date())
        if business_days > 1:
            warnings.append(
                f"Holdings tradeDate is {business_days} Taiwan business days old: {ratio.get('parsedTradeDate')}"
            )

    intraday_time = _parse_datetime(intraday.get("dataTime") or intraday.get("intradayNavDataTime"))
    if intraday_time is None:
        warnings.append("Intraday NAV dataTime is unavailable.")
    else:
        age_seconds = max(0, int((_taipei_now() - intraday_time.astimezone(TAIPEI_TZ)).total_seconds()))
        if age_seconds > 60:
            session_note = "during regular session" if _is_taiwan_regular_session() else "outside regular session"
            warnings.append(f"Intraday NAV dataTime is {age_seconds}s old ({session_note}); review manually.")

    if failures:
        status = "FAIL"
    elif warnings:
        status = "WARN"
    else:
        status = "PASS"

    return {
        "overallStatus": status,
        "warnings": warnings,
        "failures": failures,
        "basicSourceStatus": basic.get("sourceStatus"),
        "ratioSourceStatus": ratio.get("sourceStatus"),
        "intradaySourceStatus": intraday.get("sourceStatus"),
        "intradaySourceContract": intraday.get("sourceContract"),
        "intradayCacheStatus": intraday.get("cacheStatus"),
        "marketPrice": intraday.get("marketPrice"),
        "estimatedNav": intraday.get("estimatedNav"),
        "premiumDiscountPct": intraday.get("premiumDiscountPct"),
        "dataTime": intraday.get("dataTime") or intraday.get("intradayNavDataTime"),
        "fetchedAt": intraday.get("fetchedAt"),
    }


def _taipei_now() -> datetime:
    return datetime.now(TAIPEI_TZ).replace(microsecond=0)


def _is_taiwan_regular_session() -> bool:
    now = _taipei_now()
    if now.weekday() >= 5:
        return False
    return time(9, 0) <= now.time() <= time(13, 35)


def _parse_date(value: Any) -> datetime.date | None:
    if not value:
        return None
    try:
        return datetime.strptime(str(value), "%Y-%m-%d").date()
    except ValueError:
        return None


def _parse_datetime(value: Any) -> datetime | None:
    if not value:
        return None
    text = str(value).replace("Z", "+00:00")
    try:
        parsed = datetime.fromisoformat(text)
    except ValueError:
        return None
    if parsed.tzinfo is None:
        return parsed.replace(tzinfo=TAIPEI_TZ)
    return parsed


def _business_days_between(start: datetime.date, end: datetime.date) -> int:
    days = 0
    cursor = start
    while cursor < end:
        cursor += timedelta(days=1)
        if cursor.weekday() < 5:
            days += 1
    return days


def _print_result(name: str, payload: dict[str, Any]) -> None:
    print(f"\n[{name}]")
    print(json.dumps(payload, ensure_ascii=True, indent=2, sort_keys=True))


if __name__ == "__main__":
    raise SystemExit(main())
