from __future__ import annotations

import argparse
import json
from datetime import datetime, timezone
import os
from pathlib import Path
import sys
from typing import Any


ROOT = Path(__file__).resolve().parents[2]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from backend.app.config import settings  # noqa: E402
from backend.app.price_history import PriceHistoryStore, utc_now_iso  # noqa: E402
from backend.app.static_export import static_export_status  # noqa: E402
from backend.scripts.public_backend_status_00631l import (  # noqa: E402
    DEFAULT_BACKEND_URL,
    run_public_backend_status,
)


def run_public_data_freshness_check(
    *,
    base_url: str = DEFAULT_BACKEND_URL,
    timeout_seconds: int = 30,
    dry_run: bool = False,
    max_coverage_lag_days: int = 3,
    public_status: dict[str, Any] | None = None,
    local_status: dict[str, Any] | None = None,
    static_status: dict[str, Any] | None = None,
) -> dict[str, Any]:
    checked_at = _now_iso()
    if dry_run:
        return {
            "sourceContract": "00631l_public_data_freshness",
            "checkedAt": checked_at,
            "dryRun": True,
            "overallStatus": "PASS",
            "summary": {},
            "steps": [
                _planned_step("public_backend_status"),
                _planned_step("local_price_history_status"),
                _planned_step("static_public_status"),
                _planned_step("freshness_comparison"),
            ],
            "warnings": [],
            "failures": [],
            "actionItems": [],
        }

    resolved_public_status = public_status or run_public_backend_status(
        base_url=base_url,
        timeout_seconds=max(1, timeout_seconds),
    )
    resolved_local_status = local_status or _local_price_history_status()
    resolved_static_status = static_status or static_export_status(
        ROOT / "web" / "00631l-static-data"
    )
    return compare_public_data_freshness(
        public_status=resolved_public_status,
        local_status=resolved_local_status,
        static_status=resolved_static_status,
        checked_at=checked_at,
        max_coverage_lag_days=max_coverage_lag_days,
    )


def compare_public_data_freshness(
    *,
    public_status: dict[str, Any],
    local_status: dict[str, Any],
    static_status: dict[str, Any],
    checked_at: str,
    max_coverage_lag_days: int = 3,
) -> dict[str, Any]:
    public_summary = public_status.get("summary")
    if not isinstance(public_summary, dict):
        public_summary = {}

    public_rows = _int(public_summary.get("priceHistoryRows"))
    public_start = _str_or_none(public_summary.get("priceHistoryCoverageStart"))
    public_end = _str_or_none(public_summary.get("priceHistoryCoverageEnd"))
    public_etf_ready = _int(public_summary.get("etfHistoryReadyCount"))

    local_rows = _int(local_status.get("rowCount"))
    local_start = _str_or_none(local_status.get("coverageStart"))
    local_end = _str_or_none(local_status.get("coverageEnd"))

    static_rows = _int(static_status.get("rowCount"))
    static_start = _str_or_none(static_status.get("coverageStart"))
    static_end = _str_or_none(static_status.get("coverageEnd"))
    static_etf_ready = _int(static_status.get("etfPriceHistoryReadyCount"))

    public_lag_vs_local = _positive_day_lag(public_end, local_end)
    public_lag_vs_static = _positive_day_lag(public_end, static_end)
    public_etf_ready_lag = max(0, static_etf_ready - public_etf_ready)

    warnings: list[str] = []
    failures: list[str] = []
    action_items: list[str] = []

    public_overall = str(public_status.get("overallStatus") or "WARN")
    if public_overall == "FAIL":
        failures.append("public backend status check failed")
    elif public_overall == "WARN":
        warnings.append("public backend status check returned WARN")
    if public_rows < 2:
        warnings.append("public backend 00631L price history has fewer than 2 rows")
        action_items.append(
            "Run remote maintenance: scripts\\00631l_remote_maintenance.cmd --mode daily"
        )
    if (
        public_lag_vs_local is not None
        and public_lag_vs_local > max_coverage_lag_days
    ):
        warnings.append(
            "public backend 00631L history lags local history by "
            f"{public_lag_vs_local} days"
        )
        action_items.append(
            "Run remote maintenance: scripts\\00631l_remote_maintenance.cmd --mode daily"
        )
    if (
        public_lag_vs_static is not None
        and public_lag_vs_static > max_coverage_lag_days
    ):
        warnings.append(
            "public backend 00631L history lags static public data by "
            f"{public_lag_vs_static} days"
        )
        action_items.append(
            "Run remote maintenance: scripts\\00631l_remote_maintenance.cmd --mode daily"
        )
    if public_etf_ready_lag > 0:
        warnings.append(
            "public backend ETF history ready count is lower than static public data "
            f"by {public_etf_ready_lag}"
        )
        action_items.append(
            "Run public ETF catalog batches: scripts\\00631l_public_etf_catalog_batches.cmd "
            "--batch-size 1 --max-batches 1 --soft-fail"
        )
    if local_rows < 2:
        warnings.append("local 00631L price history has fewer than 2 rows")
        action_items.append("Run scripts\\00631l_update_price_history.cmd --status-only")
    if static_rows < 2:
        warnings.append("static public 00631L price history has fewer than 2 rows")
        action_items.append("Run scripts\\00631l_export_static_data.cmd --status-only")

    summary = {
        "publicBackendVersion": public_summary.get("backendVersion"),
        "publicReleaseTag": public_summary.get("releaseTag"),
        "publicGitSha": public_summary.get("gitSha"),
        "publicPriceHistoryRows": public_rows,
        "publicCoverageStart": public_start,
        "publicCoverageEnd": public_end,
        "publicEtfHistoryReadyCount": public_etf_ready,
        "localPriceHistoryRows": local_rows,
        "localCoverageStart": local_start,
        "localCoverageEnd": local_end,
        "staticPriceHistoryRows": static_rows,
        "staticCoverageStart": static_start,
        "staticCoverageEnd": static_end,
        "staticEtfHistoryReadyCount": static_etf_ready,
        "publicCoverageLagDaysVsLocal": public_lag_vs_local,
        "publicCoverageLagDaysVsStatic": public_lag_vs_static,
        "publicEtfReadyLagVsStatic": public_etf_ready_lag,
    }
    comparison_status = "FAIL" if failures else "WARN" if warnings else "PASS"
    return {
        "sourceContract": "00631l_public_data_freshness",
        "checkedAt": checked_at,
        "dryRun": False,
        "overallStatus": comparison_status,
        "summary": summary,
        "steps": [
            _status_step(
                "public_backend_status",
                public_overall,
                f"rows={public_rows} coverage={public_start}..{public_end}",
            ),
            _status_step(
                "local_price_history_status",
                "PASS" if local_rows >= 2 else "WARN",
                f"rows={local_rows} coverage={local_start}..{local_end}",
            ),
            _status_step(
                "static_public_status",
                "PASS" if static_rows >= 2 else "WARN",
                f"rows={static_rows} coverage={static_start}..{static_end}",
            ),
            _status_step(
                "freshness_comparison",
                comparison_status,
                "public/local/static freshness compared",
            ),
        ],
        "warnings": warnings,
        "failures": failures,
        "actionItems": _dedupe(action_items),
    }


