from __future__ import annotations

import json
import os
from datetime import date, datetime, timezone
from pathlib import Path
from typing import Any, Callable

from .analysis import AnalysisProvider, RuleBasedAnalysisProvider
from .cache import TimedMemoryCache
from .config import Settings, settings
from .data_integrity import integrity_status
from .etf_catalog import (
    etf_catalog_status,
    load_etf_catalog,
    parse_twse_etf_catalog,
    save_etf_catalog,
)
from .etf_price_history import (
    DEFAULT_ETF_HISTORY_CODES,
    EtfPriceHistoryStore,
    fetch_etf_price_history,
    normalize_etf_code,
    parse_code_list,
)
from .fetcher import FetchError, fetch_text
from .backtest import default_backtest_payload, run_backtest
from .daily_report import report_status
from .holdings_history import HoldingsHistoryStore, empty_history_response
from .intraday_nav_history import (
    IntradayNavHistoryStore,
    empty_intraday_history_response,
)
from .market_session import intraday_market_session
from .price_history import (
    PRICE_ADJUSTMENT_FIELD,
    PriceHistoryStore,
    fetch_twse_stock_day_range,
    performance_summary,
    price_adjustment_metadata,
)
from .taifex_tx import (
    TaifexQuoteFetchConfig,
    fetch_taifex_tx_quote,
    unavailable_tx_quote,
)
from .parsers import (
    empty_holdings_response,
    mark_cached,
    parse_holdings,
    parse_intraday_nav,
    parse_profile,
    parse_yuanta_intraday_nav,
    unavailable_intraday_nav,
    utc_now_iso,
)


FetchText = Callable[[str, float], str]


