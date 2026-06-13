from __future__ import annotations

import argparse
from datetime import datetime, timezone
import json
from pathlib import Path
import sys


ROOT = Path(__file__).resolve().parents[2]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from backend.app.config import settings  # noqa: E402
from backend.app.fetcher import fetch_text  # noqa: E402
from backend.app.price_history import (  # noqa: E402
    PriceHistoryStore,
    fetch_twse_stock_day_range,
)
from backend.app.static_export import (  # noqa: E402
    export_static_00631l_data,
    static_export_status,
)


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Export static public 00631L data for Flutter Web / GitHub Pages.",
    )
    parser.add_argument("--output-dir", default="web/00631l-static-data")
    parser.add_argument("--price-history-path", default=settings.price_history_path)
    parser.add_argument("--start-date", default="2014-10-31")
    parser.add_argument("--end-date", default="")
    parser.add_argument(
        "--seed-price-history-path",
        default=str(ROOT / "backend" / "seeds" / "00631l_price_history_seed.jsonl"),
    )
    parser.add_argument("--min-row-count", type=int, default=2800)
    parser.add_argument("--update", action="store_true")
    parser.add_argument("--strict", action="store_true")
    parser.add_argument("--status-only", action="store_true")
    args = parser.parse_args()

    if args.status_only:
        payload = static_export_status(args.output_dir)
        print(json.dumps(payload, ensure_ascii=False, indent=2, sort_keys=True))
        print(
            "[summary] "
            f"overallStatus={payload['overallStatus']} "
            f"rows={payload.get('rowCount', 0)} "
            f"coverage={payload.get('coverageStart')}..{payload.get('coverageEnd')}"
        )
        return 1 if payload["overallStatus"] == "FAIL" else 0

    store = PriceHistoryStore(args.price_history_path)
    warnings: list[str] = []
    if args.update:
        start = datetime.strptime(args.start_date, "%Y-%m-%d").date()
        end = (
            datetime.strptime(args.end_date, "%Y-%m-%d").date()
            if args.end_date
            else datetime.now(timezone.utc).date()
        )
        fetched = fetch_twse_stock_day_range(
            fetcher=fetch_text,
            url_template=settings.twse_price_history_url_template,
            start_date=start,
            end_date=end,
            timeout_seconds=settings.request_timeout_seconds,
        )
        saved = store.save_points(fetched["points"])
        warnings.extend(fetched.get("warnings", []))
        if fetched.get("sourceStatus") != "official":
            warnings.append(fetched.get("errorMessage") or "TWSE price history update failed.")
        warnings.append(f"updateSavedRows={saved}")
        _merge_seed_if_needed(
            store=store,
            seed_path=Path(args.seed_price_history_path),
            min_row_count=args.min_row_count,
            warnings=warnings,
        )

    payload = export_static_00631l_data(
        output_dir=args.output_dir,
        price_history_store=store,
        strict=args.strict,
        minimum_row_count=args.min_row_count,
        warnings=warnings,
    )
    print(json.dumps(payload, ensure_ascii=False, indent=2, sort_keys=True))
    print(
        "[summary] "
        f"overallStatus={payload['overallStatus']} "
        f"rows={payload.get('rowCount', 0)} "
        f"coverage={payload.get('coverageStart')}..{payload.get('coverageEnd')} "
        f"output={payload['outputDir']}"
    )
    return 1 if payload["overallStatus"] == "FAIL" else 0


def _merge_seed_if_needed(
    *,
    store: PriceHistoryStore,
    seed_path: Path,
    min_row_count: int,
    warnings: list[str],
) -> None:
    status = store.status_response(fetched_at=datetime.now(timezone.utc).isoformat())
    row_count = int(status.get("rowCount") or 0)
    if row_count >= min_row_count:
        return
    if not seed_path.exists():
        warnings.append(
            f"seedPriceHistoryMissing={seed_path}; rowCount={row_count}"
        )
        return
    seed_store = PriceHistoryStore(seed_path)
    seed_records = seed_store.all()
    if not seed_records:
        warnings.append(f"seedPriceHistoryEmpty={seed_path}; rowCount={row_count}")
        return
    saved = store.save_points(seed_records)
    merged_status = store.status_response(
        fetched_at=datetime.now(timezone.utc).isoformat()
    )
    warnings.append(
        "seedPriceHistoryMerged="
        f"{len(seed_records)}; seedSavedRows={saved}; "
        f"rowCountBefore={row_count}; rowCountAfter={merged_status.get('rowCount', 0)}"
    )


if __name__ == "__main__":
    raise SystemExit(main())
