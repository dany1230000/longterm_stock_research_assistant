from __future__ import annotations

import argparse
import json
import os
import sys
import urllib.error
import urllib.request
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Callable


ROOT = Path(__file__).resolve().parents[2]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from backend.scripts.public_backend_status_00631l import DEFAULT_BACKEND_URL
from backend.scripts.remote_maintenance_00631l import _request_etf_history_update


RequestFn = Callable[[str, str, int], dict[str, Any]]
MaintenanceRunnerFn = Callable[..., dict[str, Any]]


def run_public_etf_catalog_batches(
    *,
    base_url: str,
    batch_size: int = 10,
    max_batches: int = 8,
    start_offset: int = 0,
    timeout_seconds: int = 120,
    retry_count: int = 2,
    retry_delay_seconds: float = 3.0,
    dry_run: bool = False,
    catalog_row_count: int | None = None,
    requester: RequestFn | None = None,
    maintenance_runner: MaintenanceRunnerFn | None = None,
) -> dict[str, Any]:
    normalized_base_url = _normalize_base_url(base_url)
    checked_at = _now_iso()
    limit = max(1, int(batch_size or 10))
    offset = max(0, int(start_offset or 0))
    max_batch_count = max(1, int(max_batches or 1))

    request = requester or _request_json
    if dry_run and catalog_row_count is None:
        planned_offsets = [
            offset + (index * limit) for index in range(max_batch_count)
        ]
        return _payload(
            checked_at=checked_at,
            base_url=normalized_base_url,
            dry_run=True,
            steps=[
                _step(
                    "catalog_status",
                    "PASS",
                    "planned without contacting backend",
                ),
                *[
                    _step("catalog_batch", "PASS", f"planned offset={planned_offset} limit={limit}")
                    for planned_offset in planned_offsets
                ],
            ],
            summary={
                "catalogRowCount": None,
                "catalogSourceStatus": "unknown",
                "plannedOffsets": planned_offsets,
                "plannedBatchCount": len(planned_offsets),
                "finalReadyCount": None,
            },
            action_items=[],
        )

    catalog_status = (
        _catalog_status_from_row_count(catalog_row_count, checked_at)
        if catalog_row_count is not None
        else request(normalized_base_url, "/api/etf/catalog/status", timeout_seconds)
    )
    catalog_payload = (
        catalog_status.get("payload")
        if isinstance(catalog_status.get("payload"), dict)
        else {}
    )
    catalog_rows = int(catalog_payload.get("rowCount") or 0)
    catalog_source_status = str(catalog_payload.get("sourceStatus") or "unavailable")
    planned_offsets = _planned_offsets(
        catalog_rows,
        start_offset=offset,
        batch_size=limit,
        max_batches=max_batch_count,
    )

    if dry_run:
        return _payload(
            checked_at=checked_at,
            base_url=normalized_base_url,
            dry_run=True,
            steps=[
                _step("catalog_status", "PASS", f"catalogRows={catalog_rows}"),
                *[
                    _step("catalog_batch", "PASS", f"planned offset={planned_offset} limit={limit}")
                    for planned_offset in planned_offsets
                ],
            ],
            summary={
                "catalogRowCount": catalog_rows,
                "catalogSourceStatus": catalog_source_status,
                "plannedOffsets": planned_offsets,
                "plannedBatchCount": len(planned_offsets),
                "finalReadyCount": None,
            },
            action_items=[],
        )

    if catalog_rows < 1:
        return _payload(
            checked_at=checked_at,
            base_url=normalized_base_url,
            dry_run=False,
            steps=[
                _step(
                    "catalog_status",
                    "WARN",
                    f"catalog unavailable sourceStatus={catalog_source_status}",
                    http_status=catalog_status.get("httpStatus"),
                )
            ],
            summary={
                "catalogRowCount": catalog_rows,
                "catalogSourceStatus": catalog_source_status,
                "plannedOffsets": [],
                "plannedBatchCount": 0,
                "finalReadyCount": 0,
            },
            action_items=[
                "Check /api/etf/catalog/status or deploy the backend with ETF_CATALOG_SEED_PATH.",
            ],
        )

    initial_status = request(normalized_base_url, "/api/etf/history/status", timeout_seconds)
    initial_payload = (
        initial_status.get("payload")
        if isinstance(initial_status.get("payload"), dict)
        else {}
    )
    initial_ready_count = int(initial_payload.get("readyCount") or 0)

    runner = maintenance_runner or _run_single_batch
    steps = [
        _step(
            "catalog_status",
            "PASS",
            f"catalogRows={catalog_rows} sourceStatus={catalog_source_status}",
            http_status=catalog_status.get("httpStatus"),
        ),
        _step(
            "etf_history_status_initial",
            "PASS",
            f"readyCount={initial_ready_count}",
            http_status=initial_status.get("httpStatus"),
            summary={
                "readyCount": initial_ready_count,
                "rowCount": initial_payload.get("rowCount"),
                "sourceUpdatedAt": initial_payload.get("sourceUpdatedAt"),
            },
        )
    ]
    batch_steps: list[dict[str, Any]] = []
    for planned_offset in planned_offsets:
        batch_result = runner(
            base_url=normalized_base_url,
            offset=planned_offset,
            limit=limit,
            timeout_seconds=timeout_seconds,
            retry_count=retry_count,
            retry_delay_seconds=retry_delay_seconds,
        )
        status = str(batch_result.get("overallStatus") or "WARN")
        batch_steps.append(
            _step(
                "catalog_batch",
                status if status in {"PASS", "WARN", "FAIL"} else "WARN",
                f"offset={planned_offset} limit={limit}",
                summary={
                    "offset": planned_offset,
                    "limit": limit,
                    "warnings": batch_result.get("warnings") or [],
                    "failures": batch_result.get("failures") or [],
                },
            )
        )

    final_status = request(normalized_base_url, "/api/etf/history/status", timeout_seconds)
    final_payload = (
        final_status.get("payload")
        if isinstance(final_status.get("payload"), dict)
        else {}
    )
    final_ready_count = int(final_payload.get("readyCount") or 0)
    final_validation_failures = int(final_payload.get("validationFailureCount") or 0)
    final_step_status = "PASS" if final_validation_failures == 0 else "WARN"
    final_step_message = f"readyCount={final_ready_count}"
    if final_ready_count > initial_ready_count:
        batch_steps = [
            _downgrade_progress_timeout(step)
            for step in batch_steps
        ]
    failed_offsets = _failed_offsets(batch_steps)
    if final_ready_count < initial_ready_count:
        final_step_status = "WARN"
        final_step_message = (
            f"readyCount={final_ready_count}; ready count decreased from initial "
            f"{initial_ready_count}"
        )
    next_offset = (
        failed_offsets[0]
        if failed_offsets
        else _next_offset(planned_offsets, limit, catalog_rows)
    )
    steps.extend(batch_steps)
    steps.append(
        _step(
            "etf_history_status",
            final_step_status,
            final_step_message,
            http_status=final_status.get("httpStatus"),
            summary={
                "readyCount": final_ready_count,
                "rowCount": final_payload.get("rowCount"),
                "validationFailureCount": final_validation_failures,
                "sourceUpdatedAt": final_payload.get("sourceUpdatedAt"),
            },
        )
    )

    return _payload(
        checked_at=checked_at,
        base_url=normalized_base_url,
        dry_run=False,
        steps=steps,
        summary={
            "catalogRowCount": catalog_rows,
            "catalogSourceStatus": catalog_source_status,
            "initialReadyCount": initial_ready_count,
            "plannedOffsets": planned_offsets,
            "plannedBatchCount": len(planned_offsets),
            "nextOffset": next_offset,
            "finalReadyCount": final_ready_count,
            "finalValidationFailureCount": final_validation_failures,
        },
        action_items=_action_items(
            final_ready_count,
            catalog_rows,
            next_offset=next_offset,
            failed_offset=failed_offsets[0] if failed_offsets else None,
        ),
    )


