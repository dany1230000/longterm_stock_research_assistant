from __future__ import annotations

from datetime import datetime, timezone

from fastapi import FastAPI
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


@app.get("/api/etf/00631l/intraday-nav")
def intraday_nav() -> dict:
    return service.intraday_nav()
