from __future__ import annotations

import argparse
import json
import os
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
from dataclasses import dataclass
from datetime import date, datetime, timedelta, timezone
from typing import Any, Callable


DEFAULT_BACKEND_URL = "https://longterm-stock-research-assistant.onrender.com"
LISTING_DATE = date(2014, 10, 31)


@dataclass(frozen=True)
class MaintenanceEndpoint:
    name: str
    method: str
    path: str
    mode: str
    description: str


ENDPOINTS = [
    MaintenanceEndpoint(
        name="health",
        method="GET",
        path="/health",
        mode="intraday",
        description="backend health and deployment metadata",
    ),
    MaintenanceEndpoint(
        name="ready",
        method="GET",
        path="/ready",
        mode="intraday",
        description="backend readiness, CORS, persistence, and live-source checks",
    ),
    MaintenanceEndpoint(
        name="holdings",
        method="GET",
        path="/api/etf/00631l/holdings",
        mode="daily",
        description="official Yuanta daily holdings snapshot",
    ),
    MaintenanceEndpoint(
        name="intraday_nav",
        method="GET",
        path="/api/etf/00631l/intraday-nav",
        mode="intraday",
        description="TWSE intraday NAV and premium/discount snapshot",
    ),
    MaintenanceEndpoint(
        name="operations_status",
        method="GET",
        path="/api/etf/00631l/operations/status",
        mode="intraday",
        description="frontend operations status payload",
    ),
    MaintenanceEndpoint(
        name="analysis_summary",
        method="GET",
        path="/api/etf/00631l/analysis/summary",
        mode="intraday",
        description="rule-based AI data-status summary",
    ),
    MaintenanceEndpoint(
        name="history_update",
        method="POST",
        path="/api/etf/00631l/history/update",
        mode="daily",
        description="official TWSE price history update",
    ),
    MaintenanceEndpoint(
        name="history_status",
        method="GET",
        path="/api/etf/00631l/history/status",
        mode="daily",
        description="price history coverage and row count",
    ),
    MaintenanceEndpoint(
        name="history_performance",
        method="GET",
        path="/api/etf/00631l/history/performance",
        mode="daily",
        description="price history performance statistics",
    ),
    MaintenanceEndpoint(
        name="etf_history_update",
        method="POST",
        path="/api/etf/history/update",
        mode="daily",
        description="selected ETF basket price history update",
    ),
    MaintenanceEndpoint(
        name="etf_history_status",
        method="GET",
        path="/api/etf/history/status",
        mode="daily",
        description="multi-ETF price history readiness index",
    ),
]


RequestFn = Callable[[str, MaintenanceEndpoint, int], dict[str, Any]]
SleepFn = Callable[[float], None]

TRANSIENT_HTTP_STATUSES = {429, 500, 502, 503, 504}
NON_CRITICAL_GET_ENDPOINTS = {"operations_status", "analysis_summary"}


