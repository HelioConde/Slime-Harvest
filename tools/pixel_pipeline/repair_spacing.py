"""Repair foreign atlas fragments and add gutters without resampling approved frames."""
import argparse
import json
import os
import shutil
from pathlib import Path
from PIL import Image
from catalog import AtlasIsolation, assert_sources, refresh_status
from pipeline import atomic_json, export, process, save_png

def repair(root, project, padding=8):
    if not isinstance(padding,int) or not 0<=padding<=64:
        raise ValueError('Padding must be an integer between 0 and 64')
    lock=Path(root)/'production.lock'
    fd=os.open(lock,os.O_CREAT|os.O_EXCL|os.O_WRONLY)
    try:
        os.write(fd,str(os.getpid()).encode());os.close(fd)
        return _repair(root,project,padding)
    finally:
        lock.unlink(missing_ok=True)

def _repair(root, project, padding):
    root=Path(root)
    snapshot=json.loads((root/'inventory.json').read_text(encoding='utf8'))
    assert_sources(project,snapshot)
    isolation=AtlasIsolation(project);results=[]
    for statefile in sorted(root.glob('*/*/*/state.json')):
        folder=statefile.parent;destination=folder/'export'
        if not (destination/'metadata.json').exists():continue
        character,name,mode=folder.relative_to(root).parts
        sequence=snapshot[character]['sequences'][name]
        old=json.loads((destination/'metadata.json').read_text(encoding='utf8'))
        backup=root/'history_spacing'/character/name/mode
        if not backup.exists():
            shutil.copytree(folder,backup,ignore=shutil.ignore_patterns('.godot','*.import','__pycache__'))
        frames=[];audits=[]
        for i,source in enumerate(sequence['frames']):
            # Always repair the immutable pre-repair frame, making repeated runs identical.
            with Image.open(backup/f'frames/{i:03}.png') as im:frame=im.convert('RGBA')
            _,mask,audit=isolation.isolate(source)
            mask=process(mask).getchannel('A')
            removed=[]
            for y in range(64):
                for x in range(64):
                    if mask.getpixel((x,y)) and frame.getpixel((x,y))[3]:
                        removed.append([x,y]);frame.putpixel((x,y),(0,0,0,0))
            audit['removed_output_pixels']=removed;audits.append(audit)
            save_png(frame,folder/f'frames/{i:03}.png');frames.append(frame)
        meta=export(frames,destination,character,old['animation'],old['direction'],old['fps'],poses=old.get('poses'),provenance=old.get('provenance'),durations=old['durations'],loop=old['loop'],origin=old['origin'],allow_repeated_frames=old['animation']=='idle',padding=padding)
        meta['events']=old.get('events',[])
        meta['provenance']['atlas_isolation']=audits
        meta['validation']['visual_approved']=False
        meta['validation']['motion_timing_preserved']=True
        meta['validation']['ambiguous_atlas_overlap']=any(a['ambiguous_components'] for a in audits)
        # Verify actual atlas regions and that every gutter is fully transparent.
        sheet=Image.open(destination/'sheet.png').convert('RGBA')
        residual=sheet.copy()
        for i,frame in enumerate(frames):
            x=padding+i*(64+padding);box=(x,padding,x+64,padding+64)
            assert sheet.crop(box).tobytes()==frame.tobytes()
            residual.paste((0,0,0,0),box)
        assert residual.getchannel('A').getbbox() is None
        meta['validation']['atlas_regions_and_gutters_verified']=True
        atomic_json(destination/'metadata.json',meta)
        state=json.loads(statefile.read_text(encoding='utf8'))
        state.update(validation=meta['validation'],validation_status='needs_visual_review' if meta['validation']['structural_ok'] else 'needs_source_repair')
        atomic_json(statefile,state)
        results.append(dict(sequence=f'{character}/{name}/{mode}',frames=len(frames),removed_pixels=sum(len(a['removed_output_pixels']) for a in audits),ambiguous_frames=[i for i,a in enumerate(audits) if a['ambiguous_components']],padding=padding,regions_verified=True))
    atomic_json(root/'spacing_validation.json',results);refresh_status(root)
    return results

if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('--output',type=Path,required=True);p.add_argument('--project',type=Path,required=True);p.add_argument('--padding',type=int,default=8)
    args=p.parse_args();print(json.dumps(repair(args.output,args.project,args.padding),indent=2))
