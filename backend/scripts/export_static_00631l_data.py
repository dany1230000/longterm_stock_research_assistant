from __future__ import annotations

import argparse
from datetime import date, datetime, timezone
import json
from pathlib import Path
import sys


ROOT = Path(__file__).resolve().parents[2]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from backend.app.config import settings  # noqa: E402
from backend.app.etf_catalog import (  # noqa: E402
    load_etf_catalog,
    parse_twse_etf_catalog,
    save_etf_catalog,
)
from backend.app.etf_price_history import (  # noqa: E402
    DEFAULT_ETF_HISTORY_CODES,
    EtfPriceHistoryStore,
    parse_code_list,
)
from backend.app.fetcher import fetch_text  # noqa: E402
from backend.app.parsers import utc_now_iso  # noqa: E402
from backend.app.price_history import (  # noqa: E402
    PriceHistoryStore,
    fetch_twse_stock_day_range,
)
from backend.app.static_export import (  # noqa: E402
    export_static_00631l_data,
    static_export_status,
)


DEFAULT_TWSE_ALL_ETF_URL = "https://mis.twse.com.tw/stock/data/all_etf.txt"


def build_static_export_summary_line(payload: dict[str, object]) -> str:
    tiers = payload.get("etfPriceHistoryCoverageTierCounts") or {}
    if not isinstance(tiers, dict):
        tiers = {}
    etf_catalog_rows = int(payload.get("etfCatalogRowCount") or 0)
    etf_ready_rows = int(payload.get("etfPriceHistoryReadyCount") or 0)
    etf_history_rows = int(payload.get("etfPriceHistoryRowCount") or 0)
    etf_completion_total = max(etf_catalog_rows, etf_history_rows, etf_ready_rows)
    etf_gap = max(0, etf_completion_total - etf_ready_rows)
    tier_text = (
        ",".join(
            f"{key}:{int(tiers.get(key) or 0)}"
            for key in ("long_term", "recent", "unavailable", "error")
        )
        if tiers
        else "not_available"
    )
    parts = [
        "[summary]",
        f"overallStatus={payload.get('overallStatus', 'UNKNOWN')}",
        f"rows={int(payload.get('rowCount') or 0)}",
        f"coverage={payload.get('coverageStart')}..{payload.get('coverageEnd')}",
        f"etfReady={etf_ready_rows}",
        f"etfRows={etf_history_rows}",
        f"etfCatalogRows={etf_catalog_rows}",
        f"etfGap={etf_gap}",
        f"tiers={tier_text}",
    ]
    if payload.get("outputDir"):
        parts.append(f"output={payload['outputDir']}")
    return " ".join(parts)


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Export static public 00631L data for Flutter Web / GitHub Pages.",
    )
    parser.add_argument("--output-dir", default="web/00631l-static-data")
    parser.add_argument("--price-history-path", default=settings.price_history_path)
    parser.add_argument("--start-date", default="")
    parser.add_argument("--end-date", default="")
    parser.add_argument(
        "--full-refresh",
        action="store_true",
        help="Fetch 00631L price history from 2014-10-31 before static export.",
    )
    parser.add_argument(
        "--seed-price-history-path",
        default=str(ROOT / "backend" / "seeds" / "00631l_price_history_seed.jsonl"),
    )
    parser.add_argument(
        "--etf-catalog-path",
        default=settings.etf_catalog_path,
    )
    parser.add_argument(
        "--etf-catalog-url",
        default=settings.twse_intraday_nav_url or DEFAULT_TWSE_ALL_ETF_URL,
    )
    parser.add_argument(
        "--seed-etf-catalog-path",
        default=str(ROOT / "backend" / "seeds" / "twse_etf_catalog_seed.json"),
    )
    parser.add_argument("--min-row-count", type=int, default=2800)
    parser.add_argument("--min-etf-catalog-row-count", type=int, default=100)
    parser.add_argument(
        "--multi-etf-codes",
        default=",".join(DEFAULT_ETF_HISTORY_CODES),
        help="Selected ETF codes to include in static public price-history files.",
    )
    parser.add_argument(
        "--etf-price-history-dir",
        default=settings.etf_price_history_dir,
    )
    parser.add_argument(
        "--seed-etf-price-history-dir",
        default=str(ROOT / "backend" / "seeds" / "etf_price_history_seed"),
        help=(
            "Committed official baseline ETF price-history seed directory. "
            "Used to keep static Pages export usable when live multi-ETF "
            "refresh is skipped or rate-limited."
        ),
    )
    parser.add_argument("--update", action="store_true")
    parser.add_argument(
        "--update-etf-catalog",
        action="store_true",
        help="Update the TWSE all-ETF catalog before exporting static data.",
    )
    parser.add_argument("--strict", action="store_true")
    parser.add_argument("--status-only", action="store_true")
    args = parser.parse_args()

    if args.status_only:
        payload = static_export_status(args.output_dir)
        print(json.dumps(payload, ensure_ascii=False, indent=2, sort_keys=True))
        print(build_static_export_summary_line(payload))
        return 1 if payload["overallStatus"] == "FAIL" else 0

    store = PriceHistoryStore(args.price_history_path)
    warnings: list[str] = []
    if args.update:
        default_start = date(2014, 10, 31)
        start, update_mode = _prepare_price_history_update_start(
            store=store,
            seed_path=Path(args.seed_price_history_path),
            min_row_count=args.min_row_count,
            warnings=warnings,
            start_date_text=args.start_date,
            full_refresh=args.full_refresh,
            default_start=default_start,
        )
        end = (
            datetime.strptime(args.end_date, "%Y-%m-%d").date()
            if args.end_date
            else datetime.now(timezone.utc).date()
        )
        try:
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
                warnings.append(
                    fetched.get("errorMessage") or "TWSE price history update failed."
                )
            warnings.append(f"updateMode={update_mode}")
            warnings.append(f"updateSavedRows={saved}")
        except Exception as error:  # noqa: BLE001 - seed fallback keeps Pages deployable.
            warnings.append(f"priceHistoryUpdateFailed={error}")
    _merge_seed_if_needed(
        store=store,
        seed_path=Path(args.seed_price_history_path),
        min_row_count=args.min_row_count,
        warnings=warnings,
    )

    etf_catalog_payload = _load_etf_catalog_payload(
        path=Path(args.etf_catalog_path),
        seed_path=Path(args.seed_etf_catalog_path),
        url=args.etf_catalog_url,
        update=args.update or args.update_etf_catalog,
        min_row_count=args.min_etf_catalog_row_count,
        warnings=warnings,
    )
    etf_price_history_store = EtfPriceHistoryStore(args.etf_price_history_dir)
    seed_codes = (
        list(DEFAULT_ETF_HISTORY_CODES)
        if _is_all_local_codes_mode(args.multi_etf_codes)
        else parse_code_list(args.multi_etf_codes)
    )
    _merge_etf_price_history_seed_if_needed(
        store=etf_price_history_store,
        seed_dir=Path(args.seed_etf_price_history_dir),
        codes=seed_codes,
        warnings=warnings,
    )
    multi_etf_codes = _resolve_multi_etf_codes(
        args.multi_etf_codes,
        store=etf_price_history_store,
        warnings=warnings,
    )

    payload = export_static_00631l_data(
        output_dir=args.output_dir,
        price_history_store=store,
        etf_price_history_store=etf_price_history_store,
        etf_price_history_codes=multi_etf_codes,
        etf_catalog_payload=etf_catalog_payload,
        strict=args.strict,
        minimum_row_count=args.min_row_count,
        minimum_catalog_row_count=args.min_etf_catalog_row_count,
        warnings=warnings,
    )
    print(json.dumps(payload, ensure_ascii=False, indent=2, sort_keys=True))
    print(build_static_export_summary_line(payload))
    return 1 if payload["overallStatus"] == "FAIL" else 0


