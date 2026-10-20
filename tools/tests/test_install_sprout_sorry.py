"""Tests for the Sprout Sorry character importer without third-party PNG data."""
from pathlib import Path
from tempfile import TemporaryDirectory
from zipfile import ZipFile
import sys
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from install_sprout_sorry import SOURCE_NAME, DESTINATION, get_sprite, install

PNG = (bytes((137, 80, 78, 71, 13, 10, 26, 10))
       + bytes((0, 0, 0, 13)) + b"IHDR"
       + (128).to_bytes(4, "big") + (96).to_bytes(4, "big")
       + bytes((8, 6, 0, 0, 0)))


class SproutSorryInstallerTest(unittest.TestCase):
    def setUp(self):
        self.tmp = TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        self.project = self.root / "project"
        self.project.mkdir()
        (self.project / "project.godot").write_text("config_version=5")
        self.zip = self.root / "sorry.zip"
        with ZipFile(self.zip, "w") as archive:
            archive.writestr(SOURCE_NAME, PNG)

    def test_install_dry_run_idempotent(self):
        destination = self.project / DESTINATION
        self.assertEqual(get_sprite(self.zip), PNG)
        install(self.zip, self.project, dry_run=True)
        self.assertFalse(destination.exists())
        install(self.zip, self.project)
        self.assertEqual(destination.read_bytes(), PNG)
        install(self.zip, self.project)
        self.assertEqual((self.project / "project.godot").read_text(), "config_version=5")

    def test_rejects_conflicts(self):
        destination = self.project / DESTINATION
        destination.parent.mkdir(parents=True)
        destination.write_bytes(b"custom")
        with self.assertRaises(ValueError):
            install(self.zip, self.project)
        self.assertEqual(destination.read_bytes(), b"custom")

    def test_rejects_wrong_dimensions(self):
        with ZipFile(self.zip, "w") as archive:
            archive.writestr(SOURCE_NAME, PNG[:16] + (64).to_bytes(4, "big") + PNG[20:])
        with self.assertRaises(ValueError):
            get_sprite(self.zip)


if __name__ == "__main__":
    unittest.main()
