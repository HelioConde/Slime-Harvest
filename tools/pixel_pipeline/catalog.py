"""Read the actual SpriteFrames timeline, including repeats, margins and durations."""
import hashlib
import json
import re
from pathlib import Path
from PIL import Image
from collections import Counter

DIRECTIONS = ['down', 'up', 'left', 'right']
PRIMARY = ['idle', 'walk', 'run', 'axe', 'pick', 'hoe', 'watering']
FARM = ['plant','harvest','fertilize','weed','sickle','refill_watering_can']
OTHER = ['fish','cook','build','sleep','attack','hurt','death','interact','tool_use']
SLIMES = ['pet_slime','pickup_slime','hold_slime','putdown_slime','feed_slime','play_slime','hug_slime','call_slime','command_follow','command_stay','command_work','command_attack','give_item','receive_item','heal_slime','train_slime','celebrate_slime','protect_slime','combo_attack','rescue_slime','place_slime_home','rest_slime']
ALL_ACTIONS = PRIMARY + FARM + OTHER + SLIMES

def configured_definitions():
    path=Path(__file__).with_name('animation_catalog.json')
    return json.loads(path.read_text(encoding='utf8')) if path.exists() else definitions()

def digest(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()

def read_resource(project, resource):
    project = Path(project)
    text = (project/resource).read_text(encoding='utf-8')
    textures = {ident:path for path,ident in re.findall(r'\[ext_resource[^\]]*path="res://([^"]+)" id="([^"]+)"\]',text)}
    regions = {}
    for ident,body in re.findall(r'\[sub_resource type="AtlasTexture" id="([^"]+)"\]([^\[]+)',text):
        atlas = re.search(r'atlas = ExtResource\("([^"]+)"\)',body)
        region = re.search(r'region = Rect2\(([^)]+)\)',body)
        margin = re.search(r'margin = Rect2\(([^)]+)\)',body)
        if not atlas or not region: raise ValueError('Unsupported atlas: '+ident)
        regions[ident] = dict(texture=textures[atlas[1]],region=[round(float(v)) for v in region[1].split(',')],margin=[round(float(v)) for v in margin[1].split(',')] if margin else [0,0,0,0])
    animations = {}
    for frames,loop,name,speed in re.findall(r'"frames":\s*\[(.*?)\],\s*"loop":\s*(true|false|0|1),\s*"name":\s*&?"([^"]+)",\s*"speed":\s*([\d.]+)',text,re.S):
        timeline=[]
        for duration,ident in re.findall(r'"duration":\s*([\d.]+),\s*"texture":\s*SubResource\("([^"]+)"\)',frames):
            timeline.append(dict(resource_id=ident,duration=float(duration),**regions[ident]))
        if not timeline: raise ValueError('Unsupported empty animation: '+name)
        animations[name] = dict(fps=float(speed),loop=loop in ('true','1'),frames=timeline)
    if not animations: raise ValueError('No supported timelines in '+resource)
    return animations

def load_frame(project, frame):
    x,y,w,h=frame['region'];mx,my,mw,mh=frame['margin']
    with Image.open(Path(project)/frame['texture']) as im:
        crop=im.convert('RGBA').crop((x,y,x+w,y+h))
    canvas=Image.new('RGBA',(w+mw,h+mh));canvas.paste(crop,(mx,my))
    return canvas

class AtlasIsolation:
    """Remove only small intrusions belonging to a different, complete atlas body.

    Small detached objects/particles are retained. Ambiguous large overlaps are
    reported, never resolved by erasing a limb or inventing a new pose.
    """
    def __init__(self, project):
        self.project=Path(project);self.cache={}

    def isolate(self, frame):
        from pipeline import connected_regions
        path=frame['texture']
        if path not in self.cache:
            with Image.open(self.project/path) as source:image=source.convert('RGBA')
            labels=Image.new('I',image.size);pixels=labels.load();sizes={}
            for ident,group in enumerate(connected_regions(image),1):
                sizes[ident]=len(group)
                for xy in group:pixels[xy]=ident
            self.cache[path]=(image,labels,sizes)
        image,labels,sizes=self.cache[path]
        x,y,w,h=frame['region'];mx,my,mw,mh=frame['margin']
        local=labels.crop((x,y,x+w,y+h));counts=Counter(local.getdata());counts.pop(0,None)
        foreign=[];ambiguous=[]
        if counts:
            primary=max(counts,key=counts.get)
            for ident,inside in counts.items():
                if ident==primary or sizes[ident]<sizes[primary]*.4:continue
                if inside/sizes[ident]<.25:foreign.append(ident)
                else:ambiguous.append(dict(component=ident,pixels_inside=inside,total_pixels=sizes[ident]))
        crop=image.crop((x,y,x+w,y+h));mask=Image.new('RGBA',(w,h));removed=0
        for yy in range(h):
            for xx in range(w):
                if local.getpixel((xx,yy)) in foreign:
                    crop.putpixel((xx,yy),(0,0,0,0));mask.putpixel((xx,yy),(255,255,255,255));removed+=1
        canvas=Image.new('RGBA',(w+mw,h+mh));canvas.paste(crop,(mx,my))
        foreign_mask=Image.new('RGBA',canvas.size);foreign_mask.paste(mask,(mx,my))
        return canvas,foreign_mask,dict(removed_source_pixels=removed,foreign_components=foreign,ambiguous_components=ambiguous,region=frame['region'],margin=frame['margin'],body_repositioned=False)

def inventory(project):
    result={}
    for character in ('feminino','masculino'):
        resource=f'assets/Characters/animation/player_{character}_frames.tres'
        sequences=read_resource(project,resource)
        paths={resource}|{f['texture'] for seq in sequences.values() for f in seq['frames']}
        result[character]=dict(resource=resource,source_hashes={p:digest(Path(project)/p) for p in sorted(paths)},sequences=sequences)
    return result

def assert_sources(project, snapshot):
    for character in snapshot.values():
        for path,expected in character['source_hashes'].items():
            if digest(Path(project)/path)!=expected: raise ValueError('Source changed; re-inspect before resuming: '+path)

def definitions():
    """Draft pose/event plans are explicitly distinct from validated pixel poses."""
    events={'axe':'impact','pick':'impact','hoe':'impact','watering':'water_start','plant':'seed_release','harvest':'crop_collect','fertilize':'fertilizer_release','weed':'weed_remove','sickle':'impact','refill_watering_can':'water_refill','fish':'cast','cook':'ingredient_add','build':'impact','attack':'hit','hurt':'hit_reaction','death':'collapse','interact':'activate','tool_use':'impact','pickup_slime':'attach_slime','hold_slime':'hold_anchor','putdown_slime':'detach_slime','pet_slime':'pet_contact','feed_slime':'food_transfer','play_slime':'play_cue','hug_slime':'hug_contact','give_item':'item_transfer','receive_item':'item_receive','heal_slime':'heal','train_slime':'training_cue','celebrate_slime':'celebrate','protect_slime':'shield','combo_attack':'combo_hit','rescue_slime':'rescue_attach','place_slime_home':'home_release','rest_slime':'rest_release'}
    output=[]
    for action in ALL_ACTIONS:
        priority=0 if action in ('idle','walk') else 1 if action in PRIMARY else 2 if action in FARM else 3 if action in OTHER else 4
        event=events.get(action,'command' if action.startswith(('command_','call_')) else None)
        output.append(dict(id=action,name=action.replace('_',' '),priority=priority,directions=['down'] if action in ('cook','sleep') else DIRECTIONS,planned_frames=8 if action in PRIMARY else None,fps=None,loop=action in ('idle','walk','run','hold_slime','sleep'),pose_family='command' if action.startswith('command_') else 'carry' if action in ('pickup_slime','hold_slime','putdown_slime','rescue_slime','place_slime_home','rest_slime') else action,pose_plan=['preparation','execution','contact','recovery'] if action not in ('idle','walk','run','hold_slime','sleep') else ['cycle'],pose_validation='pending',prompt=f'same character, {action.replace("_"," ")}, readable full body pose, correct tool or interaction object, top-down 3/4 pixel art',reference_image=None,palette=None,origin=[32,62],events=[dict(id=event,phase='contact',frame=None,socket='hands',validated=False)] if event else [],interruptible=action in ('idle','walk','run','hold_slime','sleep'),generation_status='pending_reference',validation_status='pending',export_path=None))
    return dict(schema_version=1,aliases={'pickaxe':'pick','watering_can':'watering','planting':'plant','harvesting':'harvest'},actions=output)

def refresh_status(root):
    """Materialize per-character/per-direction state without calling a PNG complete."""
    from pipeline import atomic_json
    root=Path(root);catalog=json.loads((root/'catalog.json').read_text(encoding='utf8'))
    snap=json.loads((root/'inventory.json').read_text(encoding='utf8'));characters={}
    for character,data in snap.items():
        rows={}
        for action in catalog['actions']:
            for direction in action['directions']:
                name=f"{action['id']}_{direction}";source=data['sequences'].get(name)
                candidates={}
                for mode in ('clean','sd'):
                    path=root/character/name/mode/'state.json'
                    if path.exists():
                        state=json.loads(path.read_text(encoding='utf8'))
                        candidates[mode]={k:v for k,v in state.items() if k in ('generation_status','validation_status','validation','done')}
                        candidates[mode]['export_path']=f'{character}/{name}/{mode}/export' if state.get('export_path') else None
                rows[name]=dict(action=action['id'],direction=direction,priority=action['priority'],planned_frames=action['planned_frames'],source_frame_count=len(source['frames']) if source else 0,fps=source['fps'] if source else action['fps'],durations=[f['duration'] for f in source['frames']] if source else [],loop=source['loop'] if source else action['loop'],pose_references=source['frames'] if source else [],reference_image=data['sequences'].get('idle_down',{}).get('frames',[None])[0],palette=f'palettes/{character}.json',origin=action['origin'],events=action['events'],generation_status='candidates_available' if candidates else 'source_available' if source else 'pending_posed_references',validation_status='not_approved',candidates=candidates,motion_locked=action['id'] in ('idle','walk'),runtime_integrated=False)
        characters[character]=rows
    catalog['characters']=characters
    atomic_json(root/'catalog.json',catalog)
    return catalog

if __name__=='__main__':
    import argparse
    from pipeline import atomic_json
    p=argparse.ArgumentParser();p.add_argument('--project',default=r'C:\FarmSlime');p.add_argument('--output',type=Path,required=True);a=p.parse_args()
    atomic_json(a.output/'inventory.json',inventory(a.project));atomic_json(a.output/'catalog.json',definitions())
