import tempfile
import unittest
from pathlib import Path

from backend.scripts.deploy_precheck_00631l import run_deploy_precheck
from backend.scripts.release_check_00631l import (
    _has_overall,
    _iter_text_files,
    _required_files_check,
)


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

    def test_overall_status_detection_accepts_summary_format(self) -> None:
        self.assertTrue(_has_overall("[summary] overallStatus=WARN", "WARN"))
        self.assertTrue(_has_overall("overallStatus WARN", "WARN"))
        self.assertTrue(_has_overall('{"overallStatus": "PASS"}', "PASS"))
        self.assertFalse(_has_overall("[summary] overallStatus=PASS", "FAIL"))

    def test_deploy_precheck_fails_when_required_files_are_missing(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            payload = run_deploy_precheck(Path(temp_dir))

            self.assertEqual(payload["overallStatus"], "FAIL")
            self.assertGreater(payload["failureCount"], 0)

    def test_deploy_precheck_accepts_minimal_local_layout(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            for directory in [
                "backend/data",
                "backend/exports",
                "backend/backups",
                "backend/reports",
                "backend",
                "scripts",
                "docs",
                "web",
            ]:
                (root / directory).mkdir(parents=True, exist_ok=True)
            for file_name in [
                "backend/.env.example",
                "backend/requirements.txt",
                "web/index.html",
                "web/manifest.json",
                "scripts/00631l_start_backend.cmd",
                "scripts/00631l_start_frontend_live.cmd",
                "scripts/00631l_open_lab.cmd",
                "scripts/00631l_daily_cycle.cmd",
                "scripts/00631l_release_check.cmd",
                "scripts/00631l_apply_retention.cmd",
                "scripts/00631l_restore_dry_run.cmd",
                "docs/00631l_daily_usage.md",
                "docs/00631l_deployment_notes.md",
                "docs/00631l_troubleshooting.md",
                "docs/00631l_maintenance_index.md",
            ]:
                (root / file_name).write_text("ok", encoding="utf-8")

            payload = run_deploy_precheck(root)

            self.assertNotEqual(payload["overallStatus"], "FAIL")
            self.assertEqual(payload["failureCount"], 0)


if __name__ == "__main__":
    unittest.main()