def _local_price_history_status() -> dict[str, Any]:
    store = PriceHistoryStore(settings.price_history_path, seed_path=settings.price_history_seed_path)
    return store.status_response(fetched_at=utc_now_iso())


def _planned_step(name: str) -> dict[str, str]:
    return {"name": name, "status": "PASS", "message": "planned"}


def _status_step(name: str, status: str, message: str) -> dict[str, str]:
    normalized = status if status in {"PASS", "WARN", "FAIL"} else "WARN"
    return {"name": name, "status": normalized, "message": message}


def _positive_day_lag(first: str | None, second: str | None) -> int | None:
    first_date = _parse_date(first)
    second_date = _parse_date(second)
    if first_date is None or second_date is None:
        return None
    return max(0, (second_date - first_date).days)


def _parse_date(value: str | None):
    if not value:
        return None
    try:
        return datetime.strptime(value[:10], "%Y-%m-%d").date()
    except ValueError:
        return None


def _int(value: Any) -> int:
    try:
        return int(value or 0)
    except (TypeError, ValueError):
        return 0


def _str_or_none(value: Any) -> str | None:
    text = str(value or "").strip()
    return text or None


def _dedupe(items: list[str]) -> list[str]:
    seen: set[str] = set()
    result: list[str] = []
    for item in items:
        if item in seen:
            continue
        seen.add(item)
        result.append(item)
    return result


def _now_iso() -> str:
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat()


def _parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Compare public backend, local, and static 00631L data freshness.",
    )
    parser.add_argument(
        "--base-url",
        default=os.getenv("PUBLIC_BACKEND_URL")
        or os.getenv("00631L_PUBLIC_BACKEND_URL")
        or DEFAULT_BACKEND_URL,
    )
    parser.add_argument("--timeout-seconds", type=int, default=30)
    parser.add_argument("--max-coverage-lag-days", type=int, default=3)
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--soft-fail", action="store_true")
    return parser.parse_args()


def main() -> int:
    args = _parse_args()
    payload = run_public_data_freshness_check(
        base_url=args.base_url,
        timeout_seconds=max(1, args.timeout_seconds),
        dry_run=args.dry_run,
        max_coverage_lag_days=max(0, args.max_coverage_lag_days),
    )
    print(json.dumps(payload, ensure_ascii=True, indent=2, sort_keys=True))
    summary = payload.get("summary") or {}
    print(
        "[summary] "
        f"overallStatus={payload['overallStatus']} "
        f"warnings={len(payload['warnings'])} "
        f"failures={len(payload['failures'])} "
        f"publicRows={summary.get('publicPriceHistoryRows') or 0} "
        f"localRows={summary.get('localPriceHistoryRows') or 0} "
        f"staticRows={summary.get('staticPriceHistoryRows') or 0} "
        f"publicEnd={summary.get('publicCoverageEnd') or 'unknown'} "
        f"localEnd={summary.get('localCoverageEnd') or 'unknown'}"
    )
    return 0 if args.soft_fail or payload["overallStatus"] != "FAIL" else 1


if __name__ == "__main__":
    raise SystemExit(main())
