import json
import unittest

from backend.scripts.check_public_pages_00631l import run_public_pages_check


class PublicPagesCheckTests(unittest.TestCase):
    def test_public_pages_check_passes_with_valid_static_data(self) -> None:
        def fetcher(url: str, timeout: float) -> dict:
            del timeout
            if url.endswith("/manifest.json") and "00631l-static-data" not in url:
                return _response({"name": "00631L ETF Research Room"})
            if url.endswith("/00631l-static-data/status.json"):
                return _response(
                    {
                        "sourceStatus": "static_official",
                        "priceField": "adjustedClose",
                        "rowCount": 2832,
                        "coverageStart": "2014-10-31",
                        "coverageEnd": "2026-06-18",
                    }
                )
            if url.endswith("/00631l-static-data/manifest.json"):
                return _response(
                    {
                        "files": {
                            "priceHistory": "price_history.json",
                            "performance": "performance.json",
                            "status": "status.json",
                            "release": "release.json",
                        },
                        "rowCount": 2832,
                    }
                )
            if url.endswith("/00631l-static-data/release.json"):
                return _response(
                    {
                        "sourceContract": "00631l_static_public_release_marker",
                        "appVersion": "5.39-public-release-marker",
                        "releaseTag": "00631l-lab-v5.39-public-release-marker",
                        "gitSha": "abc123fff",
                        "buildTime": "2026-06-24T08:00:00+00:00",
                    }
                )
            return {
                "httpStatus": 200,
                "contentLength": 80,
                "text": '<html><link rel="manifest" href="manifest.json"><script src="flutter_bootstrap.js"></script></html>',
            }

        payload = run_public_pages_check(fetcher=fetcher, expected_sha="abc123")

        self.assertEqual(payload["overallStatus"], "PASS")
        self.assertEqual(payload["failureCount"], 0)
        self.assertEqual(payload["rowCount"], 2832)
        self.assertEqual(payload["coverageStart"], "2014-10-31")
        self.assertEqual(payload["releaseTag"], "00631l-lab-v5.39-public-release-marker")
        self.assertEqual(payload["releaseGitSha"], "abc123fff")

    def test_public_pages_check_fails_when_static_rows_are_too_low(self) -> None:
        def fetcher(url: str, timeout: float) -> dict:
            del timeout
            if url.endswith("/00631l-static-data/status.json"):
                return _response(
                    {
                        "sourceStatus": "static_official",
                        "priceField": "adjustedClose",
                        "rowCount": 10,
                        "coverageStart": "2026-01-01",
                        "coverageEnd": "2026-01-15",
                    }
                )
            if url.endswith("/00631l-static-data/manifest.json"):
                return _response(
                    {
                        "files": {
                            "priceHistory": "price_history.json",
                            "performance": "performance.json",
                            "status": "status.json",
                            "release": "release.json",
                        }
                    }
                )
            if url.endswith("/00631l-static-data/release.json"):
                return _response(
                    {
                        "sourceContract": "00631l_static_public_release_marker",
                        "releaseTag": "00631l-lab-v5.39-public-release-marker",
                        "gitSha": "abc123fff",
                    }
                )
            if url.endswith("/manifest.json"):
                return _response({"name": "00631L ETF Research Room"})
            return {
                "httpStatus": 200,
                "contentLength": 80,
                "text": '<html><link rel="manifest" href="manifest.json"><script src="flutter_bootstrap.js"></script></html>',
            }

        payload = run_public_pages_check(fetcher=fetcher)

        self.assertEqual(payload["overallStatus"], "FAIL")
        self.assertGreater(payload["failureCount"], 0)
        self.assertIn("rowCount 10 is below 2800", payload["failures"][0])

    def test_public_pages_check_warns_when_release_marker_sha_differs(self) -> None:
        def fetcher(url: str, timeout: float) -> dict:
            del timeout
            if url.endswith("/manifest.json") and "00631l-static-data" not in url:
                return _response({"name": "00631L ETF Research Room"})
            if url.endswith("/00631l-static-data/status.json"):
                return _response(
                    {
                        "sourceStatus": "static_official",
                        "priceField": "adjustedClose",
                        "rowCount": 2832,
                        "coverageStart": "2014-10-31",
                        "coverageEnd": "2026-06-18",
                    }
                )
            if url.endswith("/00631l-static-data/manifest.json"):
                return _response(
                    {
                        "files": {
                            "priceHistory": "price_history.json",
                            "performance": "performance.json",
                            "status": "status.json",
                            "release": "release.json",
                        }
                    }
                )
            if url.endswith("/00631l-static-data/release.json"):
                return _response(
                    {
                        "sourceContract": "00631l_static_public_release_marker",
                        "releaseTag": "00631l-lab-v5.38-public-checkup-rate-limit",
                        "gitSha": "oldsha123456",
                    }
                )
            return {
                "httpStatus": 200,
                "contentLength": 80,
                "text": '<html><link rel="manifest" href="manifest.json"><script src="flutter_bootstrap.js"></script></html>',
            }

        payload = run_public_pages_check(fetcher=fetcher, expected_sha="newsha123456")

        self.assertEqual(payload["overallStatus"], "WARN")
        self.assertEqual(payload["failureCount"], 0)
        self.assertTrue(
            any("public release SHA differs" in item for item in payload["warnings"])
        )

    def test_public_pages_check_warns_when_network_is_unavailable(self) -> None:
        def fetcher(url: str, timeout: float) -> dict:
            del url, timeout
            raise OSError("offline")

        payload = run_public_pages_check(fetcher=fetcher)

        self.assertEqual(payload["overallStatus"], "WARN")
        self.assertEqual(payload["failureCount"], 0)
        self.assertGreater(payload["warningCount"], 0)


def _response(payload: dict) -> dict:
    text = json.dumps(payload)
    return {"httpStatus": 200, "contentLength": len(text), "text": text}


if __name__ == "__main__":
    unittest.main()