class Etf00631LService:
    def __init__(
        self,
        *,
        config: Settings = settings,
        fetcher: FetchText = fetch_text,
        cache: TimedMemoryCache | None = None,
        history_store: HoldingsHistoryStore | None = None,
        intraday_history_store: IntradayNavHistoryStore | None = None,
        price_history_store: PriceHistoryStore | None = None,
        etf_price_history_store: EtfPriceHistoryStore | None = None,
        analysis_provider: AnalysisProvider | None = None,
    ) -> None:
        self._config = config
        self._fetcher = fetcher
        self._cache = cache or TimedMemoryCache()
        self._history_store = history_store or HoldingsHistoryStore(
            self._config.holdings_history_path
        )
        self._intraday_history_store = intraday_history_store or IntradayNavHistoryStore(
            self._config.intraday_nav_history_path
        )
        self._price_history_store = price_history_store or PriceHistoryStore(
            self._config.price_history_path,
            seed_path=self._config.price_history_seed_path,
        )
        self._etf_price_history_store = (
            etf_price_history_store
            or EtfPriceHistoryStore(
                self._config.etf_price_history_dir,
                seed_dir=self._config.etf_price_history_seed_dir,
            )
        )
        self._analysis_provider = analysis_provider or RuleBasedAnalysisProvider()

    def health_status(self, *, server_time: str | None = None) -> dict[str, Any]:
        now = server_time or utc_now_iso()
        env_status = self._env_status()
        return {
            "status": "ok",
            "serverTime": now,
            "appName": "00631L lab backend",
            "appVersion": "3.4-live-backend",
            "sourceContract": "00631l_backend_health",
            "scope": "00631L only",
            "publicApiBaseUrl": self._config.public_api_base_url,
            "allowedOrigins": list(self._config.allowed_origins),
            "liveSourceConfigured": {
                "twseIntradayNav": bool(self._config.twse_intraday_nav_url),
                "yuantaIntradayNav": bool(self._config.yuanta_intraday_nav_url),
                "yuantaProfile": bool(self._config.yuanta_profile_url),
                "yuantaHoldings": bool(self._config.yuanta_holdings_url),
                "twsePriceHistory": bool(self._config.twse_price_history_url_template),
                "taifexTxQuote": bool(self._config.taifex_tx_sockjs_url),
                "twseEtfCatalog": bool(self._config.twse_intraday_nav_url),
            },
            "localState": {
                "envFileExists": env_status["envFileExists"],
                "dataDirReady": env_status["dataDirReady"],
                "exportDirReady": env_status["exportDirReady"],
                "backupDirReady": env_status["backupDirReady"],
                "dataDir": self._config.data_dir,
                "dataPersistenceMode": self._config.data_persistence_mode,
                "dataPersistenceWarning": env_status["dataPersistenceWarning"],
                "missingKeys": env_status["missingKeys"],
                "optionalMissingKeys": env_status["optionalMissingKeys"],
            },
            "endpoints": {
                "readiness": "/ready",
                "profile": "/api/etf/00631l/profile",
                "holdings": "/api/etf/00631l/holdings",
                "intradayNav": "/api/etf/00631l/intraday-nav",
                "operationsStatus": "/api/etf/00631l/operations/status",
                "analysisSummary": "/api/etf/00631l/analysis/summary",
                "priceHistory": "/api/etf/00631l/history/price",
                "pricePerformance": "/api/etf/00631l/history/performance",
                "txQuote": "/api/etf/00631l/tx-quote",
                "etfCatalog": "/api/etf/catalog",
                "backtestDefaults": "/api/etf/00631l/backtest/defaults",
                "backtestRun": "/api/etf/00631l/backtest/run",
            },
        }

    def readiness_status(self) -> dict[str, Any]:
        now = utc_now_iso()
        checks = [
            self._readiness_public_api_check(),
            self._readiness_cors_check(),
            self._readiness_data_dir_check(),
            self._readiness_persistence_check(),
            self._readiness_url_check(
                "twse_intraday_nav_url",
                self._config.twse_intraday_nav_url,
                required=True,
            ),
            self._readiness_url_check(
                "yuanta_intraday_nav_url",
                self._config.yuanta_intraday_nav_url,
                required=False,
            ),
            self._readiness_url_check(
                "twse_price_history_url_template",
                self._config.twse_price_history_url_template,
                required=True,
            ),
            self._readiness_url_check(
                "taifex_tx_sockjs_url",
                self._config.taifex_tx_sockjs_url,
                required=False,
            ),
            self._readiness_live_source_check(),
        ]
        failures = [
            f"{check['name']}: {check['message']}"
            for check in checks
            if check["status"] == "FAIL"
        ]
        warnings = [
            f"{check['name']}: {check['message']}"
            for check in checks
            if check["status"] == "WARN"
        ]
        overall_status = "FAIL" if failures else "WARN" if warnings else "PASS"
        return {
            "status": "ok" if not failures else "degraded",
            "sourceStatus": "cached" if not failures else "error",
            "sourceContract": "00631l_backend_readiness",
            "sourceUrl": "local://00631l-backend-readiness",
            "checkedAt": now,
            "fetchedAt": now,
            "sourceUpdatedAt": now,
            "dataTime": now,
            "isStale": bool(warnings),
            "overallStatus": overall_status,
            "failures": failures,
            "warnings": warnings,
            "checks": checks,
            "publicApiBaseUrl": self._config.public_api_base_url,
            "allowedOrigins": list(self._config.allowed_origins),
            "dataDir": self._config.data_dir,
            "dataPersistenceMode": self._config.data_persistence_mode,
            "errorMessage": "; ".join(failures) if failures else None,
        }

    def profile(self) -> dict[str, Any]:
        now = utc_now_iso()
        cached = self._cache.get("profile", self._config.profile_cache_seconds)
        if cached is not None:
            return mark_cached(cached, fetched_at=now)

        try:
            source = self._fetcher(self._config.yuanta_profile_url, self._config.request_timeout_seconds)
            payload = parse_profile(
                source,
                source_url=self._config.yuanta_profile_url,
                fetched_at=now,
            )
            if payload["sourceStatus"] not in {"error", "unavailable"}:
                self._cache.set("profile", payload)
            return payload
        except (FetchError, OSError, RuntimeError) as error:
            stale = self._cache.get_any("profile")
            if stale is not None:
                return mark_cached(stale, fetched_at=now, error_message=f"Live profile fetch failed: {error}")
            return parse_profile(
                "",
                source_url=self._config.yuanta_profile_url,
                fetched_at=now,
                source_status="mock",
                error_message=f"Live profile fetch failed; returning profile fallback: {error}",
            )

    def holdings(self) -> dict[str, Any]:
        now = utc_now_iso()
        cached = self._cache.get("holdings", self._config.holdings_cache_seconds)
        if cached is not None:
            return mark_cached(cached, fetched_at=now)

        try:
            source = self._fetcher(self._config.yuanta_holdings_url, self._config.request_timeout_seconds)
            payload = parse_holdings(
                source,
                source_url=self._config.yuanta_holdings_url,
                fetched_at=now,
            )
            if payload["sourceStatus"] not in {"error", "unavailable"}:
                self._cache.set("holdings", payload)
                if payload["sourceStatus"] == "official":
                    try:
                        self._history_store.save_official_snapshot(payload)
                    except OSError:
                        pass
            else:
                fallback = self._holdings_history_fallback(
                    now=now,
                    error_message=f"Live holdings unavailable: {payload.get('errorMessage')}",
                )
                if fallback is not None:
                    return fallback
            return payload
        except (FetchError, OSError, RuntimeError) as error:
            stale = self._cache.get_any("holdings")
            if stale is not None:
                return mark_cached(stale, fetched_at=now, error_message=f"Live holdings fetch failed: {error}")
            fallback = self._holdings_history_fallback(
                now=now,
                error_message=f"Live holdings fetch failed: {error}",
            )
            if fallback is not None:
                return fallback
            return empty_holdings_response(
                source_url=self._config.yuanta_holdings_url,
                fetched_at=now,
                error_message=f"Live holdings fetch failed and no cached snapshot is available: {error}",
            )

    def _holdings_history_fallback(self, *, now: str, error_message: str) -> dict[str, Any] | None:
        try:
            records = self._history_store.recent(1)
        except (OSError, RuntimeError):
            return None
        if not records:
            return None

        cached = dict(records[0])
        cached["sourceStatus"] = "cached"
        cached["sourceContract"] = "local_jsonl_history"
        cached["sourceUrl"] = "local://00631l-holdings-history"
        cached["fetchedAt"] = now
        cached["dataTime"] = cached.get("dataTime") or cached.get("sourceUpdatedAt")
        cached["sourceUpdatedAt"] = cached.get("sourceUpdatedAt") or cached.get("dataTime")
        cached["isStale"] = bool(cached.get("isStale", False))
        cached["errorMessage"] = error_message
        self._cache.set("holdings", cached)
        return cached

    def holdings_history(self, *, limit: int = 30) -> dict[str, Any]:
        now = utc_now_iso()
        try:
            return self._history_store.history_response(limit=limit, fetched_at=now)
        except (OSError, RuntimeError) as error:
            return empty_history_response(
                limit=limit,
                fetched_at=now,
                error_message=f"Holdings history read failed: {error}",
            )

    def holdings_history_summary(self, *, limit: int = 30) -> dict[str, Any]:
        now = utc_now_iso()
        try:
            return self._history_store.summary_response(limit=limit, fetched_at=now)
        except (OSError, RuntimeError) as error:
            return empty_history_response(
                limit=limit,
                fetched_at=now,
                error_message=f"Holdings history summary read failed: {error}",
            )

    def intraday_nav(self) -> dict[str, Any]:
        now = utc_now_iso()
        candidates = self._intraday_candidates()
        if not candidates:
            return self._with_intraday_market_session(
                unavailable_intraday_nav(
                    "",
                    now,
                    "No intraday NAV URL is configured for 00631L",
                ),
                now=now,
            )

        cached = self._cache.get("intraday_nav", self._config.intraday_cache_seconds)
        if cached is not None:
            return self._with_intraday_market_session(
                mark_cached(cached, fetched_at=now),
                now=now,
            )

        errors: list[str] = []
        for source_name, url, parser in candidates:
            try:
                source = self._fetcher(url, self._config.request_timeout_seconds)
                payload = parser(source, source_url=url, fetched_at=now)
                if payload["sourceStatus"] not in {"error", "unavailable"}:
                    payload = self._with_intraday_market_session(payload, now=now)
                    self._cache.set("intraday_nav", payload)
                    if payload["sourceStatus"] == "official":
                        try:
                            self._intraday_history_store.save_official_nav(payload)
                        except OSError:
                            pass
                    return payload
                errors.append(f"{source_name}: {payload.get('errorMessage')}")
            except (FetchError, OSError, RuntimeError, ValueError) as error:
                errors.append(f"{source_name}: {error}")

        stale = self._cache.get_any("intraday_nav")
        joined = "; ".join(error for error in errors if error) or "all intraday NAV sources failed"
        if stale is not None:
            return self._with_intraday_market_session(
                mark_cached(
                    stale,
                    fetched_at=now,
                    error_message=f"Live intraday NAV fetch failed: {joined}",
                ),
                now=now,
            )
        source_url = candidates[0][1] if candidates else ""
        return self._with_intraday_market_session(
            unavailable_intraday_nav(
                source_url,
                now,
                f"Live intraday NAV fetch failed and no cached data is available: {joined}",
                source_status="error",
            ),
            now=now,
        )

    def _with_intraday_market_session(
        self,
        payload: dict[str, Any],
        *,
        now: str,
    ) -> dict[str, Any]:
        session = intraday_market_session(
            now_iso=now,
            data_time_iso=payload.get("dataTime"),
            user_delay_ms=payload.get("userDelayMs"),
        )
        enriched = dict(payload)
        enriched["marketSession"] = session
        if enriched.get("sourceStatus") in {"error", "unavailable"}:
            enriched["isStale"] = True
        elif session["phase"] == "regular":
            enriched["isStale"] = not session["isIntradayFresh"]
        elif enriched.get("dataTime"):
            enriched["isStale"] = False
        else:
            enriched["isStale"] = True
        return enriched

    def tx_quote(self) -> dict[str, Any]:
        now = utc_now_iso()
        source_url = self._config.taifex_tx_sockjs_url
        if not source_url:
            return unavailable_tx_quote(
                "",
                now,
                "TAIFEX TX quote URL is not configured.",
            )
        cached = self._cache.get("tx_quote", self._config.tx_quote_cache_seconds)
        if cached is not None:
            return mark_cached(cached, fetched_at=now)
        try:
            payload = fetch_taifex_tx_quote(
                TaifexQuoteFetchConfig(
                    sockjs_url=source_url,
                    futures_symbol=self._config.taifex_tx_futures_symbol,
                    spot_symbol=self._config.taifex_tx_spot_symbol,
                    timeout_seconds=self._config.request_timeout_seconds,
                ),
                fetched_at=now,
            )
        except (OSError, RuntimeError, ValueError) as error:
            stale = self._cache.get_any("tx_quote")
            if stale is not None:
                return mark_cached(
                    stale,
                    fetched_at=now,
                    error_message=f"Live TAIFEX TX quote fetch failed: {error}",
                )
            return unavailable_tx_quote(
                source_url,
                now,
                f"Live TAIFEX TX quote fetch failed: {error}",
            )
        if payload["sourceStatus"] == "official":
            self._cache.set("tx_quote", payload)
        return payload

    def etf_catalog(self) -> dict[str, Any]:
        now = utc_now_iso()
        return load_etf_catalog(self._config.etf_catalog_path, fetched_at=now)

    def etf_catalog_status(self) -> dict[str, Any]:
        now = utc_now_iso()
        return etf_catalog_status(self._config.etf_catalog_path, fetched_at=now)

    def etf_catalog_import(self) -> dict[str, Any]:
        now = utc_now_iso()
        if not self._config.twse_intraday_nav_url:
            return {
                "sourceStatus": "unavailable",
                "sourceContract": "twse_all_etf_catalog_import",
                "sourceUrl": "",
                "fetchedAt": now,
                "rowCount": 0,
                "outputPath": self._config.etf_catalog_path,
                "errorMessage": "TWSE_00631L_INTRADAY_NAV_URL is required for ETF catalog import.",
            }
        try:
            source = self._fetcher(
                self._config.twse_intraday_nav_url,
                self._config.request_timeout_seconds,
            )
            payload = parse_twse_etf_catalog(
                source,
                source_url=self._config.twse_intraday_nav_url,
                fetched_at=now,
            )
            if payload.get("sourceStatus") == "official":
                save_etf_catalog(payload, self._config.etf_catalog_path)
            return {
                **payload,
                "sourceContract": "twse_all_etf_catalog_import",
                "outputPath": self._config.etf_catalog_path,
            }
        except (FetchError, OSError, RuntimeError, ValueError) as error:
            return {
                "sourceStatus": "error",
                "sourceContract": "twse_all_etf_catalog_import",
                "sourceUrl": self._config.twse_intraday_nav_url,
                "fetchedAt": now,
                "rowCount": 0,
                "outputPath": self._config.etf_catalog_path,
                "errorMessage": f"ETF catalog import failed: {error}",
            }

    def intraday_nav_history(
        self,
        *,
        date: str | None = None,
        limit: int = 500,
    ) -> dict[str, Any]:
        now = utc_now_iso()
        try:
            return self._intraday_history_store.history_response(
                date=date,
                limit=limit,
                fetched_at=now,
            )
        except (OSError, RuntimeError) as error:
            return empty_intraday_history_response(
                fetched_at=now,
                error_message=f"Intraday NAV history read failed: {error}",
            )

    def intraday_nav_history_summary(
        self,
        *,
        date: str | None = None,
    ) -> dict[str, Any]:
        now = utc_now_iso()
        try:
            return self._intraday_history_store.summary_response(
                date=date,
                fetched_at=now,
            )
        except (OSError, RuntimeError) as error:
            return empty_intraday_history_response(
                fetched_at=now,
                error_message=f"Intraday NAV history summary read failed: {error}",
            )

    def price_history(self, *, limit: int = 5000) -> dict[str, Any]:
        now = utc_now_iso()
        try:
            return self._price_history_store.price_response(
                limit=limit,
                fetched_at=now,
            )
        except (OSError, RuntimeError) as error:
            return _empty_price_history_response(
                limit=limit,
                fetched_at=now,
                error_message=f"Price history read failed: {error}",
            )

    def price_history_performance(self) -> dict[str, Any]:
        now = utc_now_iso()
        try:
            return self._price_history_store.performance_response(fetched_at=now)
        except (OSError, RuntimeError) as error:
            return _empty_performance_response(
                fetched_at=now,
                error_message=f"Price performance read failed: {error}",
            )

    def price_history_status(self) -> dict[str, Any]:
        now = utc_now_iso()
        try:
            return self._price_history_store.status_response(fetched_at=now)
        except (OSError, RuntimeError) as error:
            return _empty_performance_response(
                fetched_at=now,
                error_message=f"Price history status read failed: {error}",
            )

    def price_history_update(
        self,
        *,
        start_date: str | None = None,
        end_date: str | None = None,
    ) -> dict[str, Any]:
        now = utc_now_iso()
        default_start = date(2014, 10, 31)
        parsed_start = _parse_date(start_date)
        start = parsed_start or self._price_history_store.default_incremental_start_date(
            default_start=default_start
        )
        update_mode = "custom" if parsed_start else "incremental"
        end = _parse_date(end_date) or datetime.now(timezone.utc).date()
        try:
            fetched = fetch_twse_stock_day_range(
                fetcher=self._fetcher,
                url_template=self._config.twse_price_history_url_template,
                start_date=start,
                end_date=end,
                timeout_seconds=self._config.request_timeout_seconds,
            )
            saved_count = self._price_history_store.save_points(fetched["points"])
            status = self._price_history_store.status_response(fetched_at=now)
            return {
                "sourceStatus": fetched["sourceStatus"],
                "sourceContract": "twse_stock_day_history_update",
                "sourceUrl": fetched["sourceUrl"],
                "fetchedAt": now,
                "sourceUpdatedAt": status.get("coverageEnd"),
                "dataTime": status.get("coverageEnd"),
                "requestedMonths": fetched["requestedMonths"],
                "fetchedRows": fetched["rowCount"],
                "savedRows": saved_count,
                "updateMode": update_mode,
                "coverageStart": status.get("coverageStart"),
                "coverageEnd": status.get("coverageEnd"),
                "isStale": status.get("isStale"),
                "warnings": fetched["warnings"],
                "errorMessage": fetched.get("errorMessage"),
            }
        except (OSError, RuntimeError, ValueError, FetchError) as error:
            return {
                "sourceStatus": "error",
                "sourceContract": "twse_stock_day_history_update",
                "sourceUrl": self._config.twse_price_history_url_template,
                "fetchedAt": now,
                "sourceUpdatedAt": None,
                "dataTime": None,
                "requestedMonths": 0,
                "fetchedRows": 0,
                "savedRows": 0,
                "coverageStart": None,
                "coverageEnd": None,
                "isStale": True,
                "warnings": [],
                "errorMessage": f"Price history update failed: {error}",
            }

    def etf_price_history_index(self) -> dict[str, Any]:
        return self._etf_price_history_store.index_response(fetched_at=utc_now_iso())

    def etf_price_history(self, *, code: str, limit: int = 5000) -> dict[str, Any]:
        now = utc_now_iso()
        normalized = normalize_etf_code(code)
        if not normalized:
            return {
                "code": code,
                "items": [],
                "limit": limit,
                "sourceStatus": "error",
                "sourceContract": "twse_multi_etf_stock_day",
                "sourceUrl": "",
                "fetchedAt": now,
                "sourceUpdatedAt": None,
                "dataTime": None,
                "coverageStart": None,
                "coverageEnd": None,
                "rowCount": 0,
                "isStale": True,
                "priceField": "close",
                "errorMessage": f"Invalid ETF code: {code}",
            }
        return self._etf_price_history_store.price_response(
            code=normalized,
            limit=limit,
            fetched_at=now,
        )

    def etf_price_history_update(
        self,
        *,
        codes: str | None = None,
        start_date: str | None = None,
        end_date: str | None = None,
    ) -> dict[str, Any]:
        now = utc_now_iso()
        requested_codes = parse_code_list(codes or "")
        if not requested_codes:
            requested_codes = list(DEFAULT_ETF_HISTORY_CODES)
        parsed_start = _parse_date(start_date)
        default_start = date(2019, 1, 1)
        end = _parse_date(end_date) or datetime.now(timezone.utc).date()
        items: list[dict[str, Any]] = []
        warnings: list[str] = []
        failures: list[str] = []
        for code in requested_codes:
            if parsed_start is not None:
                start = parsed_start
                update_mode = "custom"
            else:
                start = self._etf_price_history_store.default_incremental_start_date(
                    code,
                    default_start=default_start,
                )
                update_mode = "incremental"
            try:
                fetched = fetch_etf_price_history(
                    code=code,
                    fetcher=self._fetcher,
                    url_template=self._config.twse_price_history_url_template,
                    start_date=start,
                    end_date=end,
                    timeout_seconds=self._config.request_timeout_seconds,
                )
                saved = self._etf_price_history_store.save_points(
                    code,
                    fetched["points"],
                )
                normalized_rows = self._etf_price_history_store.normalize_saved_records(
                    code,
                )
                status = self._etf_price_history_store.status(code, fetched_at=now)
                if fetched.get("sourceStatus") != "official":
                    failures.append(f"{code}: {fetched.get('errorMessage')}")
                warnings.extend(f"{code}: {warning}" for warning in fetched.get("warnings", []))
                validation = status.get("validation") or {}
                warnings.extend(
                    f"{code}: validation: {warning}"
                    for warning in validation.get("warnings", [])
                )
                failures.extend(
                    f"{code}: validation: {failure}"
                    for failure in validation.get("failures", [])
                )
                items.append(
                    {
                        "code": code,
                        "sourceStatus": fetched.get("sourceStatus"),
                        "requestedMonths": fetched.get("requestedMonths"),
                        "fetchedRows": fetched.get("rowCount"),
                        "savedRows": saved,
                        "normalizedRows": normalized_rows,
                        "updateMode": update_mode,
                        "coverageStart": status.get("coverageStart"),
                        "coverageEnd": status.get("coverageEnd"),
                        "rowCount": status.get("rowCount"),
                        "priceField": status.get("priceField"),
                        "validationStatus": status.get("validationStatus"),
                        "validationFailureCount": status.get("validationFailureCount"),
                        "validationWarningCount": status.get("validationWarningCount"),
                        "errorMessage": fetched.get("errorMessage"),
                    }
                )
            except (OSError, RuntimeError, ValueError, FetchError) as error:
                failures.append(f"{code}: {error}")
                items.append(
                    {
                        "code": code,
                        "sourceStatus": "error",
                        "requestedMonths": 0,
                        "fetchedRows": 0,
                        "savedRows": 0,
                        "coverageStart": None,
                        "coverageEnd": None,
                        "rowCount": 0,
                        "errorMessage": str(error),
                    }
                )
        index = self._etf_price_history_store.index_response(fetched_at=now)
        return {
            "sourceStatus": "error" if failures else "cached",
            "sourceContract": "twse_multi_etf_price_history_update",
            "sourceUrl": self._config.twse_price_history_url_template,
            "fetchedAt": now,
            "sourceUpdatedAt": index.get("sourceUpdatedAt"),
            "dataTime": index.get("dataTime"),
            "requestedCodes": requested_codes,
            "updatedCount": len([item for item in items if item.get("rowCount")]),
            "readyCount": index.get("readyCount", 0),
            "validationFailureCount": index.get("validationFailureCount", 0),
            "validationWarningCount": index.get("validationWarningCount", 0),
            "items": items,
            "warnings": warnings,
            "failures": failures,
            "errorMessage": "; ".join(failures) if failures else None,
        }

    def backtest_defaults(self) -> dict[str, Any]:
        return default_backtest_payload()

    def backtest_run(self, payload: dict[str, Any]) -> dict[str, Any]:
        records = self._price_history_store.all()
        return run_backtest(request=payload, history=records)

    def operations_status(self) -> dict[str, Any]:
        now = utc_now_iso()
        holdings = self.holdings_history_summary(limit=1)
        intraday = self.intraday_nav_history_summary()
        tx_quote = self._cache.get_any("tx_quote") or unavailable_tx_quote(
            self._config.taifex_tx_sockjs_url,
            now,
            "TAIFEX TX quote has not been fetched in this backend process yet.",
        )
        catalog_status = self.etf_catalog_status()
        price_history_status = self.price_history_status()
        etf_price_history = self.etf_price_history_index()
        export_status = self._export_status()
        backup_status = self._backup_status()
        report = report_status(self._config.report_dir)
        daily_cycle_status = self._daily_cycle_status()
        integrity = integrity_status(self._config.integrity_status_path)
        env_status = self._env_status()
        data_directory_health = self._data_directory_health(
            backup_status=backup_status,
            export_status=export_status,
        )
        holdings_items = holdings.get("items") if isinstance(holdings.get("items"), list) else []
        latest_holding = holdings_items[0] if holdings_items else {}
        intraday_items = intraday.get("items") if isinstance(intraday.get("items"), list) else []
        latest_intraday = intraday_items[0] if intraday_items else {}
        intraday_market = intraday_market_session(
            now_iso=now,
            data_time_iso=latest_intraday.get("dataTime") or intraday.get("lastDataTime"),
            user_delay_ms=self._config.intraday_cache_seconds * 1000,
        )
        errors = [
            value.get("errorMessage")
            for value in (holdings, intraday, tx_quote)
            if value.get("sourceStatus") == "error" and value.get("errorMessage")
        ]
        source_status = (
            "error"
            if errors
            else "cached"
            if holdings_items or intraday.get("sampleCount", 0)
            else "unavailable"
        )
        source_updated_at = (
            latest_intraday.get("dataTime")
            or latest_holding.get("sourceUpdatedAt")
            or holdings.get("sourceUpdatedAt")
            or intraday.get("sourceUpdatedAt")
        )
        return {
            "sourceStatus": source_status,
            "sourceContract": "00631l_operations_status",
            "sourceUrl": "local://00631l-operations-status",
            "fetchedAt": now,
            "sourceUpdatedAt": source_updated_at,
            "dataTime": source_updated_at,
            "isStale": source_status != "cached",
            "errorMessage": "; ".join(str(error) for error in errors) if errors else None,
            "config": {
                "publicApiBaseUrl": self._config.public_api_base_url,
                "allowedOrigins": list(self._config.allowed_origins),
                "dataDir": self._config.data_dir,
                "dataPersistenceMode": self._config.data_persistence_mode,
                "intradaySourceMode": self._config.intraday_nav_source,
                "twseIntradayNavConfigured": bool(self._config.twse_intraday_nav_url),
                "yuantaIntradayNavConfigured": bool(self._config.yuanta_intraday_nav_url),
                "envFileExists": env_status["envFileExists"],
                "missingKeys": env_status["missingKeys"],
                "optionalMissingKeys": env_status["optionalMissingKeys"],
                "dataPersistenceWarning": env_status["dataPersistenceWarning"],
                "dataDirReady": env_status["dataDirReady"],
                "exportDirReady": env_status["exportDirReady"],
                "backupDirReady": env_status["backupDirReady"],
                "profileCacheSeconds": self._config.profile_cache_seconds,
                "holdingsCacheSeconds": self._config.holdings_cache_seconds,
                "intradayNavCacheSeconds": self._config.intraday_cache_seconds,
                "txQuoteCacheSeconds": self._config.tx_quote_cache_seconds,
                "taifexTxQuoteConfigured": bool(self._config.taifex_tx_sockjs_url),
                "taifexTxFuturesSymbol": self._config.taifex_tx_futures_symbol,
                "taifexTxSpotSymbol": self._config.taifex_tx_spot_symbol,
                "holdingsHistoryPathConfigured": bool(self._config.holdings_history_path),
                "intradayNavHistoryPathConfigured": bool(self._config.intraday_nav_history_path),
                "priceHistoryPathConfigured": bool(self._config.price_history_path),
                "etfCatalogPathConfigured": bool(self._config.etf_catalog_path),
                "etfPriceHistoryDirConfigured": bool(
                    self._config.etf_price_history_dir
                ),
                "twsePriceHistoryUrlTemplateConfigured": bool(self._config.twse_price_history_url_template),
                "historyExportDir": self._config.history_export_dir,
                "dailyCycleStatusPath": self._config.daily_cycle_status_path,
                "backupDir": self._config.backup_dir,
                "reportDir": self._config.report_dir,
            },
            "dataDirectoryHealth": data_directory_health,
            "dataUpdateFrequencies": _data_update_frequencies(
                intraday_cache_seconds=self._config.intraday_cache_seconds,
            ),
            "holdingsHistory": {
                "sourceStatus": holdings.get("sourceStatus"),
                "sourceContract": holdings.get("sourceContract"),
                "itemCount": len(holdings_items),
                "latestTradeDate": latest_holding.get("tradeDate"),
                "sourceUpdatedAt": holdings.get("sourceUpdatedAt"),
                "isStale": holdings.get("isStale"),
                "errorMessage": holdings.get("errorMessage"),
            },
            "intradayNavHistory": {
                "sourceStatus": intraday.get("sourceStatus"),
                "sourceContract": intraday.get("sourceContract"),
                "sampleCount": intraday.get("sampleCount", 0),
                "latestDataTime": latest_intraday.get("dataTime") or intraday.get("lastDataTime"),
                "marketSession": intraday_market,
                "date": intraday.get("date"),
                "sourceUpdatedAt": intraday.get("sourceUpdatedAt"),
                "isStale": intraday.get("isStale"),
                "errorMessage": intraday.get("errorMessage"),
            },
            "priceHistory": {
                "sourceStatus": price_history_status.get("sourceStatus"),
                "sourceContract": price_history_status.get("sourceContract"),
                "rowCount": price_history_status.get("rowCount", 0),
                "coverageStart": price_history_status.get("coverageStart"),
                "coverageEnd": price_history_status.get("coverageEnd"),
                "isCompleteFromListing": price_history_status.get("isCompleteFromListing"),
                "isStale": price_history_status.get("isStale"),
                "errorMessage": price_history_status.get("errorMessage"),
            },
            "txQuote": {
                "sourceStatus": tx_quote.get("sourceStatus"),
                "sourceContract": tx_quote.get("sourceContract"),
                "txSymbol": tx_quote.get("txSymbol"),
                "spotSymbol": tx_quote.get("spotSymbol"),
                "txPrice": tx_quote.get("txPrice"),
                "weightedIndex": tx_quote.get("weightedIndex"),
                "futuresBasisPct": tx_quote.get("futuresBasisPct"),
                "dataTime": tx_quote.get("dataTime"),
                "isStale": tx_quote.get("isStale"),
                "errorMessage": tx_quote.get("errorMessage"),
            },
            "etfCatalog": {
                "sourceStatus": catalog_status.get("sourceStatus"),
                "sourceContract": catalog_status.get("sourceContract"),
                "rowCount": catalog_status.get("rowCount", 0),
                "sourceUpdatedAt": catalog_status.get("sourceUpdatedAt"),
                "dataTime": catalog_status.get("dataTime"),
                "isStale": catalog_status.get("isStale"),
                "errorMessage": catalog_status.get("errorMessage"),
            },
            "etfPriceHistory": {
                "sourceStatus": etf_price_history.get("sourceStatus"),
                "sourceContract": etf_price_history.get("sourceContract"),
                "rowCount": etf_price_history.get("rowCount", 0),
                "readyCount": etf_price_history.get("readyCount", 0),
                "sourceUpdatedAt": etf_price_history.get("sourceUpdatedAt"),
                "dataTime": etf_price_history.get("dataTime"),
                "isStale": etf_price_history.get("isStale"),
                "errorMessage": etf_price_history.get("errorMessage"),
            },
            "backtest": {
                "sourceStatus": "cached"
                if price_history_status.get("sourceStatus") == "cached"
                else "unavailable",
                "sourceContract": "00631l_backtest_data_availability",
                "available": price_history_status.get("rowCount", 0) >= 2,
                "priceHistoryRows": price_history_status.get("rowCount", 0),
                "errorMessage": None
                if price_history_status.get("rowCount", 0) >= 2
                else "Price history needs at least two rows before backtest can run.",
            },
            "position": {
                "sourceStatus": "local_only",
                "sourceContract": "00631l_frontend_local_position",
                "storage": "browser_local_storage",
                "uploadedToBackend": False,
                "errorMessage": None,
            },
            "export": export_status,
            "backup": backup_status,
            "report": report,
            "dailyCycle": daily_cycle_status,
            "integrity": integrity,
            "backendHealth": self.health_status(server_time=now),
            "statusSummary": {
                "operations": source_status,
                "holdingsHistory": holdings.get("sourceStatus"),
                "intradayHistory": intraday.get("sourceStatus"),
                "txQuote": tx_quote.get("sourceStatus"),
                "etfCatalog": catalog_status.get("sourceStatus"),
                "priceHistory": price_history_status.get("sourceStatus"),
                "export": export_status["sourceStatus"],
                "backup": backup_status["sourceStatus"],
                "report": report["sourceStatus"],
                "dailyCycle": daily_cycle_status["sourceStatus"],
                "integrity": integrity.get("sourceStatus"),
                "env": env_status["sourceStatus"],
            },
            "collector": {
                "oneShotCommand": "scripts\\00631l_collect_snapshot.cmd --samples 1",
                "intradayCommand": (
                    "scripts\\00631l_collect_snapshot.cmd --skip-profile "
                    "--skip-holdings --samples 20 --interval-seconds 15"
                ),
            },
        }

    def analysis_summary(self) -> dict[str, Any]:
        now = utc_now_iso()
        try:
            operations = self.operations_status()
            holdings = self.holdings_history_summary(limit=30)
            intraday = self.intraday_nav_history_summary()
            price_history = self.price_history_performance()
            integrity = _read_json_file(Path(self._config.integrity_status_path))
            payload = self._analysis_provider.summarize(
                {
                    "operations": operations,
                    "holdingsHistory": holdings,
                    "intradayNavHistory": intraday,
                    "priceHistory": price_history,
                    "integrity": integrity,
                }
            )
            payload.setdefault("sourceStatus", "cached")
            payload.setdefault("sourceContract", "00631l_rule_based_analysis_summary")
            payload.setdefault("generatedAt", now)
            payload.setdefault("disclaimer", "非買賣建議")
            return payload
        except (OSError, RuntimeError, ValueError) as error:
            return {
                "source": "rule_based",
                "sourceStatus": "error",
                "sourceContract": "00631l_rule_based_analysis_summary",
                "generatedAt": now,
                "dataTime": None,
                "readinessLevel": "action_needed",
                "bullets": ["資料不足，暫時無法產生完整 AI 分析摘要。"],
                "actionItems": [
                    "請執行 scripts\\00631l_check_env.cmd 與 scripts\\00631l_daily_cycle.cmd 後再重新整理。"
                ],
                "sourceStatuses": {
                    "operations": "error",
                    "holdingsHistory": "unavailable",
                    "intradayNavHistory": "unavailable",
                    "dailyCycle": "unavailable",
                    "report": "unavailable",
                    "export": "unavailable",
                    "backup": "unavailable",
                    "integrity": "unavailable",
                },
                "disclaimer": "非買賣建議",
                "errorMessage": f"Rule-based analysis failed: {error}",
            }

    def _backup_status(self) -> dict[str, Any]:
        backup_dir = Path(self._config.backup_dir)
        latest_path: Path | None = None
        latest_mtime = 0.0
        if backup_dir.exists() and backup_dir.is_dir():
            for path in backup_dir.glob("00631l_local_data_backup_*.zip"):
                if not path.is_file():
                    continue
                mtime = path.stat().st_mtime
                if mtime >= latest_mtime:
                    latest_path = path
                    latest_mtime = mtime
        available = latest_path is not None
        return {
            "sourceStatus": "cached" if available else "unavailable",
            "sourceContract": "00631l_backup_status",
            "available": available,
            "backupDir": str(backup_dir),
            "latestFile": str(latest_path) if latest_path else None,
            "latestUpdatedAt": _mtime_iso(latest_mtime) if latest_path else None,
            "errorMessage": None if available else "No local backup archive found.",
        }

    def _data_directory_health(
        self,
        *,
        backup_status: dict[str, Any],
        export_status: dict[str, Any],
    ) -> dict[str, Any]:
        data_root = Path(self._config.data_dir)
        data_dir = Path(self._config.holdings_history_path).parent
        export_dir = Path(self._config.history_export_dir)
        backup_dir = Path(self._config.backup_dir)
        persistence = _persistence_health(
            data_root,
            mode=self._config.data_persistence_mode,
        )
        data_files = [
            Path(self._config.holdings_history_path),
            Path(self._config.intraday_nav_history_path),
            Path(self._config.price_history_path),
            Path(self._config.daily_cycle_status_path),
        ]
        export_files = [
            export_dir / "00631l_holdings_history_summary.csv",
            export_dir / "00631l_intraday_nav_history.csv",
            export_dir / "00631l_price_history.csv",
            export_dir / "00631l_history_export_metadata.json",
        ]
        health = {
            "sourceStatus": "cached",
            "sourceContract": "00631l_data_directory_health",
            "dataRoot": str(data_root),
            "persistence": persistence,
            "dataDir": _directory_health(data_dir, data_files),
            "exportDir": _directory_health(export_dir, export_files),
            "backupDir": _directory_health(
                backup_dir,
                [Path(backup_status["latestFile"])]
                if backup_status.get("latestFile")
                else [],
            ),
            "latestExportUpdatedAt": export_status.get("latestUpdatedAt"),
            "latestBackupUpdatedAt": backup_status.get("latestUpdatedAt"),
        }
        directories = [health["dataDir"], health["exportDir"], health["backupDir"]]
        if persistence["sourceStatus"] == "error" or any(
            directory["sourceStatus"] == "error" for directory in directories
        ):
            health["sourceStatus"] = "error"
        elif persistence["sourceStatus"] == "stale":
            health["sourceStatus"] = "stale"
        elif any(directory["sourceStatus"] == "unavailable" for directory in directories):
            health["sourceStatus"] = "unavailable"
        return health

    def _export_status(self) -> dict[str, Any]:
        export_dir = Path(self._config.history_export_dir)
        expected = [
            export_dir / "00631l_holdings_history_summary.csv",
            export_dir / "00631l_intraday_nav_history.csv",
            export_dir / "00631l_price_history.csv",
            export_dir / "00631l_history_export_metadata.json",
        ]
        files = []
        latest_path: Path | None = None
        latest_mtime = 0.0
        for path in expected:
            exists = path.exists()
            mtime = path.stat().st_mtime if exists else None
            if mtime is not None and mtime >= latest_mtime:
                latest_mtime = mtime
                latest_path = path
            files.append(
                {
                    "name": path.name,
                    "path": str(path),
                    "exists": exists,
                    "updatedAt": _mtime_iso(mtime),
                    "sizeBytes": path.stat().st_size if exists else 0,
                }
            )
        available = any(file["exists"] for file in files)
        metadata = _read_json_file(export_dir / "00631l_history_export_metadata.json")
        return {
            "sourceStatus": "cached" if available else "unavailable",
            "sourceContract": "00631l_history_export_status",
            "available": available,
            "outputDir": str(export_dir),
            "latestFile": str(latest_path) if latest_path else None,
            "latestUpdatedAt": _mtime_iso(latest_mtime) if latest_path else None,
            "metadataPath": str(export_dir / "00631l_history_export_metadata.json"),
            "exportedAt": metadata.get("exportedAt"),
            "rows": metadata.get("totalRowCount"),
            "sourceHistoryRange": metadata.get("sourceHistoryRange"),
            "files": files,
            "errorMessage": None if available else "No local CSV export files found.",
        }

    def _daily_cycle_status(self) -> dict[str, Any]:
        path = Path(self._config.daily_cycle_status_path)
        if not path.exists():
            return {
                "sourceStatus": "unavailable",
                "sourceContract": "00631l_daily_cycle_status",
                "available": False,
                "path": str(path),
                "overallStatus": "missing",
                "startedAt": None,
                "finishedAt": None,
                "warningCount": 0,
                "failureCount": 0,
                "errorMessage": "No local daily cycle status file found.",
            }
        try:
            payload = json.loads(path.read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError) as error:
            return {
                "sourceStatus": "error",
                "sourceContract": "00631l_daily_cycle_status",
                "available": False,
                "path": str(path),
                "overallStatus": "error",
                "startedAt": None,
                "finishedAt": None,
                "warningCount": 0,
                "failureCount": 1,
                "errorMessage": f"Daily cycle status read failed: {error}",
            }
        warnings = payload.get("warnings") if isinstance(payload.get("warnings"), list) else []
        failures = payload.get("failures") if isinstance(payload.get("failures"), list) else []
        return {
            "sourceStatus": "cached",
            "sourceContract": "00631l_daily_cycle_status",
            "available": True,
            "path": str(path),
            "overallStatus": str(payload.get("overallStatus") or "unknown"),
            "startedAt": payload.get("startedAt"),
            "finishedAt": payload.get("finishedAt"),
            "warningCount": len(warnings),
            "failureCount": len(failures),
            "errorMessage": payload.get("errorMessage"),
        }

    def _env_status(self) -> dict[str, Any]:
        backend_root = Path(__file__).resolve().parents[1]
        env_path = backend_root / ".env"
        persistence = _persistence_health(
            Path(self._config.data_dir),
            mode=self._config.data_persistence_mode,
        )
        data_dir_ready = (
            _path_parent_ready(self._config.holdings_history_path)
            and _path_parent_ready(self._config.intraday_nav_history_path)
            and _path_parent_ready(self._config.price_history_path)
            and _path_parent_ready(self._config.etf_catalog_path)
        )
        export_dir = Path(self._config.history_export_dir)
        export_dir_ready = export_dir.exists() or export_dir.parent.exists()
        backup_dir = Path(self._config.backup_dir)
        backup_dir_ready = backup_dir.exists() or backup_dir.parent.exists()
        missing_keys: list[str] = []
        optional_missing_keys: list[str] = []
        if not env_path.exists():
            missing_keys.append("backend/.env")
        if not self._config.twse_intraday_nav_url:
            missing_keys.append("TWSE_00631L_INTRADAY_NAV_URL")
        if not self._config.twse_price_history_url_template:
            missing_keys.append("TWSE_00631L_PRICE_HISTORY_URL_TEMPLATE")
        if not self._config.yuanta_intraday_nav_url:
            optional_missing_keys.append("YUANTA_00631L_INTRADAY_NAV_URL")
        if not data_dir_ready:
            missing_keys.append("backend/data")
        if not export_dir_ready:
            missing_keys.append("backend/exports")
        if not backup_dir_ready:
            optional_missing_keys.append("backend/backups")
        return {
            "sourceStatus": "cached" if not missing_keys else "unavailable",
            "sourceContract": "00631l_env_status",
            "envFileExists": env_path.exists(),
            "missingKeys": missing_keys,
            "optionalMissingKeys": optional_missing_keys,
            "dataDirReady": data_dir_ready,
            "exportDirReady": export_dir_ready,
            "backupDirReady": backup_dir_ready,
            "dataPersistenceWarning": persistence["warning"],
        }

    def _readiness_public_api_check(self) -> dict[str, Any]:
        url = self._config.public_api_base_url.strip()
        if not url:
            return _readiness_check(
                "public_api_base_url",
                "WARN",
                "PUBLIC_API_BASE_URL is not set; backend can run locally but public status will not advertise a public URL.",
            )
        if not _looks_like_http_url(url):
            return _readiness_check(
                "public_api_base_url",
                "FAIL",
                "PUBLIC_API_BASE_URL must be an http(s) URL.",
                value=url,
            )
        return _readiness_check("public_api_base_url", "PASS", "ok", value=url)

    def _readiness_cors_check(self) -> dict[str, Any]:
        origins = list(self._config.allowed_origins)
        if not origins:
            return _readiness_check(
                "allowed_origins",
                "WARN",
                "ALLOWED_ORIGINS is not set; backend will use localhost/LAN development CORS.",
            )
        if "*" in origins:
            return _readiness_check(
                "allowed_origins",
                "FAIL",
                "ALLOWED_ORIGINS must list explicit frontend origins.",
                origins=origins,
            )
        invalid = [origin for origin in origins if not _looks_like_http_url(origin)]
        if invalid:
            return _readiness_check(
                "allowed_origins",
                "FAIL",
                f"Invalid origin values: {', '.join(invalid)}",
                origins=origins,
            )
        return _readiness_check("allowed_origins", "PASS", "ok", origins=origins)

    def _readiness_data_dir_check(self) -> dict[str, Any]:
        path = Path(self._config.data_dir)
        writable = _ensure_directory_writable(path)
        return _readiness_check(
            "data_dir_writable",
            "PASS" if writable else "FAIL",
            "ok" if writable else "00631L_DATA_DIR is not writable.",
            path=str(path),
            exists=path.exists(),
            writable=writable,
        )

    def _readiness_persistence_check(self) -> dict[str, Any]:
        persistence = _persistence_health(
            Path(self._config.data_dir),
            mode=self._config.data_persistence_mode,
        )
        if not persistence["writable"]:
            status = "FAIL"
        elif persistence["isPersistent"]:
            status = "PASS"
        else:
            status = "WARN"
        return _readiness_check(
            "data_persistence",
            status,
            persistence["warning"] or "ok",
            mode=persistence["mode"],
            isPersistent=persistence["isPersistent"],
            path=persistence["path"],
        )

    def _readiness_url_check(
        self,
        name: str,
        url: str,
        *,
        required: bool,
    ) -> dict[str, Any]:
        if not url:
            return _readiness_check(
                name,
                "WARN" if required else "PASS",
                f"{name} is not set."
                if required
                else f"{name} is optional and not set.",
            )
        return _readiness_check(
            name,
            "PASS" if _looks_like_fetch_url(url) else "FAIL",
            "ok" if _looks_like_fetch_url(url) else f"{name} must be an http(s) or fixture URL.",
            value=url,
        )

    def _readiness_live_source_check(self) -> dict[str, Any]:
        url = self._config.twse_intraday_nav_url
        if not url:
            return _readiness_check(
                "live_source_connectivity",
                "WARN",
                "TWSE intraday NAV URL is not configured; live intraday data may be unavailable.",
            )
        try:
            source = self._fetcher(url, min(self._config.request_timeout_seconds, 5))
        except (FetchError, OSError, RuntimeError, ValueError) as error:
            return _readiness_check(
                "live_source_connectivity",
                "WARN",
                f"TWSE intraday NAV source was not reachable during readiness check: {error}",
                url=url,
            )
        length = len(source)
        return _readiness_check(
            "live_source_connectivity",
            "PASS" if length > 0 else "WARN",
            "ok" if length > 0 else "TWSE intraday NAV source returned empty content.",
            url=url,
            contentLength=length,
        )

    def _intraday_candidates(self) -> list[tuple[str, str, Callable[..., dict[str, Any]]]]:
        mode = self._config.intraday_nav_source
        if mode not in {"twse", "yuanta", "auto"}:
            mode = "auto"

        candidates: list[tuple[str, str, Callable[..., dict[str, Any]]]] = []
        if mode in {"twse", "auto"} and self._config.twse_intraday_nav_url:
            candidates.append(("twse", self._config.twse_intraday_nav_url, parse_intraday_nav))
        if mode in {"yuanta", "auto"} and self._config.yuanta_intraday_nav_url:
            candidates.append(("yuanta", self._config.yuanta_intraday_nav_url, parse_yuanta_intraday_nav))
        return candidates


