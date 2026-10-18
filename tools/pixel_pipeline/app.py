"""Loopback UI, bounded requests and a single persistent generation worker."""
import argparse
import hashlib
import json
import queue
import threading
import time
import uuid
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import unquote, urlparse
from PIL import Image
from pipeline import SDClient, decode, process, shared_palette, align_frames, export, save_png, atomic_json, pose_manifest, ANIMATIONS, DIRECTIONS, constrain_mask, protect_contour

ROOT=Path(__file__).resolve().parent

class Jobs:
    def __init__(self, root, client=None):
        self.root=Path(root); self.root.mkdir(parents=True,exist_ok=True)
        self.client=client or SDClient(); self.queue=queue.Queue(); self.jobs={}; self.lock=threading.RLock()
        self.paused=threading.Event()
        for p in self.root.glob('*/job.json'):
            try:
                j=json.loads(p.read_text(encoding='utf-8'))
                if j['status'] in ('queued','running'): j.update(status='interrupted',error='Servidor reiniciado; arquivos parciais preservados.'); atomic_json(p,j)
                self.jobs[j['id']]=j
            except (ValueError,KeyError): pass
        threading.Thread(target=self.work,daemon=True).start()

    def update(self,j,**values):
        with self.lock:
            j.update(values); atomic_json(self.root/j['id']/'job.json',j)

    def submit(self, p):
        mode=p.get('mode','process')
        p['mode']=mode
        if mode not in ('process','txt2img','img2img'): raise ValueError('Modo inválido.')
        size=int(p.get('size',64)); fps=int(p.get('fps',8)); count=int(p.get('count',1))
        if size not in (32,48,64,96,128) or not 1<=fps<=60 or not 1<=count<=32: raise ValueError('Resolução, FPS ou quantidade inválidos.')
        if p.get('animation','idle') not in ANIMATIONS or p.get('direction','down') not in DIRECTIONS: raise ValueError('Animação/direção inválida.')
        if not 2<=int(p.get('colors',24))<=256 or not 0<=int(p.get('tolerance',24))<=255: raise ValueError('Cores/tolerância inválidas.')
        if mode!='process' and (int(p.get('resolution',256)) not in (256,384,512) or not .1<=float(p.get('denoise',.3))<=.4 or not 1<=int(p.get('steps',16))<=40 or not 0<=int(p.get('seed',1234))<2**32): raise ValueError('Parâmetros de geração inválidos.')
        refs=p.pop('images',[])
        if len(refs)>32: raise ValueError('Máximo de 32 imagens.')
        images=[decode(s) for s in refs]
        if mode in ('process','img2img') and len(images)!=count: raise ValueError('Envie uma referência já posada para cada quadro; para corrigir um quadro, use quantidade 1.')
        if mode=='txt2img' and count!=1: raise ValueError('txt2img cria apenas a base. Animações exigem referências por quadro.')
        palette=p.get('palette')
        if palette is not None and not isinstance(palette,list): raise ValueError('Paleta deve ser uma lista RGB.')
        if palette is not None: process(Image.new('RGBA',(1,1)),palette=palette)
        anchors=p.get('anchors')
        if anchors is not None and (len(anchors)!=count or any(len(a)!=2 or any(not isinstance(v,(int,float)) or not 0<=v<=size for v in a) for a in anchors)): raise ValueError('Informe uma origem [x,y] válida por quadro.')
        ident=uuid.uuid4().hex[:12]; folder=self.root/ident
        folder.mkdir()
        for i,im in enumerate(images): save_png(im,folder/f'input/{i:03}.png')
        j=dict(id=ident,status='queued',done=0,count=count,created=time.time(),config=p,cancel=False)
        with self.lock: self.jobs[ident]=j
        self.update(j); self.queue.put(j)
        return j

    def cancel(self, ident):
        with self.lock:
            j=self.jobs[ident]
            if j['status'] in ('queued','running'): self.update(j,cancel=True)
            return dict(j)

    def review(self, ident, review):
        with self.lock:
            j=self.jobs[ident]
            if j['status'] not in ('review','approved'): raise ValueError('A geração ainda não está disponível para revisão.')
            path=self.root/ident/'export/metadata.json'
            meta=json.loads(path.read_text(encoding='utf-8'))
            if not meta['provenance'].get('base_approved'): raise ValueError('A referência visual precisa de aprovação explícita.')
            required=meta['validation']['visual_review_required']
            if not meta['validation']['structural_ok']: raise ValueError('Corrija os problemas estruturais antes de aprovar.')
            if set(review.get('checks',[]))!=set(required) or review.get('frames')!=list(range(j['count'])) or not review.get('reviewer','').strip():
                raise ValueError('Identifique o revisor e confira todos os quadros e critérios.')
            meta['human_review']=dict(review,at=time.time()); meta['validation']['status']='approved'
            atomic_json(path,meta); self.update(j,status='approved',validation=meta['validation'])
            return dict(j)

    def work(self):
        while True:
            j=self.queue.get()
            try:
                while self.paused.is_set() and not j['cancel']: time.sleep(.2)
                if j['cancel']: self.update(j,status='cancelled'); continue
                self.update(j,status='running')
                p=j['config']; folder=self.root/j['id']; raw=[]; history=[]
                options=self.client.health() if p['mode']!='process' else {}
                model=p.get('model') or options.get('sd_model_checkpoint')
                for i in range(j['count']):
                    if j['cancel']: break
                    ref=folder/f'input/{i:03}.png'
                    if p['mode']=='process':
                        im=Image.open(ref).convert('RGBA'); info={'source':'local_processing'}
                    else:
                        reference=Image.open(ref).convert('RGBA') if ref.exists() else None
                        args=dict(prompt=p.get('prompt',''),seed=int(p.get('seed',1234)),denoise=float(p.get('denoise',.3)),steps=int(p.get('steps',16)),resolution=int(p.get('resolution',256)),model=model)
                        # Cache exact input bytes, settings and loaded-model identity.
                        key=hashlib.sha256(json.dumps({'preprocessing_version':2,'args':args,'webui_options':options},sort_keys=True).encode()+(ref.read_bytes() if ref.exists() else b'')).hexdigest()
                        cache=self.root/'cache'/key
                        if (cache.with_suffix('.png')).exists() and cache.with_suffix('.json').exists():
                            im=Image.open(cache.with_suffix('.png')).convert('RGBA'); info=json.loads(cache.with_suffix('.json').read_text(encoding='utf-8')); info['cache_hit']=True
                        else:
                            im,info=self.client.generate(reference=reference,**args)
                            if j['cancel']: break
                            save_png(im,cache.with_suffix('.png')); atomic_json(cache.with_suffix('.json'),info)
                    save_png(im,folder/f'raw/{i:03}.png'); raw.append(im); history.append(info)
                    atomic_json(folder/'history.json',history); self.update(j,done=i+1)
                if j['cancel']: self.update(j,status='cancelled'); continue
                opts=dict(size=int(p.get('size',64)),colors=int(p.get('colors',24)),background=bool(p.get('background',False)),tolerance=int(p.get('tolerance',24)),dither=bool(p.get('dither',False)),cleanup=bool(p.get('cleanup',False)))
                prepared=raw
                if p.get('preserve_mask') and p['mode']=='img2img':
                    prepared=[constrain_mask(im,Image.open(folder/f'input/{i:03}.png')) for i,im in enumerate(raw)]
                    palette_sources=[process(Image.open(folder/f'input/{i:03}.png'),**opts) for i in range(len(raw))]
                else:
                    palette_sources=[process(im,**opts) for im in raw]
                palette=p.get('palette') or shared_palette(palette_sources,opts['colors'])
                # Apply shared palette to originals, avoiding accumulated quantization.
                frames=[process(im,palette=palette,**opts) for im in prepared]
                if p.get('preserve_mask') and p['mode']=='img2img':
                    frames=[protect_contour(im,process(Image.open(folder/f'input/{i:03}.png'),size=opts['size'],palette=palette)) for i,im in enumerate(frames)]
                frames=align_frames(frames,p.get('anchors'))
                direction=p.get('direction','down'); animation=p.get('animation','idle')
                metadata=export(frames,folder/'export',p.get('name','personagem'),animation,direction,int(p.get('fps',8)),
                    pose_manifest(direction) if animation=='walk' and len(frames)==8 else None,
                    {'mode':p['mode'],'history':'../history.json','reference_policy':'one_posed_reference_per_frame','palette':palette,
                     'base_approved':bool(p.get('base_approved',False)),'preserve_mask':bool(p.get('preserve_mask',False)),
                     'contour_from_reference':bool(p.get('preserve_mask') and p['mode']=='img2img')})
                self.update(j,status='review',validation=metadata['validation'])
            except Exception as e:
                # Never automatically retry OOM or timeout with another heavy request.
                if j['config']['mode']!='process': self.paused.set()
                self.update(j,status='error',error=str(e),queue_paused=self.paused.is_set())
            finally: self.queue.task_done()

