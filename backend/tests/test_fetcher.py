import unittest
from urllib.error import HTTPError
from unittest.mock import patch

from backend.app.fetcher import FetchError, fetch_text


class FetcherTests(unittest.TestCase):
    def test_fetch_text_follows_http_redirect_with_curl_fallback(self) -> None:
        url = "https://www.twse.com.tw/exchangeReport/STOCK_DAY?stockNo=00749B"

        with patch(
            "backend.app.fetcher.urlopen",
            side_effect=HTTPError(url, 307, "Temporary Redirect", {}, None),
        ), patch(
            "backend.app.fetcher._fetch_text_with_curl",
            return_value='{"stat":"很抱歉，沒有符合條件的資料!","total":0}',
        ) as curl_fallback:
            payload = fetch_text(url, timeout_seconds=3)

        self.assertIn("沒有符合條件", payload)
        curl_fallback.assert_called_once_with(url, 3)

    def test_fetch_text_keeps_non_redirect_http_errors_as_errors(self) -> None:
        url = "https://www.twse.com.tw/exchangeReport/STOCK_DAY?stockNo=00749B"

        with patch(
            "backend.app.fetcher.urlopen",
            side_effect=HTTPError(url, 500, "Internal Server Error", {}, None),
        ), patch("backend.app.fetcher._fetch_text_with_curl") as curl_fallback:
            with self.assertRaises(FetchError) as context:
                fetch_text(url, timeout_seconds=3)

        self.assertIn("HTTP 500", str(context.exception))
        curl_fallback.assert_not_called()


if __name__ == "__main__":
    unittest.main()
