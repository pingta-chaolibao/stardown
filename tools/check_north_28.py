#!/usr/bin/env python3
"""Independent constructed route:crystal shields fire,green single crystal/dragon pulls."""
import json,argparse
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
TERRAIN=['...#...','.......','...#...','#####..','#......','.......','#......']
PATH='RLDDRRU'+'RRRR'+'ULLDU'+'RRDDL'+'DDDD'+'LUUL'+'RRR'+'DDLLULL'+'URR'+'DDLLLUL'
DIRS={'U':(0,-1),'D':(0,1),'L':(-1,0),'R':(1,0)}
def plus(a,b):return a[0]+b[0],a[1]+b[1]
def verify(write=False):
 d=json.load(open(ROOT/'levels/north_28.json'));assert d['terrain']==TERRAIN and d['player']==[0,0] and d['crates']==[[1,1]] and d['exit']==[0,5] and d['hero_kind']=='green'
 assert [(m['kind'],m['position'],m['facing']) for m in d['monsters']]==[('fire_dragon',[2,0],'down'),('fire_dragon',[4,2],'right'),('fire_dragon',[1,4],'down'),('fire_dragon',[2,4],'down')]
 assert not any(d.get(k) for k in ['bushes','fences','energy_links'])
 floor={(x,y) for y,row in enumerate(TERRAIN) for x,c in enumerate(row) if c=='.'};assert len(floor)==40 and (6,0) in floor and (0,6) not in floor
 hero=(0,0);crystal=(1,1);positions=[(2,0),(4,2),(1,4),(2,4)];facings=[(0,1),(1,0),(0,1),(0,1)];living=[True]*4;pulls=0;dragon_pulls=0;crystal_pulls=0;trace=[]
 for n,key in enumerate(PATH,1):
  delta=DIRS[key];target=plus(hero,delta);assert target in floor and target!=crystal and not any(alive and target==p for alive,p in zip(living,positions)),('blocked',n,hero,key)
  behind=(hero[0]-delta[0],hero[1]-delta[1]);pulled=None
  if behind==crystal:crystal=hero;pulls+=1;crystal_pulls+=1;pulled='crystal'
  else:
   for i,p in enumerate(positions):
    if living[i] and p==behind:positions[i]=hero;pulls+=1;dragon_pulls+=1;pulled=i;break
  hero=target;victims=set();dead=False
  for i,p in enumerate(positions):
   if not living[i]:continue
   c=plus(p,facings[i])
   while c in floor and c!=crystal:
    if c==hero:dead=True;break
    j=next((j for j,p in enumerate(positions) if j!=i and living[j] and c==p),None)
    if j is not None:victims.add(j);break
    c=plus(c,facings[i])
  assert not dead,('firedeath',n,hero,key)
  for i in victims:living[i]=False
  assert (hero==(0,5))==(n==len(PATH)),('prematurevictory',n)
  trace.append({'action':n,'input':key,'hero':hero,'crystal':crystal,'monsters':positions.copy(),'monster_alive':living.copy(),'pulls':pulls,'dragon_pulls':dragon_pulls,'crystal_pulls':crystal_pulls,'pulled':pulled,'victims':sorted(victims)})
 assert all(living) and dragon_pulls==7 and crystal_pulls==10 and pulls==17
 sol={'level_id':d['id'],'path':PATH,'moves':len(PATH),'directions':len(PATH),'input_events':len(PATH),'selection_events':0,'pushes':0,'pulls':pulls,'dragon_pulls':dragon_pulls,'crystal_pulls':crystal_pulls,'swaps':0,'destroyed_crystals':0,'note':'构造合法路线并独立逐步复算：先拉3号龙左移，用水晶挡住其与19号龙火线；水晶下移后拉31号龙右移，水晶左移挡住30号龙移位后的火焰，再从下方绕到目标。7号可走、43岩石保持。无需新机制，无最短/穷尽搜索声明。'}
 p=ROOT/'levels/solutions/north_28.json'
 if write:p.write_text(json.dumps(sol,ensure_ascii=False,indent=2)+'\n')
 else:assert json.load(open(p))==sol
 out=ROOT/'artifacts/verification/north_28_route.json';out.parent.mkdir(exist_ok=True);out.write_text(json.dumps({'method':'constructed route,independent stable-identity automatic single pull and simultaneous-fire replay;not shortest/exhaustive','solution':sol,'trace':trace},ensure_ascii=False,indent=2)+'\n')
 print('NORTH28 INDEPENDENT RESULT:',len(PATH),'livingactions,17pulls(7dragon/10crystal),all4dragonsalive,crystalpreserved;40floors9walls')
 print('PULL EVENTS:',[(t['action'],t['pulled']) for t in trace if t['pulled'] is not None])
 return trace
if __name__=='__main__':
 p=argparse.ArgumentParser();p.add_argument('--write-solution',action='store_true');verify(p.parse_args().write_solution)
