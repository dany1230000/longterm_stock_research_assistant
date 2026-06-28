import unittest
import io
import urllib.error
import warnings

from backend.scripts.check_pages_deploy_status_00631l import (
    run_pages_deploy_status_check,
)


class PagesDeployStatusTests(unittest.TestCase):
    def test_pages_deploy_status_passes_for_successful_workflow_and_static_data(self) -> None:
        payload = run_pages_deploy_status_check(
            expected_sha="abc123",
            fetch_json=_fetch_success,
            public_pages_payload=_public_pages_payload("PASS"),
        )

        self.assertEqual(payload["overallStatus"], "PASS")
        self.assertEqual(payload["failureCount"], 0)
        self.assertEqual(payload["summary"]["latestRunConclusion"], "success")
        self.assertEqual(payload["summary"]["staticRowCount"], 2835)

    def test_pages_deploy_status_warns_for_workflow_failure_by_default(self) -> None:
        payload = run_pages_deploy_status_check(
            expected_sha="abc123",
            fetch_json=_fetch_failed_workflow,
            public_pages_payload=_public_pages_payload("PASS"),
        )

        self.assertEqual(payload["overallStatus"], "WARN")
        self.assertEqual(payload["failureCount"], 0)
        self.assertGreater(payload["warningCount"], 0)

    def test_pages_deploy_status_passes_when_public_release_matches_expected_sha(self) -> None:
        payload = run_pages_deploy_status_check(
            expected_sha="abc123",
            fetch_json=_fetch_cancelled_workflow,
            public_pages_payload=_public_pages_payload(
                "PASS",
                release_git_sha="abc123ff",
                release_tag="00631l-lab-v6.19-pages-deploy-status-alignment",
            ),
        )

        self.assertEqual(payload["overallStatus"], "PASS")
        self.assertEqual(payload["failureCount"], 0)
        self.assertEqual(payload["warningCount"], 0)
        self.assertEqual(payload["summary"]["publicReleaseGitSha"], "abc123ff")
        workflow = next(
            check for check in payload["checks"] if check["name"] == "workflow_runs"
        )
        self.assertIn("public release marker matches expected HEAD", workflow["message"])

    def test_pages_deploy_status_fails_for_workflow_failure_when_strict(self) -> None:
        payload = run_pages_deploy_status_check(
            expected_sha="abc123",
            fetch_json=_fetch_failed_workflow,
            public_pages_payload=_public_pages_payload("PASS"),
            strict_workflow=True,
        )

        self.assertEqual(payload["overallStatus"], "FAIL")
        self.assertGreater(payload["failureCount"], 0)

    def test_pages_deploy_status_warns_when_github_api_unavailable(self) -> None:
        def fetcher(url: str, timeout: float) -> dict:
            del url, timeout
            raise OSError("offline")

        payload = run_pages_deploy_status_check(
            fetch_json=fetcher,
            public_pages_payload=_public_pages_payload("PASS"),
        )

        self.assertEqual(payload["overallStatus"], "WARN")
        self.assertEqual(payload["failureCount"], 0)
        self.assertGreater(payload["warningCount"], 0)

    def test_pages_settings_404_is_ok_when_workflow_and_public_pages_pass(self) -> None:
        def fetcher(url: str, timeout: float) -> dict:
            del timeout
            if url.endswith("/pages"):
                raise urllib.error.HTTPError(url, 404, "Not Found", None, io.BytesIO(b""))
            return {
                "workflow_runs": [
                    {
                        "status": "completed",
                        "conclusion": "success",
                        "head_sha": "abc123ff",
                        "html_url": "https://github.com/example/actions/runs/3",
                    }
                ]
            }

        with warnings.catch_warnings():
            warnings.simplefilter("ignore", ResourceWarning)
            payload = run_pages_deploy_status_check(
                expected_sha="abc123",
                fetch_json=fetcher,
                public_pages_payload=_public_pages_payload("PASS"),
            )

        self.assertEqual(payload["overallStatus"], "PASS")
        self.assertEqual(payload["warningCount"], 0)


def _fetch_success(url: str, timeout: float) -> dict:
    del timeout
    if url.endswith("/pages"):
        return {"html_url": "https://dany1230000.github.io/longterm_stock_research_assistant/", "status": "built"}
    return {
        "workflow_runs": [
            {
                "status": "completed",
                "conclusion": "success",
                "head_sha": "abc123ff",
                "html_url": "https://github.com/example/actions/runs/1",
            }
        ]
    }


def _fetch_failed_workflow(url: str, timeout: float) -> dict:
    del timeout
    if url.endswith("/pages"):
        return {"html_url": "https://dany1230000.github.io/longterm_stock_research_assistant/", "status": "built"}
    return {
        "workflow_runs": [
            {
                "status": "completed",
                "conclusion": "failure",
                "head_sha": "abc123ff",
                "html_url": "https://github.com/example/actions/runs/2",
            }
        ]
    }


def _fetch_cancelled_workflow(url: str, timeout: float) -> dict:
    del timeout
    if url.endswith("/pages"):
        return {"html_url": "https://dany1230000.github.io/longterm_stock_research_assistant/", "status": "built"}
    return {
        "workflow_runs": [
            {
                "status": "completed",
                "conclusion": "cancelled",
                "head_sha": "old456ff",
                "html_url": "https://github.com/example/actions/runs/4",
            }
        ]
    }


def _public_pages_payload(
    status: str,
    *,
    release_git_sha: str = "",
    release_tag: str = "",
) -> dict:
    return {
        "overallStatus": status,
        "rowCount": 2835,
        "coverageStart": "2014-10-31",
        "coverageEnd": "2026-06-24",
        "rootUrl": "https://dany1230000.github.io/longterm_stock_research_assistant/",
        "releaseGitSha": release_git_sha,
        "releaseTag": release_tag,
        "warnings": [] if status == "PASS" else ["temporary"],
        "failures": [],
    }


if __name__ == "__main__":
    unittest.main()
