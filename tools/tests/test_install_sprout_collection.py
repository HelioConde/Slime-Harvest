"""Regressao offline: protege saves, paths, packs, addons e licencas."""
import tempfile
import unittest
from pathlib import Path
from zipfile import ZipFile
import sys

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from install_sprout_ui import UI_FILES, ORIGINAL_TEXTURE_PATH, THEME_SUFFIX
from install_sprout_collection import install, plan, _safe_relative

PNG = bytes((137, 80, 78, 71, 13, 10, 26, 10)) + b"test"


class SproutCollectionTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.project = Path(self.tmp.name) / "game"
        self.project.mkdir()
        (self.project / "project.godot").write_text("config_version=5")
        (self.project / "save.json").write_text("nao alterar")
        root = Path(self.tmp.name)
        self.ui = root / "ui.zip"
        self.sprites = root / "sprites.zip"
        self.ui_addon = root / "ui_addon.zip"
        self.tilemap = root / "tilemap_addon.zip"

        with ZipFile(self.ui, "w") as z:
            for path in UI_FILES:
                z.writestr("Sprout Lands - UI Pack - Basic pack/" + path, PNG)
            z.writestr("Sprout Lands - UI Pack - Basic pack/fonts/ui.ttf", b"font")
        with ZipFile(self.sprites, "w") as z:
            for i in range(5):
                z.writestr(
                    "Sprout Lands - Sprites - Basic pack/Objects/sample_%d.png" % i,
                    PNG,
                )
        with ZipFile(self.ui_addon, "w") as z:
            base = "Sprout-Lands-UI-0.2.0/addons/sprout_lands_ui/"
            z.writestr(base + THEME_SUFFIX.split("addons/sprout_lands_ui/")[1],
                       '[gd_resource type="Theme" uid="uid://aabb"]\n'
                       '[ext_resource type="Texture2D" uid="uid://ccdd" path="'
                       + ORIGINAL_TEXTURE_PATH + '" id="1"]')
            for i in range(5):
                z.writestr(base + f"f_{i}.gd", "@tool\nextends EditorPlugin")
            z.writestr(base + "plugin.cfg", "[plugin]")
        with ZipFile(self.tilemap, "w") as z:
            base = "Sprout-Lands-Tilemap-0.2.0/addons/sprout_lands_tilemap/"
            for i in range(5):
                z.writestr(base + f"f_{i}.gd", "@tool\nextends EditorPlugin")
            z.writestr(base + "plugin.cfg", "[plugin]")
            z.writestr(base + "examples/scene.tscn",
                       '[gd_scene uid="uid://abc"]\n[node name="Map" type="Node2D"]')
            z.writestr(base + "assets/test.png.import", b"ignore-import")
        self.zips = (self.ui, self.sprites, self.ui_addon, self.tilemap, self.project)

    def test_installs_all_without_modifying_project_or_saves(self):
        files = plan(*self.zips)
        self.assertGreater(len(files), 20)
        created, same = install(files)
        self.assertEqual(created, len(files))
        self.assertEqual(same, 0)
        self.assertEqual((self.project / "save.json").read_text(), "nao alterar")
        self.assertEqual((self.project / "project.godot").read_text(), "config_version=5")
        self.assertTrue((self.project / "assets/sprout_lands/sprites/Objects/sample_0.png").exists())
        self.assertTrue((self.project / "assets/sprout_lands/ui_pack/fonts/ui.ttf").exists())
        self.assertTrue((self.project / "addons/sprout_lands_tilemap/plugin.cfg").exists())
        scene = (self.project / "addons/sprout_lands_tilemap/examples/scene.tscn").read_text()
        self.assertNotIn('uid="uid://', scene)
        self.assertFalse((self.project / "addons/sprout_lands_tilemap/assets/test.png.import").exists())
        self.assertEqual(install(files), (0, len(files)))

    def test_dry_run_and_conflict_are_safe(self):
        files = plan(*self.zips)
        install(files, dry_run=True)
        self.assertFalse((self.project / "assets").exists())
        path = self.project / "assets/sprout_lands/sprites/Objects/sample_0.png"
        path.parent.mkdir(parents=True)
        path.write_bytes(b"personalizado")
        with self.assertRaises(ValueError):
            install(files)
        self.assertEqual(path.read_bytes(), b"personalizado")
        self.assertFalse((self.project / "addons").exists())

    def test_rejects_zip_path_traversal(self):
        for path in ("../secret.png", "/etc/file", r"..\secret.txt", "folder/../file"):
            with self.assertRaises(ValueError):
                _safe_relative(path)


if __name__ == "__main__":
    unittest.main()
