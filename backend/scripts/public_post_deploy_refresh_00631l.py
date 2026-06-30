from __future__ import annotations

import argparse
import json
import os
import sys
import urllib.error
import urllib.parse
import urllib.request
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Callable


ROOT = Path(__file__).resolve().parents[2]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from backend.app.config import settings  # noqa: E402
from backend.scripts.compare_public_data_freshness_00631l import (  # noqa: E402
    run_public_data_freshness_check,
)
from backend.scripts.public_backend_status_00631l import (  # noqa: E402
    DEFAULT_BACKEND_URL,
    run_public_backend_status,
)
from backend.scripts.remote_maintenance_00631l import run_remote_maintenance  # noqa: E402
from backend.scripts.run_public_etf_catalog_batches_00631l import (  # noqa: E402
    run_public_etf_catalog_batches,
)
from backend.scripts.wait_public_deploy_00631l import (  # noqa: E402
    run_public_deploy_wait_check,
)


RunnerFn = Callable[..., dict[str, Any]]
RequestFn = Callable[[str, str, int, dict[str, str] | None], dict[str, Any]]


def run_public_post_deploy_refresh(
    *,
    base_url: str = DEFAULT_BACKEND_URL,
    expected_release_tag: str | None = None,
    timeout_seconds: int = 120,
    wait_attempts: int = 12,
    wait_interval_seconds: int = 10,
    max_gap_batches: int = 5,
    dry_run: bool = False,
    deploy_wait_runner: RunnerFn | None = None,
    backend_status_runner: RunnerFn | None = None,
    maintenance_runner: RunnerFn | None = None,
    batch_runner: RunnerFn | None = None,
    freshness_runner: RunnerFn | None = None,
    requester: RequestFn | None = None,
) -> dict[str, Any]:
    normalized_base_url = _normalize_base_url(base_url)
    checked_at = _now_iso()
    resolved_release_tag = (
        expected_release_tag
        or os.getenv("EXPECTED_00631L_RELEASE_TAG")
        or settings.backend_release_tag
    ).strip()
    if dry_run:
        return _payload(
            checked_at=checked_at,
            base_url=normalized_base_url,
            dry_run=True,
            steps=[
                _step("deploy_wait", "PASS", "planned"),
                _step("public_backend_status", "PASS", "planned"),
                _step("remote_maintenance", "PASS", "planned"),
                _step("gap_discovery", "PASS", "planned"),
                _step("gap_batches", "PASS", "planned"),
                _step("freshness", "PASS", "planned"),
            ],
            summary={
                "expectedReleaseTag": resolved_release_tag,
                "maxGapBatches": max(0, int(max_gap_batches or 0)),
            },
            action_items=[],
        )

    wait_payload = (deploy_wait_runner or run_public_deploy_wait_check)(
        base_url=normalized_base_url,
        expected_release_tag=resolved_release_tag,
        attempts=max(1, int(wait_attempts or 1)),
        interval_seconds=max(0, int(wait_interval_seconds or 0)),
        timeout_seconds=max(1, int(timeout_seconds or 1)),
    )
    backend_status_payload = (backend_status_runner or run_public_backend_status)(
        base_url=normalized_base_url,
        timeout_seconds=max(1, int(timeout_seconds or 1)),
    )
    if str(backend_status_payload.get("overallStatus") or "WARN") == "FAIL":
        return _payload(
            checked_at=checked_at,
            base_url=normalized_base_url,
            dry_run=False,
            steps=[
                _payload_step("deploy_wait", wait_payload),
                _payload_step("public_backend_status", backend_status_payload),
            ],
            summary={
                "expectedReleaseTag": resolved_release_tag,
                "finalFreshnessStatus": None,
                "finalFreshnessSummary": {},
            },
            action_items=_dedupe(
                [
                    *[str(item) for item in wait_payload.get("actionItems") or []],
                    *[
                        str(item)
                        for item in backend_status_payload.get("actionItems") or []
                    ],
                    (
                        "Fix public backend storage readiness before running "
                        "post-deploy data refresh."
                    ),
                ]
            ),
        )
    maintenance_payload = (maintenance_runner or run_remote_maintenance)(
        base_url=normalized_base_url,
        mode="daily",
        timeout_seconds=max(1, int(timeout_seconds or 1)),
    )
    request = requester or _request_json
    discovery_status = "PASS"
    discovery_message = "gaps discovered"
    discovery_summary: dict[str, Any] = {}
    try:
        catalog_response = request(
            normalized_base_url,
            "/api/etf/catalog",
            max(1, timeout_seconds),
            None,
        )
        gaps_response = request(
            normalized_base_url,
            "/api/etf/history/gaps",
            max(1, timeout_seconds),
            {"fromCatalog": "true", "limit": str(max(1, max_gap_batches))},
        )
        catalog_payload = _payload_body(catalog_response)
        gaps_payload = _payload_body(gaps_response)
        catalog_http_status = _http_status(catalog_response)
        gaps_http_status = _http_status(gaps_response)
        if _is_http_error(catalog_http_status) or _is_http_error(gaps_http_status):
            discovery_status = "WARN"
            discovery_message = (
                "gap discovery returned "
                f"catalogStatus={catalog_http_status} gapsStatus={gaps_http_status}"
            )
        discovery_summary = {
            "catalogHttpStatus": catalog_http_status,
            "gapsHttpStatus": gaps_http_status,
        }
    except Exception as error:  # noqa: BLE001 - operational script should summarize network failures.
        catalog_payload = {}
        gaps_payload = {}
        discovery_status = "WARN"
        discovery_message = f"gap discovery failed: {error}"
        discovery_summary = {"errorMessage": str(error)}
    gap_offsets = _gap_offsets(catalog_payload, gaps_payload, max_gap_batches)
    batch_payloads: list[dict[str, Any]] = []
    for gap in gap_offsets:
        batch_payloads.append(
            (batch_runner or run_public_etf_catalog_batches)(
                base_url=normalized_base_url,
                start_offset=gap["offset"],
                batch_size=1,
                max_batches=1,
                timeout_seconds=max(1, int(timeout_seconds or 1)),
                enable_preflight=True,
                continue_on_failure=True,
            )
        )
    freshness_payload = (freshness_runner or run_public_data_freshness_check)(
        base_url=normalized_base_url,
        timeout_seconds=max(1, int(timeout_seconds or 1)),
    )

    steps = [
        _payload_step("deploy_wait", wait_payload),
        _payload_step("public_backend_status", backend_status_payload),
        _payload_step("remote_maintenance", maintenance_payload),
        _step(
            "gap_discovery",
            discovery_status,
            f"{discovery_message}; gaps={len(gap_offsets)}",
            summary={
                "gapCount": len(gap_offsets),
                "gapOffsets": gap_offsets,
                **discovery_summary,
            },
        ),
        *[
            _payload_step(f"gap_batch_{index + 1}", payload)
            for index, payload in enumerate(batch_payloads)
        ],
        _payload_step("freshness", freshness_payload),
    ]
    action_items = _dedupe(
        [
            *[str(item) for item in wait_payload.get("actionItems") or []],
            *[str(item) for item in maintenance_payload.get("actionItems") or []],
            *[
                str(item)
                for payload in batch_payloads
                for item in (payload.get("actionItems") or [])
            ],
            *[str(item) for item in freshness_payload.get("actionItems") or []],
        ]
    )
    return _payload(
        checked_at=checked_at,
        base_url=normalized_base_url,
        dry_run=False,
        steps=steps,
        summary={
            "expectedReleaseTag": resolved_release_tag,
            "gapCount": len(gap_offsets),
            "gapOffsets": gap_offsets,
            "batchCount": len(batch_payloads),
            "finalFreshnessStatus": freshness_payload.get("overallStatus"),
            "finalFreshnessSummary": freshness_payload.get("summary") or {},
        },
        action_items=action_items,
        resolve_final_freshness_warnings=True,
    )


