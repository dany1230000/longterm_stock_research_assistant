from __future__ import annotations

import argparse
import json
import os
import urllib.error
import urllib.request
from dataclasses import dataclass
from datetime import datetime, timezone
from typing import Any, Callable


DEFAULT_BACKEND_URL = "https://longterm-stock-research-assistant.onrender.com"


@dataclass(frozen=True)
class PublicStatusEndpoint:
    name: str
    path: str
    description: str


ENDPOINTS = [
    PublicStatusEndpoint("health", "/health", "backend release and health"),
    PublicStatusEndpoint("ready", "/ready", "readiness, CORS, persistence"),
    PublicStatusEndpoint(
        "operations_status",
        "/api/etf/00631l/operations/status",
        "operations status payload",
    ),
    PublicStatusEndpoint(
        "history_status",
        "/api/etf/00631l/history/status",
        "00631L price history status",
    ),
    PublicStatusEndpoint(
        "etf_history_status",
        "/api/etf/history/status",
        "selected ETF basket history status",
    ),
]


RequestFn = Callable[[str, PublicStatusEndpoint, int], dict[str, Any]]


def run_public_backend_status(
    *,
    base_url: str,
    timeout_seconds: int = 30,
    dry_run: bool = False,
    min_price_history_rows: int = 2,
    min_etf_ready_count: int = 1,
    requester: RequestFn | None = None,
) -> dict[str, Any]:
    normalized_base_url = _normalize_base_url(base_url)
    checked_at = _now_iso()
    if dry_run:
        return _result_payload(
            base_url=normalized_base_url,
            checked_at=checked_at,
            dry_run=True,
            steps=[
                {
                    "name": endpoint.name,
                    "path": endpoint.path,
                    "status": "PASS",
                    "message": "planned",
                    "description": endpoint.description,
                }
                for endpoint in ENDPOINTS
            ],
            summary={
                "minPriceHistoryRows": max(1, int(min_price_history_rows or 2)),
                "minEtfReadyCount": max(1, int(min_etf_ready_count or 1)),
            },
        )

    request = requester or _request_json
    steps = []
    payloads: dict[str, dict[str, Any]] = {}
    for endpoint in ENDPOINTS:
        try:
            response = request(normalized_base_url, endpoint, timeout_seconds)
            payload = (
                response.get("payload")
                if isinstance(response.get("payload"), dict)
                else {}
            )
            payloads[endpoint.name] = payload
            steps.append(
                _assess_endpoint(
                    endpoint,
                    response,
                    min_price_history_rows=max(1, int(min_price_history_rows or 2)),
                    min_etf_ready_count=max(1, int(min_etf_ready_count or 1)),
                )
            )
        except Exception as error:  # noqa: BLE001 - operational script summarizes.
            steps.append(
                {
                    "name": endpoint.name,
                    "path": endpoint.path,
                    "status": "FAIL",
                    "message": str(error),
                    "description": endpoint.description,
                    "httpStatus": None,
                }
            )
    return _result_payload(
        base_url=normalized_base_url,
        checked_at=checked_at,
        dry_run=False,
        steps=steps,
        summary=_summary(
            payloads,
            min_price_history_rows=max(1, int(min_price_history_rows or 2)),
            min_etf_ready_count=max(1, int(min_etf_ready_count or 1)),
        ),
    )


def _result_payload(
    *,
    base_url: str,
    checked_at: str,
    dry_run: bool,
    steps: list[dict[str, Any]],
    summary: dict[str, Any] | None = None,
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
        "sourceContract": "00631l_public_backend_status",
        "checkedAt": checked_at,
        "baseUrl": base_url,
        "dryRun": dry_run,
        "overallStatus": overall_status,
        "summary": summary or {},
        "steps": steps,
        "warnings": warnings,
        "failures": failures,
    }


