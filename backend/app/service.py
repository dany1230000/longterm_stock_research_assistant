from __future__ import annotations

from typing import Any, Callable

from .cache import TimedMemoryCache
from .config import Settings, settings
from .fetcher import FetchError, fetch_text
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
    ) -> None:
        self._config = config
        self._fetcher = fetcher
        self._cache = cache or TimedMemoryCache()

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


service = Etf00631LService()
