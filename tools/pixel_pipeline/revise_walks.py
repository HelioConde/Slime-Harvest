import sys,json,time,argparse
from pathlib import Path
sys.path.insert(0,str(Path(__file__).resolve().parent))
from pipeline import *
from app import Jobs
from PIL import Image,ImageDraw
parser=argparse.ArgumentParser(description='Reproduz as caminhadas experimentais da aventureira existente. Não aprova animações.')
parser.add_argument('--phase',choices=['samples','full'],default='samples')
parser.add_argument('--output',type=Path,required=True)
parser.add_argument('--palette-job',type=Path,required=True,help='job.json do idle V2, para reutilizar a mesma paleta')
parser.add_argument('--project',default=r'C:\FarmSlime')
args=parser.parse_args();out=args.output;out.mkdir(parents=True,exist_ok=True)
refsroot=out/'referencias';refsroot.mkdir(exist_ok=True)
# The existing down/up AtlasTexture cells cut through the feet. Recover complete
# connected bodies from their source atlas, then use a common canvas and scale.
atlas=Image.open(Path(args.project)/'assets/Characters/new/exec-af55c5be-081c-44df-8fe1-617ca0bc67e8.png').convert('RGBA')
a=atlas.getchannel('A');remaining={(x,y) for y in range(atlas.height) for x in range(atlas.width) if a.getpixel((x,y))>=128};bodies=[]
while remaining:
 todo=[remaining.pop()];group=set(todo)
 while todo:
  x,y=todo.pop()
  for dx,dy in [(-1,0),(1,0),(0,-1),(0,1),(-1,-1),(1,-1),(-1,1),(1,1)]:
   n=x+dx,y+dy
   if n in remaining:remaining.remove(n);todo.append(n);group.add(n)
 if len(group)>5000:
  xs=[xy[0] for xy in group];ys=[xy[1] for xy in group];bodies.append((min(xs),min(ys),max(xs)+1,max(ys)+1,group))
report=[]
for direction in ['down','up','left','right']:
 if direction in ['down','up']:
  row=sorted([b for b in bodies if (b[1]<200 if direction=='down' else 200<=b[1]<400)],key=lambda b:b[0])
  if len(row)!=8:raise ValueError('Unexpected atlas: expected eight complete bodies in each row')
  refs=[]
  for i,(x0,y0,x1,y1,group) in enumerate(row):
   # No per-frame resizing: original pixels translated to a fixed head center.
   head=[x for x,y in group if y<y0+100];center=(min(head)+max(head))/2
   dx=round(128-center);dy=(36 if direction=='down' else 36)-min(b[1] for b in row)
   im=Image.new('RGBA',(256,256))
   for x,y in group:
    if not (0<=x+dx<256 and 0<=y+dy<256):raise ValueError('Recovered body does not fit the canvas')
    im.putpixel((x+dx,y+dy),atlas.getpixel((x,y)))
   refs.append(im);report.append(dict(direction=direction,frame=i,source_bbox=[x0,y0,x1,y1],translation=[dx,dy],policy='complete_body_fixed_scale_head_registration'))
 else:
  refs=extract_godot_frames(args.project,'assets/Characters/animation/player_feminino_frames.tres','walk_'+direction,8)
 for i,im in enumerate(refs):save_png(im,refsroot/f'{direction}_{i}.png')
atomic_json(out/'limpeza_referencias.json',report)
mode=args.phase;count=1 if mode=='samples' else 8
palette=json.loads(args.palette_job.read_text(encoding='utf-8'))['config']['palette']
jobs=Jobs(out/'jobs');index=[]
for direction in ['down','up','left','right']:
 p=dict(mode='img2img',name='aventureira_v2',animation='walk',direction=direction,count=count,fps=8,size=64,colors=24,resolution=512,steps=20,denoise=.12,seed=1234,preserve_mask=True,base_approved=True,palette=palette,prompt='same female adventurer, curly brown hair, green vest, cream shirt, brown trousers, turquoise pendant, '+{'down':'front view','up':'back view','left':'left side view','right':'right side view'}[direction],images=[encode(Image.open(refsroot/f'{direction}_{i}.png')) for i in range(count)])
 j=jobs.submit(p);index.append(dict(direction=direction,id=j['id']));print(direction,j['id'],flush=True)
atomic_json(out/f'{mode}_index.json',index)
while jobs.queue.unfinished_tasks:
 if jobs.paused.is_set():raise RuntimeError('Generation paused; inspect job.json')
 time.sleep(1)
print('COMPLETE',mode,flush=True)
