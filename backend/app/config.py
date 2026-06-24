from dataclasses import dataclass
import os
from pathlib import Path


def _load_backend_dotenv() -> None:
    env_path = Path(__file__).resolve().parents[1] / ".env"
    if not env_path.exists():
        return

    for raw_line in env_path.read_text(encoding="utf-8").splitlines():
        line = raw_line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        if line.startswith("export "):
            line = line[len("export ") :].strip()
        key, value = line.split("=", 1)
        key = key.strip()
        value = value.strip().strip('"').strip("'")
        if key:
            os.environ.setdefault(key, value)


def _env_int(name: str, default: int) -> int:
    try:
        value = int(os.getenv(name, str(default)))
    except ValueError:
        return default
    return value if value > 0 else default


def _env_float(name: str, default: float) -> float:
    try:
        value = float(os.getenv(name, str(default)))
    except ValueError:
        return default
    return value if value > 0 else default


def _env_csv(name: str) -> tuple[str, ...]:
    raw = os.getenv(name, "")
    return tuple(item.strip() for item in raw.split(",") if item.strip())


_load_backend_dotenv()

_BACKEND_ROOT = Path(__file__).resolve().parents[1]
_DATA_ROOT = Path(os.getenv("00631L_DATA_DIR", str(_BACKEND_ROOT / "data")))
_SEED_ROOT = _BACKEND_ROOT / "seeds"


def _data_path(name: str, filename: str) -> str:
    return os.getenv(name, str(_DATA_ROOT / filename))


