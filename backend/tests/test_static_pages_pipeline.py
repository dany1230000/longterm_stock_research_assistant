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
        self.assertIn("--multi-etf-codes all-local", workflow)

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
        self.assertIn("--multi-etf-codes all-local", script)


if __name__ == "__main__":
    unittest.main()
