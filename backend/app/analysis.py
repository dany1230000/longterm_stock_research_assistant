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
    """Placeholder for a future opt-in LLM provider.

    The production default is rule-based. External LLM integration must stay
    disabled unless a future release explicitly enables it through local env.
    """

    def summarize(self, context: dict[str, Any]) -> dict[str, Any]:
        return {
            "source": "external_llm_placeholder",
            "sourceStatus": "unavailable",
            "sourceContract": "00631l_external_llm_analysis_placeholder",
            "generatedAt": _now_iso(),
            "dataTime": _data_time(context),
            "readinessLevel": "unavailable",
            "bullets": [
                "外部 LLM 分析目前未啟用；預設只使用 rule-based 摘要。",
            ],
            "actionItems": [
                "維持 rule-based analysis；若未來接外部 LLM，必須透過本機 env 明確啟用。",
            ],
            "sourceStatuses": _source_statuses(context),
            "disclaimer": DISCLAIMER,
            "errorMessage": "External LLM provider is a disabled placeholder.",
        }


class RuleBasedAnalysisProvider(AnalysisProvider):
    def summarize(self, context: dict[str, Any]) -> dict[str, Any]:
        operations = _as_dict(context.get("operations"))
        holdings = _as_dict(context.get("holdingsHistory"))
        intraday = _as_dict(context.get("intradayNavHistory"))
        integrity = _as_dict(context.get("integrity"))
        report = _as_dict(operations.get("report"))
        export = _as_dict(operations.get("export"))
        backup = _as_dict(operations.get("backup"))
        daily_cycle = _as_dict(operations.get("dailyCycle"))

        readiness_level = _readiness_level(
            operations=operations,
            holdings=holdings,
            intraday=intraday,
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
            "bullets": bullets[:6],
            "actionItems": action_items[:6],
            "sourceStatuses": _source_statuses(context),
            "disclaimer": DISCLAIMER,
            "errorMessage": None,
        }


def _readiness_level(
    *,
    operations: dict[str, Any],
    holdings: dict[str, Any],
    intraday: dict[str, Any],
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
        integrity.get("overallStatus") == "WARN",
        report.get("overallStatus") == "WARN",
        daily_cycle.get("overallStatus") == "WARN",
        not bool(export.get("available")),
        not bool(backup.get("available")),
    ]
    if any(attention_markers):
        return "attention"

    return "ready"


def _bullets(
    *,
    readiness_level: str,
    operations: dict[str, Any],
    holdings: dict[str, Any],
    intraday: dict[str, Any],
    integrity: dict[str, Any],
    report: dict[str, Any],
    export: dict[str, Any],
    backup: dict[str, Any],
    daily_cycle: dict[str, Any],
) -> list[str]:
    bullets = [
        f"今日資料狀態為 {_readiness_label(readiness_level)}；此摘要只描述資料狀態與偏離程度。",
    ]

    latest_holding = _nested(operations, "holdingsHistory", "latestTradeDate")
    holding_status = _nested(operations, "holdingsHistory", "sourceStatus") or holdings.get("sourceStatus")
    if latest_holding:
        bullets.append(
            f"official holdings 為每日快照，最近日期 {latest_holding}，sourceStatus {holding_status}。"
        )
    else:
        bullets.append("official holdings history 尚未累積，暫時無法比較每日內容物變化。")

    latest_intraday = _nested(operations, "intradayNavHistory", "latestDataTime") or intraday.get("lastDataTime")
    intraday_status = _nested(operations, "intradayNavHistory", "sourceStatus") or intraday.get("sourceStatus")
    if latest_intraday:
        bullets.append(
            f"intraday NAV 為盤中估算資料，最近資料時間 {latest_intraday}，sourceStatus {intraday_status}。"
        )
    else:
        bullets.append("intraday NAV history 尚無可用樣本，暫時無法判斷盤中折溢價歷史。")

    latest_point = _latest_holding_point(holdings)
    if latest_point:
        bullets.append(
            "最新 holdings summary：TX 權重 "
            f"{_pct(latest_point.get('txWeightPct'))}，台積電權重 "
            f"{_pct(latest_point.get('tsmcWeightPct'))}，股票/期貨/現金與保證金 "
            f"{_pct(latest_point.get('stockExposurePct'))} / "
            f"{_pct(latest_point.get('futuresExposurePct'))} / "
            f"{_pct(latest_point.get('cashAndMarginPct'))}。"
        )

    premium = intraday.get("averagePremiumDiscountPct")
    if premium is not None:
        bullets.append(
            f"今日 intraday NAV history 平均折溢價 {_signed_pct(premium)}，屬於價格偏離提示。"
        )

    bullets.append(
        "daily report/export/backup 狀態："
        f" report {report.get('sourceStatus', 'unknown')}，"
        f" export {export.get('sourceStatus', 'unknown')}，"
        f" backup {backup.get('sourceStatus', 'unknown')}。"
    )

    if integrity:
        bullets.append(
            f"資料完整性最近結果為 {integrity.get('overallStatus', 'unknown')}，"
            f"failures {integrity.get('failureCount', 0)}，warnings {integrity.get('warningCount', 0)}。"
        )

    return bullets


def _action_items(
    *,
    operations: dict[str, Any],
    holdings: dict[str, Any],
    intraday: dict[str, Any],
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
        actions.append("請檢查 backend .env 與必要設定，並執行 scripts\\00631l_check_env.cmd。")

    if daily_cycle.get("sourceStatus") in {"unavailable", "error"} or daily_cycle.get("overallStatus") in {None, "missing", "FAIL"}:
        actions.append("請先執行 scripts\\00631l_daily_cycle.cmd。")

    if intraday.get("sourceStatus") in {"unavailable", "error"} or not _nested(operations, "intradayNavHistory", "latestDataTime"):
        actions.append("請確認 intraday NAV 資料時間，並檢查 TWSE URL 設定或交易時段。")

    if holdings.get("sourceStatus") in {"unavailable", "error"} or not _nested(operations, "holdingsHistory", "latestTradeDate"):
        actions.append("請執行 daily cycle，確認 Yuanta official ratio 是否已累積到 local history。")

    if report.get("sourceStatus") in {"unavailable", "error"}:
        actions.append("請執行 scripts\\00631l_generate_daily_report.cmd 產生日報。")

    if not bool(export.get("available")):
        actions.append("請執行 scripts\\00631l_export_history.cmd 更新 CSV export。")

    if not bool(backup.get("available")):
        actions.append("請執行 scripts\\00631l_backup_data.cmd 建立 local backup。")

    if integrity.get("overallStatus") in {"WARN", "FAIL"}:
        actions.append("請執行 scripts\\00631l_check_integrity.cmd 並查看完整性結果。")

    if not actions:
        actions.append("目前沒有必要的本機處理項目；請以官方資料時間為準。")

    return actions


def _source_statuses(context: dict[str, Any]) -> dict[str, str]:
    operations = _as_dict(context.get("operations"))
    integrity = _as_dict(context.get("integrity"))
    return {
        "operations": str(operations.get("sourceStatus") or "unavailable"),
        "holdingsHistory": str(_nested(operations, "holdingsHistory", "sourceStatus") or "unavailable"),
        "intradayNavHistory": str(_nested(operations, "intradayNavHistory", "sourceStatus") or "unavailable"),
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
