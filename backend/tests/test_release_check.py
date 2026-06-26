import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

from backend.scripts.check_public_config_00631l import (
    _allowed_origins_check,
    _data_persistence_check,
    _public_api_url_check,
    _render_disk_check,
)
from backend.scripts.deploy_precheck_00631l import run_deploy_precheck
from backend.scripts.release_check_00631l import (
    ROOT,
    _compact_release_check_payload,
    _has_overall,
    _iter_text_files,
    _required_files_check,
    _static_summary_has_usable_tiers,
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

    def test_compact_release_check_payload_removes_step_output_tails(self) -> None:
        payload = {
            "sourceContract": "00631l_release_check",
            "overallStatus": "WARN",
            "warnings": ["smoke: reported overallStatus WARN"],
            "failures": [],
            "steps": [
                {
                    "name": "smoke",
                    "status": "WARN",
                    "message": "reported overallStatus WARN",
                    "exitCode": 0,
                    "stdoutTail": "long output",
                    "stderrTail": "",
                }
            ],
        }

        compact = _compact_release_check_payload(payload)

        self.assertNotIn("steps", compact)
        self.assertEqual(compact["stepCount"], 1)
        self.assertEqual(compact["stepSummary"][0]["name"], "smoke")
        self.assertNotIn("stdoutTail", compact["stepSummary"][0])

    def test_release_check_uses_concise_etf_history_status(self) -> None:
        source = (ROOT / "backend" / "scripts" / "release_check_00631l.py").read_text(
            encoding="utf-8",
        )

        self.assertIn('"--summary-only"', source)

    def test_release_check_runs_dart_format_gate(self) -> None:
        source = (ROOT / "backend" / "scripts" / "release_check_00631l.py").read_text(
            encoding="utf-8",
        )

        self.assertIn('"dart_format_check"', source)
        self.assertIn('"--set-exit-if-changed"', source)

    def test_release_check_runs_public_pages_smoke(self) -> None:
        source = (ROOT / "backend" / "scripts" / "release_check_00631l.py").read_text(
            encoding="utf-8",
        )

        self.assertIn('"public_pages"', source)
        self.assertIn("scripts\\\\00631l_check_public_pages.cmd", source)

    def test_release_check_runs_pages_deploy_status(self) -> None:
        source = (ROOT / "backend" / "scripts" / "release_check_00631l.py").read_text(
            encoding="utf-8",
        )

        self.assertIn('"pages_deploy_status"', source)
        self.assertIn("scripts\\\\00631l_check_pages_deploy.cmd", source)

    def test_release_check_runs_pages_deploy_wait_dry_run(self) -> None:
        source = (ROOT / "backend" / "scripts" / "release_check_00631l.py").read_text(
            encoding="utf-8",
        )

        self.assertIn('"pages_deploy_wait_dry_run"', source)
        self.assertIn("scripts\\\\00631l_wait_pages_deploy.cmd", source)

    def test_release_check_runs_public_pages_checkup(self) -> None:
        source = (ROOT / "backend" / "scripts" / "release_check_00631l.py").read_text(
            encoding="utf-8",
        )

        self.assertIn('"public_pages_checkup"', source)
        self.assertIn("scripts\\\\00631l_public_pages_checkup.cmd", source)
        self.assertIn('"--skip-github-api"', source)
        self.assertIn('"--summary-only"', source)

    def test_release_check_runs_compact_public_release_marker_wait(self) -> None:
        source = (ROOT / "backend" / "scripts" / "release_check_00631l.py").read_text(
            encoding="utf-8",
        )

        self.assertIn('"public_release_marker_wait_dry_run"', source)
        self.assertIn("scripts\\\\00631l_wait_public_release_marker.cmd", source)
        self.assertIn('"--summary-only"', source)

    def test_static_summary_tier_guard_requires_tiers_when_etf_history_exists(self) -> None:
        self.assertTrue(
            _static_summary_has_usable_tiers(
                "[summary] overallStatus=PASS rows=2832 etfReady=15 "
                "tiers=long_term:8,recent:220,unavailable:0,error:0"
            )
        )
        self.assertFalse(
            _static_summary_has_usable_tiers(
                "[summary] overallStatus=PASS rows=2832 etfReady=15 "
                "tiers=not_available"
            )
        )
        self.assertTrue(
            _static_summary_has_usable_tiers(
                "[summary] overallStatus=WARN rows=0 etfReady=0 tiers=not_available"
            )
        )

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
                "deploy",
                "scripts",
                "docs",
                "web",
            ]:
                (root / directory).mkdir(parents=True, exist_ok=True)
            for file_name in [
                "backend/.env.example",
                "backend/Dockerfile",
                "backend/requirements.txt",
                "deploy/docker-compose.yml",
                "deploy/Caddyfile",
                "deploy/nginx.example.conf",
                "deploy/render.yaml",
                "render.yaml",
                "web/index.html",
                "web/manifest.json",
                "scripts/00631l_check_public_config.cmd",
                "scripts/00631l_check_public_static_data.cmd",
                "scripts/00631l_build_web_public.cmd",
                "scripts/00631l_backend_prod_check.cmd",
                "scripts/00631l_backend_docker_check.cmd",
                "scripts/00631l_start_backend.cmd",
                "scripts/00631l_start_frontend_live.cmd",
                "scripts/00631l_open_lab.cmd",
                "scripts/00631l_daily_cycle.cmd",
                "scripts/00631l_release_check.cmd",
                "scripts/00631l_import_missing_etf_batch.cmd",
                "scripts/00631l_apply_retention.cmd",
                "scripts/00631l_restore_dry_run.cmd",
                "docs/00631l_daily_usage.md",
                "docs/00631l_deployment_notes.md",
                "docs/00631l_public_deployment.md",
                "docs/00631l_live_backend_deployment.md",
                "docs/00631l_pwa_usage.md",
                "docs/00631l_app_store_path.md",
                "docs/00631l_troubleshooting.md",
                "docs/00631l_maintenance_index.md",
                "docs/00631l_v3_3_live_public_summary.md",
            ]:
                (root / file_name).write_text("ok", encoding="utf-8")

            payload = run_deploy_precheck(root)

            self.assertNotEqual(payload["overallStatus"], "FAIL")
            self.assertEqual(payload["failureCount"], 0)

    def test_public_config_accepts_explicit_public_values(self) -> None:
        env = {
            "PUBLIC_API_BASE_URL": "https://api.example.com",
            "ALLOWED_ORIGINS": "https://00631l.example.com,https://www.example.com",
            "00631L_DATA_PERSISTENCE_MODE": "persistent",
            "00631L_DATA_DIR": "/data",
        }

        self.assertEqual(_public_api_url_check(env)["status"], "PASS")
        self.assertEqual(_allowed_origins_check(env)["status"], "PASS")
        self.assertEqual(_data_persistence_check(env)["status"], "PASS")

    def test_public_config_uses_render_defaults_without_public_values(self) -> None:
        with patch.dict(
            "os.environ",
            {
                "PUBLIC_API_BASE_URL": "",
                "ALLOWED_ORIGINS": "",
                "00631L_DATA_PERSISTENCE_MODE": "",
            },
        ):
            self.assertEqual(_public_api_url_check({})["status"], "PASS")
            self.assertEqual(_allowed_origins_check({})["status"], "PASS")
            self.assertEqual(_data_persistence_check({})["status"], "WARN")

    def test_public_config_rejects_wildcard_origin(self) -> None:
        self.assertEqual(_allowed_origins_check({"ALLOWED_ORIGINS": "*"})["status"], "FAIL")

    def test_public_config_checks_render_disk_template(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            (root / "deploy").mkdir()
            (root / "deploy" / "render.yaml").write_text(
                "\n".join(
                    [
                        "services:",
                        "  - type: web",
                        "    disk:",
                        "      name: 00631l-data",
                        "      mountPath: /data/00631l",
                        "      sizeGB: 1",
                    ]
                ),
                encoding="utf-8",
            )

            self.assertEqual(_render_disk_check(root, "deploy/render.yaml")["status"], "PASS")

            (root / "render.yaml").write_text("services:\n  - type: web\n", encoding="utf-8")
            self.assertEqual(_render_disk_check(root, "render.yaml")["status"], "WARN")


if __name__ == "__main__":
    unittest.main()
