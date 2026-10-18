import json
import os
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch
from PIL import Image, ImageDraw
from pipeline import *

def fixture(i=0):
    im=Image.new('RGBA',(64,64)); d=ImageDraw.Draw(im)
    d.rectangle((24,12,39,51),fill=(50,100,60,255)); d.rectangle((24+i,52,29+i,61),fill=(70,40,20,255)); d.rectangle((34-i,52,39-i,61),fill=(80,40,20,255))
    return im

class PipelineTests(unittest.TestCase):
    def test_transparency_and_dimensions(self):
        for size in SIZES:
            im=process(fixture(),size)
            self.assertEqual(im.size,(size,size)); self.assertEqual(set(im.getchannel('A').getdata()),{0,255})
    def test_background_preserves_enclosed_white(self):
        im=Image.new('RGB',(20,20),'white'); d=ImageDraw.Draw(im); d.rectangle((4,4,15,15),fill='black'); d.rectangle((7,7,12,12),fill='white')
        out=remove_background(im); self.assertEqual(out.getpixel((0,0))[3],0); self.assertEqual(out.getpixel((9,9))[3],255)
    def test_palette(self):
        palette=[[20,20,20],[90,120,80]]; im=process(fixture(),palette=palette)
        self.assertTrue(set(p[:3] for p in im.getdata() if p[3]).issubset(set(map(tuple,palette))))
    def test_duplicate_and_count_detection(self):
        v=validate_frames([fixture(),fixture()],8)
        self.assertFalse(v['structural_ok']); self.assertTrue(any('duplicados' in s for s in v['issues']))
    def test_anchor_alignment(self):
        a=fixture(); b=Image.new('RGBA',a.size); b.paste(a,(1,-1))
        aligned=align_frames([a,b],[(32,62),(33,61)])
        self.assertEqual(aligned[0].tobytes(),aligned[1].tobytes())
    def test_clipping_rejected(self):
        with self.assertRaises(ValueError): align_frames([fixture()],[(0,0)])
    def test_anchor_warning(self):
        a=fixture(); b=Image.new('RGBA',a.size); b.paste(a,(0,-5))
        self.assertTrue(any('Apoio' in s for s in validate_frames([a,b])['issues']))
    def test_pose_alternation(self):
        for direction in DIRECTIONS: self.assertEqual(validate_poses(pose_manifest(direction)),[])
        poses=pose_manifest('down'); poses[4]['left_stride']=1
        self.assertTrue(validate_poses(poses))
    def test_export_roundtrip(self):
        with tempfile.TemporaryDirectory() as d:
            frames=[fixture(i) for i in range(4)]; meta=export(frames,d,animation='idle')
            self.assertEqual(meta['frame_count'],4)
            with Image.open(Path(d)/'sheet.png') as sheet:
                self.assertEqual(sheet.size,(256,64))
                for i,im in enumerate(frames): self.assertEqual(sheet.crop((64*i,0,64*(i+1),64)).tobytes(),im.tobytes())
            with Image.open(Path(d)/'preview.png') as preview: self.assertEqual(preview.n_frames,4)
            self.assertEqual(len(list((Path(d)/'frames').glob('*.png'))),4)
            self.assertIn('texture_filter = 1',(Path(d)/'Preview.tscn').read_text())
    def test_api_contract(self):
        c=SDClient()
        with patch.object(c,'request',return_value={'images':[encode(fixture())],'info':'fixture'}) as req:
            im,info=c.generate('test',reference=fixture())
            self.assertEqual(req.call_args.args[0],'/sdapi/v1/img2img')
            payload=req.call_args.args[1]; self.assertEqual(payload['batch_size'],1); self.assertEqual(payload['width'],256)
            self.assertEqual(im.size,(64,64))
    def test_txt2img_contract(self):
        c=SDClient()
        with patch.object(c,'request',return_value={'images':[encode(fixture())]}) as req:
            c.generate('test'); self.assertEqual(req.call_args.args[0],'/sdapi/v1/txt2img')
    def test_invalid_generation(self):
        with self.assertRaises(ValueError): SDClient().generate('test',resolution=64)
    def test_health_contract(self):
        c=SDClient()
        with patch.object(c,'request',return_value={'sd_model_checkpoint':'fixture'}) as req:
            self.assertEqual(c.health()['sd_model_checkpoint'],'fixture'); req.assert_called_with('/sdapi/v1/options')

@unittest.skipUnless(os.getenv('PIXEL_LIVE_TEST')=='1','opt-in: PIXEL_LIVE_TEST=1 (usa GPU)')
class LiveTests(unittest.TestCase):
    def test_live_generation(self):
        c=SDClient(); self.assertTrue(c.health())
        im,_=c.generate('single green slime',steps=4); self.assertEqual(im.size,(256,256))
        im,_=c.generate('single green slime',reference=im,steps=4); self.assertEqual(im.size,(256,256))

if __name__=='__main__': unittest.main()
