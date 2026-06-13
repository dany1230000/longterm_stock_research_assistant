from __future__ import annotations

from abc import ABC, abstractmethod
from datetime import datetime, timezone
from typing import Any


DISCLAIMER = "非買賣建議"


class AnalysisProvider(ABC):
    @abstractmethod
    def summarize(self, context: dict[str, Any]) -> dict[str, Any]:
        """Return a normalized 00631L analysis summary."""


class ExternalLlmAnalysisProvider(AnalysisProvider):
    """Disabled placeholder for a future opt-in external LLM provider."""

    def summarize(self, context: dict[str, Any]) -> dict[str, Any]:
        return {
            "source": "external_llm_placeholder",
            "sourceStatus": "unavailable",
            "sourceContract": "00631l_external_llm_analysis_placeholder",
            "generatedAt": _now_iso(),
            "dataTime": _data_time(context),
            "readinessLevel": "unavailable",
            "bullets": [
                "外部 LLM 尚未啟用；目前使用 rule_based 分析。",
            ],
            "actionItems": [
                "未來若啟用外部 LLM，請只透過本機 .env 設定，且預設保持關閉。",
            ],
            "sourceStatuses": _source_statuses(context),
            "disclaimer": DISCLAIMER,
            "errorMessage": "External LLM provider is disabled.",
        }


class RuleBasedAnalysisProvider(AnalysisProvider):
    def summarize(self, context: dict[str, Any]) -> dict[str, Any]:
        operations = _as_dict(context.get("operations"))
        holdings = _as_dict(context.get("holdingsHistory"))
        intraday = _as_dict(context.get("intradayNavHistory"))
        price_history = _as_dict(context.get("priceHistory"))
        integrity = _as_dict(context.get("integrity"))
        report = _as_dict(operations.get("report"))
        export = _as_dict(operations.get("export"))
        backup = _as_dict(operations.get("backup"))
        daily_cycle = _as_dict(operations.get("dailyCycle"))

        readiness_level = _readiness_level(
            operations=operations,
            holdings=holdings,
            intraday=intraday,
            price_history=price_history,
            integrity=integrity,
            report=report,
            export=export,
            backup=backup,
            daily_cycle=daily_cycle,
        )
        bullets = _bullets(
            readiness_level=readiness_level,
            operations=operations,
            holdings=holdings,
            intraday=intraday,
            price_history=price_history,
            integrity=integrity,
            report=report,
            export=export,
            backup=backup,
            daily_cycle=daily_cycle,
        )
        action_items = _action_items(
            operations=operations,
            holdings=holdings,
            intraday=intraday,
            price_history=price_history,
            integrity=integrity,
            report=report,
            export=export,
            backup=backup,
            daily_cycle=daily_cycle,
        )

        return {
            "source": "rule_based",
            "sourceStatus": "cached",
            "sourceContract": "00631l_rule_based_analysis_summary",
            "generatedAt": _now_iso(),
            "dataTime": _data_time(context),
            "readinessLevel": readiness_level,
            "bullets": bullets[:8],
            "actionItems": action_items[:8],
            "sourceStatuses": _source_statuses(context),
            "disclaimer": DISCLAIMER,
            "errorMessage": None,
        }


def _readiness_level(
    *,
    operations: dict[str, Any],
    holdings: dict[str, Any],
    intraday: dict[str, Any],
    price_history: dict[str, Any],
    integrity: dict[str, Any],
    report: dict[str, Any],
    export: dict[str, Any],
    backup: dict[str, Any],
    daily_cycle: dict[str, Any],
) -> str:
    failure_markers = [
        operations.get("sourceStatus") in {"error", "unavailable"},
        holdings.get("sourceStatus") in {"error", "unavailable"},
        intraday.get("sourceStatus") in {"error", "unavailable"},
        integrity.get("overallStatus") == "FAIL",
        report.get("overallStatus") == "FAIL",
        daily_cycle.get("overallStatus") == "FAIL",
    ]
    if any(failure_markers):
        return "action_needed"

    attention_markers = [
        operations.get("isStale") is True,
        holdings.get("isStale") is True,
        intraday.get("isStale") is True,
        price_history.get("sourceStatus") in {"unavailable", "error"},
        integrity.get("overallStatus") == "WARN",
        report.get("overallStatus") == "WARN",
        daily_cycle.get("overallStatus") == "WARN",
        not bool(export.get("available")),
        not bool(backup.get("available")),
    ]
    return "attention" if any(attention_markers) else "ready"


