import io
import tempfile
import unittest
from pathlib import Path
from zipfile import ZipFile
import sys

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from install_all_art_packs import safe_path, strip_root, plan_extra, install


class AllPacksInstallerTest(unittest.TestCase):
    def test_sanitizes_paths(self):
        for candidate in ("../file.png", r"test\bad.png", "/root/file", "a/../b.png", "C:/test"):
            with self.assertRaises(ValueError):
                safe_path(candidate)

    def test_root_folder_detection(self):
        self.assertTrue(strip_root(["download/A.png", "download/sub/B.png"]))
        self.assertFalse(strip_root(["assets/A.png", "info/LICENSE.txt"]))

    def test_imports_nested_free_packs_without_conflicts(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            project = root / "project"
            project.mkdir()
            (project / "project.godot").write_text("config_version=5")
            pack = root / "animal.zip"
            with ZipFile(pack, "w") as z:
                z.writestr("Original Pack/Farm Animals/chicken.png", b"PNG-placeholder")
                z.writestr("Original Pack/README.md", b"license text")
                z.writestr("Original Pack/.DS_Store", b"skip")
            result = plan_extra(pack, "tiny_animals", project)
            self.assertEqual(len(result), 2)
            self.assertTrue(any(p.as_posix().endswith("/tiny_animals/Farm Animals/chicken.png") for p in result))
            self.assertEqual(install(result, dry_run=True), (2, 0))
            self.assertFalse((project / "assets").exists())
            self.assertEqual(install(result), (2, 0))
            self.assertEqual(install(result), (0, 2))
            target = next(p for p in result if p.suffix == ".png")
            target.write_bytes(b"personal")
            with self.assertRaises(ValueError):
                install(result)
            self.assertEqual(target.read_bytes(), b"personal")

    def test_premium_preview_is_not_imported(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            pack = root / "ranch.zip"
            with ZipFile(pack, "w") as z:
                z.writestr("assets/crops/carrot.png", b"free")
                z.writestr("assets_premium_preview/bunny.png", b"premium")
                z.writestr("info/License_SuperRetroRanch_FreeTier.txt", b"license")
            result = plan_extra(pack, "ranch", root)
            self.assertEqual(len(result), 2)
            self.assertFalse(any("premium" in str(p).lower() for p in result))


if __name__ == "__main__":
    unittest.main()
