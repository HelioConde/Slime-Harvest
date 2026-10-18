"""Local sprite pipeline. Python 3.10+, Pillow; no GPU dependencies."""
from __future__ import annotations
import base64
import hashlib
import io
import json
import math
import os
import re
import threading
import time
import urllib.request
import urllib.error
from collections import deque
from pathlib import Path
from PIL import Image, ImageChops

SIZES = (32, 48, 64, 96, 128)
DIRECTIONS = ('down', 'up', 'left', 'right')
ANIMATIONS = ('idle','walk','run','attack','hurt','death','interact','tool_use','watering','planting','harvesting','jump','water_jet')
STYLE = 'cozy fantasy game sprite, full body, single character, 3/4 top-down, pixel art, harmonious colors, plain white background'
NEGATIVE = 'photo, text, watermark, multiple characters, cropped, blurry, extra limbs'
PHASES = ['left_contact','left_weight','right_passing','right_advance','right_contact','right_weight','left_passing','left_advance']

def atomic_json(path, value):
    path = Path(path)
    path.parent.mkdir(parents=True, exist_ok=True)
    tmp = path.with_suffix('.tmp')
    tmp.write_text(json.dumps(value, ensure_ascii=False, indent=2), encoding='utf-8')
    os.replace(tmp, path)

def save_png(im, path):
    path = Path(path)
    path.parent.mkdir(parents=True, exist_ok=True)
    tmp = path.with_suffix('.tmp')
    im.save(tmp, format='PNG')
    os.replace(tmp, path)

def encode(im):
    b = io.BytesIO()
    im.save(b, format='PNG')
    return base64.b64encode(b.getvalue()).decode('ascii')

def decode(s):
    data = base64.b64decode(s.split(',')[-1], validate=True)
    im = Image.open(io.BytesIO(data))
    if max(im.size) > 4096:
        raise ValueError('Imagem excede 4096 pixels.')
    return im.convert('RGBA')

def remove_background(im, color=(255,255,255), tolerance=24):
    """Remove only matching background connected to the border, not white clothing."""
    im = im.convert('RGBA').copy()
    w,h = im.size
    px = im.load()
    todo = deque([(x,y) for x in range(w) for y in (0,h-1)] + [(x,y) for y in range(h) for x in (0,w-1)])
    seen = set()
    while todo:
        x,y = todo.popleft()
        if (x,y) in seen or not (0<=x<w and 0<=y<h):
            continue
        seen.add((x,y))
        p = px[x,y]
        if p[3] == 0 or max(abs(p[i]-color[i]) for i in range(3)) <= tolerance:
            px[x,y] = (0,0,0,0)
            todo.extend(((x-1,y),(x+1,y),(x,y-1),(x,y+1)))
    return im

