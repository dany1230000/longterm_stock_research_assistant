from __future__ import annotations

import argparse
import json
import os
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[2]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from backend.scripts.check_public_deploy_drift_00631l import (  # noqa: E402
    run_public_backend_deploy_drift_check,
)
from backend.scripts.compare_public_data_freshness_00631l import (  # noqa: E402
    run_public_data_freshness_check,
)
from backend.scripts.public_backend_status_00631l import (  # noqa: E402
    DEFAULT_BACKEND_URL,
    run_public_backend_status,
)
from backend.scripts.run_public_etf_catalog_batches_00631l import (  # noqa: E402
    DEFAULT_STATE_PATH as DEFAULT_CATALOG_BATCH_STATE_PATH,
)


def run_public_maintenance_status(
    *,
    base_url: str = DEFAULT_BACKEND_URL,
    timeout_seconds: int = 30,
    min_price_history_rows: int = 2,
    min_etf_ready_count: int = 1,
    dry_run: bool = False,
) -> dict[str, Any]:
    checked_at = _now_iso()
    if dry_run:
        return {
            "sourceContract": "00631l_public_maintenance_status",
            "checkedAt": checked_at,
            "dryRun": True,
            "overallStatus": "PASS",
            "failureCount": 0,
            "warningCount": 0,
            "summary": {
                "baseUrl": _normalize_base_url(base_url),
                "minPriceHistoryRows": max(1, min_price_history_rows),
                "minEtfReadyCount": max(1, min_etf_ready_count),
            },
            "steps": [
                {"name": "deploy_drift", "status": "PASS", "message": "planned"},
                {"name": "public_backend_status", "status": "PASS", "message": "planned"},
                {"name": "public_freshness", "status": "PASS", "message": "planned"},
            ],
            "warnings": [],
            "failures": [],
            "actionItems": [],
        }

    deploy_drift = run_public_backend_deploy_drift_check(
        base_url=base_url,
        timeout_seconds=max(1, timeout_seconds),
    )
    public_status = run_public_backend_status(
        base_url=base_url,
        timeout_seconds=max(1, timeout_seconds),
        min_price_history_rows=max(1, min_price_history_rows),
        min_etf_ready_count=max(1, min_etf_ready_count),
    )
    freshness = run_public_data_freshness_check(
        base_url=base_url,
        timeout_seconds=max(1, timeout_seconds),
    )
    return build_public_maintenance_status(
        deploy_drift=deploy_drift,
        public_status=public_status,
        freshness=freshness,
        catalog_batch_state=load_catalog_batch_state(DEFAULT_CATALOG_BATCH_STATE_PATH),
        checked_at=checked_at,
    )