def _mtime_iso(mtime: float | None) -> str | None:
    if mtime is None:
        return None
    return datetime.fromtimestamp(mtime, tz=timezone.utc).replace(microsecond=0).isoformat()


def _parse_date(value: str | None) -> date | None:
    if not value:
        return None
    try:
        return datetime.strptime(value, "%Y-%m-%d").date()
    except ValueError:
        return None


def _readiness_check(
    name: str,
    status: str,
    message: str,
    **extra: Any,
) -> dict[str, Any]:
    payload = {
        "name": name,
        "status": status,
        "message": message,
    }
    payload.update(extra)
    return payload


def _looks_like_http_url(value: str) -> bool:
    return value.startswith("http://") or value.startswith("https://")


def _looks_like_fetch_url(value: str) -> bool:
    return _looks_like_http_url(value) or value.startswith("fixture://")


def _empty_price_history_response(
    *,
    limit: int,
    fetched_at: str,
    error_message: str,
) -> dict[str, Any]:
    return {
        "items": [],
        "limit": limit,
        "sourceStatus": "error",
        "sourceContract": "twse_stock_day_local_jsonl",
        "sourceUrl": "local://00631l-price-history",
        "fetchedAt": fetched_at,
        "sourceUpdatedAt": None,
        "dataTime": None,
        "coverageStart": None,
        "coverageEnd": None,
        "isCompleteFromListing": False,
        "isStale": True,
        "priceField": PRICE_ADJUSTMENT_FIELD,
        "priceAdjustment": price_adjustment_metadata(),
        "errorMessage": error_message,
    }


