#!/usr/bin/env python3
"""Independently validate confirmed perimeter and a constructed single-dragon-pull route."""
from pathlib import Path
import json,argparse
ROOT=Path(__file__).resolve().parents[1]
PATH='D'+'R'*9+'DD'+'L'*9+'DD'+'R'*9+'DDLD'+'RUU'+'L'*8+'UDLUU'+'R'*8+'UDRUU'+'L'*9
DIRECTIONS={'U':(0,-1),'D':(0,1),'L':(-1,0),'R':(1,0)}
def plus(a,b):return a[0]+b[0],a[1]+b[1]
def verify(write=False):
 d=json.load(open(ROOT/'levels/north_27.json'));mapping=json.load(open(ROOT/'levels/mappings/north_27_markers.json'))
 old={(x,y) for y in range(8) for x in range(9) if y or x<3};extra={(9,y) for y in range(1,8)}|{(-1,y) for y in range(9)}|{(-2,7),(-2,8),(0,8),(8,8),(9,8)};floor={(x+2,y) for x,y in old|extra}
 assert d['terrain']==[''.join('.' if (x,y) in floor else '#' for x in range(12)) for y in range(9)]
 assert len(floor)==87 and (11,0) not in floor and (10,0) not in floor
 assert d['player']==[2,0] and d['exit']==[2,2] and not any(d.get(k) for k in ['crates','energy_links','fences','bushes'])
 assert [(m['kind'],m['position'],m['facing']) for m in d['monsters']]==[('fire_dragon',[10,2],'left'),('fire_dragon',[3,4],'right'),('fire_dragon',[10,6],'left')]
 assert len(mapping['markers'])==93 and mapping['normalization_offset']==[2,0]
 for m in mapping['markers']:
  x,y=m['original'];assert m['position']==[x+2,y] and m['walkable']==((x+2,y) in floor)
  if m['number']<=72:assert (x,y)==((m['number']-1)%9,(m['number']-1)//9)
 hero=(2,0);dragons=[(10,2),(3,4),(10,6)];facing=[(-1,0),(1,0),(-1,0)];living=[True]*3;pulls=0;trace=[]
 for n,s in enumerate(PATH,1):
  delta=DIRECTIONS[s];dest=plus(hero,delta);assert dest in floor and not any(alive and pos==dest for alive,pos in zip(living,dragons)),('blocked',n,hero,s)
  behind=(hero[0]-delta[0],hero[1]-delta[1]);pulled=None
  for i,pos in enumerate(dragons):
   if living[i] and pos==behind:dragons[i]=hero;pulled=i;pulls+=1;break
  hero=dest;victims=set();hero_dead=False
  for i,pos in enumerate(dragons):
   if not living[i]:continue
   c=plus(pos,facing[i])
   while c in floor:
    if c==hero:hero_dead=True;break
    j=next((j for j,other in enumerate(dragons) if j!=i and living[j] and other==c),None)
    if j is not None:victims.add(j);break
    c=plus(c,facing[i])
  assert not hero_dead,('firedeath',n,hero,s)
  for i in victims:living[i]=False
  assert (hero==(2,2))==(n==len(PATH)),('prematurevictory',n)
  trace.append({'action':n,'input':s,'hero':hero,'positions':dragons.copy(),'alive':living.copy(),'pulls':pulls,'pulled_dragon':pulled,'victims':sorted(victims)})
 assert len(PATH)==74 and pulls==3 and living==[True,True,True] and dragons==[(10,3),(3,5),(10,7)]
 assert [(t['action'],t['pulled_dragon']) for t in trace if t['pulled_dragon'] is not None]==[(36,2),(49,1),(62,0)]
 sol={'level_id':d['id'],'path':PATH,'moves':74,'directions':74,'input_events':74,'selection_events':0,'pushes':0,'pulls':3,'dragon_pulls':3,'swaps':0,'destroyed_crystals':0,'note':'完整外围修订确认后构造合法路线，74方向/3拉龙，依次63/38/27向下各拉一格（36/49/62步），三龙存活朝向不变。全部x统一+2，保留1–93编号映射；无最短或穷尽搜索声明。'}
 path=ROOT/'levels/solutions/north_27.json'
 if write:path.write_text(json.dumps(sol,ensure_ascii=False,indent=2)+'\n')
 else:assert json.load(open(path))==sol
 out=ROOT/'artifacts/verification/north_27_route.json';out.parent.mkdir(exist_ok=True);out.write_text(json.dumps({'method':'constructed legal route;independent identity-aware simultaneous-fire replay,not shortest/exhaustive','solution':sol,'trace':trace},ensure_ascii=False,indent=2)+'\n')
 print('NORTH27 INDEPENDENT RESULT: 74 legal actions,3single dragon pulls at36/49/62,all3alive;87floors/15void/6walls,93markers uniformly translated')
 return trace
if __name__=='__main__':
 p=argparse.ArgumentParser();p.add_argument('--write-solution',action='store_true');verify(p.parse_args().write_solution)
