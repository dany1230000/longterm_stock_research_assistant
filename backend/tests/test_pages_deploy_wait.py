import unittest

from backend.scripts.wait_pages_deploy_00631l import run_pages_deploy_wait


class PagesDeployWaitTests(unittest.TestCase):
    def test_pages_deploy_wait_passes_when_expected_commit_is_deployed(self) -> None:
        payload = run_pages_deploy_wait(
            expected_sha="abc123",
            interval_seconds=0,
            mode="github-api",
            checker=_checker([_sample("PASS", "completed", "success", "abc123fff")]),
        )

        self.assertEqual(payload["overallStatus"], "PASS")
        self.assertTrue(payload["summary"]["completedSuccessfully"])
        self.assertEqual(payload["failureCount"], 0)

    def test_pages_deploy_wait_warns_when_workflow_is_still_running(self) -> None:
        payload = run_pages_deploy_wait(
            expected_sha="abc123",
            attempts=1,
            interval_seconds=0,
            mode="github-api",
            checker=_checker([_sample("WARN", "in_progress", "", "abc123fff")]),
        )

        self.assertEqual(payload["overallStatus"], "WARN")
        self.assertFalse(payload["summary"]["completedSuccessfully"])
        self.assertGreater(payload["warningCount"], 0)
        self.assertEqual(payload["failureCount"], 0)

    def test_pages_deploy_wait_stops_after_second_successful_sample(self) -> None:
        calls = []

        def checker(**kwargs) -> dict:
            calls.append(kwargs)
            return (
                _sample("WARN", "in_progress", "", "abc123fff")
                if len(calls) == 1
                else _sample("PASS", "completed", "success", "abc123fff")
            )

        payload = run_pages_deploy_wait(
            expected_sha="abc123",
            attempts=5,
            interval_seconds=0,
            mode="github-api",
            checker=checker,
        )

        self.assertEqual(payload["overallStatus"], "PASS")
        self.assertEqual(payload["summary"]["sampleCount"], 2)
        self.assertEqual(len(calls), 2)

    def test_pages_deploy_wait_dry_run_is_pass(self) -> None:
        payload = run_pages_deploy_wait(expected_sha="abc123", dry_run=True)

        self.assertEqual(payload["overallStatus"], "PASS")
        self.assertTrue(payload["dryRun"])
        self.assertEqual(payload["mode"], "public-marker")

    def test_pages_deploy_wait_defaults_to_public_release_marker(self) -> None:
        payload = run_pages_deploy_wait(
            expected_sha="abc123",
            attempts=2,
            interval_seconds=0,
            public_checker=lambda **kwargs: _public_pages("abc123fff"),
        )

        self.assertEqual(payload["overallStatus"], "PASS")
        self.assertEqual(payload["mode"], "public-marker")
        self.assertTrue(payload["summary"]["matchedExpectedSha"])
        self.assertTrue(payload["summary"]["completedSuccessfully"])
        self.assertEqual(payload["summary"]["latestReleaseGitSha"], "abc123fff")


def _checker(samples: list[dict]):
    def checker(**kwargs) -> dict:
        del kwargs
        return samples.pop(0)

    return checker


def _sample(overall: str, run_status: str, conclusion: str, head_sha: str) -> dict:
    return {
        "overallStatus": overall,
        "summary": {
            "latestRunStatus": run_status,
            "latestRunConclusion": conclusion,
            "latestRunHeadSha": head_sha,
            "latestRunUrl": "https://github.com/example/actions/runs/1",
            "staticRowCount": 2835,
            "coverageStart": "2014-10-31",
            "coverageEnd": "2026-06-24",
        },
        "warnings": [] if overall == "PASS" else ["waiting"],
        "failures": [],
    }


def _public_pages(release_sha: str) -> dict:
    return {
        "overallStatus": "PASS",
        "rowCount": 2835,
        "coverageStart": "2014-10-31",
        "coverageEnd": "2026-06-24",
        "releaseTag": "00631l-lab-v9.45-pages-marker-first",
        "releaseGitSha": release_sha,
        "releaseAppVersion": "9.45-pages-marker-first",
        "warnings": [],
        "failures": [],
    }


if __name__ == "__main__":
    unittest.main()
