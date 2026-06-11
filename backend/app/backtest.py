from __future__ import annotations

import math
from datetime import datetime
from typing import Any


def default_backtest_payload() -> dict[str, Any]:
    return {
        "sourceStatus": "cached",
        "sourceContract": "00631l_backtest_defaults",
        "strategyOptions": ["lump_sum", "monthly_contribution"],
        "defaultStrategy": "monthly_contribution",
        "defaultInitialAmount": 100000,
        "defaultMonthlyAmount": 5000,
        "defaultMonthlyDay": 5,
        "defaultFeeRatePct": 0,
        "priceField": "close",
        "disclaimer": "回測不代表未來表現，非買賣建議",
    }


def run_backtest(
    *,
    request: dict[str, Any],
    history: list[dict[str, Any]],
) -> dict[str, Any]:
    points = _filtered_points(
        history=history,
        start_date=str(request.get("startDate") or ""),
        end_date=str(request.get("endDate") or ""),
    )
    if len(points) < 2:
        return _unavailable_result("Price history is insufficient for the requested backtest range.")

    strategy = str(request.get("strategy") or "monthly_contribution")
    initial_amount = max(0.0, _float(request.get("initialAmount")) or 0.0)
    monthly_amount = max(0.0, _float(request.get("monthlyAmount")) or 0.0)
    monthly_day = max(1, min(31, _int(request.get("monthlyDay")) or 5))
    fee_rate_pct = max(0.0, _float(request.get("feeRatePct")) or 0.0)

    total_invested = 0.0
    units = 0.0
    last_month = ""
    equity_curve: list[dict[str, Any]] = []
    drawdown_curve: list[dict[str, Any]] = []
    period_returns: list[float] = []
    peak = 0.0

    for index, point in enumerate(points):
        close = _float(point.get("close")) or 0.0
        if close <= 0:
            continue
        parsed_date = _parse_date(str(point.get("date") or ""))
        if parsed_date is None:
            continue
        contribution = 0.0
        if index == 0 and initial_amount > 0:
            contribution += initial_amount
        month_key = f"{parsed_date.year:04d}-{parsed_date.month:02d}"
        if (
            strategy == "monthly_contribution"
            and monthly_amount > 0
            and parsed_date.day >= monthly_day
            and month_key != last_month
        ):
            contribution += monthly_amount
            last_month = month_key
        if contribution > 0:
            fee = contribution * fee_rate_pct / 100
            units += (contribution - fee) / close
            total_invested += contribution
        value = units * close
        if equity_curve and equity_curve[-1]["value"] > 0:
            period_returns.append((value / equity_curve[-1]["value"] - 1) * 100)
        peak = max(peak, value)
        drawdown = 0.0 if peak <= 0 else (value / peak - 1) * 100
        equity_curve.append({"date": point["date"], "value": value})
        drawdown_curve.append({"date": point["date"], "value": drawdown})

    if not equity_curve or total_invested <= 0:
        return _unavailable_result("Backtest inputs did not create any historical exposure.")

    final_value = equity_curve[-1]["value"]
    first_date = _parse_date(str(equity_curve[0]["date"]))
    last_date = _parse_date(str(equity_curve[-1]["date"]))
    days = 0 if first_date is None or last_date is None else (last_date - first_date).days
    total_return_pct = (final_value / total_invested - 1) * 100
    annualized_return_pct = (
        None
        if days <= 0
        else (math.pow(final_value / total_invested, 365 / days) - 1) * 100
    )
    period_returns.sort()
    return {
        "sourceStatus": "calculated",
        "sourceContract": "00631l_backtest_engine",
        "strategy": strategy,
        "startDate": equity_curve[0]["date"],
        "endDate": equity_curve[-1]["date"],
        "totalInvested": total_invested,
        "finalValue": final_value,
        "totalReturnPct": total_return_pct,
        "annualizedReturnPct": annualized_return_pct,
        "maxDrawdownPct": min(point["value"] for point in drawdown_curve),
        "volatilityPct": None if len(period_returns) < 2 else _stdev(period_returns) * math.sqrt(252),
        "bestPeriodReturnPct": period_returns[-1] if period_returns else None,
        "worstPeriodReturnPct": period_returns[0] if period_returns else None,
        "equityCurve": equity_curve,
        "drawdownCurve": drawdown_curve,
        "disclaimer": "回測不代表未來表現，非買賣建議",
        "errorMessage": None,
    }


def _filtered_points(
    *,
    history: list[dict[str, Any]],
    start_date: str,
    end_date: str,
) -> list[dict[str, Any]]:
    parsed_start = _parse_date(start_date)
    parsed_end = _parse_date(end_date)
    points = []
    for point in history:
        parsed = _parse_date(str(point.get("date") or ""))
        if parsed is None:
            continue
        if parsed_start is not None and parsed < parsed_start:
            continue
        if parsed_end is not None and parsed > parsed_end:
            continue
        if _float(point.get("close")) is None:
            continue
        points.append(point)
    return sorted(points, key=lambda item: str(item.get("date") or ""))


def _unavailable_result(message: str) -> dict[str, Any]:
    return {
        "sourceStatus": "unavailable",
        "sourceContract": "00631l_backtest_engine",
        "totalInvested": 0,
        "finalValue": 0,
        "totalReturnPct": None,
        "annualizedReturnPct": None,
        "maxDrawdownPct": None,
        "volatilityPct": None,
        "bestPeriodReturnPct": None,
        "worstPeriodReturnPct": None,
        "equityCurve": [],
        "drawdownCurve": [],
        "disclaimer": "回測不代表未來表現，非買賣建議",
        "errorMessage": message,
    }


def _float(value: Any) -> float | None:
    if isinstance(value, (int, float)):
        return float(value)
    if value is None:
        return None
    try:
        return float(str(value).replace(",", "").strip())
    except ValueError:
        return None


def _int(value: Any) -> int | None:
    number = _float(value)
    return None if number is None else int(number)


def _parse_date(value: str):
    try:
        return datetime.strptime(value, "%Y-%m-%d").date()
    except ValueError:
        return None


def _stdev(values: list[float]) -> float:
    if len(values) < 2:
        return 0.0
    mean = sum(values) / len(values)
    variance = sum((value - mean) ** 2 for value in values) / (len(values) - 1)
    return math.sqrt(variance)
