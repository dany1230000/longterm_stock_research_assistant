import unittest
from unittest.mock import patch

from backend.scripts.check_public_console_00631l import check_public_console


class PublicConsoleCheckTests(unittest.TestCase):
    def test_noninteractive_public_console_check_passes_with_app_assets(self) -> None:
        def fake_fetch(url: str, timeout: float):
            if url.endswith("/"):
                return (
                    200,
                    (
                        '<html><head><title>00631L 正二研究室</title>'
                        '<link rel="manifest" href="manifest.json">'
                        '<script src="flutter_bootstrap.js"></script>'
                        "</head></html>"
                    ).encode("utf-8"),
                    None,
                )
            return 200, b"asset", None

        with patch("backend.scripts.check_public_console_00631l._fetch", fake_fetch):
            payload = check_public_console("https://example.test/app/", timeout=1)

        self.assertEqual(payload["overallStatus"], "PASS")
        self.assertEqual(payload["failures"], [])
        self.assertEqual(payload["sourceContract"], "00631l_public_console_noninteractive")
        self.assertTrue(any(item["name"] == "public_app_marker" for item in payload["checks"]))

    def test_noninteractive_public_console_check_fails_without_app_marker(self) -> None:
        def fake_fetch(url: str, timeout: float):
            return 200, b"<html><title>placeholder</title></html>", None

        with patch("backend.scripts.check_public_console_00631l._fetch", fake_fetch):
            payload = check_public_console("https://example.test/app/", timeout=1)

        self.assertEqual(payload["overallStatus"], "FAIL")
        self.assertIn("public_root missing 00631L Flutter app marker", payload["failures"])


if __name__ == "__main__":
    unittest.main()
