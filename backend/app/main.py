from __future__ import annotations

from datetime import datetime, timezone
from typing import Any

from fastapi import FastAPI, Query
from fastapi.middleware.cors import CORSMiddleware

from .config import Settings, settings
from .service import service


LOCAL_ALLOWED_ORIGINS = [
        "http://localhost:3000",
        "http://localhost:5000",
        "http://localhost:8000",
        "http://localhost:8080",
        "http://localhost:5173",
        "http://127.0.0.1:3000",
        "http://127.0.0.1:5000",
        "http://127.0.0.1:8000",
        "http://127.0.0.1:8080",
        "http://127.0.0.1:5173",
]

LOCAL_LAN_ALLOW_ORIGIN_REGEX = (
    r"^http://("
    r"localhost|127\.0\.0\.1|"
    r"10\.\d{1,3}\.\d{1,3}\.\d{1,3}|"
    r"192\.168\.\d{1,3}\.\d{1,3}|"
    r"172\.(1[6-9]|2\d|3[0-1])\.\d{1,3}\.\d{1,3}"
    r"):\d+$"
)


def create_app(
    *,
    app_config: Settings = settings,
    app_service: Any | None = None,
) -> FastAPI:
    fastapi_app = FastAPI(title="00631L live proxy", version="1.0.0")
    resolved_service = app_service

    fastapi_app.add_middleware(
        CORSMiddleware,
        allow_origins=_allowed_origins(app_config),
        allow_origin_regex=_allow_origin_regex(app_config),
        allow_credentials=False,
        allow_methods=["GET", "POST"],
        allow_headers=["*"],
    )

    def current_service() -> Any:
        return resolved_service or service

    @fastapi_app.get("/health")
    def health() -> dict:
        return current_service().health_status(
            server_time=datetime.now(timezone.utc).replace(microsecond=0).isoformat(),
        )

    @fastapi_app.get("/ready")
    def readiness() -> dict:
        return current_service().readiness_status()

    @fastapi_app.get("/api/etf/00631l/profile")
    def profile() -> dict:
        return current_service().profile()

    @fastapi_app.get("/api/etf/00631l/holdings")
    def holdings() -> dict:
        return current_service().holdings()

    @fastapi_app.get("/api/etf/00631l/holdings/history")
    def holdings_history(limit: int = Query(30, ge=1, le=365)) -> dict:
        return current_service().holdings_history(limit=limit)

    @fastapi_app.get("/api/etf/00631l/holdings/history/summary")
    def holdings_history_summary(limit: int = Query(30, ge=1, le=365)) -> dict:
        return current_service().holdings_history_summary(limit=limit)

    @fastapi_app.get("/api/etf/00631l/intraday-nav")
    def intraday_nav() -> dict:
        return current_service().intraday_nav()

    @fastapi_app.get("/api/etf/00631l/intraday-nav/history")
    def intraday_nav_history(
        date: str | None = None,
        limit: int = Query(500, ge=1, le=2000),
    ) -> dict:
        return current_service().intraday_nav_history(date=date, limit=limit)

    @fastapi_app.get("/api/etf/00631l/intraday-nav/history/summary")
    def intraday_nav_history_summary(date: str | None = None) -> dict:
        return current_service().intraday_nav_history_summary(date=date)

    @fastapi_app.get("/api/etf/00631l/tx-quote")
    def tx_quote() -> dict:
        return current_service().tx_quote()

    @fastapi_app.get("/api/etf/catalog")
    def etf_catalog() -> dict:
        return current_service().etf_catalog()

    @fastapi_app.get("/api/etf/catalog/status")
    def etf_catalog_status() -> dict:
        return current_service().etf_catalog_status()

    @fastapi_app.post("/api/etf/catalog/import")
    def etf_catalog_import() -> dict:
        return current_service().etf_catalog_import()

    @fastapi_app.get("/api/etf/00631l/operations/status")
    def operations_status() -> dict:
        return current_service().operations_status()

    @fastapi_app.get("/api/etf/00631l/analysis/summary")
    def analysis_summary() -> dict:
        return current_service().analysis_summary()

    @fastapi_app.get("/api/etf/00631l/history/price")
    def history_price(limit: int = Query(5000, ge=1, le=5000)) -> dict:
        return current_service().price_history(limit=limit)

    @fastapi_app.get("/api/etf/00631l/history/performance")
    def history_performance() -> dict:
        return current_service().price_history_performance()

    @fastapi_app.get("/api/etf/00631l/history/status")
    def history_status() -> dict:
        return current_service().price_history_status()

    @fastapi_app.post("/api/etf/00631l/history/update")
    def history_update(
        startDate: str | None = None,
        endDate: str | None = None,
    ) -> dict:
        return current_service().price_history_update(
            start_date=startDate,
            end_date=endDate,
        )

    @fastapi_app.get("/api/etf/history/status")
    def etf_history_status() -> dict:
        return current_service().etf_price_history_index()

    @fastapi_app.get("/api/etf/history/gaps")
    def etf_history_gaps(
        reason: str | None = None,
        limit: int = Query(50, ge=1, le=500),
        fromCatalog: bool = False,
    ) -> dict:
        return current_service().etf_price_history_gaps(
            reason=reason,
            limit=limit,
            from_catalog=fromCatalog,
        )

    @fastapi_app.get("/api/etf/history/price")
    def etf_history_price(
        code: str,
        limit: int = Query(5000, ge=1, le=5000),
    ) -> dict:
        return current_service().etf_price_history(code=code, limit=limit)

    @fastapi_app.post("/api/etf/history/update")
    def etf_history_update(
        codes: str | None = None,
        startDate: str | None = None,
        endDate: str | None = None,
        fromCatalog: bool = False,
        limit: int = Query(0, ge=0, le=500),
        offset: int = Query(0, ge=0),
    ) -> dict:
        return current_service().etf_price_history_update(
            codes=codes,
            start_date=startDate,
            end_date=endDate,
            from_catalog=fromCatalog,
            limit=limit,
            offset=offset,
        )

    @fastapi_app.get("/api/etf/00631l/backtest/defaults")
    def backtest_defaults() -> dict:
        return current_service().backtest_defaults()

    @fastapi_app.post("/api/etf/00631l/backtest/run")
    def backtest_run(payload: dict[str, Any]) -> dict:
        return current_service().backtest_run(payload)

    return fastapi_app


def _allowed_origins(app_config: Settings) -> list[str]:
    if app_config.allowed_origins:
        return list(app_config.allowed_origins)
    return LOCAL_ALLOWED_ORIGINS


def _allow_origin_regex(app_config: Settings) -> str | None:
    if app_config.allowed_origins:
        return None
    return LOCAL_LAN_ALLOW_ORIGIN_REGEX


app = create_app()