def build_public_maintenance_status(
    *,
    deploy_drift: dict[str, Any],
    public_status: dict[str, Any],
    freshness: dict[str, Any],
    catalog_batch_state: dict[str, Any] | None = None,
    checked_at: str,
) -> dict[str, Any]:
    steps = [
        _step_from_payload("deploy_drift", deploy_drift),
        _step_from_payload("public_backend_status", public_status),
        _step_from_payload("public_freshness", freshness),
    ]
    warnings = _collect("warnings", deploy_drift, public_status, freshness)
    failures = _collect("failures", deploy_drift, public_status, freshness)
    public_summary = (
        public_status.get("summary")
        if isinstance(public_status.get("summary"), dict)
        else {}
    )
    freshness_summary = (
        freshness.get("summary")
        if isinstance(freshness.get("summary"), dict)
        else {}
    )
    drift_summary = (
        deploy_drift.get("summary")
        if isinstance(deploy_drift.get("summary"), dict)
        else {}
    )
    ready_regression = _catalog_batch_ready_regression(
        catalog_batch_state,
        public_ready_count=public_summary.get("etfHistoryReadyCount"),
    )
    has_persistence_warning = _has_public_persistence_warning(public_status)
    catalog_regression_warning = (
        [
            "Public ETF ready count regressed from the last batch state; "
            "check Render deploy persistence before running more batches."
        ]
        if ready_regression > 0
        else []
    )
    action_items = _dedupe(
        [
            *list(deploy_drift.get("actionItems") or []),
            *list(public_status.get("actionItems") or []),
            *list(freshness.get("actionItems") or []),
            *_persistence_action_items(has_persistence_warning),
            *_catalog_batch_regression_action_items(ready_regression),
            *(
                []
                if has_persistence_warning
                else _catalog_batch_action_items(
                    catalog_batch_state,
                    public_ready_count=public_summary.get("etfHistoryReadyCount"),
                    ready_lag=freshness_summary.get("publicEtfReadyLagVsStatic"),
                )
            ),
        ]
    )
    warnings = _dedupe([*warnings, *catalog_regression_warning])
    overall_status = "FAIL" if failures else "WARN" if warnings else "PASS"
    catalog_summary = _catalog_batch_summary(catalog_batch_state)
    return {
        "sourceContract": "00631l_public_maintenance_status",
        "checkedAt": checked_at,
        "dryRun": False,
        "overallStatus": overall_status,
        "failureCount": len(failures),
        "warningCount": len(warnings),
        "summary": {
            "baseUrl": public_status.get("baseUrl") or drift_summary.get("baseUrl"),
            "publicReleaseTag": public_summary.get("releaseTag")
            or drift_summary.get("publicReleaseTag"),
            "expectedReleaseTag": drift_summary.get("expectedReleaseTag"),
            "publicEtfReadyCount": public_summary.get("etfHistoryReadyCount"),
            "minEtfReadyCount": public_summary.get("minEtfReadyCount"),
            "publicEtfReadyLagVsStatic": freshness_summary.get("publicEtfReadyLagVsStatic"),
            "publicCoverageEnd": freshness_summary.get("publicCoverageEnd"),
            "staticCoverageEnd": freshness_summary.get("staticCoverageEnd"),
            "publicPriceHistoryRows": public_summary.get("priceHistoryRows"),
            **catalog_summary,
            "catalogBatchReadyRegression": ready_regression,
        },
        "steps": steps,
        "warnings": warnings,
        "failures": failures,
        "actionItems": action_items,
    }


def load_catalog_batch_state(path: str | Path) -> dict[str, Any] | None:
    state_path = Path(path)
    try:
        payload = json.loads(state_path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError):
        return None
    return payload if isinstance(payload, dict) else None


def _catalog_batch_summary(state: dict[str, Any] | None) -> dict[str, Any]:
    if not state:
        return {
            "catalogBatchStateUpdatedAt": None,
            "catalogBatchStateStatus": "unavailable",
            "catalogBatchCatalogRowCount": None,
            "catalogBatchFinalReadyCount": None,
            "catalogBatchNextOffset": None,
            "catalogBatchFailedOffset": None,
        }
    return {
        "catalogBatchStateUpdatedAt": state.get("updatedAt"),
        "catalogBatchStateStatus": state.get("overallStatus"),
        "catalogBatchCatalogRowCount": state.get("catalogRowCount"),
        "catalogBatchFinalReadyCount": state.get("finalReadyCount"),
        "catalogBatchNextOffset": state.get("nextOffset"),
        "catalogBatchFailedOffset": state.get("failedOffset"),
    }


def _catalog_batch_action_items(
    state: dict[str, Any] | None,
    *,
    public_ready_count: Any = None,
    ready_lag: Any = None,
) -> list[str]:
    if not state:
        return []
    if state.get("failedOffset") is not None:
        return [
            "Review public ETF catalog batch state, then resume with "
            "scripts\\00631l_public_etf_catalog_batches.cmd --resume --batch-size 1 --max-batches 1 --soft-fail."
        ]
    if state.get("nextOffset") is not None:
        return [
            "Resume public ETF catalog batches with scripts\\00631l_public_etf_catalog_batches.cmd --resume --batch-size 1 --max-batches 1 --soft-fail."
        ]
    try:
        ready_count = max(0, int(public_ready_count))
        lag_count = int(ready_lag)
    except (TypeError, ValueError):
        return []
    if ready_count > 0 and lag_count > 0:
        return [
            "Continue public ETF catalog batches with "
            "scripts\\00631l_public_etf_catalog_batches.cmd "
            f"--start-offset {ready_count} --batch-size 1 --max-batches 1 --soft-fail."
        ]
    return []


