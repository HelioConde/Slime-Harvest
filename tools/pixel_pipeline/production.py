"""Catalog-driven CPU processing and bounded, resumable single-frame SD batches."""
import argparse
import hashlib
import json
import os
from pathlib import Path
from PIL import Image
from catalog import inventory, definitions, assert_sources, load_frame, refresh_status
from pipeline import clean_frame
from pipeline import atomic_json, save_png, process, shared_palette, export, SDClient, constrain_mask, protect_contour

def initialize(project, root):
    root=Path(root);root.mkdir(parents=True,exist_ok=True)
    if (root/'inventory.json').exists():
        snap=json.loads((root/'inventory.json').read_text(encoding='utf8'));assert_sources(project,snap)
    else:
        snap=inventory(project);atomic_json(root/'inventory.json',snap)
    if not (root/'catalog.json').exists():
        template=Path(__file__).with_name('animation_catalog.json')
        atomic_json(root/'catalog.json',json.loads(template.read_text(encoding='utf8')) if template.exists() else definitions())
    for character,data in snap.items():
        path=root/'palettes'/f'{character}.json'
        if not path.exists():
            sources=[process(load_frame(project,f)) for seq in data['sequences'].values() for f in seq['frames']]
            atomic_json(path,shared_palette(sources,32))
    return snap

