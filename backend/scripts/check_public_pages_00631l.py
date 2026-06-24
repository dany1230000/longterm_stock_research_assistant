from __future__ import annotations

import argparse
import json
import socket
import urllib.error
import urllib.request
from datetime import datetime, timezone
from typing import Any, Callable
from urllib.parse import urljoin


DEFAULT_ROOT_URL = "https://dany1230000.github.io/longterm_stock_research_assistant/"
DEFAULT_STATIC_BASE_URL = urljoin(DEFAULT_ROOT_URL, "00631l-static-data/")
DEFAULT_MIN_ROW_COUNT = 2800

FetchResult = dict[str, Any]
Fetcher = Callable[[str, float], FetchResult]


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Smoke-check the public GitHub Pages 00631L PWA and static data.",
    )
    parser.add_argument("--root-url", default=DEFAULT_ROOT_URL)
    parser.add_argument("--static-base-url", default=DEFAULT_STATIC_BASE_URL)
    parser.add_argument("--timeout", type=float, default=15.0)
    parser.add_argument("--min-row-count", type=int, default=DEFAULT_MIN_ROW_COUNT)
    args = parser.parse_args()

    payload = run_public_pages_check(
        root_url=args.root_url,
        static_base_url=args.static_base_url,
        timeout=args.timeout,
        min_row_count=args.min_row_count,
    )
    print(json.dumps(payload, ensure_ascii=False, indent=2, sort_keys=True))
    print(
        "[summary] "
        f"overallStatus={payload['overallStatus']} "
        f"rows={payload.get('rowCount', 0)} "
        f"coverage={payload.get('coverageStart') or '-'}..{payload.get('coverageEnd') or '-'} "
        f"warnings={payload['warningCount']} "
        f"failures={payload['failureCount']}"
    )
    return 1 if payload["overallStatus"] == "FAIL" else 0


def run_public_pages_check(
    *,
    root_url: str = DEFAULT_ROOT_URL,
    static_base_url: str = DEFAULT_STATIC_BASE_URL,
    timeout: float = 15.0,
    min_row_count: int = DEFAULT_MIN_ROW_COUNT,
    fetcher: Fetcher = None,
) -> dict[str, Any]:
    fetch = fetcher or _fetch_url
    normalized_root = _with_trailing_slash(root_url)
    normalized_static = _with_trailing_slash(static_base_url)
    checks = [
        _index_check(fetch, normalized_root, timeout),
        _manifest_check(fetch, urljoin(normalized_root, "manifest.json"), timeout),
        _static_status_check(
            fetch,
            urljoin(normalized_static, "status.json"),
            timeout,
            min_row_count=min_row_count,
        ),
        _static_manifest_check(fetch, urljoin(normalized_static, "manifest.json"), timeout),
    ]
    failures = [check["message"] for check in checks if check["status"] == "FAIL"]
    warnings = [check["message"] for check in checks if check["status"] == "WARN"]
    status_payload = next(
        (check.get("payload") for check in checks if check["name"] == "static_status"),
        {},
    )
    row_count = _int(status_payload.get("rowCount")) if isinstance(status_payload, dict) else 0
    coverage_start = status_payload.get("coverageStart") if isinstance(status_payload, dict) else None
    coverage_end = status_payload.get("coverageEnd") if isinstance(status_payload, dict) else None
    overall_status = "FAIL" if failures else "WARN" if warnings else "PASS"
    return {
        "sourceContract": "00631l_public_pages_smoke",
        "checkedAt": datetime.now(timezone.utc).replace(microsecond=0).isoformat(),
        "overallStatus": overall_status,
        "rootUrl": normalized_root,
        "hashUrl": f"{normalized_root}#/00631l-lab",
        "staticBaseUrl": normalized_static,
        "rowCount": row_count,
        "coverageStart": coverage_start,
        "coverageEnd": coverage_end,
        "checks": [_strip_payload(check) for check in checks],
        "warnings": warnings,
        "failures": failures,
        "warningCount": len(warnings),
        "failureCount": len(failures),
    }


def _index_check(fetch: Fetcher, url: str, timeout: float) -> dict[str, Any]:
    response = _safe_fetch(fetch, url, timeout)
    if response["status"] != "PASS":
        return response | {"name": "index"}
    text = response["text"]
    missing = [
        marker
        for marker in ["manifest.json", "flutter_bootstrap.js"]
        if marker not in text
    ]
    if missing:
        return _check(
            "index",
            "FAIL",
            f"Public root responded but does not look like the Flutter web app: {', '.join(missing)} missing.",
            url=url,
            httpStatus=response["httpStatus"],
            contentLength=response["contentLength"],
        )
    return _check(
        "index",
        "PASS",
        "ok",
        url=url,
        httpStatus=response["httpStatus"],
        contentLength=response["contentLength"],
    )


