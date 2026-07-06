import unittest
from pathlib import Path

from backend.scripts import run_00631l_daily_cycle


class DailyCycleRunnerTests(unittest.TestCase):
    def test_daily_cycle_runner_uses_python_entrypoints_without_cmd_wrapper(self) -> None:
        source = Path(run_00631l_daily_cycle.__file__).read_text(encoding="utf-8")

        self.assertIn("collect_00631l_snapshot.py", source)
        self.assertIn("export_00631l_history.py", source)
        self.assertIn("smoke_00631l_live.py", source)
        self.assertIn("check_00631l_data_integrity.py", source)
        self.assertNotIn('"cmd", "/c"', source)
        self.assertNotIn("00631l_daily_smoke.cmd", source)

    def test_subprocess_env_loads_backend_env_file_when_present(self) -> None:
        source = Path(run_00631l_daily_cycle.__file__).read_text(encoding="utf-8")

        self.assertIn("backend", source)
        self.assertIn(".env", source)
        self.assertIn("env=_subprocess_env()", source)


if __name__ == "__main__":
    unittest.main()
