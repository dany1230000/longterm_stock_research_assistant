from __future__ import annotations

import argparse
from datetime import date, datetime, timezone
import json
import os
from pathlib import Path
import subprocess
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
    catalog_codes,
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
    etf_attempted_rows = int(payload.get("etfPriceHistoryAttemptedCount") or 0)
    etf_out_of_catalog_rows = int(
        payload.get("etfPriceHistoryOutOfCatalogCount")
        or max(0, etf_history_rows - etf_catalog_rows)
    )
    etf_missing_rows = int(
        payload.get("etfPriceHistoryMissingCount")
        or max(0, max(etf_catalog_rows, etf_history_rows, etf_ready_rows) - etf_ready_rows)
    )
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
        f"etfMissing={etf_missing_rows}",
        f"etfAttempted={etf_attempted_rows}",
        f"etfOutOfCatalog={etf_out_of_catalog_rows}",
        f"tiers={tier_text}",
    ]
    if payload.get("outputDir"):
        parts.append(f"output={payload['outputDir']}")
    return " ".join(parts)


def build_static_export_compact_response(
    payload: dict[str, object],
    *,
    sample_size: int = 5,
) -> dict[str, object]:
    warnings = [
        str(warning)
        for warning in payload.get("warnings", [])
        if warning is not None
    ]
    failures = [
        str(failure)
        for failure in payload.get("failures", [])
        if failure is not None
    ]
    notes = [
        str(note)
        for note in payload.get("notes", [])
        if note is not None
    ]
    return {
        "sourceStatus": payload.get("sourceStatus"),
        "sourceContract": payload.get("sourceContract"),
        "overallStatus": payload.get("overallStatus"),
        "generatedAt": payload.get("generatedAt"),
        "rowCount": payload.get("rowCount", 0),
        "coverageStart": payload.get("coverageStart"),
        "coverageEnd": payload.get("coverageEnd"),
        "isCompleteFromListing": payload.get("isCompleteFromListing"),
        "etfCatalogRowCount": payload.get("etfCatalogRowCount", 0),
        "etfPriceHistoryReadyCount": payload.get("etfPriceHistoryReadyCount", 0),
        "etfPriceHistoryRowCount": payload.get("etfPriceHistoryRowCount", 0),
        "etfPriceHistoryMissingCount": payload.get("etfPriceHistoryMissingCount", 0),
        "etfPriceHistoryAttemptedCount": payload.get("etfPriceHistoryAttemptedCount", 0),
        "etfPriceHistoryOutOfCatalogCount": payload.get(
            "etfPriceHistoryOutOfCatalogCount",
            0,
        ),
        "etfPriceHistoryCoverageTierCounts": payload.get(
            "etfPriceHistoryCoverageTierCounts",
            {},
        ),
        "etfPriceHistorySeedMerge": payload.get("etfPriceHistorySeedMerge"),
        "outputDir": payload.get("outputDir"),
        "release": payload.get("release"),
        "noteCount": len(notes),
        "notesSample": [
            _truncate_compact_text(note)
            for note in notes[: max(sample_size, 0)]
        ],
        "warningCount": len(warnings),
        "warningsSample": [
            _truncate_compact_text(warning)
            for warning in warnings[: max(sample_size, 0)]
        ],
        "failureCount": len(failures),
        "failures": [
            _truncate_compact_text(failure, limit=240)
            for failure in failures
        ],
    }