def run_remote_maintenance(
    *,
    base_url: str,
    mode: str,
    timeout_seconds: int = 120,
    dry_run: bool = False,
    etf_from_catalog: bool = False,
    etf_limit: int = 0,
    etf_offset: int = 0,
    retry_count: int = 1,
    retry_delay_seconds: float = 2.0,
    sleep_fn: SleepFn = time.sleep,
    requester: RequestFn | None = None,
) -> dict[str, Any]:
    normalized_base_url = _normalize_base_url(base_url)
    selected = _selected_endpoints(mode)
    checked_at = _now_iso()
    if dry_run:
        steps = [
            {
                "name": endpoint.name,
                "method": endpoint.method,
                "path": endpoint.path,
                "mode": endpoint.mode,
                "status": "PASS",
                "message": "planned",
                "description": endpoint.description,
            }
            for endpoint in selected
        ]
        return _result_payload(
            base_url=normalized_base_url,
            mode=mode,
            checked_at=checked_at,
            steps=steps,
            dry_run=True,
        )

    request = requester or (
        lambda base, endpoint, timeout: _request_json(
            base,
            endpoint,
            timeout,
            etf_from_catalog=etf_from_catalog,
            etf_limit=etf_limit,
            etf_offset=etf_offset,
            retry_count=retry_count,
            retry_delay_seconds=retry_delay_seconds,
            sleep_fn=sleep_fn,
        )
    )
    steps = []
    for endpoint in selected:
        try:
            response = _request_with_retries(
                request,
                normalized_base_url,
                endpoint,
                timeout_seconds,
                retry_count=max(0, retry_count),
                retry_delay_seconds=max(0.0, retry_delay_seconds),
                sleep_fn=sleep_fn,
            )
            steps.append(_assess_response(endpoint, response))
        except Exception as error:  # noqa: BLE001 - operational script should summarize all failures.
            steps.append(
                {
                    "name": endpoint.name,
                    "method": endpoint.method,
                    "path": endpoint.path,
                    "mode": endpoint.mode,
                    "status": "FAIL",
                    "message": str(error),
                    "description": endpoint.description,
                    "httpStatus": None,
                }
            )

    return _result_payload(
        base_url=normalized_base_url,
        mode=mode,
        checked_at=checked_at,
        steps=steps,
        dry_run=False,
    )


