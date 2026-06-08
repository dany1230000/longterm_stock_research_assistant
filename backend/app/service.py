from __future__ import annotations

import json
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Callable

from .cache import TimedMemoryCache
from .config import Settings, settings
from .fetcher import FetchError, fetch_text
from .holdings_history import HoldingsHistoryStore, empty_history_response
from .intraday_nav_history import (
    IntradayNavHistoryStore,
    empty_intraday_history_response,
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
            if payload["sourceStatus"] != "error":
                self._cache.set("holdings", payload)
                if payload["sourceStatus"] == "official":
                    try:
                        self._history_store.save_official_snapshot(payload)
                    except OSError:
                        pass
            return payload
        except (FetchError, OSError, RuntimeError) as error:
            stale = self._cache.get_any("holdings")
            if stale is not None:
                return mark_cached(stale, fetched_at=now, error_message=f"Live holdings fetch failed: {error}")
            return empty_holdings_response(
                source_url=self._config.yuanta_holdings_url,
                fetched_at=now,
                error_message=f"Live holdings fetch failed and no cached snapshot is available: {error}",
            )

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
            return unavailable_intraday_nav(
                "",
                now,
                "No intraday NAV URL is configured for 00631L",
            )

        cached = self._cache.get("intraday_nav", self._config.intraday_cache_seconds)
        if cached is not None:
            return mark_cached(cached, fetched_at=now)

        errors: list[str] = []
        for source_name, url, parser in candidates:
            try:
                source = self._fetcher(url, self._config.request_timeout_seconds)
                payload = parser(source, source_url=url, fetched_at=now)
                if payload["sourceStatus"] not in {"error", "unavailable"}:
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
            return mark_cached(stale, fetched_at=now, error_message=f"Live intraday NAV fetch failed: {joined}")
        source_url = candidates[0][1] if candidates else ""
        return unavailable_intraday_nav(
            source_url,
            now,
            f"Live intraday NAV fetch failed and no cached data is available: {joined}",
            source_status="error",
        )

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

    def operations_status(self) -> dict[str, Any]:
        now = utc_now_iso()
        holdings = self.holdings_history_summary(limit=1)
        intraday = self.intraday_nav_history_summary()
        export_status = self._export_status()
        daily_cycle_status = self._daily_cycle_status()
        env_status = self._env_status()
        holdings_items = holdings.get("items") if isinstance(holdings.get("items"), list) else []
        latest_holding = holdings_items[0] if holdings_items else {}
        intraday_items = intraday.get("items") if isinstance(intraday.get("items"), list) else []
        latest_intraday = intraday_items[0] if intraday_items else {}
        errors = [
            value.get("errorMessage")
            for value in (holdings, intraday)
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
                "intradaySourceMode": self._config.intraday_nav_source,
                "twseIntradayNavConfigured": bool(self._config.twse_intraday_nav_url),
                "yuantaIntradayNavConfigured": bool(self._config.yuanta_intraday_nav_url),
                "envFileExists": env_status["envFileExists"],
                "missingKeys": env_status["missingKeys"],
                "optionalMissingKeys": env_status["optionalMissingKeys"],
                "dataDirReady": env_status["dataDirReady"],
                "exportDirReady": env_status["exportDirReady"],
                "profileCacheSeconds": self._config.profile_cache_seconds,
                "holdingsCacheSeconds": self._config.holdings_cache_seconds,
                "intradayNavCacheSeconds": self._config.intraday_cache_seconds,
                "holdingsHistoryPathConfigured": bool(self._config.holdings_history_path),
                "intradayNavHistoryPathConfigured": bool(self._config.intraday_nav_history_path),
                "historyExportDir": self._config.history_export_dir,
                "dailyCycleStatusPath": self._config.daily_cycle_status_path,
            },
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
                "date": intraday.get("date"),
                "sourceUpdatedAt": intraday.get("sourceUpdatedAt"),
                "isStale": intraday.get("isStale"),
                "errorMessage": intraday.get("errorMessage"),
            },
            "export": export_status,
            "dailyCycle": daily_cycle_status,
            "statusSummary": {
                "operations": source_status,
                "holdingsHistory": holdings.get("sourceStatus"),
                "intradayHistory": intraday.get("sourceStatus"),
                "export": export_status["sourceStatus"],
                "dailyCycle": daily_cycle_status["sourceStatus"],
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

    def _export_status(self) -> dict[str, Any]:
        export_dir = Path(self._config.history_export_dir)
        expected = [
            export_dir / "00631l_holdings_history_summary.csv",
            export_dir / "00631l_intraday_nav_history.csv",
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
        return {
            "sourceStatus": "cached" if available else "unavailable",
            "sourceContract": "00631l_history_export_status",
            "available": available,
            "outputDir": str(export_dir),
            "latestFile": str(latest_path) if latest_path else None,
            "latestUpdatedAt": _mtime_iso(latest_mtime) if latest_path else None,
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
        data_dir_ready = _path_parent_ready(self._config.holdings_history_path) and _path_parent_ready(
            self._config.intraday_nav_history_path
        )
        export_dir = Path(self._config.history_export_dir)
        export_dir_ready = export_dir.exists() or export_dir.parent.exists()
        missing_keys: list[str] = []
        optional_missing_keys: list[str] = []
        if not env_path.exists():
            missing_keys.append("backend/.env")
        if not self._config.twse_intraday_nav_url:
            missing_keys.append("TWSE_00631L_INTRADAY_NAV_URL")
        if not self._config.yuanta_intraday_nav_url:
            optional_missing_keys.append("YUANTA_00631L_INTRADAY_NAV_URL")
        if not data_dir_ready:
            missing_keys.append("backend/data")
        if not export_dir_ready:
            missing_keys.append("backend/exports")
        return {
            "sourceStatus": "cached" if not missing_keys else "unavailable",
            "sourceContract": "00631l_env_status",
            "envFileExists": env_path.exists(),
            "missingKeys": missing_keys,
            "optionalMissingKeys": optional_missing_keys,
            "dataDirReady": data_dir_ready,
            "exportDirReady": export_dir_ready,
        }

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


def _path_parent_ready(path_text: str) -> bool:
    path = Path(path_text)
    return path.exists() or path.parent.exists()


service = Etf00631LService()
