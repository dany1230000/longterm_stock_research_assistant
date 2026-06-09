from __future__ import annotations

import json
import os
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Callable

from .analysis import AnalysisProvider, RuleBasedAnalysisProvider
from .cache import TimedMemoryCache
from .config import Settings, settings
from .fetcher import FetchError, fetch_text
from .daily_report import report_status
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
        self._analysis_provider = analysis_provider or RuleBasedAnalysisProvider()

    def health_status(self, *, server_time: str | None = None) -> dict[str, Any]:
        now = server_time or utc_now_iso()
        env_status = self._env_status()
        return {
            "status": "ok",
            "serverTime": now,
            "appName": "00631L lab backend",
            "appVersion": "1.42",
            "sourceContract": "00631l_backend_health",
            "scope": "00631L only",
            "publicApiBaseUrl": self._config.public_api_base_url,
            "allowedOrigins": list(self._config.allowed_origins),
            "liveSourceConfigured": {
                "twseIntradayNav": bool(self._config.twse_intraday_nav_url),
                "yuantaIntradayNav": bool(self._config.yuanta_intraday_nav_url),
                "yuantaProfile": bool(self._config.yuanta_profile_url),
                "yuantaHoldings": bool(self._config.yuanta_holdings_url),
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
                "profile": "/api/etf/00631l/profile",
                "holdings": "/api/etf/00631l/holdings",
                "intradayNav": "/api/etf/00631l/intraday-nav",
                "operationsStatus": "/api/etf/00631l/operations/status",
                "analysisSummary": "/api/etf/00631l/analysis/summary",
            },
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
        backup_status = self._backup_status()
        report = report_status(self._config.report_dir)
        daily_cycle_status = self._daily_cycle_status()
        env_status = self._env_status()
        data_directory_health = self._data_directory_health(
            backup_status=backup_status,
            export_status=export_status,
        )
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
                "holdingsHistoryPathConfigured": bool(self._config.holdings_history_path),
                "intradayNavHistoryPathConfigured": bool(self._config.intraday_nav_history_path),
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
                "date": intraday.get("date"),
                "sourceUpdatedAt": intraday.get("sourceUpdatedAt"),
                "isStale": intraday.get("isStale"),
                "errorMessage": intraday.get("errorMessage"),
            },
            "export": export_status,
            "backup": backup_status,
            "report": report,
            "dailyCycle": daily_cycle_status,
            "backendHealth": self.health_status(server_time=now),
            "statusSummary": {
                "operations": source_status,
                "holdingsHistory": holdings.get("sourceStatus"),
                "intradayHistory": intraday.get("sourceStatus"),
                "export": export_status["sourceStatus"],
                "backup": backup_status["sourceStatus"],
                "report": report["sourceStatus"],
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

    def analysis_summary(self) -> dict[str, Any]:
        now = utc_now_iso()
        try:
            operations = self.operations_status()
            holdings = self.holdings_history_summary(limit=30)
            intraday = self.intraday_nav_history_summary()
            integrity = _read_json_file(Path(self._config.integrity_status_path))
            payload = self._analysis_provider.summarize(
                {
                    "operations": operations,
                    "holdingsHistory": holdings,
                    "intradayNavHistory": intraday,
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
            Path(self._config.daily_cycle_status_path),
        ]
        export_files = [
            export_dir / "00631l_holdings_history_summary.csv",
            export_dir / "00631l_intraday_nav_history.csv",
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
        data_dir_ready = _path_parent_ready(self._config.holdings_history_path) and _path_parent_ready(
            self._config.intraday_nav_history_path
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
            "frequency": "not_connected",
            "description": "TX live 尚未接入；目前只保留 mock/fallback 顯示，不會標示為 official。",
            "sourceStatus": "mock_fallback",
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