def _bullets(
    *,
    readiness_level: str,
    operations: dict[str, Any],
    holdings: dict[str, Any],
    intraday: dict[str, Any],
    price_history: dict[str, Any],
    integrity: dict[str, Any],
    report: dict[str, Any],
    export: dict[str, Any],
    backup: dict[str, Any],
    daily_cycle: dict[str, Any],
) -> list[str]:
    bullets = [
        f"今日資料狀態：{_readiness_label(readiness_level)}。本摘要只描述資料狀態、內容物變化與價格偏離。",
    ]

    latest_holding = _nested(operations, "holdingsHistory", "latestTradeDate")
    holding_status = _nested(operations, "holdingsHistory", "sourceStatus") or holdings.get("sourceStatus")
    if latest_holding:
        bullets.append(
            f"今日使用的 official holdings 日期為 {latest_holding}，sourceStatus {holding_status}；這是每日快照，不是盤中即時內容物。"
        )
    else:
        bullets.append("今日尚無 official holdings history 紀錄；請先執行 daily cycle 建立每日快照。")

    latest_intraday = _nested(operations, "intradayNavHistory", "latestDataTime") or intraday.get("lastDataTime")
    intraday_status = _nested(operations, "intradayNavHistory", "sourceStatus") or intraday.get("sourceStatus")
    premium = intraday.get("averagePremiumDiscountPct")
    if latest_intraday:
        bullets.append(
            f"盤中 NAV 最新資料時間為 {latest_intraday}，sourceStatus {intraday_status}；平均折溢價 {_signed_pct(premium)}，狀態 {_premium_state_label(premium)}。"
        )
    else:
        bullets.append("今日盤中 NAV 尚無可用紀錄，折溢價狀態暫時無法判斷。")

    latest_point = _latest_holding_point(holdings)
    if latest_point:
        bullets.append(
            "今日內容物重點："
            f"TX 權重 {_pct(latest_point.get('txWeightPct'))}，"
            f"台積電權重 {_pct(latest_point.get('tsmcWeightPct'))}，"
            f"股票/期貨/現金保證金 {_pct(latest_point.get('stockExposurePct'))} / "
            f"{_pct(latest_point.get('futuresExposurePct'))} / "
            f"{_pct(latest_point.get('cashAndMarginPct'))}。"
        )

    if premium is not None:
        bullets.append(
            f"今日折溢價偏離為 {_signed_pct(premium)}，屬於 {_premium_state_label(premium)}；這是價格偏離提示。"
        )

    if price_history.get("rowCount", 0):
        bullets.append(
            "歷史價格背景：coverage "
            f"{price_history.get('coverageStart')} - {price_history.get('coverageEnd')}，"
            f"累積報酬 {_signed_pct(price_history.get('totalReturnPct'))}，"
            f"最大回撤 {_signed_pct(price_history.get('maxDrawdownPct'))}。"
        )
    else:
        bullets.append("歷史價格尚未建立 official cache，歷史回測區會顯示資料不足。")

    bullets.append(
        "維護狀態："
        f"report {report.get('sourceStatus', 'unknown')}，"
        f"export {export.get('sourceStatus', 'unknown')}，"
        f"backup {backup.get('sourceStatus', 'unknown')}。"
    )

    if integrity:
        bullets.append(
            f"資料完整性檢查為 {integrity.get('overallStatus', 'unknown')}，"
            f"failures {integrity.get('failureCount', 0)}，"
            f"warnings {integrity.get('warningCount', 0)}。"
        )

    return bullets