def _empty_performance_response(
    *,
    fetched_at: str,
    error_message: str,
) -> dict[str, Any]:
    return {
        **performance_summary([]),
        "sourceStatus": "error",
        "sourceContract": "00631l_price_performance",
        "sourceUrl": "local://00631l-price-history",
        "fetchedAt": fetched_at,
        "sourceUpdatedAt": None,
        "dataTime": None,
        "coverageStart": None,
        "coverageEnd": None,
        "rowCount": 0,
        "isCompleteFromListing": False,
        "isStale": True,
        "priceField": PRICE_ADJUSTMENT_FIELD,
        "priceAdjustment": price_adjustment_metadata(),
        "errorMessage": error_message,
    }


def _path_parent_ready(path_text: str) -> bool:
    path = Path(path_text)
    return path.exists() or path.parent.exists()


def _directory_health(directory: Path, files: list[Path]) -> dict[str, Any]:
    exists = directory.exists() and directory.is_dir()
    writable = exists and os.access(directory, os.W_OK)
    existing_files = [path for path in files if path.exists()]
    latest_path: Path | None = None
    latest_mtime = 0.0
    for path in existing_files:
        mtime = path.stat().st_mtime
        if mtime >= latest_mtime:
            latest_path = path
            latest_mtime = mtime
    source_status = "cached" if exists and writable else "error"
    if exists and writable and not existing_files:
        source_status = "unavailable"
    return {
        "sourceStatus": source_status,
        "path": str(directory),
        "exists": exists,
        "writable": writable,
        "fileCount": len(existing_files),
        "latestFile": str(latest_path) if latest_path else None,
        "latestUpdatedAt": _mtime_iso(latest_mtime) if latest_path else None,
    }


