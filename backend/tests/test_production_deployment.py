import unittest

from backend.scripts.backend_prod_check_00631l import run_backend_prod_check


class ProductionDeploymentTests(unittest.TestCase):
    def test_backend_prod_check_contract_has_no_failures(self) -> None:
        payload = run_backend_prod_check()

        self.assertEqual(payload["sourceContract"], "00631l_backend_prod_check")
        self.assertIn(payload["overallStatus"], {"PASS", "WARN"})
        self.assertEqual(payload["failures"], [])
        names = {check["name"] for check in payload["checks"]}
        self.assertIn("backend/Dockerfile", names)
        self.assertIn("deploy/docker-compose.yml", names)
        self.assertIn("env_template", names)
        self.assertIn("readiness_endpoint_contract", names)


if __name__ == "__main__":
    unittest.main()
