from __future__ import annotations

import argparse
import json
import os
import sys
import urllib.error
import urllib.request
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

FRESH_PUBLIC_MARKER_SECONDS = 15 * 60


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
    readiness_probe = _run_public_readiness_probe(
        base_url=base_url,
        timeout_seconds=max(1, timeout_seconds),
    )
    return build_public_maintenance_status(
        deploy_drift=deploy_drift,
        public_status=public_status,
        freshness=freshness,
        readiness_probe=readiness_probe,
        catalog_batch_state=load_catalog_batch_state(DEFAULT_CATALOG_BATCH_STATE_PATH),
        checked_at=checked_at,
    )


def build_public_maintenance_status(
    *,
    deploy_drift: dict[str, Any],
    public_status: dict[str, Any],
    freshness: dict[str, Any],
    readiness_probe: dict[str, Any] | None = None,
    catalog_batch_state: dict[str, Any] | None = None,
    checked_at: str,
) -> dict[str, Any]:
    steps = [
        _step_from_payload("deploy_drift", deploy_drift),
        _step_from_payload("public_backend_status", public_status),
        _step_from_payload("public_freshness", freshness),
    ]
    if readiness_probe is not None:
        steps.append(_step_from_payload("public_readiness_probe", readiness_probe))
    warnings = _collect("warnings", deploy_drift, public_status, freshness, readiness_probe)
    failures = _collect("failures", deploy_drift, public_status, freshness, readiness_probe)
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
    marker_newly_created = bool(public_summary.get("persistenceMarkerNewlyCreated"))
    marker_fresh = _has_fresh_public_marker(public_summary)
    has_persistence_warning = _has_public_persistence_warning(public_status)
    has_readiness_blocker = _has_public_readiness_blocker(
        public_status,
    ) or _has_readiness_probe_blocker(readiness_probe)
    catalog_regression_warning = (
        [
            "Public ETF ready count regressed from the last batch state; "
            "check Render deploy persistence before running more batches."
        ]
        if ready_regression > 0
        else []
    )
    marker_warning = (
        [
            "Public persistence marker was newly created; verify that the backend "
            "is using the intended persistent volume before long batch runs."
        ]
        if marker_newly_created
        else []
    )
    fresh_marker_warning = (
        [
            "Public persistence marker is fresh while ETF history ready count is "
            "below the required floor; verify the persistent volume before running "
            "catalog batches."
        ]
        if marker_fresh
        else []
    )
    block_catalog_batches = (
        has_persistence_warning
        or has_readiness_blocker
        or ready_regression > 0
        or marker_fresh
    )
    action_items = _filter_catalog_batch_actions(
        _dedupe(
            [
                *list(deploy_drift.get("actionItems") or []),
                *list(public_status.get("actionItems") or []),
                *list(freshness.get("actionItems") or []),
                *list((readiness_probe or {}).get("actionItems") or []),
                *_persistence_action_items(has_persistence_warning),
                *_readiness_action_items(has_readiness_blocker),
                *_persistence_marker_action_items(marker_newly_created),
                *_fresh_persistence_marker_action_items(marker_fresh),
                *_catalog_batch_regression_action_items(ready_regression),
                *(
                    []
                    if block_catalog_batches
                    else _catalog_batch_action_items(
                        catalog_batch_state,
                        public_ready_count=public_summary.get("etfHistoryReadyCount"),
                        ready_lag=freshness_summary.get("publicEtfReadyLagVsStatic"),
                    )
                ),
            ]
        ),
        block_catalog_batches=block_catalog_batches,
    )
    warnings = _dedupe(
        [*warnings, *catalog_regression_warning, *marker_warning, *fresh_marker_warning]
    )
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
            "publicPersistenceMarkerCreatedAt": public_summary.get(
                "persistenceMarkerCreatedAt"
            ),
            "publicPersistenceMarkerAgeSeconds": public_summary.get(
                "persistenceMarkerAgeSeconds"
            ),
            "publicPersistenceMarkerNewlyCreated": public_summary.get(
                "persistenceMarkerNewlyCreated"
            ),
            "publicPersistenceMarkerFresh": marker_fresh,
            "publicPersistenceMarkerFreshThresholdSeconds": FRESH_PUBLIC_MARKER_SECONDS,
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


def _has_fresh_public_marker(public_summary: dict[str, Any]) -> bool:
    if bool(public_summary.get("persistenceMarkerNewlyCreated")):
        return _public_ready_below_target(public_summary)
    try:
        age_seconds = int(public_summary.get("persistenceMarkerAgeSeconds"))
    except (TypeError, ValueError):
        return False
    if age_seconds < 0 or age_seconds >= FRESH_PUBLIC_MARKER_SECONDS:
        return False
    return _public_ready_below_target(public_summary)


def _public_ready_below_target(public_summary: dict[str, Any]) -> bool:
    try:
        ready_count = int(public_summary.get("etfHistoryReadyCount"))
        min_ready_count = int(public_summary.get("minEtfReadyCount"))
    except (TypeError, ValueError):
        return False
    return ready_count < max(1, min_ready_count)