@dataclass(frozen=True)
class Settings:
    backend_app_version: str = os.getenv(
        "00631L_BACKEND_APP_VERSION",
        "5.29-pages-format-alignment",
    ).strip()
    backend_release_tag: str = os.getenv(
        "00631L_BACKEND_RELEASE_TAG",
        "00631l-lab-v5.29-pages-format-alignment",
    ).strip()
    backend_git_sha: str = os.getenv("00631L_BACKEND_GIT_SHA", "").strip()
    backend_build_time: str = os.getenv("00631L_BACKEND_BUILD_TIME", "").strip()
    public_api_base_url: str = os.getenv("PUBLIC_API_BASE_URL", "").strip()
    allowed_origins: tuple[str, ...] = _env_csv("ALLOWED_ORIGINS")
    data_dir: str = os.getenv("00631L_DATA_DIR", str(_DATA_ROOT))
    data_persistence_mode: str = os.getenv(
        "00631L_DATA_PERSISTENCE_MODE",
        "local",
    ).strip().lower()
    yuanta_profile_url: str = os.getenv(
        "YUANTA_00631L_PROFILE_URL",
        "https://www.yuantaetfs.com/product/detail/00631L/Basic_information",
    )
    yuanta_holdings_url: str = os.getenv(
        "YUANTA_00631L_HOLDINGS_URL",
        "https://www.yuantaetfs.com/product/detail/00631L/ratio",
    )
    twse_intraday_nav_url: str = os.getenv("TWSE_00631L_INTRADAY_NAV_URL", "")
    yuanta_intraday_nav_url: str = os.getenv("YUANTA_00631L_INTRADAY_NAV_URL", "")
    intraday_nav_source: str = os.getenv("00631L_INTRADAY_NAV_SOURCE", "auto").strip().lower()
    twse_price_history_url_template: str = os.getenv(
        "TWSE_00631L_PRICE_HISTORY_URL_TEMPLATE",
        (
            "https://www.twse.com.tw/exchangeReport/STOCK_DAY"
            "?response=json&date={yyyymmdd}&stockNo={symbol}"
        ),
    )
    request_timeout_seconds: float = _env_float("00631L_PROXY_TIMEOUT_SECONDS", 8)
    profile_cache_seconds: int = _env_int("00631L_PROFILE_CACHE_SECONDS", 24 * 60 * 60)
    holdings_cache_seconds: int = _env_int("00631L_HOLDINGS_CACHE_SECONDS", 10 * 60)
    intraday_cache_seconds: int = _env_int("00631L_INTRADAY_NAV_CACHE_SECONDS", 15)
    tx_quote_cache_seconds: int = _env_int("00631L_TX_QUOTE_CACHE_SECONDS", 15)
    taifex_tx_sockjs_url: str = os.getenv(
        "TAIFEX_TX_SOCKJS_URL",
        "https://mis.taifex.com.tw/futures/rt",
    )
    taifex_tx_futures_symbol: str = os.getenv("TAIFEX_TX_FUTURES_SYMBOL", "auto")
    taifex_tx_spot_symbol: str = os.getenv("TAIFEX_TX_SPOT_SYMBOL", "TXF-S")
    holdings_history_path: str = os.getenv(
        "00631L_HOLDINGS_HISTORY_PATH",
        _data_path("00631L_HOLDINGS_HISTORY_PATH", "00631l_holdings_history.jsonl"),
    )
    intraday_nav_history_path: str = os.getenv(
        "00631L_INTRADAY_NAV_HISTORY_PATH",
        _data_path(
            "00631L_INTRADAY_NAV_HISTORY_PATH",
            "00631l_intraday_nav_history.jsonl",
        ),
    )
    price_history_path: str = os.getenv(
        "00631L_PRICE_HISTORY_PATH",
        _data_path("00631L_PRICE_HISTORY_PATH", "00631l_price_history.jsonl"),
    )
    price_history_seed_path: str = os.getenv(
        "00631L_PRICE_HISTORY_SEED_PATH",
        str(_SEED_ROOT / "00631l_price_history_seed.jsonl"),
    )
    etf_catalog_path: str = os.getenv(
        "ETF_CATALOG_PATH",
        _data_path("ETF_CATALOG_PATH", "twse_etf_catalog.json"),
    )
    etf_catalog_seed_path: str = os.getenv(
        "ETF_CATALOG_SEED_PATH",
        str(_SEED_ROOT / "twse_etf_catalog_seed.json"),
    )
    etf_price_history_dir: str = os.getenv(
        "ETF_PRICE_HISTORY_DIR",
        _data_path("ETF_PRICE_HISTORY_DIR", "etf_price_history"),
    )
    etf_price_history_seed_dir: str = os.getenv(
        "ETF_PRICE_HISTORY_SEED_DIR",
        str(_SEED_ROOT / "etf_price_history_seed"),
    )
    history_export_dir: str = os.getenv(
        "00631L_HISTORY_EXPORT_DIR",
        str(_BACKEND_ROOT / "exports"),
    )
    daily_cycle_status_path: str = os.getenv(
        "00631L_DAILY_CYCLE_STATUS_PATH",
        _data_path(
            "00631L_DAILY_CYCLE_STATUS_PATH",
            "00631l_daily_cycle_status.json",
        ),
    )
    integrity_status_path: str = os.getenv(
        "00631L_INTEGRITY_STATUS_PATH",
        _data_path("00631L_INTEGRITY_STATUS_PATH", "00631l_integrity_status.json"),
    )
    restore_dry_run_status_path: str = os.getenv(
        "00631L_RESTORE_DRY_RUN_STATUS_PATH",
        _data_path(
            "00631L_RESTORE_DRY_RUN_STATUS_PATH",
            "00631l_restore_dry_run_status.json",
        ),
    )
    persistence_marker_path: str = os.getenv(
        "00631L_PERSISTENCE_MARKER_PATH",
        _data_path(
            "00631L_PERSISTENCE_MARKER_PATH",
            "00631l_persistence_marker.json",
        ),
    )
    backup_dir: str = os.getenv(
        "00631L_BACKUP_DIR",
        str(_BACKEND_ROOT / "backups"),
    )
    backup_retention_count: int = _env_int("00631L_BACKUP_RETENTION_COUNT", 30)
    report_dir: str = os.getenv(
        "00631L_REPORT_DIR",
        str(_BACKEND_ROOT / "reports"),
    )
    report_retention_count: int = _env_int("00631L_REPORT_RETENTION_COUNT", 30)
    export_retention_count: int = _env_int("00631L_EXPORT_RETENTION_COUNT", 30)


settings = Settings()
