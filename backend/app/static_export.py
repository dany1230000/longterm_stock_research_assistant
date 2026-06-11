from __future__ import annotations

import json
from pathlib import Path
from typing import Any

from .price_history import PriceHistoryStore, utc_now_iso


STATIC_SOURCE_CONTRACT = "00631l_static_public_data"


def export_static_00631l_data(
    *,
    output_dir: str | Path,
    price_history_store: PriceHistoryStore,
    strict: bool = False,
    warnings: list[str] | None = None,
) -> dict[str, Any]:
    generated_at = utc_now_iso()
    output = Path(output_dir)
    output.mkdir(parents=True, exist_ok=True)
    warnings = list(warnings or [])

    price_history = price_history_store.price_response(
        limit=5000,
        fetched_at=generated_at,
    )
    performance = price_history_store.performance_response(fetched_at=generated_at)
    status = price_history_store.status_response(fetched_at=generated_at)
    row_count = int(status.get("rowCount") or 0)
    failures: list[str] = []
    if row_count < 2:
        message = (
            "Official price history has fewer than two rows; static public "
            "history/backtest data is not ready."
        )
        warnings.append(message)
        if strict:
            failures.append(message)

    status_payload = {
        **status,
        "sourceStatus": "static_official" if row_count >= 2 else "unavailable",
        "sourceContract": STATIC_SOURCE_CONTRACT,
        "generatedAt": generated_at,
        "outputDir": str(output),
        "warnings": warnings,
        "failures": failures,
        "strict": strict,
    }
    price_payload = {
        **price_history,
        "sourceStatus": "static_official" if row_count >= 2 else "unavailable",
        "sourceContract": "00631l_static_price_history",
        "generatedAt": generated_at,
        "rowCount": row_count,
        "errorMessage": None if row_count >= 2 else status.get("errorMessage"),
    }
    performance_payload = {
        **performance,
        "sourceStatus": "static_official" if row_count >= 2 else "unavailable",
        "sourceContract": "00631l_static_price_performance",
        "generatedAt": generated_at,
        "errorMessage": None if row_count >= 2 else status.get("errorMessage"),
    }
    manifest_payload = {
        "sourceStatus": status_payload["sourceStatus"],
        "sourceContract": STATIC_SOURCE_CONTRACT,
        "generatedAt": generated_at,
        "files": {
            "priceHistory": "price_history.json",
            "performance": "performance.json",
            "status": "status.json",
        },
        "rowCount": row_count,
        "coverageStart": status.get("coverageStart"),
        "coverageEnd": status.get("coverageEnd"),
        "isCompleteFromListing": status.get("isCompleteFromListing"),
        "warnings": warnings,
        "failures": failures,
    }

    _write_json(output / "price_history.json", price_payload)
    _write_json(output / "performance.json", performance_payload)
    _write_json(output / "status.json", status_payload)
    _write_json(output / "manifest.json", manifest_payload)

    return {
        "sourceStatus": status_payload["sourceStatus"],
        "sourceContract": STATIC_SOURCE_CONTRACT,
        "generatedAt": generated_at,
        "outputDir": str(output),
        "rowCount": row_count,
        "coverageStart": status.get("coverageStart"),
        "coverageEnd": status.get("coverageEnd"),
        "isCompleteFromListing": status.get("isCompleteFromListing"),
        "warnings": warnings,
        "failures": failures,
        "overallStatus": "FAIL" if failures else "PASS" if row_count >= 2 else "WARN",
        "files": manifest_payload["files"],
    }


def static_export_status(output_dir: str | Path) -> dict[str, Any]:
    checked_at = utc_now_iso()
    output = Path(output_dir)
    manifest_path = output / "manifest.json"
    status_path = output / "status.json"
    if not manifest_path.exists() or not status_path.exists():
        return {
            "sourceStatus": "unavailable",
            "sourceContract": STATIC_SOURCE_CONTRACT,
            "checkedAt": checked_at,
            "outputDir": str(output),
            "rowCount": 0,
            "coverageStart": None,
            "coverageEnd": None,
            "overallStatus": "WARN",
            "warnings": ["Static public data export does not exist yet."],
            "failures": [],
            "errorMessage": (
                "Run scripts\\00631l_export_static_data.cmd --update to "
                "generate web\\00631l-static-data."
            ),
        }
    try:
        manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
        status = json.loads(status_path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as error:
        return {
            "sourceStatus": "error",
            "sourceContract": STATIC_SOURCE_CONTRACT,
            "checkedAt": checked_at,
            "outputDir": str(output),
            "rowCount": 0,
            "coverageStart": None,
            "coverageEnd": None,
            "overallStatus": "FAIL",
            "warnings": [],
            "failures": [str(error)],
            "errorMessage": f"Static public data JSON is invalid: {error}",
        }
    row_count = int(manifest.get("rowCount") or status.get("rowCount") or 0)
    warnings = list(manifest.get("warnings") or [])
    failures = list(manifest.get("failures") or [])
    return {
        "sourceStatus": manifest.get("sourceStatus", "unavailable"),
        "sourceContract": STATIC_SOURCE_CONTRACT,
        "checkedAt": checked_at,
        "generatedAt": manifest.get("generatedAt"),
        "outputDir": str(output),
        "rowCount": row_count,
        "coverageStart": manifest.get("coverageStart"),
        "coverageEnd": manifest.get("coverageEnd"),
        "isCompleteFromListing": manifest.get("isCompleteFromListing") is True,
        "overallStatus": "FAIL" if failures else "PASS" if row_count >= 2 else "WARN",
        "warnings": warnings,
        "failures": failures,
        "errorMessage": None if row_count >= 2 else status.get("errorMessage"),
    }


def _write_json(path: Path, payload: dict[str, Any]) -> None:
    path.write_text(
        json.dumps(payload, ensure_ascii=False, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )
