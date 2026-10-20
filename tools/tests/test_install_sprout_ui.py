"""Regressao do instalador da arte UI Sprout Lands (sem dependencias externas)."""
import tempfile
import unittest
from pathlib import Path
from zipfile import ZipFile
import sys

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from install_sprout_ui import (
    UI_FILES, THEME_SUFFIX, ORIGINAL_TEXTURE_PATH, NEW_TEXTURE_PATH,
    install, plan,
)


class SproutUIInstallerTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.project = self.root / "game"
        self.project.mkdir()
        (self.project / "project.godot").write_text("config_version=5\n")
        self.ui_zip = self.root / "art.zip"
        with ZipFile(self.ui_zip, "w") as zipped:
            for internal_path in UI_FILES:
                zipped.writestr("UI Pack/" + internal_path, bytes((137, 80, 78, 71, 13, 10, 26, 10)) + b"test")
        self.theme_zip = self.root / "theme.zip"
        with ZipFile(self.theme_zip, "w") as zipped:
            zipped.writestr(
                "Sprout-Lands-UI-0.2.0/" + THEME_SUFFIX,
                '[gd_resource type="Theme" uid="uid://aabbcc"]\n'
                '[ext_resource type="Texture2D" uid="uid://ddeeff" path="'
                + ORIGINAL_TEXTURE_PATH + '" id="1"]\n',
            )

    def test_installs_assets_and_patched_theme(self):
        files = plan(self.ui_zip, self.theme_zip, self.project)
        self.assertEqual(len(files), len(UI_FILES) + 1)
        install(files)
        theme_text = (self.project / "assets/ui/sprout_lands/sprout_theme.tres").read_text()
        self.assertIn(NEW_TEXTURE_PATH, theme_text)
        self.assertNotIn("uid://", theme_text)
        self.assertEqual((self.project / "assets/ui/sprout_lands/ui_atlas.png").read_bytes()[:8],
                         bytes((137, 80, 78, 71, 13, 10, 26, 10)))
        install(files)  # Idempotente

    def test_conflicts_fail_without_writing(self):
        files = plan(self.ui_zip, self.theme_zip, self.project)
        destination = self.project / "assets/ui/sprout_lands/ui_atlas.png"
        destination.parent.mkdir(parents=True)
        destination.write_bytes(b"custom")
        with self.assertRaises(ValueError):
            install(files)
        self.assertEqual(destination.read_bytes(), b"custom")
        self.assertFalse((self.project / "assets/ui/sprout_lands/sprout_theme.tres").exists())

    def test_dry_run_writes_nothing(self):
        files = plan(self.ui_zip, self.theme_zip, self.project)
        install(files, dry_run=True)
        self.assertFalse((self.project / "assets/ui/sprout_lands").exists())


if __name__ == "__main__":
    unittest.main()