def _persistence_health(directory: Path, *, mode: str) -> dict[str, Any]:
    normalized_mode = mode if mode in {"local", "persistent", "transient"} else "local"
    exists = directory.exists() and directory.is_dir()
    writable = _ensure_directory_writable(directory)
    is_persistent = normalized_mode == "persistent"
    warning = None
    if not writable:
        warning = "Data directory is not writable; history/report/export persistence may fail."
    elif normalized_mode == "transient":
        warning = (
            "Data persistence mode is transient; mount a persistent volume for "
            "public deployment."
        )
    elif normalized_mode == "local":
        warning = (
            "Data persistence mode is local; public deployment should set "
            "00631L_DATA_PERSISTENCE_MODE=persistent and mount a volume."
        )
    return {
        "sourceStatus": "error" if not writable else "cached" if is_persistent else "stale",
        "path": str(directory),
        "exists": exists,
        "writable": writable,
        "mode": normalized_mode,
        "isPersistent": is_persistent,
        "isTransient": normalized_mode == "transient",
        "warning": warning,
    }


def _ensure_directory_writable(directory: Path) -> bool:
    probe = directory / ".00631l_write_probe.tmp"
    try:
        directory.mkdir(parents=True, exist_ok=True)
        probe.write_text("write-test", encoding="utf-8")
        probe.unlink()
        return True
    except OSError:
        try:
            if probe.exists():
                probe.unlink()
        except OSError:
            pass
        return False


