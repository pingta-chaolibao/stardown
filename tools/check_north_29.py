#!/usr/bin/env python3
"""Constructed level29 route;independent automatic pulls and simultaneous fire."""
from pathlib import Path
import json,argparse
ROOT=Path(__file__).resolve().parents[1]
TERRAIN=['#..#######','#..#######','#.......##','#.......##','#.......##','#######.##','..........','...#......','##........']
PATH='RRDRRRLLLUURRDDRRRRURULLDLURUUUULDLLURRDDLLULURLDDLRRRURULLLLUUL'
DIRS={'U':(0,-1),'D':(0,1),'L':(-1,0),'R':(1,0)}
def plus(a,b):return a[0]+b[0],a[1]+b[1]
def verify(write=False):
 d=json.load(open(ROOT/'levels/north_29.json'));assert d['terrain']==TERRAIN and d['player']==[0,7] and d['hero_kind']=='green' and d['crates']==[[7,7]] and d['exit']==[1,0]
 assert [(m['kind'],m['position'],m['facing']) for m in d['monsters']]==[('fire_dragon',[3,2],'down'),('fire_dragon',[1,4],'up'),('fire_dragon',[7,5],'down'),('fire_dragon',[6,8],'up')]
 assert not any(d.get(k) for k in ['bushes','fences','energy_links'])
 floor={(x,y) for y,row in enumerate(TERRAIN) for x,c in enumerate(row) if c=='.'};assert len(floor)==53 and (3,7) not in floor
 hero=(0,7);crystal=(7,7);positions=[(3,2),(1,4),(7,5),(6,8)];facings=[(0,1),(0,-1),(0,1),(0,-1)];living=[True]*4;pulls=dragon_pulls=crystal_pulls=0;trace=[]
 for n,key in enumerate(PATH,1):
  delta=DIRS[key];target=plus(hero,delta);assert target in floor and target!=crystal and not any(a and target==p for a,p in zip(living,positions)),('blocked',n,hero,key)
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
    j=next((j for j,p2 in enumerate(positions) if j!=i and living[j] and c==p2),None)
    if j is not None:victims.add(j);break
    c=plus(c,facings[i])
  assert not dead,('firedeath',n,hero,key)
  for i in victims:living[i]=False
  assert (hero==(1,0))==(n==len(PATH)),('prematurevictory',n)
  trace.append({'action':n,'input':key,'hero':hero,'crystal':crystal,'monsters':positions.copy(),'monster_alive':living.copy(),'pulls':pulls,'dragon_pulls':dragon_pulls,'crystal_pulls':crystal_pulls,'pulled':pulled,'victims':sorted(victims)})
 assert len(PATH)==64 and pulls==23 and dragon_pulls==13 and crystal_pulls==10 and not any(living) and crystal==(5,3)
 assert [(t['action'],t['victims']) for t in trace if t['victims']]==[(21,[2,3]),(56,[0,1])]
 sol={'level_id':d['id'],'path':PATH,'moves':64,'directions':64,'input_events':64,'selection_events':0,'pushes':0,'pulls':23,'dragon_pulls':13,'crystal_pulls':10,'swaps':0,'destroyed_crystals':0,'note':'构造合法路线并独立逐步复算，不声称最短。先向左拉87号龙绕过74号墙，再借78号水晶挡火将87号龙拉至58号正下方；21步移走水晶触发上下互射。水晶上运后遮挡24号火焰，移动42号龙至下方；56步移开水晶触发第二对互射，64步抵达目标。四龙均死亡、水晶保留，朝向从未改变。'}
 p=ROOT/'levels/solutions/north_29.json'
 if write:p.write_text(json.dumps(sol,ensure_ascii=False,indent=2)+'\n')
 else:assert json.load(open(p))==sol
 out=ROOT/'artifacts/verification/north_29_route.json';out.parent.mkdir(exist_ok=True);out.write_text(json.dumps({'method':'constructed identity-aware independent single pull and common-state fire replay;not shortest/exhaustive','solution':sol,'trace':trace},ensure_ascii=False,indent=2)+'\n')
 print('NORTH29 INDEPENDENT RESULT:64livingactions,23pulls(13dragon/10crystal),mutualpairsat21/56,53floors,74wall')
 return trace
if __name__=='__main__':
 parser=argparse.ArgumentParser();parser.add_argument('--write-solution',action='store_true');verify(parser.parse_args().write_solution)
