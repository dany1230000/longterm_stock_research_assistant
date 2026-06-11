from __future__ import annotations

import argparse
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
    utc_now_iso,
)


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Update local official 00631L TWSE price history cache.",
    )
    parser.add_argument("--start-date", default="2014-10-31")
    parser.add_argument("--end-date", default="")
    parser.add_argument("--path", default=settings.price_history_path)
    parser.add_argument("--status-only", action="store_true")
    args = parser.parse_args()

    store = PriceHistoryStore(args.path)
    if args.status_only:
        payload = store.status_response(fetched_at=utc_now_iso())
        print(json.dumps(payload, ensure_ascii=False, indent=2, sort_keys=True))
        print(
            "[summary] "
            f"overallStatus={'PASS' if payload['sourceStatus'] == 'cached' else 'WARN'} "
            f"rows={payload.get('rowCount', 0)} "
            f"coverage={payload.get('coverageStart')}..{payload.get('coverageEnd')}"
        )
        return 0

    from datetime import date, datetime, timezone

    start = datetime.strptime(args.start_date, "%Y-%m-%d").date()
    end = (
        datetime.strptime(args.end_date, "%Y-%m-%d").date()
        if args.end_date
        else datetime.now(timezone.utc).date()
    )
    payload = fetch_twse_stock_day_range(
        fetcher=fetch_text,
        url_template=settings.twse_price_history_url_template,
        start_date=start,
        end_date=end,
        timeout_seconds=settings.request_timeout_seconds,
    )
    saved = store.save_points(payload["points"])
    status = store.status_response(fetched_at=utc_now_iso())
    result = {
        **payload,
        "savedRows": saved,
        "historyPath": str(args.path),
        "coverageStart": status.get("coverageStart"),
        "coverageEnd": status.get("coverageEnd"),
        "rowCount": status.get("rowCount"),
    }
    print(json.dumps(result, ensure_ascii=False, indent=2, sort_keys=True))
    overall = "PASS" if result["sourceStatus"] == "official" else "FAIL"
    print(
        "[summary] "
        f"overallStatus={overall} "
        f"fetchedRows={result['rowCount']} "
        f"savedRows={saved} "
        f"warnings={len(result.get('warnings', []))}"
    )
    return 0 if overall == "PASS" else 1


if __name__ == "__main__":
    raise SystemExit(main())