def process(im, size=64, colors=24, palette=None, background=False, tolerance=24, dither=False, cleanup=False):
    if size not in SIZES or not 2 <= colors <= 256:
        raise ValueError('Resolução ou número de cores inválido.')
    im = im.convert('RGBA')
    if background:
        im = remove_background(im, tolerance=tolerance)
    # Keep canvas/registration. Never independently fit each frame's bounding box.
    scale = min(size/im.width, size/im.height)
    small = im.resize((max(1,round(im.width*scale)),max(1,round(im.height*scale))), Image.Resampling.NEAREST)
    alpha = small.getchannel('A').point(lambda a: 255 if a>=128 else 0)
    rgb = small.convert('RGB')
    method = Image.Dither.FLOYDSTEINBERG if dither else Image.Dither.NONE
    if palette is not None:
        if not 2 <= len(palette) <= 256 or any(len(c)!=3 or any(not 0<=v<=255 for v in c) for c in palette):
            raise ValueError('Paleta requer 2–256 cores RGB.')
        pal = Image.new('P',(1,1))
        padded = list(palette) + [palette[-1]]*(256-len(palette))
        pal.putpalette([v for c in padded for v in c])
        rgb = rgb.quantize(palette=pal,dither=method).convert('RGB')
    else:
        # Quantize opaque pixels only, so the transparent canvas does not consume colors.
        pixels = [p for p,a in zip(rgb.getdata(),alpha.getdata()) if a]
        if pixels:
            strip = Image.new('RGB',(len(pixels),1)); strip.putdata(pixels)
            pal = strip.quantize(colors=colors,method=Image.Quantize.MEDIANCUT)
            rgb = rgb.quantize(palette=pal,dither=method).convert('RGB')
    rgb.putalpha(alpha)
    if cleanup:
        src = alpha.load(); dst = rgb.load()
        for y in range(rgb.height):
            for x in range(rgb.width):
                if src[x,y] and not any(src[xx,yy] for xx,yy in ((x-1,y),(x+1,y),(x,y-1),(x,y+1)) if 0<=xx<rgb.width and 0<=yy<rgb.height):
                    dst[x,y] = (0,0,0,0)
    out = Image.new('RGBA',(size,size))
    out.paste(rgb,((size-rgb.width)//2,size-rgb.height))
    out.putdata([p if p[3] else (0,0,0,0) for p in out.getdata()])
    return out

def components(im):
    a=im.getchannel('A'); w,h=im.size
    remaining={(x,y) for y in range(h) for x in range(w) if a.getpixel((x,y))>=128}
    sizes=[]
    while remaining:
        todo=[remaining.pop()]; size=0
        while todo:
            x,y=todo.pop(); size+=1
            for dx,dy in ((-1,0),(1,0),(0,-1),(0,1),(-1,-1),(1,-1),(-1,1),(1,1)):
                n=(x+dx,y+dy)
                if n in remaining: remaining.remove(n); todo.append(n)
        sizes.append(size)
    return sorted(sizes,reverse=True)

def shared_palette(images, colors=24):
    pixels = [p[:3] for im in images for p in im.convert('RGBA').getdata() if p[3]>=128]
    if not pixels:
        raise ValueError('Todos os quadros estão vazios.')
    strip = Image.new('RGB',(len(pixels),1)); strip.putdata(pixels)
    p = strip.quantize(colors=colors).getpalette()[:colors*3]
    return [p[i:i+3] for i in range(0,len(p),3)]

def align_frames(images, anchors=None, target=None):
    """Explicit per-frame ground/root anchors preserve intentional limb motion."""
    if not images: raise ValueError('Sem quadros.')
    w,h = images[0].size
    target = target or (w//2,h-2)
    anchors = anchors or [target]*len(images)
    if len(anchors)!=len(images): raise ValueError('Um ponto de origem por quadro é obrigatório.')
    result=[]
    for im,a in zip(images,anchors):
        dx,dy = round(target[0]-a[0]),round(target[1]-a[1])
        box=im.getchannel('A').getbbox()
        if box and (box[0]+dx<0 or box[1]+dy<0 or box[2]+dx>w or box[3]+dy>h):
            raise ValueError('Alinhamento cortaria a silhueta.')
        out=Image.new('RGBA',(w,h)); out.paste(im,(dx,dy)); result.append(out)
    return result

def validate_poses(poses):
    problems=[]
    if len(poses)!=8: return ['Caminhada exige oito poses.']
    for i,p in enumerate(poses):
        if p.get('phase')!=PHASES[i]: problems.append(f'Fase incorreta no quadro {i}.')
        leg=p.get('left_stride',0); arm=p.get('left_arm',0)
        if leg and leg*arm>=0: problems.append(f'Braços sem oposição no quadro {i}.')
        if abs(p.get('right_stride',0)+leg)>0.01: problems.append(f'Pernas sem oposição no quadro {i}.')
    if poses[0].get('left_stride',0)<=0 or poses[4].get('left_stride',0)>=0:
        problems.append('Contatos esquerdo/direito não alternam.')
    return problems

def pose_manifest(direction):
    if direction not in DIRECTIONS: raise ValueError('Direção inválida.')
    strides=(1,.7,0,-.7,-1,-.7,0,.7)
    return [dict(phase=PHASES[i],direction=direction,left_stride=s,right_stride=-s,left_arm=-s,right_arm=s,
                 support='left' if i<4 else 'right',root=[32,62],review='template_only') for i,s in enumerate(strides)]

def validate_frames(images, expected=None, poses=None):
    issues=[]; hashes={}; boxes=[]; bottoms=[]
    if not images: return {'structural_ok':False,'issues':['Sem quadros.'],'status':'experimental'}
    size=images[0].size
    if expected is not None and len(images)!=expected: issues.append('Quantidade de quadros incorreta.')
    for i,im in enumerate(images):
        if im.size!=size: issues.append(f'Quadro {i}: dimensões diferentes.')
        a=im.getchannel('A'); box=a.getbbox(); boxes.append(box)
        if not box: issues.append(f'Quadro {i}: vazio.')
        else:
            bottoms.append(box[3])
            if box[0]==0 or box[1]==0 or box[2]==im.width or box[3]==im.height:
                issues.append(f'Quadro {i}: silhueta toca a borda; revisar corte/margem.')
        if a.getextrema()[0]!=0: issues.append(f'Quadro {i}: sem transparência.')
        if any(v not in (0,255) for v in set(a.getdata())): issues.append(f'Quadro {i}: alpha intermediário.')
        if len(components(im))>1: issues.append(f'Quadro {i}: componentes desconectados; revisar fragmentos/efeitos.')
        canonical=Image.new('RGBA',im.size); canonical.putdata([p if p[3] else (0,0,0,0) for p in im.getdata()])
        digest=hashlib.sha256(canonical.tobytes()).hexdigest()
        if digest in hashes: issues.append(f'Quadros duplicados: {hashes[digest]} e {i}.')
        hashes[digest]=i
    if bottoms and max(bottoms)-min(bottoms)>2: issues.append('Apoio varia mais de 2 pixels; revisar contato com o solo.')
    if poses is not None: issues += validate_poses(poses)
    deltas=[]
    if len(images)>1 and all(im.size==size for im in images):
        for a,b in zip(images,images[1:]+images[:1]):
            deltas.append(sum(p!=q for p,q in zip(a.getdata(),b.getdata()))/(size[0]*size[1]))
        if deltas[-1]>max(.12,sum(deltas[:-1])/len(deltas[:-1])*2): issues.append('Descontinuidade provável no fechamento do ciclo.')
    return dict(structural_ok=not issues,status='experimental',issues=issues,bounds=boxes,pixel_changes=deltas,
                visual_review_required=['identidade','alternância real dos membros','braços opostos','contato e deslizamento','escala','continuidade'],
                note='Metadados de poses não comprovam anatomia dos pixels. Aprovação humana necessária.')

def export(images, directory, name='personagem', animation='walk', direction='down', fps=8, poses=None, provenance=None):
    if not images or not 1<=fps<=60: raise ValueError('Quadros/FPS inválidos.')
    if animation not in ANIMATIONS or direction not in DIRECTIONS: raise ValueError('Animação/direção inválida.')
    if any(im.size!=images[0].size for im in images): raise ValueError('Dimensões inconsistentes.')
    root=Path(directory); root.mkdir(parents=True,exist_ok=True)
    w,h=images[0].size; n=len(images); cols=min(4,n); rows=math.ceil(n/cols)
    horizontal=Image.new('RGBA',(w*n,h)); grid=Image.new('RGBA',(w*cols,h*rows))
    for i,im in enumerate(images):
        save_png(im,root/f'frames/{i:03}.png'); horizontal.paste(im,(w*i,0)); grid.paste(im,(w*(i%cols),h*(i//cols)))
    save_png(horizontal,root/'sheet.png'); save_png(grid,root/'grid.png')
    # APNG preserves alpha without GIF palette limitations.
    images[0].save(root/'preview.png',save_all=True,append_images=images[1:],duration=round(1000/fps),loop=0,disposal=0,blend=0)
    validation=validate_frames(images,4 if animation=='idle' else 8 if animation=='walk' else n,poses)
    metadata=dict(character=name,animation=animation,direction=direction,resolution=[w,h],frame_count=n,fps=fps,
                  origin=[w//2,h-2],grid={'columns':cols,'rows':rows},horizontal={'columns':n,'rows':1},
                  validation=validation,provenance=provenance or {},poses=poses)
    atomic_json(root/'metadata.json',metadata)
    # Standalone Godot preview, never changes the game project.
    (root/'project.godot').write_text('config_version=5\n[application]\nconfig/name="Sprite experimental"\nrun/main_scene="res://Preview.tscn"\n[rendering]\nrenderer/rendering_method="gl_compatibility"\ntextures/default_filters/use_nearest_mipmap_filter=false\n',encoding='utf-8')
    lines=['[gd_resource type="SpriteFrames" load_steps=%d format=3]'%(n+2),'[ext_resource type="Texture2D" path="res://sheet.png" id="1"]']
    for i in range(n): lines += [f'[sub_resource type="AtlasTexture" id="f{i}"]','atlas = ExtResource("1")',f'region = Rect2({i*w}, 0, {w}, {h})']
    frames=', '.join('{"duration": 1.0, "texture": SubResource("f%d")}'%i for i in range(n))
    lines += ['[resource]',f'animations = [{{"name": &"{animation}_{direction}", "speed": {float(fps)}, "loop": true, "frames": [{frames}]}}]']
    (root/'frames.tres').write_text('\n\n'.join(lines),encoding='utf-8')
    (root/'Preview.tscn').write_text(f'[gd_scene load_steps=2 format=3]\n[ext_resource type="SpriteFrames" path="res://frames.tres" id="1"]\n[node name="Preview" type="AnimatedSprite2D"]\ntexture_filter = 1\nposition = Vector2(320, 280)\nscale = Vector2(4, 4)\ncentered = false\noffset = Vector2({-w//2}, {-h+2})\nsprite_frames = ExtResource("1")\nanimation = &"{animation}_{direction}"\nautoplay = "{animation}_{direction}"\n',encoding='utf-8')
    return metadata

class SDClient:
    def __init__(self, url='http://127.0.0.1:7860', timeout=900):
        from urllib.parse import urlparse
        u=urlparse(url)
        if u.scheme!='http' or u.hostname not in ('127.0.0.1','localhost'):
            raise ValueError('Use apenas WebUI HTTP local.')
        self.url=url.rstrip('/'); self.timeout=timeout

    def request(self, path, payload=None):
        req=urllib.request.Request(self.url+path,data=None if payload is None else json.dumps(payload).encode(),headers={'Content-Type':'application/json'})
        try:
            with urllib.request.urlopen(req,timeout=self.timeout) as r: return json.load(r)
        except urllib.error.HTTPError as e:
            raise RuntimeError(f'WebUI HTTP {e.code}: {e.read(2000).decode(errors="replace")}') from e
        except (urllib.error.URLError, TimeoutError) as e:
            raise RuntimeError(f'WebUI indisponível ou timeout; confira --api. {e}') from e

    def health(self): return self.request('/sdapi/v1/options')
    def models(self): return self.request('/sdapi/v1/sd-models')
    def interrupt(self): return self.request('/sdapi/v1/interrupt',{})

    def generate(self, prompt, seed=1234, reference=None, denoise=.3, steps=16, resolution=256, model=None):
        if resolution not in (256,384) or not .25<=denoise<=.40 or not 1<=steps<=40:
            raise ValueError('Use 256/384 px, denoise 0.25–0.40 e 1–40 passos.')
        if not 0<=seed<2**32: raise ValueError('Seed deve estar entre 0 e 2^32-1.')
        payload=dict(prompt=prompt+', '+STYLE,negative_prompt=NEGATIVE,seed=seed,steps=steps,width=resolution,height=resolution,
                     sampler_name='Euler',cfg_scale=6,batch_size=1,n_iter=1,save_images=False,send_images=True)
        if model: payload.update(override_settings={'sd_model_checkpoint':model},override_settings_restore_afterwards=False)
        endpoint='txt2img'
        if reference is not None:
            # Composite transparency on white before diffusion, do not expose RGB under alpha.
            ref=reference.convert('RGBA').resize((resolution,resolution),Image.Resampling.NEAREST)
            bg=Image.new('RGBA',ref.size,'white'); bg.alpha_composite(ref)
            payload.update(init_images=[encode(bg.convert('RGB'))],denoising_strength=denoise,resize_mode=0)
            endpoint='img2img'
        start=time.monotonic(); data=self.request('/sdapi/v1/'+endpoint,payload)
        if not data.get('images'): raise RuntimeError('WebUI não retornou imagens.')
        return decode(data['images'][0]),dict(seconds=time.monotonic()-start,parameters={k:v for k,v in payload.items() if k!='init_images'},info=data.get('info'),endpoint=endpoint)

def extract_godot_frames(project, resource, animation, count):
    """Read-only extraction of existing AtlasTexture regions; never label them AI output."""
    project=Path(project); text=(project/resource).read_text(encoding='utf-8')
    textures={m[1]:m[0] for m in re.findall(r'\[ext_resource[^\]]*path="res://([^"]+)" id="([^"]+)"\]',text)}
    result=[]
    for i in range(count):
        m=re.search(r'\[sub_resource type="AtlasTexture" id="f_'+re.escape(animation)+f'_{i}"'+r'\]\s*atlas = ExtResource\("([^"]+)"\)\s*region = Rect2\(([^)]+)\)',text)
        if not m: raise ValueError(f'Região não encontrada: {animation}/{i}')
        x,y,w,h=map(lambda v:round(float(v)),m[2].split(','))
        with Image.open(project/textures[m[1]]) as im: result.append(im.convert('RGBA').crop((x,y,x+w,y+h)))
    return result