def _payload_step(name: str, payload: dict[str, Any]) -> dict[str, Any]:
    status = str(payload.get("overallStatus") or "WARN")
    normalized = status if status in {"PASS", "WARN", "FAIL"} else "WARN"
    return _step(
        name,
        normalized,
        f"overallStatus={normalized}",
        summary={
            "warnings": payload.get("warnings") or [],
            "failures": payload.get("failures") or [],
            "actionItems": payload.get("actionItems") or [],
            "summary": payload.get("summary") or {},
        },
    )


def _gap_offsets(
    catalog_payload: dict[str, Any],
    gaps_payload: dict[str, Any],
    limit: int,
) -> list[dict[str, Any]]:
    catalog_items = catalog_payload.get("items")
    gap_items = gaps_payload.get("items")
    if not isinstance(catalog_items, list) or not isinstance(gap_items, list):
        return []
    offset_by_code: dict[str, int] = {}
    name_by_code: dict[str, str | None] = {}
    for index, item in enumerate(catalog_items):
        if not isinstance(item, dict):
            continue
        code = str(item.get("code") or "").strip()
        if not code:
            continue
        offset_by_code[code] = index
        name_by_code[code] = item.get("name")
    output: list[dict[str, Any]] = []
    for item in gap_items:
        if not isinstance(item, dict):
            continue
        code = str(item.get("code") or "").strip()
        if code not in offset_by_code:
            continue
        output.append(
            {
                "code": code,
                "name": item.get("name") or name_by_code.get(code),
                "offset": offset_by_code[code],
                "gapReason": item.get("gapReason"),
            }
        )
        if len(output) >= max(0, int(limit or 0)):
            break
    return output


def _payload_body(response: dict[str, Any]) -> dict[str, Any]:
    payload = response.get("payload")
    return payload if isinstance(payload, dict) else {}


def _http_status(response: dict[str, Any]) -> int | None:
    value = response.get("httpStatus")
    try:
        return int(value) if value is not None else None
    except (TypeError, ValueError):
        return None