def serve(root, port=8877):
    jobs=Jobs(root)
    class Handler(BaseHTTPRequestHandler):
        def reply(self,data,status=200,ctype='application/json'):
            content=json.dumps(data,ensure_ascii=False).encode() if ctype=='application/json' else data
            self.send_response(status); self.send_header('Content-Type',ctype); self.send_header('Content-Length',str(len(content))); self.send_header('X-Content-Type-Options','nosniff'); self.end_headers(); self.wfile.write(content)
        def do_GET(self):
            try:
                path=urlparse(self.path).path
                if path=='/': return self.reply((ROOT/'ui.html').read_bytes(),ctype='text/html; charset=utf-8')
                if path=='/api/jobs':
                    with jobs.lock: return self.reply({'jobs':list(jobs.jobs.values()),'paused':jobs.paused.is_set()})
                if path=='/api/models': return self.reply(jobs.client.models())
                if path=='/api/health':
                    opts=jobs.client.health(); return self.reply({'ok':True,'model':opts.get('sd_model_checkpoint')})
                if path.startswith('/files/'):
                    target=(jobs.root/unquote(path[7:])).resolve()
                    if not target.is_relative_to(jobs.root.resolve()) or not target.is_file(): return self.reply({'error':'Não encontrado'},404)
                    types={'.png':'image/png','.json':'application/json','.tres':'text/plain','.tscn':'text/plain','.godot':'text/plain'}
                    return self.reply(target.read_bytes(),ctype=types.get(target.suffix,'application/octet-stream'))
                self.reply({'error':'Não encontrado'},404)
            except Exception as e: self.reply({'error':str(e)},503)
        def do_POST(self):
            try:
                if self.headers.get('Origin') not in (None,f'http://127.0.0.1:{port}',f'http://localhost:{port}'): return self.reply({'error':'Origem inválida'},403)
                if self.headers.get('Host') not in (f'127.0.0.1:{port}',f'localhost:{port}'): return self.reply({'error':'Host inválido'},403)
                if self.headers.get('Content-Type')!='application/json': raise ValueError('Envie application/json.')
                n=int(self.headers.get('Content-Length',0))
                if not 0<n<=40*1024*1024: raise ValueError('Pedido excede 40 MB ou está vazio.')
                p=json.loads(self.rfile.read(n))
                if self.path=='/api/jobs':
                    j=jobs.submit(p)
                    with jobs.lock: jobs.jobs[j['id']]=j
                    return self.reply(j,201)
                if self.path=='/api/cancel': return self.reply(jobs.cancel(p['id']))
                if self.path=='/api/review': return self.reply(jobs.review(p['id'],p))
                if self.path=='/api/resume': jobs.paused.clear(); return self.reply({'ok':True})
                self.reply({'error':'Não encontrado'},404)
            except Exception as e: self.reply({'error':str(e)},400)
        def log_message(self,*args): pass
    print(f'Pipeline: http://127.0.0.1:{port}',flush=True)
    ThreadingHTTPServer(('127.0.0.1',port),Handler).serve_forever()

if __name__=='__main__':
    p=argparse.ArgumentParser(); p.add_argument('--data',default=str(ROOT/'data')); p.add_argument('--port',type=int,default=8877); a=p.parse_args(); serve(a.data,a.port)
