from __future__ import annotations

import argparse
import json
from typing import Any, Callable
from urllib.error import URLError
from urllib.parse import urljoin
from urllib.request import Request, urlopen


DEFAULT_STATIC_BASE_URL = (
    "https://dany1230000.github.io/longterm_stock_research_assistant/"
    "00631l-static-data/"
)


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Check public GitHub Pages static 00631L data metadata.",
    )
    parser.add_argument("--base-url", default=DEFAULT_STATIC_BASE_URL)
    parser.add_argument("--expected-release-tag", default="")
    parser.add_argument("--expected-sha", default="")
    parser.add_argument(
        "--strict-release",
        action="store_true",
        help="Treat expected release tag/SHA mismatch as FAIL instead of WARN.",
    )
    args = parser.parse_args()

    payload = run_public_static_data_check(
        args.base_url,
        expected_release_tag=args.expected_release_tag,
        expected_sha=args.expected_sha,
        strict_release=args.strict_release,
    )
    print(json.dumps(payload, ensure_ascii=False, indent=2, sort_keys=True))
    print(
        "[summary] "
        f"overallStatus={payload['overallStatus']} "
        f"releaseTag={payload.get('releaseTag') or 'unknown'} "
        f"rows={payload.get('rowCount') or 0} "
        f"coverage={payload.get('coverageStart') or 'unavailable'}.."
        f"{payload.get('coverageEnd') or 'unavailable'} "
        f"etfReady={payload.get('etfPriceHistoryReadyCount') or 0} "
        f"etfCatalogRows={payload.get('etfCatalogRowCount') or 0} "
        f"gap={_gap_reason_summary(payload.get('etfPriceHistoryGapReasonCounts'))} "
        f"releaseMatchesExpected={payload.get('releaseMatchesExpected')} "
        f"failures={len(payload['failures'])}"
    )
    return 1 if payload["overallStatus"] == "FAIL" else 0


def run_public_static_data_check(
    base_url: str,
    *,
    fetch_json: Callable[[str], dict[str, Any]] | None = None,
    expected_release_tag: str = "",
    expected_sha: str = "",
    strict_release: bool = False,
) -> dict[str, Any]:
    normalized_base = base_url.rstrip("/") + "/"
    fetch = fetch_json or _fetch_json
    failures: list[str] = []
    warnings: list[str] = []

    try:
        status = fetch(urljoin(normalized_base, "status.json"))
    except Exception as error:  # noqa: BLE001 - CLI should return JSON failure.
        status = {}
        failures.append(f"status.json: {error}")
    try:
        manifest = fetch(urljoin(normalized_base, "manifest.json"))
    except Exception as error:  # noqa: BLE001 - CLI should return JSON failure.
        manifest = {}
        failures.append(f"manifest.json: {error}")
    try:
        release = fetch(urljoin(normalized_base, "release.json"))
    except Exception as error:  # noqa: BLE001 - release marker is useful but non-critical.
        release = {}
        warnings.append(f"release.json: {error}")

    row_count = _int(status.get("rowCount") or manifest.get("rowCount"))
    catalog_rows = _int(manifest.get("etfCatalogRowCount"))
    etf_ready = _int(manifest.get("etfPriceHistoryReadyCount"))
    etf_missing = _int(manifest.get("etfPriceHistoryMissingCount"))
    gap_reason_counts = (
        manifest.get("etfPriceHistoryGapReasonCounts")
        or status.get("etfPriceHistoryGapReasonCounts")
        or {}
    )
    source_status = str(status.get("sourceStatus") or manifest.get("sourceStatus") or "")
    release_tag = str(
        release.get("releaseTag")
        or (manifest.get("release") or {}).get("releaseTag")
        or "",
    )
    git_sha = str(
        release.get("gitSha") or (manifest.get("release") or {}).get("gitSha") or "",
    )
    release_mismatch: list[str] = []

    if not failures:
        if row_count < 2800:
            warnings.append(f"00631L rowCount below expected floor: {row_count}")
        if catalog_rows < 100:
            warnings.append(f"ETF catalog rows below expected floor: {catalog_rows}")
        if not release_tag:
            warnings.append("release marker is missing releaseTag")
        if source_status != "static_official":
            warnings.append(f"unexpected sourceStatus={source_status or 'missing'}")
        if expected_release_tag and release_tag != expected_release_tag:
            release_mismatch.append(
                "releaseTag mismatch: "
                f"expected {expected_release_tag}, got {release_tag or 'missing'}",
            )
        if expected_sha and not _sha_matches(git_sha, expected_sha):
            release_mismatch.append(
                "gitSha mismatch: "
                f"expected {expected_sha}, got {git_sha or 'missing'}",
            )
        if release_mismatch:
            if strict_release:
                failures.extend(release_mismatch)
            else:
                warnings.extend(release_mismatch)

    overall_status = "FAIL" if failures else "WARN" if warnings else "PASS"
    return {
        "overallStatus": overall_status,
        "sourceContract": "00631l_public_static_data_check",
        "baseUrl": normalized_base,
        "sourceStatus": source_status or None,
        "releaseTag": release_tag or None,
        "appVersion": release.get("appVersion")
        or (manifest.get("release") or {}).get("appVersion"),
        "gitSha": git_sha or None,
        "expectedReleaseTag": expected_release_tag or None,
        "expectedSha": expected_sha or None,
        "releaseMatchesExpected": not release_mismatch,
        "rowCount": row_count,
        "coverageStart": status.get("coverageStart") or manifest.get("coverageStart"),
        "coverageEnd": status.get("coverageEnd") or manifest.get("coverageEnd"),
        "etfCatalogRowCount": catalog_rows,
        "etfPriceHistoryReadyCount": etf_ready,
        "etfPriceHistoryMissingCount": etf_missing,
        "etfPriceHistoryCoverageTierCounts": manifest.get(
            "etfPriceHistoryCoverageTierCounts",
        )
        or {},
        "etfPriceHistoryGapReasonCounts": gap_reason_counts
        if isinstance(gap_reason_counts, dict)
        else {},
        "warnings": warnings,
        "failures": failures,
    }


def _fetch_json(url: str) -> dict[str, Any]:
    request = Request(url, headers={"User-Agent": "00631l-public-static-check"})
    try:
        with urlopen(request, timeout=20) as response:  # noqa: S310 - public HTTPS check.
            payload = json.loads(response.read().decode("utf-8"))
    except URLError as error:
        raise RuntimeError(str(error)) from error
    if not isinstance(payload, dict):
        raise RuntimeError("response is not a JSON object")
    return payload


def _int(value: object) -> int:
    try:
        return int(value or 0)
    except (TypeError, ValueError):
        return 0


def _sha_matches(actual_sha: str, expected_sha: str) -> bool:
    if not expected_sha:
        return True
    if not actual_sha:
        return False
    normalized_actual = actual_sha.lower()
    normalized_expected = expected_sha.lower()
    return normalized_actual.startswith(normalized_expected) or normalized_expected.startswith(
        normalized_actual,
    )


def _gap_reason_summary(value: object) -> str:
    if not isinstance(value, dict) or not value:
        return "unavailable"
    ordered = [
        "official_empty",
        "not_saved",
        "insufficient_rows",
        "validation_error",
        "source_error",
        "not_ready",
    ]
    parts = [
        f"{key}={_int(value.get(key))}"
        for key in ordered
        if _int(value.get(key)) > 0
    ]
    return ",".join(parts) if parts else "clear"


if __name__ == "__main__":
    raise SystemExit(main())
