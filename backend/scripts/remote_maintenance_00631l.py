from __future__ import annotations

import argparse
import json
import os
import sys
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
]


RequestFn = Callable[[str, MaintenanceEndpoint, int], dict[str, Any]]


def run_remote_maintenance(
    *,
    base_url: str,
    mode: str,
    timeout_seconds: int = 120,
    dry_run: bool = False,
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

    request = requester or _request_json
    steps = []
    for endpoint in selected:
        try:
            response = request(normalized_base_url, endpoint, timeout_seconds)
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
    return {
        "sourceStatus": payload.get("sourceStatus"),
        "dataTime": payload.get("dataTime"),
        "sourceUpdatedAt": payload.get("sourceUpdatedAt"),
    }


def _request_json(
    base_url: str,
    endpoint: MaintenanceEndpoint,
    timeout_seconds: int,
) -> dict[str, Any]:
    if endpoint.name == "history_update":
        return _request_history_update(base_url, timeout_seconds)
    return _request_once(base_url, endpoint.path, endpoint.method, timeout_seconds)


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


def _request_history_update(base_url: str, timeout_seconds: int) -> dict[str, Any]:
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

    final_status = _request_once(
        base_url,
        "/api/etf/00631l/history/status",
        "GET",
        timeout_seconds,
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
            "rowCount": final_payload.get("rowCount"),
            "coverageStart": final_payload.get("coverageStart"),
            "coverageEnd": final_payload.get("coverageEnd"),
            "isCompleteFromListing": final_payload.get("isCompleteFromListing"),
            "errorMessage": error_message,
        },
    }


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
    return parser.parse_args()


def main() -> int:
    args = _parse_args()
    payload = run_remote_maintenance(
        base_url=args.base_url,
        mode=args.mode,
        timeout_seconds=max(1, args.timeout_seconds),
        dry_run=args.dry_run,
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