def _truncate_compact_text(value: object, *, limit: int = 160) -> str:
    text = str(value or "")
    if len(text) <= limit:
        return text
    return f"{text[: max(limit - 3, 0)]}..."


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
    parser.add_argument(
        "--max-coverage-age-days",
        type=int,
        default=0,
        help=(
            "Fail in --strict mode when price-history coverageEnd is older "
            "than this many days. 0 disables the guard."
        ),
    )
    parser.add_argument("--min-etf-catalog-row-count", type=int, default=100)
    parser.add_argument(
        "--multi-etf-codes",
        default=",".join(DEFAULT_ETF_HISTORY_CODES),
        help=(
            "Selected ETF codes to include in static public price-history files. "
            "Use all-local for ready local histories, or all-catalog to include "
            "every TWSE ETF catalog code in the readiness index."
        ),
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
    parser.add_argument(
        "--summary-only",
        action="store_true",
        help="Print compact summary JSON instead of full warning/file details.",
    )
    args = parser.parse_args()

    if args.status_only:
        payload = static_export_status(args.output_dir)
        output_payload = (
            build_static_export_compact_response(payload)
            if args.summary_only
            else payload
        )
        print(json.dumps(output_payload, ensure_ascii=False, indent=2, sort_keys=True))
        print(build_static_export_summary_line(payload))
        return 1 if payload["overallStatus"] == "FAIL" else 0

    store = PriceHistoryStore(args.price_history_path)
    warnings: list[str] = []
    notes: list[str] = []
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
            notes.append(f"updateMode={update_mode}")
            notes.append(f"updateSavedRows={saved}")
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
        notes=notes,
    )
    etf_price_history_store = EtfPriceHistoryStore(args.etf_price_history_dir)
    seed_codes = _seed_codes_for_multi_etf_mode(
        args.multi_etf_codes,
        seed_dir=Path(args.seed_etf_price_history_dir),
    )
    seed_merge_summary = _merge_etf_price_history_seed_if_needed(
        store=etf_price_history_store,
        seed_dir=Path(args.seed_etf_price_history_dir),
        codes=seed_codes,
        warnings=warnings,
    )
    multi_etf_codes = _resolve_multi_etf_codes(
        args.multi_etf_codes,
        store=etf_price_history_store,
        catalog_payload=etf_catalog_payload,
        warnings=warnings,
        notes=notes,
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
        release_metadata=_build_release_metadata(),
    )
    payload["etfPriceHistorySeedMerge"] = seed_merge_summary
    payload["notes"] = notes
    coverage_age_message = build_coverage_age_message(
        payload.get("coverageEnd"),
        max_age_days=args.max_coverage_age_days,
    )
    if coverage_age_message:
        payload.setdefault("warnings", []).append(coverage_age_message)
        if args.strict:
            payload.setdefault("failures", []).append(coverage_age_message)
            payload["overallStatus"] = "FAIL"
    output_payload = (
        build_static_export_compact_response(payload)
        if args.summary_only
        else payload
    )
    print(json.dumps(output_payload, ensure_ascii=False, indent=2, sort_keys=True))
    print(build_static_export_summary_line(payload))
    return 1 if payload["overallStatus"] == "FAIL" else 0


def build_coverage_age_message(
    coverage_end: object,
    *,
    max_age_days: int,
    today: date | None = None,
) -> str | None:
    if max_age_days <= 0:
        return None
    parsed = _parse_iso_date(str(coverage_end or ""))
    if parsed is None:
        return "priceHistoryCoverageMissing=coverageEnd"
    current = today or datetime.now(timezone.utc).date()
    age_days = (current - parsed).days
    if age_days <= max_age_days:
        return None
    return (
        "priceHistoryCoverageTooOld="
        f"{parsed.isoformat()}; ageDays={age_days}; maxAgeDays={max_age_days}"
    )


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


def _parse_iso_date(value: str) -> date | None:
    try:
        return datetime.strptime(value, "%Y-%m-%d").date()
    except ValueError:
        return None


