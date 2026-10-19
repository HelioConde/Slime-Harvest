import json
import tempfile
import unittest
from pathlib import Path
from PIL import Image, ImageDraw
from catalog import definitions, inventory, load_frame, assert_sources
from pipeline import clean_frame, export, shared_palette
from production import run

def make_project(root):
    im=Image.new('RGBA',(128,64));d=ImageDraw.Draw(im)
    d.rectangle((20,10,40,58),fill=(60,110,70,255));d.rectangle((84,11,104,58),fill=(60,110,70,255));im.save(root/'atlas.png')
    text='[gd_resource type="SpriteFrames" format=3]\n[ext_resource type="Texture2D" path="res://atlas.png" id="a"]\n'
    for i in range(2):text+=f'[sub_resource type="AtlasTexture" id="f{i}"]\natlas = ExtResource("a")\nregion = Rect2({i*64}, 0, 64, 64)\n'
    frames=', '.join('{"duration": %s, "texture": SubResource("f%d")}'%(duration,i) for i,duration in [(0,1.5),(1,1),(0,1)])
    text+='[resource]\nanimations = [{"frames": ['+frames+'], "loop": true, "name": &"idle_down", "speed": 6.0}]'
    folder=root/'assets/Characters/animation';folder.mkdir(parents=True)
    for c in ('feminino','masculino'):(folder/f'player_{c}_frames.tres').write_text(text)

