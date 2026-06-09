from __future__ import annotations

import json
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


def generate_00631l_daily_report(
    *,
    holdings_history_path: str | Path,
    intraday_history_path: str | Path,
    daily_cycle_status_path: str | Path,
    report_dir: str | Path,
    daily_cycle_status: dict[str, Any] | None = None,
) -> dict[str, Any]:
    report_output_dir = Path(report_dir)
    report_output_dir.mkdir(parents=True, exist_ok=True)

    generated_at = _utc_now_iso()
    stamp = generated_at.replace(":", "").replace("-", "").replace("+00:00", "Z")
    report_path = report_output_dir / f"00631l_daily_report_{stamp}.md"
    latest_metadata_path = report_output_dir / "00631l_daily_report_latest.json"

    holdings = _latest_by_key(_read_jsonl(Path(holdings_history_path)), "tradeDate")
    intraday = _latest_by_key(_read_jsonl(Path(intraday_history_path)), "dataTime")
    cycle_status = daily_cycle_status or _read_json(Path(daily_cycle_status_path))
    overall_status = str(cycle_status.get("overallStatus") or "unavailable")
    warnings = _string_list(cycle_status.get("warnings"))
    failures = _string_list(cycle_status.get("failures"))

    body = _markdown_report(
        generated_at=generated_at,
        holdings=holdings,
        intraday=intraday,
        cycle_status=cycle_status,
        overall_status=overall_status,
        warnings=warnings,
        failures=failures,
    )
    report_path.write_text(body, encoding="utf-8")

    metadata = {
        "sourceStatus": "cached",
        "sourceContract": "00631l_daily_markdown_report",
        "generatedAt": generated_at,
        "reportPath": str(report_path),
        "latestMetadataPath": str(latest_metadata_path),
        "overallStatus": overall_status,
        "holdingsTradeDate": holdings.get("tradeDate"),
        "intradayDataTime": intraday.get("dataTime"),
        "warningCount": len(warnings),
        "failureCount": len(failures),
        "warnings": warnings,
        "failures": failures,
        "isStale": False,
        "errorMessage": None,
    }
    latest_metadata_path.write_text(
        json.dumps(metadata, ensure_ascii=False, indent=2, sort_keys=True),
        encoding="utf-8",
    )
    return metadata


def report_status(report_dir: str | Path) -> dict[str, Any]:
    directory = Path(report_dir)
    latest_metadata_path = directory / "00631l_daily_report_latest.json"
    if latest_metadata_path.exists():
        metadata = _read_json(latest_metadata_path)
        if metadata:
            return metadata

    reports = sorted(directory.glob("00631l_daily_report_*.md"), reverse=True) if directory.exists() else []
    if reports:
        latest = reports[0]
        return {
            "sourceStatus": "cached",
            "sourceContract": "00631l_daily_markdown_report",
            "generatedAt": _mtime_iso(latest),
            "reportPath": str(latest),
            "latestMetadataPath": str(latest_metadata_path),
            "overallStatus": "cached",
            "holdingsTradeDate": None,
            "intradayDataTime": None,
            "warningCount": 0,
            "failureCount": 0,
            "warnings": [],
            "failures": [],
            "isStale": False,
            "errorMessage": None,
        }

    return {
        "sourceStatus": "unavailable",
        "sourceContract": "00631l_daily_markdown_report",
        "generatedAt": None,
        "reportPath": None,
        "latestMetadataPath": str(latest_metadata_path),
        "overallStatus": "missing",
        "holdingsTradeDate": None,
        "intradayDataTime": None,
        "warningCount": 0,
        "failureCount": 0,
        "warnings": [],
        "failures": [],
        "isStale": True,
        "errorMessage": "No daily report has been generated",
    }