def _run_single_batch(
    *,
    base_url: str,
    offset: int,
    limit: int,
    timeout_seconds: int,
    retry_count: int,
    retry_delay_seconds: float,
) -> dict[str, Any]:
    response = _request_etf_history_update(
        base_url,
        timeout_seconds=timeout_seconds,
        from_catalog=True,
        limit=limit,
        offset=offset,
        retry_count=retry_count,
        retry_delay_seconds=retry_delay_seconds,
    )
    http_status = int(response.get("httpStatus") or 0)
    payload = response.get("payload") if isinstance(response.get("payload"), dict) else {}
    failures: list[str] = []
    warnings: list[str] = []
    if http_status < 200 or http_status >= 300:
        failures.append(f"etf_history_update: HTTP {http_status}")
    if str(payload.get("sourceStatus") or "") in {"unavailable", "error"}:
        warnings.append("etf_history_update: ETF history update did not return usable data")
    if int(payload.get("validationFailureCount") or 0) > 0:
        warnings.append("etf_history_update: validation failures present")
    status = "FAIL" if failures else "WARN" if warnings else "PASS"
    return {
        "overallStatus": status,
        "failures": failures,
        "warnings": warnings,
        "steps": [],
        "summary": {
            "readyCount": payload.get("readyCount"),
            "updateHttpStatus": payload.get("updateHttpStatus"),
            "postCheckHttpStatus": payload.get("postCheckHttpStatus"),
            "postCheckRetryAttempts": payload.get("postCheckRetryAttempts"),
        },
    }


