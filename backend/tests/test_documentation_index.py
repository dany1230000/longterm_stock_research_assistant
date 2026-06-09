import re
from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[2]


class DocumentationIndexTests(unittest.TestCase):
    def test_documentation_index_references_existing_local_files(self) -> None:
        index_path = ROOT / "docs" / "00631l_docs_index.md"
        text = index_path.read_text(encoding="utf-8")
        referenced = _local_paths_from_backticks(text)

        self.assertIn(Path("docs/00631l_daily_usage.md"), referenced)
        self.assertIn(Path("scripts/00631l_release_check.cmd"), referenced)

        missing = [
            path
            for path in sorted(referenced, key=lambda item: item.as_posix())
            if not (ROOT / path).exists()
        ]
        self.assertEqual(missing, [])


def _local_paths_from_backticks(text: str) -> set[Path]:
    paths: set[Path] = set()
    for raw in re.findall(r"`([^`]+)`", text):
        normalized = raw.split()[0].replace("\\", "/")
        if normalized.startswith(("docs/", "scripts/", "backend/")):
            paths.add(Path(normalized))
    return paths


if __name__ == "__main__":
    unittest.main()