def _manifest_check(fetch: Fetcher, url: str, timeout: float) -> dict[str, Any]:
    response = _safe_fetch(fetch, url, timeout)
    if response["status"] != "PASS":
        return response | {"name": "pwa_manifest"}
    payload = _json_payload(response)
    if payload is None:
        return _check("pwa_manifest", "FAIL", "manifest.json is not valid JSON.", url=url)
    name = str(payload.get("name") or "")
    description = str(payload.get("description") or "")
    if "00631L" not in f"{name} {description}":
        return _check(
            "pwa_manifest",
            "FAIL",
            "PWA manifest does not identify the 00631L app.",
            url=url,
            manifestName=name,
        )
    return _check(
        "pwa_manifest",
        "PASS",
        "ok",
        url=url,
        manifestName=name,
        shortName=payload.get("short_name"),
    )


def _static_status_check(
    fetch: Fetcher,
    url: str,
    timeout: float,
    *,
    min_row_count: int,
) -> dict[str, Any]:
    response = _safe_fetch(fetch, url, timeout)
    if response["status"] != "PASS":
        return response | {"name": "static_status"}
    payload = _json_payload(response)
    if payload is None:
        return _check("static_status", "FAIL", "status.json is not valid JSON.", url=url)
    row_count = _int(payload.get("rowCount"))
    failures: list[str] = []
    if payload.get("sourceStatus") != "static_official":
        failures.append("sourceStatus is not static_official")
    if payload.get("priceField") != "adjustedClose":
        failures.append("priceField is not adjustedClose")
    if row_count < min_row_count:
        failures.append(f"rowCount {row_count} is below {min_row_count}")
    if not payload.get("coverageStart") or not payload.get("coverageEnd"):
        failures.append("coverageStart/coverageEnd missing")
    return _check(
        "static_status",
        "FAIL" if failures else "PASS",
        "; ".join(failures) if failures else "ok",
        url=url,
        rowCount=row_count,
        coverageStart=payload.get("coverageStart"),
        coverageEnd=payload.get("coverageEnd"),
        sourceStatus=payload.get("sourceStatus"),
        priceField=payload.get("priceField"),
        payload=payload,
    )


def _static_manifest_check(fetch: Fetcher, url: str, timeout: float) -> dict[str, Any]:
    response = _safe_fetch(fetch, url, timeout)
    if response["status"] != "PASS":
        return response | {"name": "static_manifest"}
    payload = _json_payload(response)
    if payload is None:
        return _check("static_manifest", "FAIL", "static manifest is not valid JSON.", url=url)
    files = payload.get("files")
    if not isinstance(files, dict):
        return _check("static_manifest", "FAIL", "static manifest files map missing.", url=url)
    required = {"priceHistory", "performance", "status"}
    missing = sorted(required - set(files.keys()))
    if missing:
        return _check(
            "static_manifest",
            "FAIL",
            f"static manifest missing files: {', '.join(missing)}",
            url=url,
        )
    return _check(
        "static_manifest",
        "PASS",
        "ok",
        url=url,
        generatedAt=payload.get("generatedAt"),
        rowCount=_int(payload.get("rowCount")),
    )


def _safe_fetch(fetch: Fetcher, url: str, timeout: float) -> dict[str, Any]:
    try:
        response = fetch(url, timeout)
    except (OSError, urllib.error.URLError, socket.timeout) as error:
        return _check(
            "fetch",
            "WARN",
            f"{url} unavailable: {error}",
            url=url,
            errorMessage=str(error),
        )
    if response.get("httpStatus") != 200:
        return _check(
            "fetch",
            "WARN",
            f"{url} returned HTTP {response.get('httpStatus')}",
            url=url,
            httpStatus=response.get("httpStatus"),
            contentLength=response.get("contentLength", 0),
        )
    return {
        "name": "fetch",
        "status": "PASS",
        "message": "ok",
        "url": url,
        "httpStatus": response.get("httpStatus"),
        "contentLength": response.get("contentLength", 0),
        "text": response.get("text", ""),
    }


def _fetch_url(url: str, timeout: float) -> FetchResult:
    request = urllib.request.Request(
        url,
        headers={"User-Agent": "00631L-public-pages-smoke/1.0"},
    )
    with urllib.request.urlopen(request, timeout=timeout) as response:
        body = response.read()
        return {
            "httpStatus": response.status,
            "contentLength": len(body),
            "text": body.decode("utf-8", errors="replace"),
        }


def _json_payload(response: dict[str, Any]) -> dict[str, Any] | None:
    try:
        payload = json.loads(response.get("text", ""))
    except json.JSONDecodeError:
        return None
    return payload if isinstance(payload, dict) else None


def _strip_payload(check: dict[str, Any]) -> dict[str, Any]:
    stripped = dict(check)
    stripped.pop("payload", None)
    stripped.pop("text", None)
    return stripped


def _check(name: str, status: str, message: str, **extra: Any) -> dict[str, Any]:
    payload = {"name": name, "status": status, "message": message}
    payload.update(extra)
    return payload


def _with_trailing_slash(url: str) -> str:
    return url if url.endswith("/") else f"{url}/"


def _int(value: Any) -> int:
    try:
        return int(value)
    except (TypeError, ValueError):
        return 0


if __name__ == "__main__":
    raise SystemExit(main())