def _payload(
    *,
    checked_at: str,
    base_url: str,
    dry_run: bool,
    steps: list[dict[str, Any]],
    summary: dict[str, Any],
    action_items: list[str],
) -> dict[str, Any]:
    failures = [
        f"{step['name']}: {step['message']}"
        for step in steps
        if step.get("status") == "FAIL"
    ]
    warnings = [
        f"{step['name']}: {step['message']}"
        for step in steps
        if step.get("status") == "WARN"
    ]
    return {
        "sourceContract": "00631l_public_etf_catalog_batch_runner",
        "checkedAt": checked_at,
        "baseUrl": base_url,
        "dryRun": dry_run,
        "overallStatus": "FAIL" if failures else "WARN" if warnings else "PASS",
        "summary": summary,
        "steps": steps,
        "warnings": warnings,
        "failures": failures,
        "actionItems": action_items,
    }


def _request_json(base_url: str, path: str, timeout_seconds: int) -> dict[str, Any]:
    url = f"{base_url}{path}"
    request = urllib.request.Request(
        url,
        method="GET",
        headers={
            "Accept": "application/json",
            "User-Agent": "00631l-public-etf-catalog-batches/1.0",
        },
    )
    try:
        with urllib.request.urlopen(request, timeout=max(1, timeout_seconds)) as response:
            body = response.read().decode("utf-8", errors="replace")
            payload = json.loads(body) if body.strip() else {}
            return {"httpStatus": response.status, "payload": payload}
    except urllib.error.HTTPError as error:
        body = error.read().decode("utf-8", errors="replace")
        try:
            payload = json.loads(body) if body.strip() else {}
        except json.JSONDecodeError:
            payload = {"errorMessage": body[:500]}
        return {"httpStatus": error.code, "payload": payload}


def _catalog_status_from_row_count(row_count: int | None, checked_at: str) -> dict[str, Any]:
    rows = max(0, int(row_count or 0))
    return {
        "httpStatus": 200,
        "payload": {
            "sourceStatus": "static_official" if rows else "unavailable",
            "rowCount": rows,
            "fetchedAt": checked_at,
        },
    }


def _planned_offsets(
    row_count: int,
    *,
    start_offset: int,
    batch_size: int,
    max_batches: int,
) -> list[int]:
    if row_count < 1:
        return []
    offsets: list[int] = []
    current = max(0, start_offset)
    while current < row_count and len(offsets) < max_batches:
        offsets.append(current)
        current += max(1, batch_size)
    return offsets


def _step(
    name: str,
    status: str,
    message: str,
    *,
    http_status: Any = None,
    summary: dict[str, Any] | None = None,
) -> dict[str, Any]:
    return {
        "name": name,
        "status": status,
        "message": message,
        "httpStatus": http_status,
        "summary": summary or {},
    }


