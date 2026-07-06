from __future__ import annotations

import argparse
import json
import re
import sys
from datetime import datetime, timezone
from typing import Any
from urllib.error import HTTPError, URLError
from urllib.parse import urljoin
from urllib.request import Request, urlopen


DEFAULT_ROOT_URL = "https://dany1230000.github.io/longterm_stock_research_assistant/"
REQUIRED_ASSETS = ("flutter_bootstrap.js", "manifest.json")


def _utc_now() -> str:
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat()


def _fetch(url: str, timeout: float) -> tuple[int | None, bytes, str | None]:
    request = Request(
        url,
        headers={
            "User-Agent": "00631L-release-check/1.0",
            "Cache-Control": "no-cache",
        },
    )
    try:
        with urlopen(request, timeout=timeout) as response:
            return response.status, response.read(), None
    except HTTPError as exc:
        body = exc.read() if hasattr(exc, "read") else b""
        return exc.code, body, str(exc)
    except (OSError, URLError) as exc:
        return None, b"", str(exc)


def _contains_public_app_marker(html: str) -> bool:
    return "00631L" in html and (
        "flutter_bootstrap.js" in html or "main.dart.js" in html
    )


def _find_asset_urls(root_url: str, html: str) -> list[str]:
    urls: list[str] = []
    for asset in REQUIRED_ASSETS:
        urls.append(urljoin(root_url, asset))
    for match in re.finditer(r"""(?:src|href)=["']([^"']+main\.dart\.js[^"']*)["']""", html):
        urls.append(urljoin(root_url, match.group(1)))
    return list(dict.fromkeys(urls))


def check_public_console(root_url: str, timeout: float) -> dict[str, Any]:
    root_url = root_url if root_url.endswith("/") else f"{root_url}/"
    failures: list[str] = []
    checks: list[dict[str, Any]] = []
    root_status, root_body, root_error = _fetch(root_url, timeout)
    root_text = root_body.decode("utf-8", errors="replace")
    checks.append(
        {
            "name": "public_root",
            "url": root_url,
            "httpStatus": root_status,
            "contentLength": len(root_body),
            "status": "PASS" if root_status == 200 else "FAIL",
            "errorMessage": root_error,
        }
    )
    if root_status != 200:
        failures.append(f"public_root httpStatus={root_status} error={root_error}")
    if root_status == 200 and not _contains_public_app_marker(root_text):
        failures.append("public_root missing 00631L Flutter app marker")
        checks.append(
            {
                "name": "public_app_marker",
                "status": "FAIL",
                "message": "Root HTML did not contain expected 00631L app marker.",
            }
        )
    elif root_status == 200:
        checks.append(
            {
                "name": "public_app_marker",
                "status": "PASS",
                "message": "Root HTML contains expected 00631L app marker.",
            }
        )

    if root_status == 200:
        for asset_url in _find_asset_urls(root_url, root_text):
            status, body, error = _fetch(asset_url, timeout)
            ok = status == 200 and len(body) > 0
            checks.append(
                {
                    "name": "public_asset",
                    "url": asset_url,
                    "httpStatus": status,
                    "contentLength": len(body),
                    "status": "PASS" if ok else "FAIL",
                    "errorMessage": error,
                }
            )
            if not ok:
                failures.append(
                    f"public_asset url={asset_url} httpStatus={status} error={error}"
                )

    return {
        "checkedAt": _utc_now(),
        "sourceContract": "00631l_public_console_noninteractive",
        "rootUrl": root_url,
        "overallStatus": "FAIL" if failures else "PASS",
        "failures": failures,
        "checks": checks,
    }


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Non-interactive public 00631L PWA smoke check."
    )
    parser.add_argument("root_url", nargs="?", default=DEFAULT_ROOT_URL)
    parser.add_argument("--timeout", type=float, default=20.0)
    args = parser.parse_args()
    result = check_public_console(args.root_url, args.timeout)
    print(json.dumps(result, ensure_ascii=False, indent=2, sort_keys=True))
    print(
        "[summary] overallStatus={status} failures={count}".format(
            status=result["overallStatus"],
            count=len(result["failures"]),
        )
    )
    return 0 if result["overallStatus"] == "PASS" else 1


if __name__ == "__main__":
    sys.exit(main())