class CatalogTests(unittest.TestCase):
    def test_sd_partial_failure_resumes_without_regenerating_completed_frame(self):
        import hashlib
        class Client:
            def __init__(self):self.calls=0;self.fail=True
            def health(self):return {'sd_model_checkpoint':'fixture'}
            def request(self,path):return {'state':{'job_count':0}}
            def generate(self,**kwargs):
                self.calls+=1
                if self.calls==2 and self.fail:raise RuntimeError('simulated OOM')
                return kwargs['reference'].copy(),{'source':'test fixture'}
        with tempfile.TemporaryDirectory() as temp:
            project=Path(temp)/'project';project.mkdir();make_project(project);out=Path(temp)/'output'
            for p in (project/'assets/Characters/animation').glob('*.tres'):
                p.write_text(p.read_text().replace('idle_down','hoe_down'))
            snap=inventory(project);seq=snap['feminino']['sequences']['hoe_down']
            review=Path(temp)/'review.json';review.write_text(json.dumps({'feminino':{'hoe_down':dict(sequence_hash=hashlib.sha256(json.dumps(seq,sort_keys=True).encode()).hexdigest(),source_hashes=snap['feminino']['source_hashes'],frames=[0,1,2],reviewer='test',checks=['biomechanics','silhouette','tool_or_object','complete_motion'])}}))
            client=Client()
            with self.assertRaisesRegex(RuntimeError,'OOM'):run(project,out,'feminino',['hoe'],2,True,review,client)
            self.assertFalse((out/'production.lock').exists())
            state=json.loads((out/'feminino/hoe_down/sd/state.json').read_text());self.assertEqual(state['done'],[0])
            client.fail=False
            result=run(project,out,'feminino',['hoe'],2,True,review,client)
            self.assertEqual(result['processed'],2);self.assertEqual(client.calls,4)
            catalog=json.loads((out/'catalog.json').read_text())
            next(a for a in catalog['actions'] if a['id']=='hoe')['prompt']='changed prompt'
            (out/'catalog.json').write_text(json.dumps(catalog))
            with self.assertRaisesRegex(ValueError,'Profile changed'):run(project,out,'feminino',['hoe'],2,True,review,client)

    def test_complete_catalog_without_fake_secondary_counts(self):
        actions=definitions()['actions'];self.assertEqual(len(actions),44);self.assertEqual(len({a['id'] for a in actions}),44)
        self.assertTrue(all(a['planned_frames'] is None for a in actions if a['priority']>=2))
        self.assertTrue(all(not e['validated'] and e['frame'] is None for a in actions for e in a['events']))

    def test_real_timeline_and_resumable_color_only_preservation(self):
        with tempfile.TemporaryDirectory() as temp:
            project=Path(temp)/'project';project.mkdir();make_project(project);output=Path(temp)/'output'
            snap=inventory(project);seq=snap['feminino']['sequences']['idle_down']
            self.assertEqual([f['resource_id'] for f in seq['frames']],['f0','f1','f0'])
            first=run(project,output,'feminino',['idle'],limit=2)
            self.assertEqual(first['processed'],2);self.assertFalse((output/'feminino/idle_down/clean/export').exists())
            second=run(project,output,'feminino',['idle'],limit=2);self.assertEqual(second['processed'],1)
            meta=json.loads((output/'feminino/idle_down/clean/export/metadata.json').read_text())
            self.assertEqual(meta['durations'],[1.5,1.0,1.0]);self.assertEqual(meta['fps'],6)
            self.assertTrue(meta['validation']['source_silhouettes_preserved']);self.assertFalse(meta['validation']['visual_approved'])
            self.assertTrue(meta['validation']['structural_ok']);self.assertEqual(run(project,output,'feminino',['idle'],2)['processed'],0)
            self.assertEqual(run(project,output,'masculino',['idle'],2)['processed'],2)
            assert_sources(project,snap)

    def test_preservation_gate_and_changed_source(self):
        with tempfile.TemporaryDirectory() as temp:
            project=Path(temp)/'project';project.mkdir();make_project(project);out=Path(temp)/'output'
            with self.assertRaisesRegex(ValueError,'P0 is locked'):run(project,out,'feminino',['walk'],sd=True)
            im=Image.open(project/'atlas.png');im.putpixel((0,0),(1,2,3,255));im.save(project/'atlas.png')
            with self.assertRaisesRegex(ValueError,'Source changed'):run(project,out,'feminino',['idle'])
            self.assertFalse((out/'production.lock').exists())

    def test_single_worker_lock_does_not_remove_foreign_lock(self):
        with tempfile.TemporaryDirectory() as temp:
            out=Path(temp);(out/'production.lock').write_text('123')
            with self.assertRaises(FileExistsError):run(out,out,'feminino',['idle'])
            self.assertTrue((out/'production.lock').exists())

    def test_cleaner_preserves_alpha_and_high_contrast_eye(self):
        im=Image.new('RGBA',(64,64));d=ImageDraw.Draw(im);d.rectangle((10,10,53,58),fill=(100,100,100,255))
        im.putpixel((25,25),(108,108,108,255));im.putpixel((30,25),(0,0,0,255))
        result,stats=clean_frame(im,[[100,100,100],[108,108,108],[0,0,0]])
        self.assertEqual(result.getchannel('A').tobytes(),im.getchannel('A').tobytes())
        self.assertEqual(result.getpixel((25,25)),(100,100,100,255));self.assertEqual(result.getpixel((30,25)),(0,0,0,255));self.assertEqual(stats['recolored_pixels'],1)

    def test_p0_fragment_cleanup_does_not_move_body_or_remove_side_effects(self):
        im=Image.new('RGBA',(64,64));d=ImageDraw.Draw(im)
        d.rectangle((20,10,43,58),fill=(100,100,100,255));d.rectangle((25,1,30,2),fill=(100,100,100,255));d.rectangle((50,30,51,31),fill=(100,100,100,255))
        result,stats=clean_frame(im,[[100,100,100],[0,0,0]],remove_top_fragments=True)
        self.assertEqual(result.getpixel((25,1))[3],0)
        self.assertEqual(result.crop((20,10,44,59)).tobytes(),im.crop((20,10,44,59)).tobytes())
        self.assertEqual(result.getpixel((50,30))[3],255)
        self.assertEqual(len(stats['removed_fragment_pixels']),12)

    def test_non_looping_export_and_variable_timing(self):
        with tempfile.TemporaryDirectory() as temp:
            im=Image.new('RGBA',(64,64));ImageDraw.Draw(im).rectangle((10,10,20,58),fill='red')
            export([im,im],temp,animation='pickup_slime',fps=7,durations=[1,2],origin=[30,61],allow_repeated_frames=True)
            text=(Path(temp)/'frames.tres').read_text();self.assertIn('"loop": false',text);self.assertIn('"duration": 2',text)
            self.assertIn('offset = Vector2(-30, -61)',(Path(temp)/'Preview.tscn').read_text())

if __name__=='__main__':unittest.main()