def _is_http_error(status: int | None) -> bool:
    return status is not None and status >= 400


def _request_json(
    base_url: str,
    path: str,
    timeout_seconds: int,
    query: dict[str, str] | None,
) -> dict[str, Any]:
    encoded = urllib.parse.urlencode(query or {})
    url = f"{base_url}{path}{'?' + encoded if encoded else ''}"
    request = urllib.request.Request(
        url,
        method="GET",
        headers={
            "Accept": "application/json",
            "User-Agent": "00631l-public-post-deploy-refresh/1.0",
        },
    )
    try:
        with urllib.request.urlopen(request, timeout=max(1, timeout_seconds)) as response:
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


def _payload(
    *,
    checked_at: str,
    base_url: str,
    dry_run: bool,
    steps: list[dict[str, Any]],
    summary: dict[str, Any],
    action_items: list[str],
    resolve_final_freshness_warnings: bool = False,
) -> dict[str, Any]:
    failures = [
        f"{step['name']}: {step['message']}"
        for step in steps
        if step.get("status") == "FAIL"
    ]
    warning_steps = [step for step in steps if step.get("status") == "WARN"]
    warnings = [
        f"{step['name']}: {step['message']}"
        for step in warning_steps
    ]
    resolved_warnings: list[str] = []
    if (
        resolve_final_freshness_warnings
        and not failures
        and summary.get("finalFreshnessStatus") == "PASS"
        and all(_is_resolved_warning_step(step) for step in warning_steps)
    ):
        resolved_warnings = warnings
        warnings = []
        action_items = []
    return {
        "sourceContract": "00631l_public_post_deploy_refresh",
        "checkedAt": checked_at,
        "baseUrl": base_url,
        "dryRun": dry_run,
        "overallStatus": "FAIL" if failures else "WARN" if warnings else "PASS",
        "summary": {
            **summary,
            **({"resolvedWarnings": resolved_warnings} if resolved_warnings else {}),
        },
        "steps": steps,
        "warnings": warnings,
        "failures": failures,
        "actionItems": action_items,
    }


def _step(
    name: str,
    status: str,
    message: str,
    *,
    summary: dict[str, Any] | None = None,
) -> dict[str, Any]:
    return {
        "name": name,
        "status": status,
        "message": message,
        "summary": summary or {},
    }


def _dedupe(items: list[str]) -> list[str]:
    seen: set[str] = set()
    output: list[str] = []
    for item in items:
        if item in seen:
            continue
        seen.add(item)
        output.append(item)
    return output


def _is_resolved_warning_step(step: dict[str, Any]) -> bool:
    name = str(step.get("name") or "")
    return name in {
        "deploy_wait",
        "public_backend_status",
        "remote_maintenance",
    } or name.startswith("gap_batch_")


def _normalize_base_url(value: str) -> str:
    return (value.strip() or DEFAULT_BACKEND_URL).rstrip("/")


def _now_iso() -> str:
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat()


def _parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Wait for public deploy, refresh backend data, and fill ETF catalog gaps.",
    )
    parser.add_argument(
        "--base-url",
        default=os.getenv("PUBLIC_BACKEND_URL")
        or os.getenv("00631L_PUBLIC_BACKEND_URL")
        or DEFAULT_BACKEND_URL,
    )
    parser.add_argument(
        "--expected-release-tag",
        default=os.getenv("EXPECTED_00631L_RELEASE_TAG") or settings.backend_release_tag,
    )
    parser.add_argument("--timeout-seconds", type=int, default=120)
    parser.add_argument("--wait-attempts", type=int, default=12)
    parser.add_argument("--wait-interval-seconds", type=int, default=10)
    parser.add_argument("--max-gap-batches", type=int, default=5)
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--soft-fail", action="store_true")
    return parser.parse_args()


def main() -> int:
    args = _parse_args()
    payload = run_public_post_deploy_refresh(
        base_url=args.base_url,
        expected_release_tag=args.expected_release_tag,
        timeout_seconds=max(1, args.timeout_seconds),
        wait_attempts=max(1, args.wait_attempts),
        wait_interval_seconds=max(0, args.wait_interval_seconds),
        max_gap_batches=max(0, args.max_gap_batches),
        dry_run=args.dry_run,
    )
    print(json.dumps(payload, ensure_ascii=True, indent=2, sort_keys=True))
    summary = payload.get("summary") if isinstance(payload.get("summary"), dict) else {}
    print(
        "[summary] "
        f"overallStatus={payload['overallStatus']} "
        f"warnings={len(payload['warnings'])} "
        f"failures={len(payload['failures'])} "
        f"gaps={summary.get('gapCount') or 0} "
        f"batches={summary.get('batchCount') or 0} "
        f"freshness={summary.get('finalFreshnessStatus') or 'unknown'}"
    )
    return 0 if args.soft_fail or payload["overallStatus"] != "FAIL" else 1


if __name__ == "__main__":
    raise SystemExit(main())