def _load_etf_catalog_payload(
    *,
    path: Path,
    seed_path: Path,
    url: str,
    update: bool,
    min_row_count: int,
    warnings: list[str],
    notes: list[str],
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
                    notes.append(f"etfCatalogUpdateSavedRows={row_count}")
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
            notes.append(
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
) -> dict[str, object]:
    summary: dict[str, object] = {
        "seedDir": str(seed_dir),
        "requestedCount": len(codes),
        "readyCount": 0,
        "mergedCount": 0,
        "savedRowCount": 0,
        "seedRowCount": 0,
        "missingCount": 0,
        "missingSample": [],
    }
    if not seed_dir.exists():
        warnings.append(f"seedEtfPriceHistoryMissing={seed_dir}")
        summary["missingCount"] = len(codes)
        summary["missingSample"] = codes[:10]
        return summary

    seed_store = EtfPriceHistoryStore(seed_dir)
    merged = 0
    ready = 0
    saved_rows_total = 0
    seed_rows_total = 0
    missing_codes: list[str] = []
    for code in codes:
        seed_records = seed_store.all(code)
        if not seed_records:
            missing_codes.append(code)
            continue
        saved = store.save_points(code, seed_records)
        saved_rows_total += saved
        seed_rows_total += len(seed_records)
        status = store.status(code, fetched_at=utc_now_iso())
        row_count = int(status.get("rowCount") or 0)
        if row_count >= 2:
            ready += 1
        if saved:
            merged += 1

    summary.update(
        {
            "readyCount": ready,
            "mergedCount": merged,
            "savedRowCount": saved_rows_total,
            "seedRowCount": seed_rows_total,
            "missingCount": len(missing_codes),
            "missingSample": missing_codes[:10],
        }
    )
    return summary


def _resolve_multi_etf_codes(
    value: str,
    *,
    store: EtfPriceHistoryStore,
    catalog_payload: dict[str, object] | None = None,
    warnings: list[str],
    notes: list[str],
) -> list[str]:
    mode = str(value or "").strip().lower()
    if not _is_all_local_codes_mode(value):
        if _is_all_catalog_codes_mode(value):
            codes = catalog_codes(catalog_payload or {}, limit=0)
            store_codes = store.codes()
            merged = list(dict.fromkeys(codes + store_codes))
            notes.append(
                "multiEtfCodesResolved="
                f"{mode}; catalogCodes={len(codes)}; localCodes={len(store_codes)}; "
                f"exportCodes={len(merged)}"
            )
            return merged
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
    notes.append(
        "multiEtfCodesResolved="
        f"{mode}; readyCodes={len(codes)}; skipped={skipped}"
    )
    return codes


def _is_all_local_codes_mode(value: str) -> bool:
    return str(value or "").strip().lower() in {"all-local", "local", "*"}


def _is_all_catalog_codes_mode(value: str) -> bool:
    return str(value or "").strip().lower() in {"all-catalog", "catalog"}


def _seed_codes_for_multi_etf_mode(value: str, *, seed_dir: Path) -> list[str]:
    if _is_all_catalog_codes_mode(value):
        seed_codes = [
            path.stem.upper()
            for path in sorted(seed_dir.glob("*.jsonl"))
            if path.stem
        ] if seed_dir.exists() else []
        return seed_codes or list(DEFAULT_ETF_HISTORY_CODES)
    if _is_all_local_codes_mode(value):
        return list(DEFAULT_ETF_HISTORY_CODES)
    return parse_code_list(value)


def _build_release_metadata() -> dict[str, str]:
    release_tag = (
        os.getenv("00631L_BACKEND_RELEASE_TAG", "").strip()
        or _git_exact_release_tag()
        or settings.backend_release_tag
    )
    app_version = (
        os.getenv("00631L_BACKEND_APP_VERSION", "").strip()
        or _version_from_release_tag(release_tag)
        or settings.backend_app_version
    )
    return {
        "appVersion": app_version,
        "releaseTag": release_tag,
        "gitSha": (
            os.getenv("GITHUB_SHA", "").strip()
            or os.getenv("00631L_BACKEND_GIT_SHA", "").strip()
            or _git_head_sha()
        ),
        "buildTime": os.getenv("00631L_BACKEND_BUILD_TIME", "").strip()
        or datetime.now(timezone.utc).replace(microsecond=0).isoformat(),
    }


def _git_exact_release_tag() -> str:
    try:
        result = subprocess.run(
            ["git", "tag", "--points-at", "HEAD", "--list", "00631l-lab-v*"],
            text=True,
            capture_output=True,
            check=False,
            cwd=ROOT,
        )
    except OSError:
        return ""
    if result.returncode != 0:
        return ""
    tags = sorted(line.strip() for line in result.stdout.splitlines() if line.strip())
    return tags[-1] if tags else ""


def _version_from_release_tag(release_tag: str) -> str:
    prefix = "00631l-lab-v"
    if release_tag.startswith(prefix):
        return release_tag[len(prefix) :]
    return ""


def _git_head_sha() -> str:
    try:
        result = subprocess.run(
            ["git", "rev-parse", "HEAD"],
            text=True,
            capture_output=True,
            check=False,
            cwd=ROOT,
        )
    except OSError:
        return ""
    return result.stdout.strip() if result.returncode == 0 else ""


if __name__ == "__main__":
    raise SystemExit(main())
