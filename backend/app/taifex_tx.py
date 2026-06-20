from __future__ import annotations

import json
import queue
import random
import string
import threading
import time
import urllib.request
import http.cookiejar
from dataclasses import dataclass
from datetime import datetime, timedelta, timezone
from typing import Any
import re


TAIPEI_TZ = timezone(timedelta(hours=8))
TAIFEX_TX_SOURCE_CONTRACT = "taifex_sockjs_quote"


@dataclass(frozen=True)
class TaifexQuoteFetchConfig:
    sockjs_url: str
    futures_symbol: str = "auto"
    spot_symbol: str = "TXF-S"
    timeout_seconds: float = 8


def fetch_taifex_tx_quote(config: TaifexQuoteFetchConfig, *, fetched_at: str) -> dict[str, Any]:
    base_url = config.sockjs_url.rstrip("/")
    futures_symbols = resolve_taifex_tx_futures_symbols(
        config.futures_symbol,
        fetched_at=fetched_at,
    )
    primary_futures_symbol = futures_symbols[0]
    session_id = _session_id()
    server_id = "000"
    symbols = [*futures_symbols, config.spot_symbol]
    cookie_jar = http.cookiejar.CookieJar()
    opener = urllib.request.build_opener(urllib.request.HTTPCookieProcessor(cookie_jar))

    _open_text(opener, f"{base_url}/info", timeout_seconds=config.timeout_seconds)

    events: "queue.Queue[str]" = queue.Queue()

    def read_eventsource() -> None:
        request = urllib.request.Request(
            f"{base_url}/{server_id}/{session_id}/eventsource",
            headers={
                "Accept": "text/event-stream",
                "User-Agent": "00631L-lab-taifex-proxy/0.1",
            },
        )
        try:
            with opener.open(request, timeout=max(3, config.timeout_seconds + 6)) as response:
                for raw_line in response:
                    line = raw_line.decode("utf-8", errors="replace").strip()
                    if line:
                        events.put(line)
        except OSError as error:
            events.put(f"error: {error}")

    thread = threading.Thread(target=read_eventsource, daemon=True)
    thread.start()
    time.sleep(0.35)

    subscribe_payload = json.dumps(
        [json.dumps({"type": "subscribe", "symbols": symbols}, ensure_ascii=False)],
        ensure_ascii=False,
    ).encode("utf-8")
    request = urllib.request.Request(
        f"{base_url}/{server_id}/{session_id}/xhr_send",
        data=subscribe_payload,
        method="POST",
        headers={
            "Content-Type": "text/plain;charset=UTF-8",
            "User-Agent": "00631L-lab-taifex-proxy/0.1",
        },
    )
    with opener.open(request, timeout=max(3, config.timeout_seconds)) as response:
        if response.status not in {200, 204}:
            raise RuntimeError(f"TAIFEX subscribe returned HTTP {response.status}")

    quotes: dict[str, dict[str, Any]] = {}
    deadline = time.monotonic() + max(3, config.timeout_seconds)
    while time.monotonic() < deadline:
        try:
            line = events.get(timeout=0.4)
        except queue.Empty:
            continue
        if line.startswith("error:"):
            continue
        for event in parse_sockjs_quote_events(line):
            quote = event.get("quote")
            if not isinstance(quote, dict):
                continue
            symbol = str(quote.get("symbol") or "")
            if symbol:
                quotes[symbol] = quote
        futures_symbol = _select_futures_symbol_with_price(
            quotes,
            futures_symbols,
        )
        futures_values = _quote_values(quotes.get(futures_symbol))
        spot_values = _quote_values(quotes.get(config.spot_symbol))
        if _to_float(futures_values.get("125")) is not None and (
            _to_float(spot_values.get("125")) is not None or _to_float(spot_values.get("129")) is not None
        ):
            break

    selected_futures_symbol = _select_futures_symbol_with_price(
        quotes,
        futures_symbols,
    )
    return normalize_taifex_tx_quote(
        quotes,
        futures_symbol=selected_futures_symbol,
        spot_symbol=config.spot_symbol,
        source_url=base_url,
        fetched_at=fetched_at,
        requested_futures_symbol=primary_futures_symbol,
    )