def run(project, root, character, actions, limit=2, sd=False, pose_review=None, client=None, directions=None):
    root=Path(root);root.mkdir(parents=True,exist_ok=True)
    lock=root/'production.lock'
    fd=os.open(lock,os.O_CREAT|os.O_EXCL|os.O_WRONLY)
    try:
        os.write(fd,str(os.getpid()).encode());os.close(fd)
        snap=initialize(project,root)
        catalog=json.loads((root/'catalog.json').read_text(encoding='utf8'))
        known={a['id']:a for a in catalog['actions']}
        if not actions or any(a not in known for a in actions):raise ValueError('Unknown/empty action selection')
        if sd and any(a in ('idle','walk') for a in actions):raise ValueError('P0 is locked: idle/walk allow colour cleanup only, no SD generation')
        if not 1<=limit<=32:raise ValueError('Batch limit must be 1..32')
        palette=json.loads((root/'palettes'/f'{character}.json').read_text())
        review=json.loads(Path(pose_review).read_text(encoding='utf8')) if pose_review else {}
        client=client or SDClient()
        options=client.health() if sd else {}
        if sd and client.request('/sdapi/v1/progress')['state'].get('job_count',0)>0:raise RuntimeError('WebUI is busy; retry after its current queue completes')
        spent=0;rows=[]
        for action in actions:
            definition=known[action]
            for direction in definition['directions']:
                if directions is not None and direction not in directions:continue
                name=f'{action}_{direction}';sequence=snap[character]['sequences'].get(name)
                if sequence is None:
                    rows.append(dict(name=name,generation_status='pending_posed_references',validation_status='pending',export_path=None));continue
                folder=root/character/name/('sd' if sd else 'clean');folder.mkdir(parents=True,exist_ok=True)
                profile=dict(schema=1,sequence=sequence,source_hashes=snap[character]['source_hashes'],palette=palette,sd=sd,options=options,steps=20,denoise=.12,seed=1234)
                if action in ('idle','walk'):profile['cleanup_policy']='remove_small_top_fragments_and_singletons_v1'
                if sd:profile['prompt']=definition['prompt']+', '+direction+' view'
                key=hashlib.sha256(json.dumps(profile,sort_keys=True).encode()).hexdigest()
                statefile=folder/'state.json'
                state=json.loads(statefile.read_text()) if statefile.exists() else dict(key=key,done=[],cleaner=[],generation_status='pending',validation_status='pending')
                if state['key']!=key:raise ValueError('Profile changed; use a new output directory: '+str(folder))
                atomic_json(folder/'profile.json',profile)
                if sd:
                    r=review.get(character,{}).get(name,{})
                    expected=hashlib.sha256(json.dumps(sequence,sort_keys=True).encode()).hexdigest()
                    if r.get('sequence_hash')!=expected or r.get('frames')!=list(range(len(sequence['frames']))) or not r.get('reviewer') or r.get('checks')!=['biomechanics','silhouette','tool_or_object','complete_motion'] or r.get('source_hashes')!=snap[character]['source_hashes']:
                        raise ValueError('A complete pose review matching these exact source files is required: '+name)
                for i,source in enumerate(sequence['frames']):
                    if i in state['done']:continue
                    if spent>=limit:break
                    reference=load_frame(project,source);save_png(reference,folder/f'references/{i:03}.png')
                    image=reference
                    if sd:
                        rawfile=folder/f'raw/{i:03}.png'
                        if rawfile.exists():image=Image.open(rawfile).convert('RGBA')
                        else:
                            try:
                                image,info=client.generate(prompt=profile['prompt'],reference=reference,resolution=512,steps=20,denoise=.12,seed=1234,model=options.get('sd_model_checkpoint'))
                            except Exception as error:
                                state.update(generation_status='error',error=str(error));atomic_json(statefile,state)
                                raise
                            save_png(image,rawfile);atomic_json(folder/f'raw/{i:03}.json',info)
                        image=constrain_mask(image,reference)
                    frame,stats=clean_frame(image,palette,remove_top_fragments=action in ('idle','walk'))
                    if sd:frame=protect_contour(frame,process(reference,palette=palette))
                    save_png(frame,folder/f'frames/{i:03}.png');state['done'].append(i);state['cleaner'].append(stats);spent+=1
                    state.pop('error',None);state.update(generation_status='partial');atomic_json(statefile,state)
                if len(state['done'])==len(sequence['frames']):
                    frames=[Image.open(folder/f'frames/{i:03}.png').convert('RGBA') for i in range(len(sequence['frames']))]
                    meta=export(frames,folder/'export',character,action,direction,sequence['fps'],provenance=dict(mode='img2img' if sd else 'existing_reference_cleanup',source_resource=snap[character]['resource'],source_hashes=snap[character]['source_hashes'],motion_preserved=True,palette=palette,base_approved=character=='feminino',events_validated=False),durations=[f['duration'] for f in sequence['frames']],loop=sequence['loop'],allow_repeated_frames=action=='idle',origin=definition['origin'])
                    source_frames=[process(load_frame(project,f),palette=palette) for f in sequence['frames']]
                    original_alpha_preserved=all(im.getchannel('A').tobytes()==source.getchannel('A').tobytes() for im,source in zip(frames,source_frames))
                    for source,stats in zip(source_frames,state['cleaner']):
                        for xy in stats.get('removed_fragment_pixels',[]):source.putpixel(tuple(xy),(0,0,0,0))
                    source_masks=[im.getchannel('A').tobytes() for im in source_frames]
                    preserved=all(im.getchannel('A').tobytes()==mask for im,mask in zip(frames,source_masks))
                    meta['validation']['source_silhouettes_preserved']=preserved
                    meta['validation']['original_alpha_preserved']=original_alpha_preserved
                    meta['provenance']['fragment_removals']=[s.get('removed_fragment_pixels',[]) for s in state['cleaner']]
                    meta['validation']['visual_approved']=False
                    meta['events']=review.get(character,{}).get(name,{}).get('events',definition['events']) if sd else definition['events']
                    atomic_json(folder/'export/metadata.json',meta)
                    state.update(generation_status='exported_candidate',validation_status='needs_visual_review' if meta['validation']['structural_ok'] and preserved else 'needs_source_repair',validation=meta['validation'],export_path=str(folder/'export'))
                atomic_json(statefile,state)
                rows.append(dict(name=name,**state))
        atomic_json(root/f'last_batch_{character}.json',rows)
        refresh_status(root)
        return dict(processed=spent,rows=rows)
    finally:
        lock.unlink(missing_ok=True)

if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('--project',default=r'C:\FarmSlime');p.add_argument('--output',type=Path,required=True);p.add_argument('--character',choices=['feminino','masculino'],default='feminino');p.add_argument('--actions',nargs='+',default=['idle','walk']);p.add_argument('--directions',nargs='+',choices=['down','up','left','right']);p.add_argument('--limit',type=int,default=2);p.add_argument('--sd',action='store_true');p.add_argument('--pose-review',type=Path)
    a=p.parse_args();print(json.dumps(run(a.project,a.output,a.character,a.actions,a.limit,a.sd,a.pose_review,directions=a.directions),ensure_ascii=False,indent=2))
