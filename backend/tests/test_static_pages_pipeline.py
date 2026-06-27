import json
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]


class StaticPagesPipelineTests(unittest.TestCase):
    def test_github_pages_full_catalog_import_is_schedule_or_manual_only(self) -> None:
        workflow = (ROOT / ".github" / "workflows" / "deploy_web.yml").read_text(
            encoding="utf-8",
        )

        refresh_condition = (
            "if: github.event_name == 'schedule' || (github.event_name == 'workflow_dispatch' && "
            "(inputs.refresh_etf_histories == 'true' || inputs.full_etf_refresh == 'true'))"
        )
        self.assertIn("refresh_etf_histories", workflow)
        self.assertGreaterEqual(workflow.count(refresh_condition), 2)
        self.assertIn("full_etf_refresh", workflow)
        self.assertIn(
            "if: github.event_name == 'schedule' || (github.event_name == 'workflow_dispatch' && inputs.full_etf_refresh == 'true')",
            workflow,
        )
        self.assertIn("--from-catalog", workflow)
        self.assertIn(
            "--catalog-path backend/seeds/twse_etf_catalog_seed.json",
            workflow,
        )
        self.assertIn("--limit 0", workflow)
        self.assertIn("--summary-only", workflow)
        self.assertIn("--progress-every 25", workflow)
        self.assertIn("--missing-only", workflow)
        self.assertIn("--limit 50", workflow)
        self.assertIn("Probe missing ETF gap reasons", workflow)
        self.assertIn("--skip-attempted", workflow)
        self.assertIn("--limit 20", workflow)
        self.assertIn("--start-date 2026-06-01", workflow)
        self.assertIn("--progress-every 10", workflow)
        self.assertIn("--max-coverage-age-days 7", workflow)
        self.assertIn("--multi-etf-codes all-catalog", workflow)
        self.assertIn("Guard public static data regression", workflow)
        self.assertIn("guard_static_public_regression_00631l.py", workflow)
        self.assertIn("fetch-depth: 0", workflow)

    def test_local_pages_build_full_catalog_import_is_explicit(self) -> None:
        script = (ROOT / "scripts" / "00631l_build_pages_static.cmd").read_text(
            encoding="utf-8",
        )

        self.assertIn("--full-etf-refresh", script)
        self.assertIn("--refresh-etf-history", script)
        self.assertIn("--probe-missing", script)
        self.assertIn("FULL_ETF_REFRESH", script)
        self.assertIn("REFRESH_ETF_HISTORY", script)
        self.assertIn("PROBE_MISSING", script)
        self.assertIn("Skipping selected ETF price-history refresh", script)
        self.assertIn("Skipping broad all-catalog ETF recent refresh", script)
        self.assertIn("Skipping missing-only ETF history batch", script)
        self.assertIn("Skipping missing ETF reason probe", script)
        self.assertIn("--from-catalog", script)
        self.assertIn(
            "--catalog-path backend\\seeds\\twse_etf_catalog_seed.json",
            script,
        )
        self.assertIn("--limit 0", script)
        self.assertIn("--summary-only", script)
        self.assertIn("--progress-every 25", script)
        self.assertIn("scripts\\00631l_import_missing_etf_batch.cmd", script)
        self.assertIn("scripts\\00631l_probe_missing_etf_reasons.cmd", script)
        self.assertIn("--limit 50", script)
        self.assertIn("--limit 20", script)
        self.assertIn("--start-date 2026-06-01", script)
        self.assertIn("--progress-every 10", script)
        self.assertIn("--max-coverage-age-days 7", script)
        self.assertIn("--multi-etf-codes all-catalog", script)
        self.assertIn("scripts\\00631l_guard_static_public_regression.cmd", script)

        probe_script = (
            ROOT / "scripts" / "00631l_probe_missing_etf_reasons.cmd"
        ).read_text(encoding="utf-8")
        self.assertIn("--skip-attempted", probe_script)

    def test_broad_etf_price_seed_is_committed_for_pages_reproducibility(self) -> None:
        seed_dir = ROOT / "backend" / "seeds" / "etf_price_history_seed"
        seed_files = sorted(seed_dir.glob("*.jsonl"))

        self.assertGreaterEqual(len(seed_files), 200)
        self.assertTrue((seed_dir / "00407A.jsonl").exists())
        self.assertTrue((seed_dir / "00631L.jsonl").exists())
        self.assertTrue((seed_dir / "0050.jsonl").exists())
        self.assertTrue((seed_dir / "00878.jsonl").exists())

    def test_00407a_seed_rows_are_official_recent_history(self) -> None:
        seed_path = ROOT / "backend" / "seeds" / "etf_price_history_seed" / "00407A.jsonl"
        records = [
            json.loads(line)
            for line in seed_path.read_text(encoding="utf-8").splitlines()
            if line.strip()
        ]

        self.assertEqual([record["date"] for record in records], [
            "2026-06-24",
            "2026-06-25",
            "2026-06-26",
        ])
        self.assertTrue(all(record["code"] == "00407A" for record in records))
        self.assertTrue(all(record["sourceStatus"] == "official" for record in records))
        self.assertTrue(all(record["sourceContract"] == "twse_stock_day_json" for record in records))

    def test_00631l_static_seed_includes_latest_official_rows(self) -> None:
        seed_path = ROOT / "backend" / "seeds" / "00631l_price_history_seed.jsonl"
        records = [
            json.loads(line)
            for line in seed_path.read_text(encoding="utf-8").splitlines()
            if line.strip()
        ]

        self.assertEqual(records[-2]["date"], "2026-06-25")
        self.assertEqual(records[-1]["date"], "2026-06-26")
        self.assertEqual(records[-1]["sourceStatus"], "official")
        self.assertEqual(records[-1]["sourceContract"], "twse_stock_day_json")


if __name__ == "__main__":
    unittest.main()
