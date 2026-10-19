import json
import tempfile
import unittest
from pathlib import Path
from PIL import Image, ImageDraw
from catalog import AtlasIsolation
from pipeline import export
from repair_spacing import repair

class SpacingTests(unittest.TestCase):
    def test_repair_respects_production_lock(self):
        with tempfile.TemporaryDirectory() as tmp:
            lock=Path(tmp)/'production.lock';lock.write_text('running')
            with self.assertRaises(FileExistsError):repair(tmp,tmp)
            self.assertEqual(lock.read_text(),'running')

    def test_gutters_regions_and_timing(self):
        with tempfile.TemporaryDirectory() as tmp:
            frames=[Image.new('RGBA',(64,64),c) for c in ('red','blue')]
            meta=export(frames,tmp,durations=[2,3],fps=6,padding=8)
            sheet=Image.open(Path(tmp)/'sheet.png')
            self.assertEqual(sheet.size,(152,80))
            for i,frame in enumerate(frames):
                self.assertEqual(sheet.crop((8+72*i,8,72+72*i,72)).tobytes(),frame.tobytes())
            self.assertIsNone(sheet.crop((72,0,80,80)).getchannel('A').getbbox())
            self.assertEqual(meta['durations'],[2,3])
            self.assertIn('region = Rect2(80, 8, 64, 64)',(Path(tmp)/'frames.tres').read_text())

    def test_neighbor_removed_particle_and_margin_preserved(self):
        with tempfile.TemporaryDirectory() as tmp:
            atlas=Image.new('RGBA',(100,100));draw=ImageDraw.Draw(atlas)
            draw.rectangle((10,5,35,48),fill='red')
            draw.rectangle((10,55,35,90),fill='blue')
            draw.point((40,70),fill='white')
            atlas.save(Path(tmp)/'atlas.png')
            frame=dict(texture='atlas.png',region=[0,45,50,50],margin=[2,3,4,6])
            clean,mask,audit=AtlasIsolation(tmp).isolate(frame)
            self.assertEqual(clean.size,(54,56))
            self.assertEqual(clean.getpixel((12,3))[3],0)
            self.assertEqual(clean.getpixel((12,13)),(0,0,255,255))
            self.assertEqual(clean.getpixel((42,28)),(255,255,255,255))
            self.assertEqual(audit['removed_source_pixels'],104)
            self.assertEqual(audit['ambiguous_components'],[])

if __name__=='__main__':unittest.main()
