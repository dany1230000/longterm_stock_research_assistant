from __future__ import annotations

from datetime import datetime, timezone

from fastapi import FastAPI, Query
from fastapi.middleware.cors import CORSMiddleware

from .service import service


app = FastAPI(title="00631L live proxy", version="1.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=[
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
    ],
    allow_origin_regex=r"^http://(localhost|127\.0\.0\.1):\d+$",
    allow_credentials=False,
    allow_methods=["GET"],
    allow_headers=["*"],
)


@app.get("/health")
def health() -> dict[str, str]:
    return {
        "status": "ok",
        "serverTime": datetime.now(timezone.utc).replace(microsecond=0).isoformat(),
    }


@app.get("/api/etf/00631l/profile")
def profile() -> dict:
    return service.profile()


@app.get("/api/etf/00631l/holdings")
def holdings() -> dict:
    return service.holdings()


@app.get("/api/etf/00631l/holdings/history")
def holdings_history(limit: int = Query(30, ge=1, le=365)) -> dict:
    return service.holdings_history(limit=limit)


@app.get("/api/etf/00631l/holdings/history/summary")
def holdings_history_summary(limit: int = Query(30, ge=1, le=365)) -> dict:
    return service.holdings_history_summary(limit=limit)


@app.get("/api/etf/00631l/intraday-nav")
def intraday_nav() -> dict:
    return service.intraday_nav()


@app.get("/api/etf/00631l/intraday-nav/history")
def intraday_nav_history(
    date: str | None = None,
    limit: int = Query(500, ge=1, le=2000),
) -> dict:
    return service.intraday_nav_history(date=date, limit=limit)


@app.get("/api/etf/00631l/intraday-nav/history/summary")
def intraday_nav_history_summary(date: str | None = None) -> dict:
    return service.intraday_nav_history_summary(date=date)
