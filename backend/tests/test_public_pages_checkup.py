import unittest

from backend.scripts.public_pages_checkup_00631l import build_public_pages_checkup


class PublicPagesCheckupTests(unittest.TestCase):
    def test_public_pages_checkup_passes_when_smoke_and_deploy_status_pass(self) -> None:
        payload = build_public_pages_checkup(
            public_pages=_public_pages("PASS"),
            deploy_status=_deploy_status("PASS", "completed", "success", "abc123fff"),
            expected_sha="abc123",
        )

        self.assertEqual(payload["overallStatus"], "PASS")
        self.assertEqual(payload["failureCount"], 0)
        self.assertEqual(payload["summary"]["staticRowCount"], 2835)
        self.assertEqual(payload["summary"]["githubApiMode"], "checked")

    def test_public_pages_checkup_skips_workflow_warnings_in_public_only_mode(self) -> None:
        payload = build_public_pages_checkup(
            public_pages=_public_pages("PASS"),
            deploy_status=_deploy_status("PASS", "", "", ""),
            expected_sha="abc123",
            github_api_mode="skipped",
        )

        self.assertEqual(payload["overallStatus"], "PASS")
        self.assertEqual(payload["summary"]["githubApiMode"], "skipped")
        self.assertEqual(payload["summary"]["latestRunStatus"], "skipped")
        self.assertEqual(payload["summary"]["latestRunConclusion"], "skipped")
        self.assertEqual(payload["warnings"], [])

    def test_public_pages_checkup_warns_when_workflow_is_not_complete(self) -> None:
        payload = build_public_pages_checkup(
            public_pages=_public_pages("PASS"),
            deploy_status=_deploy_status("WARN", "in_progress", "", "abc123fff"),
            expected_sha="abc123",
        )

        self.assertEqual(payload["overallStatus"], "WARN")
        self.assertEqual(payload["failureCount"], 0)
        self.assertGreater(payload["warningCount"], 0)
        self.assertTrue(payload["actionItems"])

    def test_public_pages_checkup_fails_when_public_smoke_fails(self) -> None:
        payload = build_public_pages_checkup(
            public_pages=_public_pages("FAIL"),
            deploy_status=_deploy_status("PASS", "completed", "success", "abc123fff"),
            expected_sha="abc123",
        )

        self.assertEqual(payload["overallStatus"], "FAIL")
        self.assertGreater(payload["failureCount"], 0)

    def test_public_pages_checkup_adds_public_only_action_when_github_api_is_limited(self) -> None:
        payload = build_public_pages_checkup(
            public_pages=_public_pages("PASS"),
            deploy_status={
                "overallStatus": "WARN",
                "summary": {
                    "latestRunStatus": "",
                    "latestRunConclusion": "",
                    "latestRunHeadSha": "",
                },
                "warnings": [
                    "workflow_runs: https://api.github.com unavailable: HTTP 403 rate limit exceeded"
                ],
                "failures": [],
            },
            expected_sha="abc123",
        )

        self.assertEqual(payload["overallStatus"], "WARN")
        self.assertTrue(
            any("--skip-github-api" in item for item in payload["actionItems"])
        )


def _public_pages(status: str) -> dict:
    return {
        "overallStatus": status,
        "rootUrl": "https://dany1230000.github.io/longterm_stock_research_assistant/",
        "hashUrl": "https://dany1230000.github.io/longterm_stock_research_assistant/#/00631l-lab",
        "staticBaseUrl": "https://dany1230000.github.io/longterm_stock_research_assistant/00631l-static-data/",
        "rowCount": 2835,
        "coverageStart": "2014-10-31",
        "coverageEnd": "2026-06-24",
        "warnings": [] if status == "PASS" else ["temporary"],
        "failures": [] if status != "FAIL" else ["static payload invalid"],
    }


def _deploy_status(status: str, run_status: str, conclusion: str, head_sha: str) -> dict:
    return {
        "overallStatus": status,
        "summary": {
            "latestRunStatus": run_status,
            "latestRunConclusion": conclusion,
            "latestRunHeadSha": head_sha,
            "latestRunUrl": "https://github.com/example/actions/runs/1",
        },
        "warnings": [] if status == "PASS" else ["workflow waiting"],
        "failures": [] if status != "FAIL" else ["workflow failed"],
    }


if __name__ == "__main__":
    unittest.main()