def _catalog_batch_ready_regression(
    state: dict[str, Any] | None,
    *,
    public_ready_count: Any = None,
) -> int:
    if not state:
        return 0
    try:
        final_ready_count = int(state.get("finalReadyCount"))
        current_ready_count = int(public_ready_count)
    except (TypeError, ValueError):
        return 0
    return max(0, final_ready_count - current_ready_count)


def _catalog_batch_regression_action_items(ready_regression: int) -> list[str]:
    if ready_regression <= 0:
        return []
    return [
        "Check public backend persistent data volume and redeploy status before continuing ETF catalog batches."
    ]


def _has_public_persistence_warning(public_status: dict[str, Any]) -> bool:
    values = [str(item).lower() for item in public_status.get("warnings") or []]
    return any(
        "data_persistence" in item
        or "data directory is not writable" in item
        or "00631l_data_dir is not writable" in item
        for item in values
    )


def _persistence_action_items(has_persistence_warning: bool) -> list[str]:
    if not has_persistence_warning:
        return []
    return [
        "Fix public backend persistent data volume before running ETF catalog batches."
    ]


def _step_from_payload(name: str, payload: dict[str, Any]) -> dict[str, Any]:
    status = str(payload.get("overallStatus") or "WARN")
    normalized = status if status in {"PASS", "WARN", "FAIL"} else "WARN"
    return {
        "name": name,
        "status": normalized,
        "message": normalized,
    }


def _collect(key: str, *payloads: dict[str, Any]) -> list[str]:
    values: list[str] = []
    for payload in payloads:
        values.extend(str(item) for item in payload.get(key) or [])
    return _dedupe(values)


def _dedupe(items: list[str]) -> list[str]:
    seen: set[str] = set()
    output: list[str] = []
    for item in items:
        if item in seen:
            continue
        seen.add(item)
        output.append(item)
    return output


def _normalize_base_url(value: str) -> str:
    return (value.strip() or DEFAULT_BACKEND_URL).rstrip("/")


def _now_iso() -> str:
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat()


def _parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Summarize public 00631L backend maintenance status.",
    )
    parser.add_argument(
        "--base-url",
        default=os.getenv("PUBLIC_BACKEND_URL")
        or os.getenv("00631L_PUBLIC_BACKEND_URL")
        or DEFAULT_BACKEND_URL,
    )
    parser.add_argument("--timeout-seconds", type=int, default=30)
    parser.add_argument("--min-price-history-rows", type=int, default=2800)
    parser.add_argument("--min-etf-ready-count", type=int, default=200)
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--soft-fail", action="store_true")
    return parser.parse_args()


def main() -> int:
    args = _parse_args()
    payload = run_public_maintenance_status(
        base_url=args.base_url,
        timeout_seconds=max(1, args.timeout_seconds),
        min_price_history_rows=max(1, args.min_price_history_rows),
        min_etf_ready_count=max(1, args.min_etf_ready_count),
        dry_run=args.dry_run,
    )
    print(json.dumps(payload, ensure_ascii=True, indent=2, sort_keys=True))
    summary = payload.get("summary") if isinstance(payload.get("summary"), dict) else {}
    print(
        "[summary] "
        f"overallStatus={payload['overallStatus']} "
        f"warnings={payload['warningCount']} "
        f"failures={payload['failureCount']} "
        f"publicTag={summary.get('publicReleaseTag') or 'unknown'} "
        f"etfReady={summary.get('publicEtfReadyCount') or 0} "
        f"nextOffset={summary.get('catalogBatchNextOffset') if summary.get('catalogBatchNextOffset') is not None else 'none'}"
    )
    return 0 if args.soft_fail or payload["overallStatus"] != "FAIL" else 1


if __name__ == "__main__":
    raise SystemExit(main())
