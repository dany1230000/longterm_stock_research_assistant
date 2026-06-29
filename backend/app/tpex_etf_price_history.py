from __future__ import annotations

import json
import os
import shutil
import subprocess
from datetime import date, datetime, timedelta, timezone
from typing import Any, Callable
from urllib.error import HTTPError, URLError
from urllib.parse import urlencode
from urllib.request import Request, urlopen

from .etf_price_history import normalize_etf_code, parse_code_list
from .fetcher import FetchError


TPEX_ETF_PRICE_HISTORY_CONTRACT = "tpex_etf_historical_daily_json"
TPEX_ETF_PRICE_HISTORY_IMPORT_CONTRACT = "tpex_etf_price_history_import"
TPEX_ETF_PRICE_HISTORY_DEFAULT_URL = (
    "https://www.tpex.org.tw/www/zh-tw/ETFReport/historical"
)

PostFormFetcher = Callable[[str, dict[str, str], float], str]


def post_form_text(url: str, form: dict[str, str], timeout_seconds: float) -> str:
    encoded = urlencode(form).encode("utf-8")
    request = Request(
        url,
        data=encoded,
        headers={
            "Accept": "application/json,text/javascript,*/*;q=0.8",
            "Content-Type": "application/x-www-form-urlencoded; charset=UTF-8",
            "Referer": "https://www.tpex.org.tw/zh-tw/product/etf/info/historical/day.html",
            "User-Agent": "00631L-lab-proxy/0.1",
            "X-Requested-With": "XMLHttpRequest",
        },
        method="POST",
    )
    try:
        with urlopen(request, timeout=timeout_seconds) as response:
            raw = response.read()
            encoding = response.headers.get_content_charset() or "utf-8"
            return raw.decode(encoding, errors="replace")
    except HTTPError as error:
        try:
            return _post_form_text_with_curl(url, form, timeout_seconds)
        except FetchError as curl_error:
            raise FetchError(
                f"HTTP {error.code} while fetching {url}; curl fallback failed: {curl_error}"
            ) from error
    except URLError as error:
        try:
            return _post_form_text_with_curl(url, form, timeout_seconds)
        except FetchError as curl_error:
            raise FetchError(
                f"Network error while fetching {url}: {error.reason}; curl fallback failed: {curl_error}"
            ) from error
    except OSError as error:
        try:
            return _post_form_text_with_curl(url, form, timeout_seconds)
        except FetchError as curl_error:
            raise FetchError(f"OS error while fetching {url}: {error}; curl fallback failed: {curl_error}") from error


def _post_form_text_with_curl(
    url: str,
    form: dict[str, str],
    timeout_seconds: float,
) -> str:
    enabled = os.getenv("00631L_PROXY_CURL_FALLBACK", "true").strip().lower()
    if enabled in {"0", "false", "no", "off"}:
        raise FetchError("00631L_PROXY_CURL_FALLBACK is disabled")

    curl = shutil.which("curl.exe") or shutil.which("curl")
    if curl is None:
        raise FetchError("curl was not found on PATH")

    args = [
        curl,
        "--fail",
        "--location",
        "--max-time",
        str(max(1, int(timeout_seconds))),
        "--silent",
        "--show-error",
        "-X",
        "POST",
        "-H",
        "Content-Type: application/x-www-form-urlencoded; charset=UTF-8",
        "-H",
        "X-Requested-With: XMLHttpRequest",
        "-H",
        "Referer: https://www.tpex.org.tw/zh-tw/product/etf/info/historical/day.html",
    ]
    for key, value in form.items():
        args.extend(["--data-urlencode", f"{key}={value}"])
    args.append(url)
    try:
        completed = subprocess.run(
            args,
            capture_output=True,
            check=False,
            timeout=timeout_seconds + 5,
        )
    except (OSError, subprocess.TimeoutExpired) as error:
        raise FetchError(f"curl execution failed for {url}: {error}") from error

    if completed.returncode != 0:
        stderr = completed.stderr.decode("utf-8", errors="replace").strip()
        raise FetchError(f"curl exited {completed.returncode} for {url}: {stderr}")

    return completed.stdout.decode("utf-8", errors="replace")


