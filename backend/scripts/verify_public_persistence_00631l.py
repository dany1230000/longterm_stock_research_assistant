from __future__ import annotations

import argparse
import json
import os
import sys
import time
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Callable


ROOT = Path(__file__).resolve().parents[2]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from backend.scripts.public_backend_status_00631l import (  # noqa: E402
    DEFAULT_BACKEND_URL,
    run_public_backend_status,
)


StatusRunner = Callable[..., dict[str, Any]]


def run_public_persistence_verifier(
    *,
    base_url: str = DEFAULT_BACKEND_URL,
    sample_count: int = 3,
    interval_seconds: float = 30.0,
    timeout_seconds: int = 30,
    min_marker_age_seconds: int = 15 * 60,
    min_etf_ready_count: int = 200,
    dry_run: bool = False,
    status_runner: StatusRunner | None = None,
) -> dict[str, Any]:
    checked_at = _now_iso()
    normalized_base_url = _normalize_base_url(base_url)
    sample_total = max(1, int(sample_count or 1))
    if dry_run:
        return build_public_persistence_verifier_status(
            base_url=normalized_base_url,
            checked_at=checked_at,
            dry_run=True,
            samples=[
                {
                    "status": "PASS",
                    "planned": True,
                    "markerCreatedAt": None,
                    "markerFresh": False,
                    "markerAgeSeconds": None,
                    "etfReadyCount": 0,
                }
                for _ in range(sample_total)
            ],
            min_marker_age_seconds=max(1, int(min_marker_age_seconds or 900)),
            min_etf_ready_count=max(1, int(min_etf_ready_count or 200)),
        )

    runner = status_runner or run_public_backend_status
    samples: list[dict[str, Any]] = []
    for index in range(sample_total):
        try:
            status_payload = runner(
                base_url=normalized_base_url,
                timeout_seconds=max(1, int(timeout_seconds or 30)),
                min_etf_ready_count=1,
            )
            samples.append(_sample_from_public_status(status_payload))
        except Exception as error:  # noqa: BLE001 - operational script returns JSON.
            samples.append(
                {
                    "status": "FAIL",
                    "message": f"{type(error).__name__}: {error}",
                    "markerCreatedAt": None,
                    "markerFresh": None,
                    "markerAgeSeconds": None,
                    "etfReadyCount": 0,
                }
            )
        if index < sample_total - 1 and interval_seconds > 0:
            time.sleep(interval_seconds)

    return build_public_persistence_verifier_status(
        base_url=normalized_base_url,
        checked_at=checked_at,
        samples=samples,
        min_marker_age_seconds=max(1, int(min_marker_age_seconds or 900)),
        min_etf_ready_count=max(1, int(min_etf_ready_count or 200)),
    )