def _assess_endpoint(
    endpoint: PublicStatusEndpoint,
    response: dict[str, Any],
    *,
    min_price_history_rows: int,
    min_etf_ready_count: int,
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
            failures.extend(str(item) for item in payload.get("failures") or [])
        elif ready_status == "WARN":
            warnings.extend(str(item) for item in payload.get("warnings") or [])
    elif endpoint.name == "history_status":
        row_count = int(payload.get("rowCount") or 0)
        if row_count < min_price_history_rows:
            warnings.append(
                "00631L price history rows below minimum "
                f"{min_price_history_rows}: {row_count}"
            )
    elif endpoint.name == "etf_history_status":
        ready_count = int(payload.get("readyCount") or 0)
        if ready_count < min_etf_ready_count:
            warnings.append(
                "ETF history ready count below minimum "
                f"{min_etf_ready_count}: {ready_count}"
            )
        if int(payload.get("validationFailureCount") or 0) > 0:
            warnings.append("ETF history has validation failures")
    elif endpoint.name == "health":
        if str(payload.get("status") or "") != "ok":
            warnings.append("health status is not ok")

    status = "FAIL" if failures else "WARN" if warnings else "PASS"
    return {
        "name": endpoint.name,
        "path": endpoint.path,
        "status": status,
        "message": "; ".join([*failures, *warnings]) if status != "PASS" else "ok",
        "description": endpoint.description,
        "httpStatus": http_status,
        "summary": _endpoint_summary(endpoint.name, payload),
    }


def _endpoint_summary(name: str, payload: dict[str, Any]) -> dict[str, Any]:
    if name == "health":
        release = payload.get("release") if isinstance(payload.get("release"), dict) else {}
        return {
            "appVersion": payload.get("appVersion"),
            "releaseTag": release.get("tag"),
            "gitSha": release.get("gitSha"),
            "publicApiBaseUrl": payload.get("publicApiBaseUrl"),
        }
    if name == "ready":
        return {
            "overallStatus": payload.get("overallStatus"),
            "warningCount": len(payload.get("warnings") or []),
            "failureCount": len(payload.get("failures") or []),
        }
    if name == "history_status":
        return {
            "rowCount": payload.get("rowCount"),
            "coverageStart": payload.get("coverageStart"),
            "coverageEnd": payload.get("coverageEnd"),
            "sourceStatus": payload.get("sourceStatus"),
        }
    if name == "etf_history_status":
        return {
            "readyCount": payload.get("readyCount"),
            "rowCount": payload.get("rowCount"),
            "coverageTierCounts": payload.get("coverageTierCounts"),
            "validationFailureCount": payload.get("validationFailureCount"),
        }
    return {
        "sourceStatus": payload.get("sourceStatus"),
        "sourceUpdatedAt": payload.get("sourceUpdatedAt"),
    }


def _summary(
    payloads: dict[str, dict[str, Any]],
    *,
    min_price_history_rows: int,
    min_etf_ready_count: int,
) -> dict[str, Any]:
    health = payloads.get("health", {})
    release = health.get("release") if isinstance(health.get("release"), dict) else {}
    history = payloads.get("history_status", {})
    etf_history = payloads.get("etf_history_status", {})
    ready = payloads.get("ready", {})
    return {
        "backendVersion": health.get("appVersion") or release.get("version"),
        "releaseTag": release.get("tag"),
        "gitSha": release.get("gitSha"),
        "buildTime": release.get("buildTime"),
        "readiness": ready.get("overallStatus"),
        "priceHistoryRows": int(history.get("rowCount") or 0),
        "priceHistoryCoverageStart": history.get("coverageStart"),
        "priceHistoryCoverageEnd": history.get("coverageEnd"),
        "etfHistoryReadyCount": int(etf_history.get("readyCount") or 0),
        "etfHistoryRowCount": int(etf_history.get("rowCount") or 0),
        "minPriceHistoryRows": min_price_history_rows,
        "minEtfReadyCount": min_etf_ready_count,
        "etfHistoryValidationFailureCount": int(
            etf_history.get("validationFailureCount") or 0
        ),
    }


def _request_json(
    base_url: str,
    endpoint: PublicStatusEndpoint,
    timeout_seconds: int,
) -> dict[str, Any]:
    url = f"{base_url}{endpoint.path}"
    request = urllib.request.Request(
        url,
        method="GET",
        headers={
            "Accept": "application/json",
            "User-Agent": "00631l-public-backend-status/1.0",
        },
    )
    try:
        with urllib.request.urlopen(request, timeout=timeout_seconds) as response:
            body = response.read().decode("utf-8", errors="replace")
            return {
                "httpStatus": response.status,
                "payload": json.loads(body) if body.strip() else {},
            }
    except urllib.error.HTTPError as error:
        body = error.read().decode("utf-8", errors="replace")
        try:
            payload = json.loads(body) if body.strip() else {}
        except json.JSONDecodeError:
            payload = {"errorMessage": body[:500]}
        return {"httpStatus": error.code, "payload": payload}


def _normalize_base_url(value: str) -> str:
    return (value.strip() or DEFAULT_BACKEND_URL).rstrip("/")


def _now_iso() -> str:
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat()


def _parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Check public 00631L backend status without mutating data.",
    )
    parser.add_argument(
        "--base-url",
        default=os.getenv("PUBLIC_BACKEND_URL")
        or os.getenv("00631L_PUBLIC_BACKEND_URL")
        or DEFAULT_BACKEND_URL,
    )
    parser.add_argument("--timeout-seconds", type=int, default=30)
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--soft-fail", action="store_true")
    parser.add_argument("--min-price-history-rows", type=int, default=2)
    parser.add_argument("--min-etf-ready-count", type=int, default=1)
    return parser.parse_args()


def main() -> int:
    args = _parse_args()
    payload = run_public_backend_status(
        base_url=args.base_url,
        timeout_seconds=max(1, args.timeout_seconds),
        dry_run=args.dry_run,
        min_price_history_rows=max(1, args.min_price_history_rows),
        min_etf_ready_count=max(1, args.min_etf_ready_count),
    )
    print(json.dumps(payload, ensure_ascii=True, indent=2, sort_keys=True))
    summary = payload.get("summary") or {}
    print(
        "[summary] "
        f"overallStatus={payload['overallStatus']} "
        f"warnings={len(payload['warnings'])} "
        f"failures={len(payload['failures'])} "
        f"version={summary.get('backendVersion') or 'unknown'} "
        f"priceRows={summary.get('priceHistoryRows') or 0} "
        f"etfReady={summary.get('etfHistoryReadyCount') or 0}"
    )
    return 0 if args.soft_fail or payload["overallStatus"] != "FAIL" else 1


if __name__ == "__main__":
    raise SystemExit(main())