def _action_items(
    *,
    operations: dict[str, Any],
    holdings: dict[str, Any],
    intraday: dict[str, Any],
    price_history: dict[str, Any],
    integrity: dict[str, Any],
    report: dict[str, Any],
    export: dict[str, Any],
    backup: dict[str, Any],
    daily_cycle: dict[str, Any],
) -> list[str]:
    actions: list[str] = []
    config = _as_dict(operations.get("config"))
    missing_keys = config.get("missingKeys") if isinstance(config.get("missingKeys"), list) else []
    if missing_keys:
        actions.append("請檢查 backend .env，並執行 scripts\\00631l_check_env.cmd。")

    if daily_cycle.get("sourceStatus") in {"unavailable", "error"} or daily_cycle.get("overallStatus") in {None, "missing", "FAIL"}:
        actions.append("請執行 scripts\\00631l_daily_cycle.cmd。")

    if intraday.get("sourceStatus") in {"unavailable", "error"} or not _nested(operations, "intradayNavHistory", "latestDataTime"):
        actions.append("請確認 intraday NAV 資料時間、TWSE URL 設定與交易時段。")

    if holdings.get("sourceStatus") in {"unavailable", "error"} or not _nested(operations, "holdingsHistory", "latestTradeDate"):
        actions.append("請執行 daily cycle，確認 Yuanta official ratio 是否寫入 local history。")

    if price_history.get("sourceStatus") in {"unavailable", "error"} or not price_history.get("rowCount"):
        actions.append("請執行 scripts\\00631l_update_price_history.cmd 建立 official price history cache。")

    if report.get("sourceStatus") in {"unavailable", "error"}:
        actions.append("請執行 scripts\\00631l_generate_daily_report.cmd 產生日報。")

    if not bool(export.get("available")):
        actions.append("請執行 scripts\\00631l_export_history.cmd 產生 CSV export。")

    if not bool(backup.get("available")):
        actions.append("請執行 scripts\\00631l_backup_data.cmd 建立本機備份。")

    if integrity.get("overallStatus") in {"WARN", "FAIL"}:
        actions.append("請執行 scripts\\00631l_check_integrity.cmd 檢查本機資料完整性。")

    if not actions:
        actions.append("目前沒有必要的程式操作；請持續確認官方資料時間。")

    return actions


def _source_statuses(context: dict[str, Any]) -> dict[str, str]:
    operations = _as_dict(context.get("operations"))
    integrity = _as_dict(context.get("integrity"))
    price_history = _as_dict(context.get("priceHistory"))
    return {
        "operations": str(operations.get("sourceStatus") or "unavailable"),
        "holdingsHistory": str(_nested(operations, "holdingsHistory", "sourceStatus") or "unavailable"),
        "intradayNavHistory": str(_nested(operations, "intradayNavHistory", "sourceStatus") or "unavailable"),
        "priceHistory": str(price_history.get("sourceStatus") or _nested(operations, "priceHistory", "sourceStatus") or "unavailable"),
        "dailyCycle": str(_nested(operations, "dailyCycle", "sourceStatus") or "unavailable"),
        "report": str(_nested(operations, "report", "sourceStatus") or "unavailable"),
        "export": str(_nested(operations, "export", "sourceStatus") or "unavailable"),
        "backup": str(_nested(operations, "backup", "sourceStatus") or "unavailable"),
        "integrity": str(integrity.get("sourceStatus") or "unavailable"),
    }


def _data_time(context: dict[str, Any]) -> str | None:
    operations = _as_dict(context.get("operations"))
    return (
        _nested(operations, "intradayNavHistory", "latestDataTime")
        or _nested(operations, "holdingsHistory", "latestTradeDate")
        or _nested(operations, "priceHistory", "coverageEnd")
        or operations.get("dataTime")
        or operations.get("sourceUpdatedAt")
    )


def _latest_holding_point(holdings: dict[str, Any]) -> dict[str, Any]:
    items = holdings.get("items")
    if isinstance(items, list) and items:
        first = items[0]
        return first if isinstance(first, dict) else {}
    return {}


def _readiness_label(level: str) -> str:
    return {
        "ready": "可日常使用",
        "attention": "需要觀察",
        "action_needed": "需要處理",
    }.get(level, "資料不足")


def _premium_state_label(value: Any) -> str:
    number = _number(value)
    if number is None:
        return "資料不足"
    absolute = abs(number)
    if absolute <= 0.20:
        return "正常"
    if absolute <= 0.50:
        return "觀察"
    if absolute <= 1.00:
        return "折價偏深" if number < 0 else "溢價偏高"
    return "折價極端" if number < 0 else "溢價極端"


def _pct(value: Any) -> str:
    number = _number(value)
    return "unavailable" if number is None else f"{number:.2f}%"


def _signed_pct(value: Any) -> str:
    number = _number(value)
    if number is None:
        return "unavailable"
    prefix = "+" if number > 0 else ""
    return f"{prefix}{number:.2f}%"


def _number(value: Any) -> float | None:
    if isinstance(value, (int, float)):
        return float(value)
    if value is None:
        return None
    try:
        return float(str(value).replace(",", "").strip())
    except ValueError:
        return None


def _nested(payload: dict[str, Any], *keys: str) -> Any:
    current: Any = payload
    for key in keys:
        if not isinstance(current, dict):
            return None
        current = current.get(key)
    return current


def _as_dict(value: Any) -> dict[str, Any]:
    return value if isinstance(value, dict) else {}


def _now_iso() -> str:
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat()