def resolve_taifex_tx_futures_symbols(config_symbol: str, *, fetched_at: str) -> list[str]:
    """Return TAIFEX TX futures symbols to subscribe, primary first.

    The TAIFEX quote frontend uses month-coded symbols such as ``TXFF6-F`` for
    the 2026/06 contract. Older app configs used ``TXF-P``; that stream carries
    a reference/spot payload and can omit the futures last price, so it is
    treated as a legacy placeholder and resolved to the active month contract.
    """

    requested = (config_symbol or "").strip().upper()
    if requested not in {"", "AUTO", "FRONT_MONTH", "TXF-P"}:
        return [requested]

    reference = _fetched_at_as_taipei(fetched_at)
    primary = _tx_symbol_for_contract_month(*_front_month_for(reference))
    next_month = _tx_symbol_for_contract_month(*_next_month(*_front_month_for(reference)))
    return [primary] if primary == next_month else [primary, next_month]


def contract_month_from_taifex_symbol(symbol: str, *, fetched_at: str) -> str:
    reference = _fetched_at_as_taipei(fetched_at)
    match = re.search(r"TXF(?:[A-L]\d/)?([A-L])(\d)-F$", symbol.upper())
    if match is None:
        return "front_month"

    month = ord(match.group(1)) - ord("A") + 1
    year_digit = int(match.group(2))
    decade = reference.year - reference.year % 10
    year = decade + year_digit
    if year < reference.year - 5:
        year += 10
    elif year > reference.year + 5:
        year -= 10
    return f"{year:04d}{month:02d}"


def parse_sockjs_quote_events(line: str) -> list[dict[str, Any]]:
    stripped = line.strip()
    if stripped.startswith("data:"):
        stripped = stripped[len("data:") :].strip()
    if not stripped or stripped in {"o", "h"}:
        return []
    if not stripped.startswith("a"):
        return []
    try:
        messages = json.loads(stripped[1:])
    except json.JSONDecodeError:
        return []
    events: list[dict[str, Any]] = []
    for message in messages:
        if not isinstance(message, str):
            continue
        try:
            event = json.loads(message)
        except json.JSONDecodeError:
            continue
        if isinstance(event, dict) and event.get("type") == "quote":
            events.append(event)
    return events


def normalize_taifex_tx_quote(
    quotes: dict[str, dict[str, Any]],
    *,
    futures_symbol: str,
    spot_symbol: str,
    source_url: str,
    fetched_at: str,
    requested_futures_symbol: str | None = None,
) -> dict[str, Any]:
    futures_values = _quote_values(quotes.get(futures_symbol))
    spot_values = _quote_values(quotes.get(spot_symbol))
    tx_price = _to_float(futures_values.get("125"))
    tx_reference = _to_float(futures_values.get("129"))
    weighted_index = _to_float(spot_values.get("125")) or _to_float(spot_values.get("129"))
    data_time = _quote_data_time(futures_values) or _quote_data_time(spot_values)
    data_time_iso = data_time.isoformat() if data_time else None
    basis_points = tx_price - weighted_index if tx_price is not None and weighted_index is not None else None
    basis_pct = basis_points / weighted_index * 100 if basis_points is not None and weighted_index else None
    change_pct = (
        (tx_price / tx_reference - 1) * 100
        if tx_price is not None and tx_reference not in {None, 0}
        else None
    )
    is_stale = _is_stale(data_time, fetched_at)
    status = (
        "stale"
        if tx_price is not None and is_stale
        else "official"
        if tx_price is not None
        else "unavailable"
    )
    error_message = None
    if tx_price is None:
        error_message = (
            f"TAIFEX {futures_symbol} quote did not include CLastPrice; "
            "the source may be outside active trading hours or the contract may be inactive."
        )
        if requested_futures_symbol and requested_futures_symbol != futures_symbol:
            error_message += f" Requested primary symbol was {requested_futures_symbol}."
    return {
        "symbol": "TX",
        "contractMonth": contract_month_from_taifex_symbol(
            futures_symbol,
            fetched_at=fetched_at,
        ),
        "txSymbol": futures_symbol,
        "spotSymbol": spot_symbol,
        "txPrice": tx_price,
        "weightedIndex": weighted_index,
        "futuresBasisPoints": basis_points,
        "futuresBasisPct": basis_pct,
        "nightSessionChange": change_pct,
        "sourceStatus": status,
        "sourceContract": TAIFEX_TX_SOURCE_CONTRACT,
        "sourceUrl": source_url,
        "fetchedAt": fetched_at,
        "sourceUpdatedAt": data_time_iso,
        "dataTime": data_time_iso,
        "isStale": is_stale,
        "errorMessage": error_message,
    }