def _has_public_readiness_blocker(public_status: dict[str, Any]) -> bool:
    summary = public_status.get("summary")
    if isinstance(summary, dict) and str(summary.get("readiness") or "").upper() == "FAIL":
        return True
    for step in public_status.get("steps") or []:
        if not isinstance(step, dict) or step.get("name") != "ready":
            continue
        if str(step.get("status") or "").upper() in {"WARN", "FAIL"}:
            return True
        step_summary = step.get("summary")
        if isinstance(step_summary, dict) and str(step_summary.get("overallStatus") or "").upper() == "FAIL":
            return True
    return False


def _has_readiness_probe_blocker(readiness_probe: dict[str, Any] | None) -> bool:
    if not readiness_probe:
        return False
    return str(readiness_probe.get("overallStatus") or "").upper() in {"WARN", "FAIL"}


def _persistence_action_items(has_persistence_warning: bool) -> list[str]:
    if not has_persistence_warning:
        return []
    return [
        "Fix public backend persistent data volume before running ETF catalog batches."
    ]


def _persistence_marker_action_items(marker_newly_created: bool) -> list[str]:
    if not marker_newly_created:
        return []
    return [
        "Recheck public backend status after the next deploy; the persistence marker should keep the same createdAt."
    ]


def _fresh_persistence_marker_action_items(marker_fresh: bool) -> list[str]:
    if not marker_fresh:
        return []
    return [
        "Attach or verify the public backend persistent volume before continuing ETF catalog batches."
    ]


def _readiness_action_items(has_readiness_blocker: bool) -> list[str]:
    if not has_readiness_blocker:
        return []
    return [
        "Fix public backend readiness before running ETF catalog batches."
    ]


def _filter_catalog_batch_actions(
    items: list[str],
    *,
    block_catalog_batches: bool,
) -> list[str]:
    if not block_catalog_batches:
        return items
    return [
        item
        for item in items
        if "00631l_public_etf_catalog_batches" not in item
    ]


def _run_public_readiness_probe(
    *,
    base_url: str,
    timeout_seconds: int,
    sample_count: int = 2,
) -> dict[str, Any]:
    normalized = _normalize_base_url(base_url)
    samples: list[dict[str, Any]] = []
    warnings: list[str] = []
    failures: list[str] = []
    for index in range(max(1, sample_count)):
        sample = _request_ready(normalized, timeout_seconds)
        sample["sampleIndex"] = index
        samples.append(sample)
        if int(sample.get("httpStatus") or 0) < 200 or int(sample.get("httpStatus") or 0) >= 300:
            failures.append(f"ready sample {index}: HTTP {sample.get('httpStatus')}")
            continue
        status = str(sample.get("overallStatus") or "WARN").upper()
        if status == "FAIL":
            warnings.append(f"ready sample {index}: readiness FAIL")
        elif status == "WARN":
            warnings.append(f"ready sample {index}: readiness WARN")
    overall_status = "FAIL" if failures else "WARN" if warnings else "PASS"
    return {
        "sourceContract": "00631l_public_readiness_probe",
        "checkedAt": _now_iso(),
        "overallStatus": overall_status,
        "warningCount": len(warnings),
        "failureCount": len(failures),
        "samples": samples,
        "warnings": warnings,
        "failures": failures,
        "actionItems": _readiness_action_items(overall_status in {"WARN", "FAIL"}),
    }


def _request_ready(base_url: str, timeout_seconds: int) -> dict[str, Any]:
    request = urllib.request.Request(
        f"{base_url}/ready",
        method="GET",
        headers={
            "Accept": "application/json",
            "User-Agent": "00631l-public-readiness-probe/1.0",
        },
    )
    try:
        with urllib.request.urlopen(request, timeout=max(1, timeout_seconds)) as response:
            body = response.read().decode("utf-8", errors="replace")
            payload = json.loads(body) if body.strip() else {}
            return {
                "httpStatus": response.status,
                "overallStatus": payload.get("overallStatus"),
                "failureCount": len(payload.get("failures") or []),
                "warningCount": len(payload.get("warnings") or []),
            }
    except urllib.error.HTTPError as error:
        return {"httpStatus": error.code, "overallStatus": "FAIL"}
    except (OSError, json.JSONDecodeError) as error:
        return {"httpStatus": None, "overallStatus": "FAIL", "errorMessage": str(error)}


def _step_from_payload(name: str, payload: dict[str, Any]) -> dict[str, Any]:
    status = str(payload.get("overallStatus") or "WARN")
    normalized = status if status in {"PASS", "WARN", "FAIL"} else "WARN"
    return {
        "name": name,
        "status": normalized,
        "message": normalized,
    }


def _collect(key: str, *payloads: dict[str, Any] | None) -> list[str]:
    values: list[str] = []
    for payload in payloads:
        if payload is None:
            continue
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