def _markdown_report(
    *,
    generated_at: str,
    holdings: dict[str, Any],
    intraday: dict[str, Any],
    cycle_status: dict[str, Any],
    overall_status: str,
    warnings: list[str],
    failures: list[str],
) -> str:
    lines = [
        "# 00631L daily report",
        "",
        f"- generatedAt: {generated_at}",
        f"- overallStatus: {overall_status}",
        f"- sourceContract: 00631l_daily_markdown_report",
        "",
        "## Holdings snapshot",
        "",
        f"- tradeDate: {_value(holdings.get('tradeDate'))}",
        f"- sourceStatus: {_value(holdings.get('sourceStatus'))}",
        f"- navPerUnit: {_value(holdings.get('navPerUnit'))}",
        f"- fundNetAssetValue: {_value(holdings.get('fundNetAssetValue'))}",
        f"- outstandingUnits: {_value(holdings.get('outstandingUnits'))}",
        f"- txWeightPct: {_holding_weight(holdings.get('futuresHoldings'), 'TX')}",
        f"- tsmcWeightPct: {_holding_weight(holdings.get('stockHoldings'), '2330')}",
        "",
        "## Intraday NAV",
        "",
        f"- dataTime: {_value(intraday.get('dataTime'))}",
        f"- sourceStatus: {_value(intraday.get('sourceStatus'))}",
        f"- sourceContract: {_value(intraday.get('sourceContract'))}",
        f"- marketPrice: {_value(intraday.get('marketPrice'))}",
        f"- estimatedNav: {_value(intraday.get('estimatedNav'))}",
        f"- premiumDiscountPct: {_value(intraday.get('premiumDiscountPct') or intraday.get('estimatedPremiumDiscountPct'))}",
        "",
        "## Daily cycle",
        "",
        f"- startedAt: {_value(cycle_status.get('startedAt'))}",
        f"- finishedAt: {_value(cycle_status.get('finishedAt'))}",
        f"- collectStatus: {_step_status(cycle_status, 'collect')}",
        f"- exportStatus: {_step_status(cycle_status, 'export')}",
        f"- smokeStatus: {_step_status(cycle_status, 'smoke')}",
        "",
        "## Warnings",
        "",
    ]
    lines.extend([f"- {warning}" for warning in warnings] or ["- none"])
    lines.extend(["", "## Failures", ""])
    lines.extend([f"- {failure}" for failure in failures] or ["- none"])
    lines.extend(
        [
            "",
            "## Notes",
            "",
            "- This report describes data and local operation status only.",
            "- Official daily holdings are daily snapshots, not intraday holdings.",
            "- Intraday NAV describes market price, estimated NAV, premium/discount, source status, and data time.",
            "- Mock or fallback data must not be labeled as official.",
        ]
    )
    return "\n".join(lines) + "\n"


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


def _read_json(path: Path) -> dict[str, Any]:
    if not path.exists():
        return {}
    try:
        decoded = json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError:
        return {}
    return decoded if isinstance(decoded, dict) else {}


def _latest_by_key(records: list[dict[str, Any]], key: str) -> dict[str, Any]:
    if not records:
        return {}
    return sorted(records, key=lambda item: str(item.get(key) or ""), reverse=True)[0]


def _holding_weight(lines_value: Any, code: str) -> str:
    lines = lines_value if isinstance(lines_value, list) else []
    total = 0.0
    for line in lines:
        if isinstance(line, dict) and str(line.get("code") or "") == code:
            total += _float(line.get("weightPct"))
    return f"{total:.2f}"


def _step_status(cycle_status: dict[str, Any], key: str) -> str:
    value = cycle_status.get(key)
    if isinstance(value, dict):
        return str(value.get("status") or "unavailable")
    return "unavailable"


def _string_list(value: Any) -> list[str]:
    if isinstance(value, list):
        return [str(item) for item in value]
    return []


def _value(value: Any) -> str:
    if value is None or value == "":
        return "unavailable"
    return str(value)


def _float(value: Any) -> float:
    if isinstance(value, (int, float)):
        return float(value)
    if value is None:
        return 0.0
    try:
        return float(str(value).replace(",", "").strip())
    except ValueError:
        return 0.0


def _mtime_iso(path: Path) -> str:
    return datetime.fromtimestamp(path.stat().st_mtime, timezone.utc).replace(microsecond=0).isoformat()


def _utc_now_iso() -> str:
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat()
