import argparse
import json
from pathlib import Path
from PIL import Image, ImageDraw
from pipeline import *

def demo(project, output, base_approved=False):
    output=Path(output); sequences={}; raw=[]
    for animation,direction,count in [('idle','down',4)]+[('walk',d,8) for d in DIRECTIONS]:
        frames=extract_godot_frames(project,'assets/Characters/animation/player_feminino_frames.tres',animation+'_'+direction,count)
        # Existing references are fixtures, not newly generated or approved animations.
        frames=[process(im,size=64,colors=32) for im in frames]
        sequences[animation+'_'+direction]=frames; raw+=frames
    palette=shared_palette(raw,24)
    contact=Image.new('RGB',(8*64,5*82),(29,42,34)); draw=ImageDraw.Draw(contact)
    for row,(key,frames) in enumerate(sequences.items()):
        animation,direction=key.split('_'); frames=[process(im,palette=palette) for im in frames]
        export(frames,output/key,'aventureira_existente',animation,direction,8,
               pose_manifest(direction) if animation=='walk' else None,
               {'source':'existing_game_atlas','generated_by_diffusion':False,'base_approved':base_approved,
                'resource':'assets/Characters/animation/player_feminino_frames.tres',
                'warning':'Referências herdadas podem conter os defeitos anatômicos relatados. Não aprovadas.'})
        for i,im in enumerate(frames): contact.paste(im,(i*64,row*82+18),im)
        draw.text((4,row*82),key,fill='white')
    save_png(sequences['idle_down'][0],output/'base_reference.png')
    save_png(contact.resize((1024,820),Image.Resampling.NEAREST),output/'contact_sheet.png')
    atomic_json(output/'review.json',{'status':'experimental','base_approved':base_approved,'source':'existing_game_atlas',
        'required':['aprovação da base','anotar membros por quadro','revisar frente/trás/laterais','corrigir deslizamento'],
        'note':'Teste completo de processamento/exportação, não nova geração SD de 36 quadros.'})
    print(output)

def templates(output):
    root=Path(output)
    for direction in DIRECTIONS:
        poses=pose_manifest(direction); atomic_json(root/direction/'poses.json',poses)
        for i,p in enumerate(poses):
            im=Image.new('RGB',(256,256),'white'); d=ImageDraw.Draw(im)
            # Anatomical left is screen-right from the front and screen-left from behind.
            mirror=-1 if direction=='up' else 1
            if direction in ('down','up'):
                lx,rx=128+18*mirror,128-18*mirror
                feet=[(lx,226+round(p['left_stride']*10)),(rx,226+round(p['right_stride']*10))]
                shoulders=[(128+24*mirror,110),(128-24*mirror,110)]
                hands=[(shoulders[0][0],165+round(p['left_arm']*10)),(shoulders[1][0],165+round(p['right_arm']*10))]
            else:
                sign=1 if direction=='right' else -1
                feet=[(128+round(p['left_stride']*32*sign),236),(128+round(p['right_stride']*32*sign),236)]
                shoulders=[(124,110),(132,110)]
                hands=[(128+round(p['left_arm']*25*sign),170),(128+round(p['right_arm']*25*sign),170)]
            d.line((128,100,128,175),fill='#333333',width=8); d.ellipse((108,58,148,98),outline='#333333',width=5)
            if direction!='up':
                d.point((128 if direction=='down' else 140 if direction=='right' else 116,78),fill='black')
            for k,c in enumerate(('#d74f38','#3479d1')):
                d.line([(128,175),feet[k]],fill=c,width=7); d.line([shoulders[k],hands[k]],fill=c,width=7)
            d.line((80,246,176,246),fill='#888888',width=1)
            save_png(im,root/direction/f'{i:03}.png')
    (root/'README.txt').write_text('Esquerda anatômica vermelha; direita azul. Guias esquemáticos, não biomecânica validada. Vista traseira tem projeção própria. Use para desenhar/ajustar o personagem-base nas poses; não envie o esqueleto sozinho esperando preservação de identidade. ControlNet não habilitado.\n',encoding='utf-8')

if __name__=='__main__':
    p=argparse.ArgumentParser(); sub=p.add_subparsers(dest='cmd',required=True)
    d=sub.add_parser('demo'); d.add_argument('--project',default=r'C:\FarmSlime'); d.add_argument('--output',default='data/demo')
    d.add_argument('--base-approved',action='store_true',help='Use somente após aprovação humana explícita da base.')
    t=sub.add_parser('templates'); t.add_argument('--output',default='data/templates')
    h=sub.add_parser('health')
    a=p.parse_args()
    if a.cmd=='demo': demo(a.project,a.output,a.base_approved)
    elif a.cmd=='templates': templates(a.output)
    else: print(json.dumps({'checkpoint':SDClient().health().get('sd_model_checkpoint')},indent=2))