def _data_update_frequencies(*, intraday_cache_seconds: int) -> list[dict[str, Any]]:
    return [
        {
            "key": "holdings_ratio",
            "label": "official holdings / ratio",
            "frequency": "official_daily_snapshot",
            "description": "元大 official ratio 是每日揭露資料，不是盤中即時內容物。",
            "sourceStatus": "official_or_cached",
        },
        {
            "key": "intraday_nav",
            "label": "intraday NAV / premium discount",
            "frequency": f"approx_{max(15, min(30, intraday_cache_seconds))}_seconds_when_backend_ready",
            "description": "TWSE all_etf.txt 可提供盤中市價、預估淨值與折溢價；需 backend 可連線且 env 設定正確。",
            "sourceStatus": "official_cached_stale_or_unavailable",
        },
        {
            "key": "tx_live",
            "label": "TX live quote",
            "frequency": "taifex_realtime_when_backend_ready",
            "description": "TAIFEX quote stream 可提供自動解析的 TX 月份合約與 TXF-S 加權指數；非交易時段可能回 unavailable 或 stale。",
            "sourceStatus": "official_cached_stale_or_unavailable",
        },
    ]


def _read_json_file(path: Path) -> dict[str, Any]:
    if not path.exists():
        return {}
    try:
        decoded = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError):
        return {}
    return decoded if isinstance(decoded, dict) else {}


service = Etf00631LService()