def _prepare_price_history_update_start(
    *,
    store: PriceHistoryStore,
    seed_path: Path,
    min_row_count: int,
    warnings: list[str],
    start_date_text: str,
    full_refresh: bool,
    default_start: date,
) -> tuple[date, str]:
    if start_date_text:
        return datetime.strptime(start_date_text, "%Y-%m-%d").date(), "custom"
    if full_refresh:
        return default_start, "full"
    _merge_seed_if_needed(
        store=store,
        seed_path=seed_path,
        min_row_count=min_row_count,
        warnings=warnings,
    )
    return store.default_incremental_start_date(default_start=default_start), "incremental"


def _load_etf_catalog_payload(
    *,
    path: Path,
    seed_path: Path,
    url: str,
    update: bool,
    min_row_count: int,
    warnings: list[str],
) -> dict[str, object] | None:
    fetched_at = utc_now_iso()
    if update:
        if not url:
            warnings.append("etfCatalogUpdateSkipped=missingUrl")
        else:
            try:
                source = fetch_text(url, settings.request_timeout_seconds)
                payload = parse_twse_etf_catalog(
                    source,
                    source_url=url,
                    fetched_at=fetched_at,
                )
                row_count = int(payload.get("rowCount") or 0)
                if payload.get("sourceStatus") == "official" and row_count >= min_row_count:
                    save_etf_catalog(payload, path)
                    warnings.append(f"etfCatalogUpdateSavedRows={row_count}")
                else:
                    warnings.append(
                        "etfCatalogUpdateInsufficient="
                        f"{row_count}; minRows={min_row_count}"
                    )
            except Exception as error:  # noqa: BLE001 - CLI should continue to seed/cache.
                warnings.append(f"etfCatalogUpdateFailed={error}")

    payload = load_etf_catalog(path, fetched_at=fetched_at)
    if int(payload.get("rowCount") or 0) >= min_row_count:
        return payload

    if seed_path.exists():
        seed_payload = load_etf_catalog(seed_path, fetched_at=fetched_at)
        seed_rows = int(seed_payload.get("rowCount") or 0)
        if seed_rows >= min_row_count:
            warnings.append(
                "seedEtfCatalogUsed="
                f"{seed_path}; seedRows={seed_rows}; localRows={payload.get('rowCount', 0)}"
            )
            return seed_payload
        warnings.append(
            f"seedEtfCatalogInsufficient={seed_path}; seedRows={seed_rows}"
        )
    else:
        warnings.append(f"seedEtfCatalogMissing={seed_path}")

    return payload if payload.get("items") else None


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


