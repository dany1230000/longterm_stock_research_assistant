import tempfile
import unittest
from pathlib import Path

from backend.scripts.release_check_00631l import _iter_text_files, _required_files_check


class ReleaseCheckTests(unittest.TestCase):
    def test_required_maintenance_artifacts_exist(self) -> None:
        payload = _required_files_check()

        self.assertEqual(payload["status"], "PASS")
        self.assertEqual(payload["missingFiles"], [])

    def test_text_file_scan_ignores_local_outputs(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            docs = root / "docs"
            reports = root / "backend" / "reports"
            backups = root / "backend" / "backups"
            docs.mkdir()
            reports.mkdir(parents=True)
            backups.mkdir(parents=True)
            (docs / "tracked.md").write_text("tracked", encoding="utf-8")
            (reports / "local_report.md").write_text("local", encoding="utf-8")
            (backups / "local_note.md").write_text("local", encoding="utf-8")

            files = _iter_text_files([root])
            names = {path.name for path in files}

            self.assertIn("tracked.md", names)
            self.assertNotIn("local_report.md", names)
            self.assertNotIn("local_note.md", names)


if __name__ == "__main__":
    unittest.main()