def _result_payload(
    *,
    base_url: str,
    mode: str,
    checked_at: str,
    steps: list[dict[str, Any]],
    dry_run: bool,
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
    overall_status = "FAIL" if failures else "WARN" if warnings else "PASS"
    return {
        "sourceContract": "00631l_remote_backend_maintenance",
        "checkedAt": checked_at,
        "baseUrl": base_url,
        "mode": mode,
        "dryRun": dry_run,
        "overallStatus": overall_status,
        "failures": failures,
        "warnings": warnings,
        "steps": steps,
        "nextAction": _next_action(overall_status, dry_run),
    }


def _assess_response(
    endpoint: MaintenanceEndpoint,
    response: dict[str, Any],
) -> dict[str, Any]:
    http_status = int(response.get("httpStatus") or 0)
    payload = response.get("payload") if isinstance(response.get("payload"), dict) else {}
    failures: list[str] = []
    warnings: list[str] = []

    if http_status < 200 or http_status >= 300:
        if endpoint.name in NON_CRITICAL_GET_ENDPOINTS and http_status in TRANSIENT_HTTP_STATUSES:
            warnings.append(
                f"transient HTTP {http_status}; read-only status can be retried"
            )
        else:
            failures.append(f"HTTP {http_status}")

    if endpoint.name == "ready":
        ready_status = str(payload.get("overallStatus") or "")
        if ready_status == "FAIL":
            failures.extend(str(item) for item in payload.get("failures") or ["readiness failed"])
        elif ready_status == "WARN":
            warnings.extend(str(item) for item in payload.get("warnings") or ["readiness warning"])
    elif endpoint.name == "intraday_nav":
        source_status = str(payload.get("sourceStatus") or "")
        if source_status in {"unavailable", "error"}:
            warnings.append("intraday NAV is unavailable; check source time and backend settings")
        elif payload.get("isStale") is True:
            warnings.append("intraday NAV payload is stale")
    elif endpoint.name == "history_status":
        row_count = int(payload.get("rowCount") or 0)
        if row_count < 2:
            warnings.append("price history has fewer than 2 rows")
        if payload.get("isStale") is True:
            warnings.append("price history status is stale")
    elif endpoint.name == "history_update":
        source_status = str(payload.get("sourceStatus") or "")
        if source_status in {"unavailable", "error"}:
            warnings.append("price history update did not return official data")
        post_check_status = int(payload.get("postCheckHttpStatus") or 0)
        if post_check_status in TRANSIENT_HTTP_STATUSES:
            warnings.append(
                f"price history post-check returned transient HTTP {post_check_status}"
            )
    elif endpoint.name == "etf_history_update":
        source_status = str(payload.get("sourceStatus") or "")
        if source_status in {"unavailable", "error"}:
            warnings.append("ETF history update did not return usable data")
        post_check_status = int(payload.get("postCheckHttpStatus") or 0)
        if post_check_status in TRANSIENT_HTTP_STATUSES:
            warnings.append(
                f"ETF history post-check returned transient HTTP {post_check_status}"
            )
        if int(payload.get("readyCount") or 0) < 1:
            warnings.append("ETF history update has no ready symbols")
        if int(payload.get("validationFailureCount") or 0) > 0:
            warnings.append("ETF history update has validation failures")
    elif endpoint.name == "etf_history_status":
        if int(payload.get("readyCount") or 0) < 1:
            warnings.append("ETF history index has no ready symbols")
        if int(payload.get("validationFailureCount") or 0) > 0:
            warnings.append("ETF history index has validation failures")
        source_status = str(payload.get("sourceStatus") or "")
        if source_status in {"unavailable", "error"}:
            warnings.append("ETF history index sourceStatus is unavailable")
    elif endpoint.name == "holdings":
        source_status = str(payload.get("sourceStatus") or "")
        if source_status in {"unavailable", "error"}:
            warnings.append(
                "official holdings are unavailable; check Yuanta source status"
            )
    else:
        source_status = str(payload.get("sourceStatus") or "")
        if source_status == "error":
            warnings.append("payload sourceStatus is error")

    status = "FAIL" if failures else "WARN" if warnings else "PASS"
    message = "; ".join([*failures, *warnings]) if status != "PASS" else "ok"
    summary = _payload_summary(endpoint.name, payload)
    return {
        "name": endpoint.name,
        "method": endpoint.method,
        "path": endpoint.path,
        "mode": endpoint.mode,
        "status": status,
        "message": message,
        "description": endpoint.description,
        "httpStatus": http_status,
        "summary": summary,
    }


def _payload_summary(name: str, payload: dict[str, Any]) -> dict[str, Any]:
    if name == "health":
        return {
            "appVersion": payload.get("appVersion"),
            "publicApiBaseUrl": payload.get("publicApiBaseUrl"),
        }
    if name == "ready":
        return {
            "overallStatus": payload.get("overallStatus"),
            "failureCount": len(payload.get("failures") or []),
            "warningCount": len(payload.get("warnings") or []),
        }
    if name == "intraday_nav":
        return {
            "sourceStatus": payload.get("sourceStatus"),
            "sourceContract": payload.get("sourceContract"),
            "dataTime": payload.get("dataTime"),
            "premiumDiscountPct": payload.get("premiumDiscountPct")
            or payload.get("estimatedPremiumDiscountPct"),
        }
    if name == "holdings":
        return {
            "sourceStatus": payload.get("sourceStatus"),
            "tradeDate": payload.get("tradeDate"),
            "sourceUpdatedAt": payload.get("sourceUpdatedAt"),
        }
    if name == "history_update":
        return {
            "sourceStatus": payload.get("sourceStatus"),
            "savedRows": payload.get("savedRows"),
            "coverageStart": payload.get("coverageStart"),
            "coverageEnd": payload.get("coverageEnd"),
            "postCheckHttpStatus": payload.get("postCheckHttpStatus"),
            "postCheckRetryAttempts": payload.get("postCheckRetryAttempts"),
        }
    if name == "history_status":
        return {
            "sourceStatus": payload.get("sourceStatus"),
            "rowCount": payload.get("rowCount"),
            "coverageStart": payload.get("coverageStart"),
            "coverageEnd": payload.get("coverageEnd"),
        }
    if name == "history_performance":
        return {
            "sourceStatus": payload.get("sourceStatus"),
            "rowCount": payload.get("rowCount"),
            "coverageStart": payload.get("coverageStart"),
            "coverageEnd": payload.get("coverageEnd"),
        }
    if name == "etf_history_update":
        return {
            "sourceStatus": payload.get("sourceStatus"),
            "readyCount": payload.get("readyCount"),
            "validationFailureCount": payload.get("validationFailureCount"),
            "validationWarningCount": payload.get("validationWarningCount"),
            "sourceUpdatedAt": payload.get("sourceUpdatedAt"),
            "dataTime": payload.get("dataTime"),
            "updateHttpStatus": payload.get("updateHttpStatus"),
            "postCheckHttpStatus": payload.get("postCheckHttpStatus"),
            "postCheckRetryAttempts": payload.get("postCheckRetryAttempts"),
        }
    if name == "etf_history_status":
        return {
            "sourceStatus": payload.get("sourceStatus"),
            "readyCount": payload.get("readyCount"),
            "rowCount": payload.get("rowCount"),
            "coverageTierCounts": payload.get("coverageTierCounts"),
            "validationFailureCount": payload.get("validationFailureCount"),
            "validationWarningCount": payload.get("validationWarningCount"),
            "sourceUpdatedAt": payload.get("sourceUpdatedAt"),
        }
    return {
        "sourceStatus": payload.get("sourceStatus"),
        "dataTime": payload.get("dataTime"),
        "sourceUpdatedAt": payload.get("sourceUpdatedAt"),
    }


def _request_json(
    base_url: str,
    endpoint: MaintenanceEndpoint,
    timeout_seconds: int,
    *,
    etf_from_catalog: bool = False,
    etf_limit: int = 0,
    etf_offset: int = 0,
    retry_count: int = 1,
    retry_delay_seconds: float = 2.0,
    sleep_fn: SleepFn = time.sleep,
) -> dict[str, Any]:
    if endpoint.name == "history_update":
        return _request_history_update(
            base_url,
            timeout_seconds,
            retry_count=retry_count,
            retry_delay_seconds=retry_delay_seconds,
            sleep_fn=sleep_fn,
        )
    if endpoint.name == "etf_history_update":
        return _request_etf_history_update(
            base_url,
            timeout_seconds,
            from_catalog=etf_from_catalog,
            limit=etf_limit,
            offset=etf_offset,
            retry_count=retry_count,
            retry_delay_seconds=retry_delay_seconds,
            sleep_fn=sleep_fn,
        )
    return _request_once(base_url, endpoint.path, endpoint.method, timeout_seconds)


def _request_with_retries(
    request: RequestFn,
    base_url: str,
    endpoint: MaintenanceEndpoint,
    timeout_seconds: int,
    *,
    retry_count: int,
    retry_delay_seconds: float,
    sleep_fn: SleepFn,
) -> dict[str, Any]:
    attempts = max(1, retry_count + 1) if endpoint.method == "GET" else 1
    response: dict[str, Any] | None = None
    for attempt in range(attempts):
        response = request(base_url, endpoint, timeout_seconds)
        http_status = int(response.get("httpStatus") or 0)
        if http_status not in TRANSIENT_HTTP_STATUSES or attempt == attempts - 1:
            if attempt > 0:
                response = dict(response)
                response["retryAttempts"] = attempt
            return response
        sleep_fn(retry_delay_seconds)
    return response or {"httpStatus": None, "payload": {}}


def _request_once_with_retries(
    base_url: str,
    path: str,
    method: str,
    timeout_seconds: int,
    *,
    retry_count: int,
    retry_delay_seconds: float,
    sleep_fn: SleepFn,
) -> dict[str, Any]:
    attempts = max(1, retry_count + 1) if method == "GET" else 1
    response: dict[str, Any] | None = None
    for attempt in range(attempts):
        response = _request_once(base_url, path, method, timeout_seconds)
        http_status = int(response.get("httpStatus") or 0)
        if http_status not in TRANSIENT_HTTP_STATUSES or attempt == attempts - 1:
            if attempt > 0:
                response = dict(response)
                response["retryAttempts"] = attempt
            return response
        sleep_fn(retry_delay_seconds)
    return response or {"httpStatus": None, "payload": {}}


def _request_once(
    base_url: str,
    path: str,
    method: str,
    timeout_seconds: int,
) -> dict[str, Any]:
    url = f"{base_url}{path}"
    data = b"{}" if method == "POST" else None
    request = urllib.request.Request(
        url,
        data=data,
        method=method,
        headers={
            "Accept": "application/json",
            "Content-Type": "application/json",
            "User-Agent": "00631l-remote-maintenance/1.0",
        },
    )
    try:
        with urllib.request.urlopen(request, timeout=timeout_seconds) as response:
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


def _request_history_update(
    base_url: str,
    timeout_seconds: int,
    *,
    retry_count: int = 1,
    retry_delay_seconds: float = 2.0,
    sleep_fn: SleepFn = time.sleep,
) -> dict[str, Any]:
    today = datetime.now(timezone.utc).date()
    status_response = _request_once(
        base_url,
        "/api/etf/00631l/history/status",
        "GET",
        timeout_seconds,
    )
    status_payload = (
        status_response.get("payload")
        if isinstance(status_response.get("payload"), dict)
        else {}
    )
    ranges = _history_update_ranges(status_payload, today=today)
    failures: list[str] = []
    warnings: list[str] = []
    total_saved = 0
    chunks: list[dict[str, Any]] = []
    http_status = 200

    for start, end in ranges:
        query = urllib.parse.urlencode(
            {"startDate": start.isoformat(), "endDate": end.isoformat()}
        )
        response = _request_once(
            base_url,
            f"/api/etf/00631l/history/update?{query}",
            "POST",
            timeout_seconds,
        )
        payload = response.get("payload") if isinstance(response.get("payload"), dict) else {}
        chunk_status = int(response.get("httpStatus") or 0)
        http_status = chunk_status if chunk_status >= 400 else http_status
        saved_rows = int(payload.get("savedRows") or 0)
        total_saved += saved_rows
        chunk_summary = {
            "startDate": start.isoformat(),
            "endDate": end.isoformat(),
            "httpStatus": chunk_status,
            "sourceStatus": payload.get("sourceStatus"),
            "savedRows": saved_rows,
            "errorMessage": payload.get("errorMessage"),
        }
        chunks.append(chunk_summary)
        if chunk_status < 200 or chunk_status >= 300:
            failures.append(f"{start.isoformat()}..{end.isoformat()}: HTTP {chunk_status}")
        elif payload.get("sourceStatus") in {"error", "unavailable"}:
            warnings.append(
                f"{start.isoformat()}..{end.isoformat()}: sourceStatus={payload.get('sourceStatus')}"
            )

    final_status = _request_once_with_retries(
        base_url,
        "/api/etf/00631l/history/status",
        "GET",
        timeout_seconds,
        retry_count=retry_count,
        retry_delay_seconds=retry_delay_seconds,
        sleep_fn=sleep_fn,
    )
    final_payload = (
        final_status.get("payload")
        if isinstance(final_status.get("payload"), dict)
        else {}
    )
    source_status = "error" if failures else "official"
    error_message = "; ".join(failures) if failures else None
    return {
        "httpStatus": http_status,
        "payload": {
            "sourceStatus": source_status,
            "sourceContract": "00631l_remote_chunked_history_update",
            "savedRows": total_saved,
            "chunkCount": len(chunks),
            "chunks": chunks,
            "warnings": warnings,
            "postCheckHttpStatus": final_status.get("httpStatus"),
            "postCheckRetryAttempts": final_status.get("retryAttempts", 0),
            "rowCount": final_payload.get("rowCount"),
            "coverageStart": final_payload.get("coverageStart"),
            "coverageEnd": final_payload.get("coverageEnd"),
            "isCompleteFromListing": final_payload.get("isCompleteFromListing"),
            "errorMessage": error_message,
        },
    }


def _request_etf_history_update(
    base_url: str,
    timeout_seconds: int,
    *,
    from_catalog: bool = False,
    limit: int = 0,
    offset: int = 0,
    retry_count: int = 1,
    retry_delay_seconds: float = 2.0,
    sleep_fn: SleepFn = time.sleep,
) -> dict[str, Any]:
    query = urllib.parse.urlencode(
        {
            key: value
            for key, value in {
                "fromCatalog": "true" if from_catalog else "",
                "limit": max(0, int(limit or 0)) if from_catalog else 0,
                "offset": max(0, int(offset or 0)) if from_catalog else 0,
            }.items()
            if value not in {"", 0}
        }
    )
    update_path = "/api/etf/history/update"
    if query:
        update_path = f"{update_path}?{query}"
    update_response = _request_once(
        base_url,
        update_path,
        "POST",
        timeout_seconds,
    )
    update_payload = (
        update_response.get("payload")
        if isinstance(update_response.get("payload"), dict)
        else {}
    )
    status_response = _request_once_with_retries(
        base_url,
        "/api/etf/history/status",
        "GET",
        timeout_seconds,
        retry_count=retry_count,
        retry_delay_seconds=retry_delay_seconds,
        sleep_fn=sleep_fn,
    )
    status_payload = (
        status_response.get("payload")
        if isinstance(status_response.get("payload"), dict)
        else {}
    )
    update_status = int(update_response.get("httpStatus") or 0)
    status_status = int(status_response.get("httpStatus") or 0)
    http_status = update_status
    if update_status < 200 or update_status >= 300:
        http_status = update_status
    payload = {
        "sourceStatus": update_payload.get("sourceStatus"),
        "sourceContract": "00631l_remote_etf_history_update",
        "sourceUrl": update_payload.get("sourceUrl"),
        "fetchedAt": update_payload.get("fetchedAt"),
        "updateHttpStatus": update_status,
        "postCheckHttpStatus": status_status,
        "postCheckRetryAttempts": status_response.get("retryAttempts", 0),
        "sourceUpdatedAt": status_payload.get("sourceUpdatedAt")
        or update_payload.get("sourceUpdatedAt"),
        "dataTime": status_payload.get("dataTime") or update_payload.get("dataTime"),
        "requestedCodes": update_payload.get("requestedCodes"),
        "readyCount": status_payload.get("readyCount")
        if status_payload.get("readyCount") is not None
        else update_payload.get("readyCount"),
        "rowCount": status_payload.get("rowCount"),
        "coverageTierCounts": status_payload.get("coverageTierCounts"),
        "validationFailureCount": status_payload.get("validationFailureCount")
        if status_payload.get("validationFailureCount") is not None
        else update_payload.get("validationFailureCount"),
        "validationWarningCount": status_payload.get("validationWarningCount")
        if status_payload.get("validationWarningCount") is not None
        else update_payload.get("validationWarningCount"),
        "updateErrorMessage": update_payload.get("errorMessage"),
        "statusErrorMessage": status_payload.get("errorMessage"),
    }
    errors = [
        str(value)
        for value in (payload["updateErrorMessage"], payload["statusErrorMessage"])
        if value
    ]
    payload["errorMessage"] = "; ".join(errors) if errors else None
    return {"httpStatus": http_status, "payload": payload}


def _history_update_ranges(
    status_payload: dict[str, Any],
    *,
    today: date,
) -> list[tuple[date, date]]:
    row_count = int(status_payload.get("rowCount") or 0)
    complete_from_listing = status_payload.get("isCompleteFromListing") is True
    coverage_end = _parse_iso_date(status_payload.get("coverageEnd"))
    if row_count >= 2 and complete_from_listing and coverage_end is not None:
        start = max(LISTING_DATE, coverage_end - timedelta(days=45))
        return [(start, today)]

    ranges: list[tuple[date, date]] = []
    start = LISTING_DATE
    while start <= today:
        end = date(start.year, 12, 31)
        if end > today:
            end = today
        ranges.append((start, end))
        start = date(start.year + 1, 1, 1)
    return ranges


def _parse_iso_date(value: Any) -> date | None:
    if not value:
        return None
    try:
        return datetime.strptime(str(value), "%Y-%m-%d").date()
    except ValueError:
        return None


def _selected_endpoints(mode: str) -> list[MaintenanceEndpoint]:
    normalized = mode.lower().strip()
    if normalized == "all":
        return ENDPOINTS
    if normalized not in {"intraday", "daily"}:
        raise ValueError("mode must be intraday, daily, or all")
    return [
        endpoint
        for endpoint in ENDPOINTS
        if endpoint.mode == normalized or endpoint.name in {"health", "ready"}
    ]


def _normalize_base_url(value: str) -> str:
    normalized = value.strip() or DEFAULT_BACKEND_URL
    return normalized.rstrip("/")


def _next_action(status: str, dry_run: bool) -> str:
    if dry_run:
        return "Dry run only; schedule or run without --dry-run to contact the public backend."
    if status == "FAIL":
        return "Check backend URL, Render service status, and /ready output before rerunning."
    if status == "WARN":
        return "Review warnings; off-hours intraday freshness warnings can be acceptable."
    return "Remote backend maintenance completed."


def _now_iso() -> str:
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat()


def _parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Run 00631L public backend maintenance checks.",
    )
    parser.add_argument(
        "--base-url",
        default=os.getenv("PUBLIC_BACKEND_URL") or os.getenv("00631L_PUBLIC_BACKEND_URL") or DEFAULT_BACKEND_URL,
        help="Public backend base URL.",
    )
    parser.add_argument(
        "--mode",
        choices=["intraday", "daily", "all"],
        default="all",
        help="Maintenance scope.",
    )
    parser.add_argument(
        "--timeout-seconds",
        type=int,
        default=120,
        help="Per-request timeout.",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Print planned endpoint calls without contacting the backend.",
    )
    parser.add_argument(
        "--soft-fail",
        action="store_true",
        help="Return exit code 0 even when the summary is FAIL.",
    )
    parser.add_argument(
        "--etf-from-catalog",
        action="store_true",
        help="Update ETF history from cached ETF catalog instead of the default basket.",
    )
    parser.add_argument(
        "--etf-limit",
        type=int,
        default=0,
        help="Catalog batch size for --etf-from-catalog. Backend defaults to 50 when omitted.",
    )
    parser.add_argument(
        "--etf-offset",
        type=int,
        default=0,
        help="Catalog batch offset for --etf-from-catalog.",
    )
    parser.add_argument(
        "--retry-count",
        type=int,
        default=1,
        help="Retry count for transient read-only HTTP failures.",
    )
    parser.add_argument(
        "--retry-delay-seconds",
        type=float,
        default=2.0,
        help="Delay between transient read-only HTTP retries.",
    )
    return parser.parse_args()


def main() -> int:
    args = _parse_args()
    payload = run_remote_maintenance(
        base_url=args.base_url,
        mode=args.mode,
        timeout_seconds=max(1, args.timeout_seconds),
        dry_run=args.dry_run,
        etf_from_catalog=args.etf_from_catalog,
        etf_limit=max(0, args.etf_limit),
        etf_offset=max(0, args.etf_offset),
        retry_count=max(0, args.retry_count),
        retry_delay_seconds=max(0.0, args.retry_delay_seconds),
    )
    print(json.dumps(payload, ensure_ascii=True, indent=2, sort_keys=True))
    print(
        "[summary] "
        f"overallStatus={payload['overallStatus']} "
        f"warnings={len(payload['warnings'])} "
        f"failures={len(payload['failures'])}"
    )
    return 0 if args.soft_fail or payload["overallStatus"] != "FAIL" else 1


if __name__ == "__main__":
    raise SystemExit(main())
