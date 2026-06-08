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


_load_backend_dotenv()

_BACKEND_ROOT = Path(__file__).resolve().parents[1]


@dataclass(frozen=True)
class Settings:
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
    request_timeout_seconds: float = _env_float("00631L_PROXY_TIMEOUT_SECONDS", 8)
    profile_cache_seconds: int = _env_int("00631L_PROFILE_CACHE_SECONDS", 24 * 60 * 60)
    holdings_cache_seconds: int = _env_int("00631L_HOLDINGS_CACHE_SECONDS", 10 * 60)
    intraday_cache_seconds: int = _env_int("00631L_INTRADAY_NAV_CACHE_SECONDS", 15)
    holdings_history_path: str = os.getenv(
        "00631L_HOLDINGS_HISTORY_PATH",
        str(_BACKEND_ROOT / "data" / "00631l_holdings_history.jsonl"),
    )


settings = Settings()
