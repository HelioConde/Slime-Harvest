import tempfile
import threading
import time
import unittest
from pathlib import Path
from app import Jobs
from pipeline import encode, atomic_json
from test_pipeline import fixture

class FakeClient:
    def __init__(self, fail=False): self.calls=0; self.fail=fail
    def health(self): return {'sd_model_checkpoint':'fixture'}
    def generate(self,**args):
        self.calls+=1
        if self.fail: raise RuntimeError('out of memory fixture')
        return args.get('reference') or fixture(),{'seconds':0,'endpoint':'fixture'}

def wait(jobs):
    end=time.monotonic()+5
    while jobs.queue.unfinished_tasks and time.monotonic()<end: time.sleep(.01)
    if jobs.queue.unfinished_tasks: raise AssertionError('Fila travada')

class JobTests(unittest.TestCase):
    def test_local_job_and_restart(self):
        with tempfile.TemporaryDirectory() as d:
            q=Jobs(d,FakeClient()); j=q.submit({'mode':'process','count':4,'images':[encode(fixture(i)) for i in range(4)]})
            wait(q); self.assertEqual(j['status'],'review')
            loaded=Jobs(d,FakeClient()); self.assertEqual(loaded.jobs[j['id']]['done'],4)
    def test_cache_exact_input(self):
        with tempfile.TemporaryDirectory() as d:
            client=FakeClient(); q=Jobs(d,client)
            for _ in range(2):
                q.submit({'mode':'img2img','count':1,'images':[encode(fixture())]}); wait(q)
            self.assertEqual(client.calls,1)
            q.submit({'mode':'img2img','count':1,'images':[encode(fixture(1))]}); wait(q)
            self.assertEqual(client.calls,2)
    def test_error_pauses_and_cancel_preserves(self):
        with tempfile.TemporaryDirectory() as d:
            q=Jobs(d,FakeClient(fail=True)); j=q.submit({'mode':'txt2img','count':1}); wait(q)
            self.assertEqual(j['status'],'error'); self.assertTrue(q.paused.is_set())
            k=q.submit({'mode':'process','count':1,'images':[encode(fixture())]}); q.cancel(k['id']); wait(q)
            self.assertEqual(k['status'],'cancelled'); self.assertTrue((Path(d)/k['id']/'input/000.png').exists())
    def test_interrupted_record(self):
        with tempfile.TemporaryDirectory() as d:
            atomic_json(Path(d)/'abcd/job.json',{'id':'abcd','status':'running'})
            q=Jobs(d,FakeClient()); self.assertEqual(q.jobs['abcd']['status'],'interrupted')
    def test_missing_pose_references_rejected(self):
        with tempfile.TemporaryDirectory() as d:
            q=Jobs(d,FakeClient())
            with self.assertRaises(ValueError): q.submit({'mode':'img2img','count':8,'images':[encode(fixture())]})
            with self.assertRaises(ValueError): q.submit({'mode':'txt2img','count':8})
    def test_review_requires_all_frames_and_criteria(self):
        with tempfile.TemporaryDirectory() as d:
            q=Jobs(d,FakeClient()); j=q.submit({'mode':'process','count':4,'base_approved':True,'images':[encode(fixture(i)) for i in range(4)]})
            wait(q)
            with self.assertRaises(ValueError): q.review(j['id'],{'reviewer':'Teste'})
            q.review(j['id'],{'reviewer':'Teste','frames':list(range(4)),'checks':j['validation']['visual_review_required']})
            self.assertEqual(j['status'],'approved')

if __name__=='__main__': unittest.main()
