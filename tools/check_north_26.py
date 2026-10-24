#!/usr/bin/env python3
"""Independent legal route with mixed pushes and single-target fire; no shortest claim."""
import json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
TERRAIN=['#..........','#..........','...........','#.....#....','#.....#....','#.....##.##','#.....#....','###.###....']
PATH='LLUUUURULLLLLULLUL'
DIRS={'U':(0,-1),'D':(0,1),'L':(-1,0),'R':(1,0)}
def plus(a,b):return a[0]+b[0],a[1]+b[1]
def verify():
 d=json.loads((ROOT/'levels/north_26.json').read_text());s=json.loads((ROOT/'levels/solutions/north_26.json').read_text())
 assert d['terrain']==TERRAIN and d['player']==[10,7] and d['exit']==[1,0] and d['crates']==[[8,6]]
 assert [(m['kind'],m['position'],m.get('facing')) for m in d['monsters']]==[('fire_dragon',[0,2],'right'),('fire_dragon',[3,7],'up'),('goblin',[8,5],None)]
 assert not any(d.get(k) for k in ['energy_links','bushes','fences']) and s['path']==PATH
 floor={(x,y) for y,row in enumerate(TERRAIN) for x,c in enumerate(row) if c=='.'}
 hero=(10,7);crystal=(8,6);positions=[(0,2),(3,7),(8,5)];living=[True]*3;pushes=0;trace=[]
 for n,key in enumerate(PATH,1):
  delta=DIRS[key];next_cell=plus(hero,delta);chain=[];end=next_cell
  while end==crystal or any(living[i] and p==end for i,p in enumerate(positions)):
   chain.append(end);end=plus(end,delta)
  assert end in floor and next_cell in floor,('illegal move',n)
  for cell in reversed(chain):
   if cell==crystal:crystal=plus(cell,delta)
   else:positions[next(i for i,p in enumerate(positions) if living[i] and p==cell)]=plus(cell,delta)
  hero=next_cell;pushes+=bool(chain);victims=[]
  # Two fixed-direction dragons sample their first target once, never pierce.
  for dragon,delta in [(0,(1,0)),(1,(0,-1))]:
   if not living[dragon]:continue
   c=plus(positions[dragon],delta)
   while c in floor and c!=crystal:
    assert c!=hero,('fire death',n,hero)
    targets=[i for i,p in enumerate(positions) if i!=dragon and living[i] and p==c]
    if targets:victims.append(targets[0]);break
    c=plus(c,delta)
  assert not any(i<2 for i in victims),'Route must not depend on unspecified mutual-dragon ordering'
  # Never a fire-vs-Goblin conflict on this route, even at action5.
  assert not any(living[i] and i==2 and abs(hero[0]-p[0])+abs(hero[1]-p[1])==1 for i,p in enumerate(positions)),('Goblin danger',n)
  for i in victims:living[i]=False
  assert (hero==(1,0))==(n==len(PATH))
  trace.append({'action':n,'input':key,'hero':hero,'crystal':crystal,'monster_positions':positions.copy(),'monster_alive':living.copy(),'victims':victims,'pushes':pushes})
 assert pushes==9 and living==[True,True,False] and crystal==(3,2)
 assert [t['action'] for t in trace if t['victims']]==[5]
 assert (s['moves'],s['pushes'],s['pulls'],s['swaps'])==(18,9,0,0)
 proof={'method':'Constructed legal route, independent action/fire replay; not shortest/exhaustive','solution':s,'trace':trace}
 out=ROOT/'artifacts/verification/north_26_route.json';out.parent.mkdir(parents=True,exist_ok=True);out.write_text(json.dumps(proof,ensure_ascii=False,indent=2)+'\n')
 print('NORTH 26 INDEPENDENT RESULT: 18 legal actions,9 pushes,Goblin killed at5,2 dragons survive; no ordering assumption')
 return proof
if __name__=='__main__':verify()
