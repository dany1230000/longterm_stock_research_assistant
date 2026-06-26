import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]


class StaticPagesPipelineTests(unittest.TestCase):
    def test_github_pages_broad_import_uses_seed_catalog(self) -> None:
        workflow = (ROOT / ".github" / "workflows" / "deploy_web.yml").read_text(
            encoding="utf-8",
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
        self.assertIn("--start-date 2026-06-01", workflow)
        self.assertIn("--progress-every 10", workflow)
        self.assertIn("--max-coverage-age-days 7", workflow)
        self.assertIn("--multi-etf-codes all-catalog", workflow)
        self.assertIn("fetch-depth: 0", workflow)

    def test_local_pages_build_broad_import_uses_seed_catalog(self) -> None:
        script = (ROOT / "scripts" / "00631l_build_pages_static.cmd").read_text(
            encoding="utf-8",
        )

        self.assertIn("--from-catalog", script)
        self.assertIn(
            "--catalog-path backend\\seeds\\twse_etf_catalog_seed.json",
            script,
        )
        self.assertIn("--limit 0", script)
        self.assertIn("--summary-only", script)
        self.assertIn("--progress-every 25", script)
        self.assertIn("scripts\\00631l_import_missing_etf_batch.cmd", script)
        self.assertIn("--limit 50", script)
        self.assertIn("--start-date 2026-06-01", script)
        self.assertIn("--progress-every 10", script)
        self.assertIn("--max-coverage-age-days 7", script)
        self.assertIn("--multi-etf-codes all-catalog", script)

    def test_broad_etf_price_seed_is_committed_for_pages_reproducibility(self) -> None:
        seed_dir = ROOT / "backend" / "seeds" / "etf_price_history_seed"
        seed_files = sorted(seed_dir.glob("*.jsonl"))

        self.assertGreaterEqual(len(seed_files), 200)
        self.assertTrue((seed_dir / "00631L.jsonl").exists())
        self.assertTrue((seed_dir / "0050.jsonl").exists())
        self.assertTrue((seed_dir / "00878.jsonl").exists())


if __name__ == "__main__":
    unittest.main()
