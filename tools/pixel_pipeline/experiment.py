"""Reproduce the 36-frame experiment from the game's actual female atlas references."""
import argparse
import time
from pathlib import Path
from app import Jobs
from pipeline import DIRECTIONS, extract_godot_frames, encode, process, shared_palette, atomic_json

def run(project, output, steps=12, denoise=.25, base_approved=False):
    root=Path(output); sequences=[]
    for animation,direction,count in [('idle','down',4)]+[('walk',d,8) for d in DIRECTIONS]:
        refs=extract_godot_frames(project,'assets/Characters/animation/player_feminino_frames.tres',animation+'_'+direction,count)
        sequences.append((animation,direction,refs))
    palette=shared_palette([process(im) for _,_,refs in sequences for im in refs],24)
    jobs=Jobs(root); index=[]
    for animation,direction,refs in sequences:
        j=jobs.submit(dict(mode='img2img',name='aventureira',category='Personagem feminino',animation=animation,direction=direction,
            count=len(refs),fps=8,size=64,colors=24,seed=1234,steps=steps,resolution=256,denoise=denoise,palette=palette,
            preserve_mask=True,base_approved=base_approved,
            prompt='same female adventurer, curly brown hair, green vest, cream shirt, brown trousers, turquoise pendant, '+
                {'down':'front view','up':'back view','left':'left side view','right':'right side view'}[direction],
            images=[encode(im) for im in refs]))
        index.append({'id':j['id'],'animation':animation,'direction':direction})
    atomic_json(root/'index.json',index)
    while jobs.queue.unfinished_tasks:
        if jobs.paused.is_set():
            atomic_json(root/'result.json',list(jobs.jobs.values()))
            raise RuntimeError('Ensaio pausado por erro; confira job.json e o WebUI. Arquivos parciais preservados.')
        time.sleep(.5)
    atomic_json(root/'result.json',list(jobs.jobs.values()))
    print('Ensaio exportado. Todos os resultados exigem revisão visual:',root)

if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('--project',default=r'C:\FarmSlime');p.add_argument('--output',default='data/experiment')
    p.add_argument('--steps',type=int,default=12);p.add_argument('--denoise',type=float,default=.25)
    p.add_argument('--base-approved',action='store_true',help='Somente após aprovação humana explícita.')
    a=p.parse_args();run(a.project,a.output,a.steps,a.denoise,a.base_approved)