def unavailable_tx_quote(source_url: str, fetched_at: str, message: str) -> dict[str, Any]:
    return {
        "symbol": "TX",
        "contractMonth": "front_month",
        "txSymbol": "",
        "spotSymbol": "TXF-S",
        "txPrice": None,
        "weightedIndex": None,
        "futuresBasisPoints": None,
        "futuresBasisPct": None,
        "nightSessionChange": None,
        "sourceStatus": "unavailable",
        "sourceContract": TAIFEX_TX_SOURCE_CONTRACT,
        "sourceUrl": source_url,
        "fetchedAt": fetched_at,
        "sourceUpdatedAt": None,
        "dataTime": None,
        "isStale": True,
        "errorMessage": message,
    }


def _open_text(opener: urllib.request.OpenerDirector, url: str, *, timeout_seconds: float) -> str:
    request = urllib.request.Request(
        url,
        headers={
            "Accept": "application/json,text/plain,*/*",
            "User-Agent": "00631L-lab-taifex-proxy/0.1",
        },
    )
    with opener.open(request, timeout=max(3, timeout_seconds)) as response:
        raw = response.read()
        encoding = response.headers.get_content_charset() or "utf-8"
        return raw.decode(encoding, errors="replace")


def _session_id() -> str:
    alphabet = string.ascii_lowercase + string.digits
    return "".join(random.choice(alphabet) for _ in range(8))


def _select_futures_symbol_with_price(
    quotes: dict[str, dict[str, Any]],
    futures_symbols: list[str],
) -> str:
    for symbol in futures_symbols:
        values = _quote_values(quotes.get(symbol))
        if _to_float(values.get("125")) is not None:
            return symbol
    return futures_symbols[0]


def _quote_values(quote: dict[str, Any] | None) -> dict[str, Any]:
    if not isinstance(quote, dict):
        return {}
    true_values = quote.get("trueValues")
    if isinstance(true_values, dict):
        return true_values
    values = quote.get("values")
    return values if isinstance(values, dict) else {}


def _to_float(value: Any) -> float | None:
    if value is None:
        return None
    text = str(value).replace(",", "").strip()
    if not text:
        return None
    try:
        return float(text)
    except ValueError:
        return None


def _quote_data_time(values: dict[str, Any]) -> datetime | None:
    date_text = str(values.get("144") or "").strip()
    time_text = str(values.get("143") or values.get("20001") or "").strip()
    if len(date_text) != 8 or not time_text:
        return None
    time_text = (time_text + "000000")[:6]
    try:
        return datetime(
            int(date_text[0:4]),
            int(date_text[4:6]),
            int(date_text[6:8]),
            int(time_text[0:2]),
            int(time_text[2:4]),
            int(time_text[4:6]),
            tzinfo=TAIPEI_TZ,
        )
    except ValueError:
        return None


def _fetched_at_as_taipei(fetched_at: str) -> datetime:
    try:
        parsed = datetime.fromisoformat(fetched_at.replace("Z", "+00:00"))
    except ValueError:
        parsed = datetime.now(timezone.utc)
    if parsed.tzinfo is None:
        parsed = parsed.replace(tzinfo=timezone.utc)
    return parsed.astimezone(TAIPEI_TZ)


def _front_month_for(taipei_now: datetime) -> tuple[int, int]:
    year = taipei_now.year
    month = taipei_now.month
    expiry = _third_wednesday(year, month)
    cutoff_minute = 14 * 60 + 30
    minute_of_day = taipei_now.hour * 60 + taipei_now.minute
    if taipei_now.date() > expiry.date() or (
        taipei_now.date() == expiry.date() and minute_of_day >= cutoff_minute
    ):
        year, month = _next_month(year, month)
    return year, month


def _next_month(year: int, month: int) -> tuple[int, int]:
    if month >= 12:
        return year + 1, 1
    return year, month + 1


def _third_wednesday(year: int, month: int) -> datetime:
    cursor = datetime(year, month, 1, tzinfo=TAIPEI_TZ)
    wednesdays = 0
    while True:
        if cursor.weekday() == 2:
            wednesdays += 1
            if wednesdays == 3:
                return cursor
        cursor += timedelta(days=1)


def _tx_symbol_for_contract_month(year: int, month: int) -> str:
    month_code = chr(ord("A") + month - 1)
    return f"TXF{month_code}{year % 10}-F"


def _is_stale(data_time: datetime | None, fetched_at: str) -> bool:
    if data_time is None:
        return True
    try:
        fetched_dt = datetime.fromisoformat(fetched_at.replace("Z", "+00:00"))
    except ValueError:
        return False
    if fetched_dt.tzinfo is None:
        fetched_dt = fetched_dt.replace(tzinfo=timezone.utc)
    return fetched_dt.astimezone(TAIPEI_TZ) - data_time > timedelta(hours=6)