def build_public_persistence_verifier_status(
    *,
    base_url: str,
    checked_at: str,
    samples: list[dict[str, Any]],
    min_marker_age_seconds: int = 15 * 60,
    min_etf_ready_count: int = 200,
    dry_run: bool = False,
) -> dict[str, Any]:
    failures: list[str] = []
    warnings: list[str] = []
    action_items: list[str] = []
    marker_created_values = [
        str(sample.get("markerCreatedAt"))
        for sample in samples
        if sample.get("markerCreatedAt")
    ]
    marker_ages = [
        _int(sample.get("markerAgeSeconds"))
        for sample in samples
        if sample.get("markerAgeSeconds") is not None
    ]
    ready_counts = [_int(sample.get("etfReadyCount")) for sample in samples]
    failed_samples = [
        str(sample.get("message") or "sample failed")
        for sample in samples
        if sample.get("status") == "FAIL"
    ]
    if failed_samples:
        failures.append(
            "Public backend status sample failed; fix connectivity before verifying persistence."
        )
        action_items.append("Run scripts\\00631l_public_backend_status.cmd --soft-fail.")
    if samples and not marker_created_values and not dry_run:
        warnings.append("Public persistence marker is missing from readiness summary.")
        action_items.append("Check /ready and confirm 00631L_PERSISTENCE_MARKER_PATH is under /data/00631l.")
    elif (
        samples
        and len(marker_created_values) < len(samples)
        and not dry_run
    ):
        warnings.append("One or more public persistence samples are missing marker details.")
        action_items.append("Rerun scripts\\00631l_public_backend_status.cmd --soft-fail and inspect /ready.")
    if len(set(marker_created_values)) > 1 and not dry_run:
        warnings.append("Public persistence marker createdAt changed between samples.")
        action_items.append("Verify the Render persistent disk is attached at /data/00631l.")
    if any(sample.get("markerFresh") is True for sample in samples) and not dry_run:
        warnings.append("Public persistence marker is still fresh.")
        action_items.append("Wait for the marker freshness window, then rerun scripts\\00631l_verify_public_persistence.cmd.")
    if marker_ages and max(marker_ages) < min_marker_age_seconds and not dry_run:
        warnings.append(
            "Public persistence marker age is below the required verification window "
            f"{min_marker_age_seconds}s."
        )
    if ready_counts and max(ready_counts) < min_etf_ready_count and not dry_run:
        warnings.append(
            "Public ETF ready count is below the persistence verification floor "
            f"{min_etf_ready_count}: {max(ready_counts)}."
        )
        action_items.append("Do not run public ETF catalog batches until persistent storage is stable.")
    ready_regression = _max_regression(ready_counts)
    if ready_regression > 0 and not dry_run:
        warnings.append("Public ETF ready count regressed during persistence verification.")
        action_items.append("Check public backend persistent volume before continuing data batches.")

    overall_status = "FAIL" if failures else "WARN" if warnings else "PASS"
    return {
        "sourceContract": "00631l_public_persistence_verifier",
        "checkedAt": checked_at,
        "baseUrl": _normalize_base_url(base_url),
        "dryRun": dry_run,
        "overallStatus": overall_status,
        "failureCount": len(failures),
        "warningCount": len(warnings),
        "summary": {
            "sampleCount": len(samples),
            "markerCreatedAtValues": marker_created_values,
            "markerCreatedAtStable": len(set(marker_created_values)) <= 1,
            "markerFreshValues": [sample.get("markerFresh") for sample in samples],
            "maxMarkerAgeSeconds": max(marker_ages) if marker_ages else None,
            "minMarkerAgeSeconds": min_marker_age_seconds,
            "etfReadyCounts": ready_counts,
            "maxEtfReadyCount": max(ready_counts) if ready_counts else 0,
            "minEtfReadyCount": min_etf_ready_count,
            "readyCountRegression": ready_regression,
        },
        "samples": samples,
        "warnings": warnings,
        "failures": failures,
        "actionItems": _dedupe(action_items),
    }


def _sample_from_public_status(payload: dict[str, Any]) -> dict[str, Any]:
    summary = payload.get("summary") if isinstance(payload.get("summary"), dict) else {}
    return {
        "status": "FAIL" if payload.get("overallStatus") == "FAIL" else "PASS",
        "publicStatus": payload.get("overallStatus"),
        "releaseTag": summary.get("releaseTag"),
        "readiness": summary.get("readiness"),
        "markerCreatedAt": summary.get("persistenceMarkerCreatedAt"),
        "markerFresh": summary.get("persistenceMarkerFresh"),
        "markerAgeSeconds": summary.get("persistenceMarkerAgeSeconds"),
        "markerNewlyCreated": summary.get("persistenceMarkerNewlyCreated"),
        "priceHistoryRows": summary.get("priceHistoryRows"),
        "etfReadyCount": summary.get("etfHistoryReadyCount"),
        "warnings": payload.get("warnings") or [],
        "failures": payload.get("failures") or [],
    }


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
        description="Verify public 00631L backend persistent data marker stability.",
    )
    parser.add_argument(
        "--base-url",
        default=os.getenv("PUBLIC_BACKEND_URL")
        or os.getenv("00631L_PUBLIC_BACKEND_URL")
        or DEFAULT_BACKEND_URL,
    )
    parser.add_argument("--sample-count", type=int, default=3)
    parser.add_argument("--interval-seconds", type=float, default=30.0)
    parser.add_argument("--timeout-seconds", type=int, default=30)
    parser.add_argument("--min-marker-age-seconds", type=int, default=15 * 60)
    parser.add_argument("--min-etf-ready-count", type=int, default=200)
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--soft-fail", action="store_true")
    return parser.parse_args()


def main() -> int:
    args = _parse_args()
    payload = run_public_persistence_verifier(
        base_url=args.base_url,
        sample_count=max(1, args.sample_count),
        interval_seconds=max(0.0, args.interval_seconds),
        timeout_seconds=max(1, args.timeout_seconds),
        min_marker_age_seconds=max(1, args.min_marker_age_seconds),
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
        f"markerFresh={summary.get('markerFreshValues') or []} "
        f"markerStable={summary.get('markerCreatedAtStable')} "
        f"etfReady={summary.get('maxEtfReadyCount') or 0}"
    )
    return 0 if args.soft_fail or payload["overallStatus"] != "FAIL" else 1


if __name__ == "__main__":
    raise SystemExit(main())