def fetch_tpex_etf_price_history(
    *,
    codes: list[str] | tuple[str, ...],
    start_date: date,
    end_date: date,
    url: str = TPEX_ETF_PRICE_HISTORY_DEFAULT_URL,
    fetcher: PostFormFetcher = post_form_text,
    timeout_seconds: float = 8,
) -> dict[str, Any]:
    requested_codes = _unique_codes(codes)
    if not requested_codes:
        raise ValueError("At least one ETF code is required")
    if end_date < start_date:
        raise ValueError("end_date must be on or after start_date")

    requested_set = set(requested_codes)
    fetched_at = datetime.now(timezone.utc).isoformat()
    points_by_code: dict[str, list[dict[str, Any]]] = {
        code: [] for code in requested_codes
    }
    requested_days = 0
    empty_days = 0
    failures: list[str] = []
    warnings: list[str] = []
    latest_source_date: str | None = None

    for report_date in _weekday_dates(start_date, end_date):
        requested_days += 1
        form = {
            "type": "Daily",
            "cate": "all",
            "date": report_date.strftime("%Y/%m/%d"),
            "response": "json",
        }
        try:
            source = fetcher(url, form, timeout_seconds)
            daily_points = parse_tpex_etf_daily_history(
                source,
                source_url=url,
                requested_codes=requested_codes,
            )
        except Exception as error:  # noqa: BLE001 - broad import should continue.
            failures.append(f"{report_date.isoformat()}: {error}")
            continue
        if not daily_points:
            empty_days += 1
            continue
        latest_source_date = report_date.isoformat()
        for point in daily_points:
            code = normalize_etf_code(str(point.get("code") or ""))
            if code in requested_set:
                points_by_code.setdefault(code, []).append(point)

    row_count = sum(len(points) for points in points_by_code.values())
    if empty_days:
        warnings.append(f"tpexEmptyDays={empty_days}")
    if failures and row_count:
        warnings.extend(f"partialFetchFailure={failure}" for failure in failures)
    return {
        "sourceStatus": "official"
        if row_count
        else "error"
        if failures
        else "unavailable",
        "sourceContract": TPEX_ETF_PRICE_HISTORY_IMPORT_CONTRACT,
        "sourceUrl": url,
        "fetchedAt": fetched_at,
        "sourceUpdatedAt": latest_source_date,
        "dataTime": latest_source_date,
        "requestedCodes": requested_codes,
        "requestedDays": requested_days,
        "emptyDays": empty_days,
        "rowCount": row_count,
        "pointsByCode": {
            code: sorted(points, key=lambda item: str(item.get("date") or ""))
            for code, points in points_by_code.items()
        },
        "warnings": warnings,
        "failures": failures,
        "errorMessage": "; ".join(failures) if failures and not row_count else None,
    }


def parse_tpex_etf_daily_history(
    source: str,
    *,
    source_url: str,
    requested_codes: list[str] | tuple[str, ...] | None = None,
) -> list[dict[str, Any]]:
    decoded = json.loads(source)
    if not isinstance(decoded, dict):
        raise ValueError("TPEx ETF history payload is not an object")
    stat = str(decoded.get("stat") or "")
    if stat.lower() != "ok":
        raise ValueError(f"TPEx ETF history status is not ok: {stat}")
    requested_set = set(_unique_codes(requested_codes or []))
    rows: list[Any] = []
    for table in decoded.get("tables") or []:
        if not isinstance(table, dict):
            continue
        table_rows = table.get("data")
        if isinstance(table_rows, list):
            rows.extend(table_rows)

    points: list[dict[str, Any]] = []
    for row in rows:
        if not isinstance(row, list) or len(row) < 9:
            continue
        code = normalize_etf_code(str(row[1] or ""))
        if not code or (requested_set and code not in requested_set):
            continue
        parsed_date = _parse_tpex_roc_date(str(row[0] or ""))
        close = _float(row[8])
        if parsed_date is None or close is None:
            continue
        points.append(
            {
                "code": code,
                "name": str(row[2] or "").strip(),
                "date": parsed_date.isoformat(),
                "volume": _int(row[3]),
                "volumeUnit": "lots",
                "tradedValueThousands": _int(row[4]),
                "open": _float(row[5]),
                "high": _float(row[6]),
                "low": _float(row[7]),
                "close": close,
                "change": _float(row[9]) if len(row) > 9 else None,
                "transactionCount": _int(row[10]) if len(row) > 10 else None,
                "nav": None,
                "premiumDiscountPct": None,
                "sourceStatus": "official",
                "sourceContract": TPEX_ETF_PRICE_HISTORY_CONTRACT,
                "sourceUrl": source_url,
            }
        )
    return sorted(
        points,
        key=lambda item: (str(item.get("code") or ""), str(item.get("date") or "")),
    )


def _weekday_dates(start_date: date, end_date: date) -> list[date]:
    days: list[date] = []
    current = start_date
    while current <= end_date:
        if current.weekday() < 5:
            days.append(current)
        current += timedelta(days=1)
    return days


def _parse_tpex_roc_date(value: str) -> date | None:
    text = value.strip().replace("/", "").replace("-", "")
    if not text.isdigit() or len(text) not in {7, 8}:
        return None
    try:
        if len(text) == 7:
            year = int(text[:3]) + 1911
            month = int(text[3:5])
            day = int(text[5:7])
        else:
            year = int(text[:4])
            month = int(text[4:6])
            day = int(text[6:8])
        return date(year, month, day)
    except ValueError:
        return None


def _unique_codes(values: list[str] | tuple[str, ...]) -> list[str]:
    seen: set[str] = set()
    output: list[str] = []
    for value in values:
        for code in parse_code_list(str(value or "")):
            if code not in seen:
                seen.add(code)
                output.append(code)
    return output


def _float(value: Any) -> float | None:
    if isinstance(value, (int, float)):
        return float(value)
    text = str(value or "").replace(",", "").strip()
    if text in {"", "--", "X"}:
        return None
    try:
        return float(text)
    except ValueError:
        return None


def _int(value: Any) -> int | None:
    number = _float(value)
    return None if number is None else int(number)
