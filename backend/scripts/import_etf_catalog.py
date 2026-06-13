from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from backend.app.config import settings
from backend.app.etf_catalog import (
    etf_catalog_status,
    parse_twse_etf_catalog,
    save_etf_catalog,
)
from backend.app.fetcher import fetch_text
from backend.app.parsers import utc_now_iso

DEFAULT_TWSE_ALL_ETF_URL = "https://mis.twse.com.tw/stock/data/all_etf.txt"


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Import TWSE all-ETF intraday catalog into local data dir.",
    )
    parser.add_argument("--status-only", action="store_true")
    parser.add_argument("--output", default=settings.etf_catalog_path)
    parser.add_argument(
        "--url",
        default=settings.twse_intraday_nav_url or DEFAULT_TWSE_ALL_ETF_URL,
    )
    args = parser.parse_args()

    fetched_at = utc_now_iso()
    if args.status_only:
        status = etf_catalog_status(args.output, fetched_at=fetched_at)
        print(json.dumps(status, ensure_ascii=False, indent=2))
        if status.get("sourceStatus") in {"cached", "official"}:
            print("PASS ETF catalog cache is available")
        else:
            print("WARN ETF catalog cache is not available yet; run without --status-only to import.")
        return 0

    if not args.url:
        print("FAIL TWSE_00631L_INTRADAY_NAV_URL is required for ETF catalog import.")
        return 1

    try:
        source = fetch_text(args.url, settings.request_timeout_seconds)
        payload = parse_twse_etf_catalog(source, source_url=args.url, fetched_at=fetched_at)
    except Exception as error:  # noqa: BLE001 - CLI should print a short failure.
        print(f"FAIL ETF catalog import failed: {error}")
        return 1

    if payload.get("sourceStatus") != "official":
        print(json.dumps(payload, ensure_ascii=False, indent=2))
        return 1

    save_etf_catalog(payload, args.output)
    print("PASS ETF catalog imported")
    print(f"rows={payload.get('rowCount', 0)}")
    print(f"dataTime={payload.get('dataTime')}")
    print(f"output={args.output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