def _merge_etf_price_history_seed_if_needed(
    *,
    store: EtfPriceHistoryStore,
    seed_dir: Path,
    codes: list[str],
    warnings: list[str],
) -> None:
    if not seed_dir.exists():
        warnings.append(f"seedEtfPriceHistoryMissing={seed_dir}")
        return

    seed_store = EtfPriceHistoryStore(seed_dir)
    merged = 0
    ready = 0
    for code in codes:
        seed_records = seed_store.all(code)
        if not seed_records:
            warnings.append(f"seedEtfPriceHistoryMissingCode={code}")
            continue
        saved = store.save_points(code, seed_records)
        status = store.status(code, fetched_at=utc_now_iso())
        row_count = int(status.get("rowCount") or 0)
        if row_count >= 2:
            ready += 1
        if saved:
            merged += 1
        warnings.append(
            "seedEtfPriceHistoryMerged="
            f"{code}; seedRows={len(seed_records)}; savedRows={saved}"
        )

    if merged or ready:
        warnings.append(
            f"seedEtfPriceHistoryReady={ready}; merged={merged}; seedDir={seed_dir}"
        )


def _resolve_multi_etf_codes(
    value: str,
    *,
    store: EtfPriceHistoryStore,
    warnings: list[str],
) -> list[str]:
    mode = str(value or "").strip().lower()
    if not _is_all_local_codes_mode(value):
        return parse_code_list(value)

    fetched_at = utc_now_iso()
    codes = []
    skipped = 0
    for code in store.codes():
        status = store.status(code, fetched_at=fetched_at)
        row_count = int(status.get("rowCount") or 0)
        validation_failures = int(status.get("validationFailureCount") or 0)
        if row_count >= 2 and validation_failures == 0:
            codes.append(code)
        else:
            skipped += 1
    warnings.append(
        "multiEtfCodesResolved="
        f"{mode}; readyCodes={len(codes)}; skipped={skipped}"
    )
    return codes


def _is_all_local_codes_mode(value: str) -> bool:
    return str(value or "").strip().lower() in {"all-local", "local", "*"}


if __name__ == "__main__":
    raise SystemExit(main())
