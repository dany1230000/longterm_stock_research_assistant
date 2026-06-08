from __future__ import annotations

from copy import deepcopy
from dataclasses import dataclass
from datetime import datetime, timedelta, timezone
from typing import Any


@dataclass
class CacheEntry:
    value: dict[str, Any]
    stored_at: datetime


class TimedMemoryCache:
    def __init__(self) -> None:
        self._items: dict[str, CacheEntry] = {}

    def get(self, key: str, ttl_seconds: int) -> dict[str, Any] | None:
        entry = self._items.get(key)
        if entry is None:
            return None
        now = datetime.now(timezone.utc)
        if now - entry.stored_at > timedelta(seconds=ttl_seconds):
            return None
        return deepcopy(entry.value)

    def get_any(self, key: str) -> dict[str, Any] | None:
        entry = self._items.get(key)
        if entry is None:
            return None
        return deepcopy(entry.value)

    def set(self, key: str, value: dict[str, Any]) -> None:
        self._items[key] = CacheEntry(
            value=deepcopy(value),
            stored_at=datetime.now(timezone.utc),
        )
