from __future__ import annotations

import os
import shutil
import subprocess
from urllib.error import HTTPError, URLError
from urllib.request import Request, urlopen


class FetchError(RuntimeError):
    pass


def fetch_text(url: str, timeout_seconds: float) -> str:
    request = Request(
        url,
        headers={
            "Accept": "text/html,application/json;q=0.9,*/*;q=0.8",
            "User-Agent": "00631L-lab-proxy/0.1",
        },
    )
    try:
        with urlopen(request, timeout=timeout_seconds) as response:
            raw = response.read()
            encoding = response.headers.get_content_charset() or "utf-8"
            return raw.decode(encoding, errors="replace")
    except HTTPError as error:
        if 300 <= error.code < 400:
            try:
                return _fetch_text_with_curl(url, timeout_seconds)
            except FetchError as curl_error:
                raise FetchError(
                    f"HTTP {error.code} redirect while fetching {url}; curl fallback failed: {curl_error}"
                ) from error
        raise FetchError(f"HTTP {error.code} while fetching {url}") from error
    except URLError as error:
        try:
            return _fetch_text_with_curl(url, timeout_seconds)
        except FetchError as curl_error:
            raise FetchError(
                f"Network error while fetching {url}: {error.reason}; curl fallback failed: {curl_error}"
            ) from error
    except OSError as error:
        try:
            return _fetch_text_with_curl(url, timeout_seconds)
        except FetchError as curl_error:
            raise FetchError(f"OS error while fetching {url}: {error}; curl fallback failed: {curl_error}") from error


def _fetch_text_with_curl(url: str, timeout_seconds: float) -> str:
    enabled = os.getenv("00631L_PROXY_CURL_FALLBACK", "true").strip().lower()
    if enabled in {"0", "false", "no", "off"}:
        raise FetchError("00631L_PROXY_CURL_FALLBACK is disabled")

    curl = shutil.which("curl.exe") or shutil.which("curl")
    if curl is None:
        raise FetchError("curl was not found on PATH")

    try:
        completed = subprocess.run(
            [
                curl,
                "--fail",
                "--location",
                "--max-time",
                str(max(1, int(timeout_seconds))),
                "--silent",
                "--show-error",
                url,
            ],
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
