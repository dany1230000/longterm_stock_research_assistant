from __future__ import annotations

from datetime import datetime, time, timedelta, timezone
from typing import Any
from zoneinfo import ZoneInfo


try:
    TAIPEI_TZ = ZoneInfo("Asia/Taipei")
except Exception:  # pragma: no cover - Windows can lack bundled tzdata.
    TAIPEI_TZ = timezone(timedelta(hours=8), name="Asia/Taipei")
REGULAR_SESSION_START = time(9, 0, 0)
REGULAR_SESSION_END = time(13, 30, 0)
POST_CLOSE_CONFIRM_END = time(13, 45, 0)


def intraday_market_session(
    *,
    now_iso: str | None = None,
    data_time_iso: str | None = None,
    user_delay_ms: int | None = None,
) -> dict[str, Any]:
    now = _to_taipei(_parse_datetime(now_iso) or datetime.now(timezone.utc))
    data_time = _parse_datetime(data_time_iso)
    data_time_taipei = _to_taipei(data_time) if data_time is not None else None
    phase = _phase_for(now)
    delay_seconds = max(15, int((user_delay_ms or 15000) / 1000))
    expected_refresh_seconds = _expected_refresh_seconds(phase, delay_seconds)
    max_fresh_age_seconds = _max_fresh_age_seconds(phase, delay_seconds)
    data_age_seconds = None
    if data_time_taipei is not None:
        data_age_seconds = max(
            0,
            int((now - data_time_taipei).total_seconds()),
        )
    data_freshness = _data_freshness(
        phase=phase,
        now=now,
        data_time=data_time_taipei,
        data_age_seconds=data_age_seconds,
        max_fresh_age_seconds=max_fresh_age_seconds,
    )

    return {
        "sourceContract": "twse_intraday_market_session",
        "timezone": "Asia/Taipei",
        "phase": phase,
        "phaseLabel": _phase_label(phase),
        "isTradingDay": now.weekday() < 5,
        "isRegularSession": phase == "regular",
        "isPostCloseConfirmWindow": phase == "post_close_confirm",
        "regularSessionStart": "09:00:00",
        "regularSessionEnd": "13:30:00",
        "postCloseConfirmEnd": "13:45:00",
        "expectedRefreshSeconds": expected_refresh_seconds,
        "maxFreshAgeSeconds": max_fresh_age_seconds,
        "dataAgeSeconds": data_age_seconds,
        "dataFreshness": data_freshness,
        "dataFreshnessLabel": _freshness_label(data_freshness),
        "isIntradayFresh": data_freshness == "fresh",
        "isDisplayUsable": data_freshness
        in {"fresh", "after_hours_last", "market_closed_last"},
        "nextRefreshSeconds": expected_refresh_seconds,
        "note": "TWSE intraday NAV is refreshed during regular hours; Yuanta holdings are daily snapshots.",
    }


def _parse_datetime(value: str | None) -> datetime | None:
    if not value:
        return None
    try:
        return datetime.fromisoformat(str(value).replace("Z", "+00:00"))
    except ValueError:
        return None


def _to_taipei(value: datetime) -> datetime:
    if value.tzinfo is None:
        return value.replace(tzinfo=TAIPEI_TZ)
    return value.astimezone(TAIPEI_TZ)


def _phase_for(now: datetime) -> str:
    if now.weekday() >= 5:
        return "closed"
    current = now.time()
    if current < REGULAR_SESSION_START:
        return "pre_open"
    if current < REGULAR_SESSION_END:
        return "regular"
    if current < POST_CLOSE_CONFIRM_END:
        return "post_close_confirm"
    return "after_close"


def _expected_refresh_seconds(phase: str, delay_seconds: int) -> int:
    if phase == "regular":
        return delay_seconds
    if phase == "post_close_confirm":
        return 30
    if phase == "pre_open":
        return 60
    return 300


def _max_fresh_age_seconds(phase: str, delay_seconds: int) -> int | None:
    if phase == "regular":
        return max(45, delay_seconds * 4)
    if phase == "post_close_confirm":
        return 15 * 60
    return None


def _data_freshness(
    *,
    phase: str,
    now: datetime,
    data_time: datetime | None,
    data_age_seconds: int | None,
    max_fresh_age_seconds: int | None,
) -> str:
    if data_time is None:
        return "unavailable"
    if phase == "regular":
        if data_age_seconds is not None and max_fresh_age_seconds is not None:
            return "fresh" if data_age_seconds <= max_fresh_age_seconds else "stale"
        return "unavailable"
    if phase == "post_close_confirm":
        if data_time.date() == now.date() and data_time.time() >= REGULAR_SESSION_START:
            return "after_hours_last"
        return "stale"
    if phase in {"pre_open", "after_close"}:
        if data_time.date() == now.date() and data_time.time() >= REGULAR_SESSION_START:
            return "after_hours_last"
        return "stale"
    return "market_closed_last"


def _phase_label(phase: str) -> str:
    return {
        "pre_open": "盤前等待",
        "regular": "盤中更新",
        "post_close_confirm": "收盤確認",
        "after_close": "盤後資料",
        "closed": "休市資料",
    }.get(phase, "資料時段")


def _freshness_label(freshness: str) -> str:
    return {
        "fresh": "即時資料新鮮",
        "after_hours_last": "盤後最後資料",
        "market_closed_last": "休市最後資料",
        "stale": "資料可能過期",
        "unavailable": "即時資料不可用",
    }.get(freshness, "資料狀態未知")