def _downgrade_progress_timeout(step: dict[str, Any]) -> dict[str, Any]:
    if step.get("status") != "FAIL":
        return step
    summary = step.get("summary") if isinstance(step.get("summary"), dict) else {}
    failures = " ".join(str(item) for item in summary.get("failures") or [])
    if "timed out" not in failures.lower() and "timeout" not in failures.lower():
        return step
    updated = dict(step)
    updated["status"] = "WARN"
    updated["message"] = f"{step.get('message')}; partial progress observed after timeout"
    return updated


def _next_offset(planned_offsets: list[int], batch_size: int, catalog_rows: int) -> int | None:
    if not planned_offsets:
        return None
    candidate = planned_offsets[-1] + max(1, batch_size)
    return candidate if candidate < catalog_rows else None


def _failed_offsets(batch_steps: list[dict[str, Any]]) -> list[int]:
    offsets: list[int] = []
    for step in batch_steps:
        if step.get("status") != "FAIL":
            continue
        summary = step.get("summary")
        if not isinstance(summary, dict):
            continue
        try:
            offsets.append(int(summary.get("offset")))
        except (TypeError, ValueError):
            continue
    return offsets


def _action_items(
    final_ready_count: int,
    catalog_rows: int,
    *,
    next_offset: int | None,
    failed_offset: int | None = None,
) -> list[str]:
    if catalog_rows > 0 and final_ready_count < catalog_rows:
        if failed_offset is not None:
            return [
                "Retry the failed offset with scripts\\00631l_public_etf_catalog_batches.cmd "
                f"--start-offset {failed_offset}."
            ]
        if next_offset is not None:
            return [
                "Run the next offset with scripts\\00631l_public_etf_catalog_batches.cmd "
                f"--start-offset {next_offset}."
            ]
        return [
            "Run another public ETF catalog batch after checking /api/etf/history/status."
        ]
    return []


def _normalize_base_url(value: str) -> str:
    return (value.strip() or DEFAULT_BACKEND_URL).rstrip("/")


def _now_iso() -> str:
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat()


def _parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Run 00631L public backend ETF catalog history batches.",
    )
    parser.add_argument(
        "--base-url",
        default=os.getenv("PUBLIC_BACKEND_URL")
        or os.getenv("00631L_PUBLIC_BACKEND_URL")
        or DEFAULT_BACKEND_URL,
        help="Public backend base URL.",
    )
    parser.add_argument("--batch-size", type=int, default=10)
    parser.add_argument("--max-batches", type=int, default=8)
    parser.add_argument("--start-offset", type=int, default=0)
    parser.add_argument("--timeout-seconds", type=int, default=120)
    parser.add_argument("--retry-count", type=int, default=2)
    parser.add_argument("--retry-delay-seconds", type=float, default=3.0)
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--soft-fail", action="store_true")
    return parser.parse_args()


def main() -> int:
    args = _parse_args()
    payload = run_public_etf_catalog_batches(
        base_url=args.base_url,
        batch_size=max(1, args.batch_size),
        max_batches=max(1, args.max_batches),
        start_offset=max(0, args.start_offset),
        timeout_seconds=max(1, args.timeout_seconds),
        retry_count=max(0, args.retry_count),
        retry_delay_seconds=max(0.0, args.retry_delay_seconds),
        dry_run=args.dry_run,
    )
    print(json.dumps(payload, ensure_ascii=True, indent=2, sort_keys=True))
    summary = payload.get("summary") if isinstance(payload.get("summary"), dict) else {}
    print(
        "[summary] "
        f"overallStatus={payload['overallStatus']} "
        f"warnings={len(payload['warnings'])} "
        f"failures={len(payload['failures'])} "
        f"catalogRows={summary.get('catalogRowCount', 0)} "
        f"finalReady={summary.get('finalReadyCount', 0)}"
    )
    return 0 if args.soft_fail or payload["overallStatus"] != "FAIL" else 1


if __name__ == "__main__":
    raise SystemExit(main())
