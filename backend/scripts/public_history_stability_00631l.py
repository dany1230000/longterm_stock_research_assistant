from __future__ import annotations

import argparse
import json
import os
import sys
import time
import urllib.error
import urllib.request
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[2]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from backend.scripts.public_backend_status_00631l import DEFAULT_BACKEND_URL  # noqa: E402


def run_public_history_stability_check(
    *,
    base_url: str = DEFAULT_BACKEND_URL,
    sample_count: int = 3,
    interval_seconds: float = 2.0,
    timeout_seconds: int = 30,
    dry_run: bool = False,
) -> dict[str, Any]:
    checked_at = _now_iso()
    normalized_base_url = _normalize_base_url(base_url)
    if dry_run:
        return build_public_history_stability_status(
            base_url=normalized_base_url,
            checked_at=checked_at,
            samples=[
                {"status": "PASS", "readyCount": 0, "rowCount": 0, "planned": True}
                for _ in range(max(1, sample_count))
            ],
            dry_run=True,
        )

    samples: list[dict[str, Any]] = []
    for index in range(max(1, sample_count)):
        samples.append(_sample_history_status(normalized_base_url, timeout_seconds))
        if index < max(1, sample_count) - 1 and interval_seconds > 0:
            time.sleep(interval_seconds)
    return build_public_history_stability_status(
        base_url=normalized_base_url,
        checked_at=checked_at,
        samples=samples,
    )


def build_public_history_stability_status(
    *,
    base_url: str,
    checked_at: str,
    samples: list[dict[str, Any]],
    dry_run: bool = False,
) -> dict[str, Any]:
    ready_counts = [_int(sample.get("readyCount")) for sample in samples]
    row_counts = [_int(sample.get("rowCount")) for sample in samples]
    failed_samples = [
        str(sample.get("message") or sample.get("errorMessage") or "sample failed")
        for sample in samples
        if sample.get("status") == "FAIL"
    ]
    ready_regression = _max_regression(ready_counts)
    warnings: list[str] = []
    action_items: list[str] = []
    if failed_samples:
        warnings.append("Public ETF history status sample failed; rerun stability check before catalog batches.")
        action_items.append("Rerun scripts\\00631l_public_history_stability.cmd --soft-fail.")
    if ready_regression > 0:
        warnings.append(
            "Public ETF ready count decreased between samples; check persistent data volume and redeploy status."
        )
        action_items.append(
            "Check public backend persistent data volume and redeploy status before continuing ETF catalog batches."
        )
    return {
        "sourceContract": "00631l_public_history_stability",
        "checkedAt": checked_at,
        "baseUrl": _normalize_base_url(base_url),
        "dryRun": dry_run,
        "overallStatus": "WARN" if warnings else "PASS",
        "failureCount": 0,
        "warningCount": len(warnings),
        "summary": {
            "sampleCount": len(samples),
            "readyCounts": ready_counts,
            "rowCounts": row_counts,
            "readyCountRegression": ready_regression,
            "firstReadyCount": ready_counts[0] if ready_counts else 0,
            "lastReadyCount": ready_counts[-1] if ready_counts else 0,
        },
        "samples": samples,
        "warnings": warnings,
        "failures": [],
        "actionItems": _dedupe(action_items),
    }


def _sample_history_status(base_url: str, timeout_seconds: int) -> dict[str, Any]:
    url = f"{_normalize_base_url(base_url)}/api/etf/history/status"
    request = urllib.request.Request(
        url,
        method="GET",
        headers={
            "Accept": "application/json",
            "User-Agent": "00631l-public-history-stability/1.0",
        },
    )
    try:
        with urllib.request.urlopen(request, timeout=max(1, timeout_seconds)) as response:
            body = response.read().decode("utf-8", errors="replace")
            payload = json.loads(body) if body.strip() else {}
            return {
                "status": "PASS" if 200 <= response.status < 300 else "FAIL",
                "httpStatus": response.status,
                "readyCount": payload.get("readyCount"),
                "rowCount": payload.get("rowCount"),
                "sourceUpdatedAt": payload.get("sourceUpdatedAt"),
            }
    except urllib.error.HTTPError as error:
        return {"status": "FAIL", "httpStatus": error.code, "message": f"HTTP {error.code}"}
    except Exception as error:  # noqa: BLE001 - maintenance scripts must return payloads.
        return {"status": "FAIL", "httpStatus": None, "message": f"{type(error).__name__}: {error}"}


def _max_regression(values: list[int]) -> int:
    if len(values) < 2:
        return 0
    peak = values[0]
    regression = 0
    for value in values[1:]:
        if value < peak:
            regression = max(regression, peak - value)
        peak = max(peak, value)
    return regression


def _int(value: Any) -> int:
    try:
        return int(value or 0)
    except (TypeError, ValueError):
        return 0


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
        description="Sample public ETF history status for ready-count instability.",
    )
    parser.add_argument(
        "--base-url",
        default=os.getenv("PUBLIC_BACKEND_URL")
        or os.getenv("00631L_PUBLIC_BACKEND_URL")
        or DEFAULT_BACKEND_URL,
    )
    parser.add_argument("--sample-count", type=int, default=3)
    parser.add_argument("--interval-seconds", type=float, default=2.0)
    parser.add_argument("--timeout-seconds", type=int, default=30)
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--soft-fail", action="store_true")
    return parser.parse_args()


def main() -> int:
    args = _parse_args()
    payload = run_public_history_stability_check(
        base_url=args.base_url,
        sample_count=max(1, args.sample_count),
        interval_seconds=max(0.0, args.interval_seconds),
        timeout_seconds=max(1, args.timeout_seconds),
        dry_run=args.dry_run,
    )
    print(json.dumps(payload, ensure_ascii=True, indent=2, sort_keys=True))
    summary = payload.get("summary") if isinstance(payload.get("summary"), dict) else {}
    print(
        "[summary] "
        f"overallStatus={payload['overallStatus']} "
        f"warnings={payload['warningCount']} "
        f"failures={payload['failureCount']} "
        f"readyCounts={summary.get('readyCounts') or []} "
        f"regression={summary.get('readyCountRegression') or 0}"
    )
    return 0 if args.soft_fail or payload["overallStatus"] != "FAIL" else 1


if __name__ == "__main__":
    raise SystemExit(main())
