import json
import tempfile
import unittest
from pathlib import Path

from backend.app.etf_price_history import EtfPriceHistoryStore
from backend.scripts.restore_public_etf_attempts import (
    compact_restore_response,
    restore_public_etf_attempts,
)


class PublicEtfAttemptRestoreTests(unittest.TestCase):
    def test_restore_public_attempts_writes_local_attempt_evidence(self) -> None:
        payload = {
            "sourceContract": "twse_multi_etf_static_price_history_index",
            "readyCount": 1,
            "missingCount": 1,
            "attemptedCount": 1,
            "items": [
                {"code": "0050", "rowCount": 3},
                {
                    "code": "00999",
                    "rowCount": 0,
                    "lastImportAttempt": {
                        "code": "00999",
                        "sourceStatus": "official_empty",
                        "sourceUrl": "fixture://00999",
                        "attemptedAt": "2026-06-27T00:00:00+00:00",
                        "emptyMonths": ["2026-06"],
                        "errorMessage": "",
                    },
                },
            ],
        }

        with tempfile.TemporaryDirectory() as temp_dir:
            result = restore_public_etf_attempts(
                base_url="https://example.test/static",
                output_dir=temp_dir,
                timeout_seconds=1,
                fetcher=lambda _url, _timeout: json.dumps(payload),
            )
            attempt = EtfPriceHistoryStore(Path(temp_dir)).import_attempt("00999")

        self.assertEqual(result["overallStatus"], "PASS")
        self.assertEqual(result["restoredCount"], 1)
        self.assertIsNotNone(attempt)
        self.assertEqual(attempt["sourceStatus"], "official_empty")

    def test_restore_public_attempts_warns_when_public_index_is_unavailable(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            result = restore_public_etf_attempts(
                base_url="https://example.test/static",
                output_dir=temp_dir,
                timeout_seconds=1,
                fetcher=lambda _url, _timeout: (_ for _ in ()).throw(
                    OSError("offline"),
                ),
            )

        self.assertEqual(result["overallStatus"], "WARN")
        self.assertEqual(result["restoredCount"], 0)
        self.assertEqual(compact_restore_response(result)["failureCount"], 0)


if __name__ == "__main__":
    unittest.main()
