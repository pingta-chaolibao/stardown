#!/usr/bin/env python3
"""Independently replay a constructed route with crystal/Goblin identity swaps."""
from pathlib import Path
import argparse,json
ROOT=Path(__file__).resolve().parents[1]
CRYSTALS=[*range(16,21),*range(28,33),*range(64,69),76,77,79,80]
MONSTERS=[4,8,24,42,46,53,56,61,87,90,113,115,124,126,129]
BLOCKED={3,5,6,7,9,10,11,12,*range(37,42),*range(43,46),*range(49,53),54,55,57,58,88,89,*range(91,97),*range(99,109),121}
PATH='DDRRURRDRRURDDDDDLLLLULDDDRDDRRRURRR'
DIRS={'U':(0,-1),'D':(0,1),'L':(-1,0),'R':(1,0)}
def xy(n):return ((n-1)%12,(n-1)//12)
def main():
 p=argparse.ArgumentParser(description=__doc__);p.add_argument('--write-solution',action='store_true');args=p.parse_args()
 d=json.loads((ROOT/'levels/north_25.json').read_text());floor={xy(n) for n in range(1,133) if n not in BLOCKED}
 assert d['terrain']==[''.join('.' if (x,y) in floor else '#' for x in range(12)) for y in range(11)]
 assert d['player']==[0,0] and d['hero_kind']=='blue' and d['exit']==[11,9]
 assert d['crates']==[list(xy(n)) for n in CRYSTALS] and len(CRYSTALS)==19 and len(floor)==89
 assert [(m['kind'],tuple(m['position'])) for m in d['monsters']]==[('goblin',xy(n)) for n in MONSTERS]
 assert not any(d.get(k) for k in ['energy_links','bushes','fences'])
 crystals={xy(n):i for i,n in enumerate(CRYSTALS)};monsters={xy(n):i for i,n in enumerate(MONSTERS)};hero=(0,0);swaps=0;monster_swaps=0;trace=[]
 for n,symbol in enumerate(PATH,1):
  dx,dy=DIRS[symbol];cell=(hero[0]+dx,hero[1]+dy);target=None
  while cell in floor:
   if cell in crystals:target=(cell,crystals,'crystal');break
   if cell in monsters:target=(cell,monsters,'goblin');break
   cell=(cell[0]+dx,cell[1]+dy)
  identity=None;kind='walk'
  if target:
   cell,family,kind=target;identity=family.pop(cell);family[hero]=identity;hero=cell;swaps+=1;monster_swaps+=kind=='goblin'
  else:
   cell=(hero[0]+dx,hero[1]+dy);assert cell in floor,('blocked',n,hero,symbol);hero=cell
  assert not any(abs(hero[0]-m[0])+abs(hero[1]-m[1])==1 for m in monsters),('dead',n,hero)
  assert (hero==(11,9))==(n==len(PATH))
  trace.append({'action':n,'input':symbol,'hero':hero,'kind':kind,'target_id':identity,'swaps':swaps,'monster_swaps':monster_swaps,'crystals':[{'id':i,'position':c} for c,i in sorted(crystals.items(),key=lambda p:p[1])],'monsters':[{'id':i,'kind':'goblin','position':c,'alive':True} for c,i in sorted(monsters.items(),key=lambda p:p[1])]})
 assert swaps==17 and monster_swaps==5 and len(monsters)==15 and len(crystals)==19
 solution={'level_id':d['id'],'path':PATH,'moves':len(PATH),'directions':len(PATH),'input_events':len(PATH),'selection_events':0,'pushes':0,'pulls':0,'swaps':swaps,'destroyed_crystals':0,'monster_swaps':monster_swaps,'note':'构造合法路线后独立按身份逐输入复算：蓝方向首目标被动交换，否则一步；17交换含5哥布林/12水晶。无搜索最短或穷尽声明，不修改用户确认地图/死亡/视线规则。'}
 dest=ROOT/'levels/solutions/north_25.json'
 if args.write_solution:dest.write_text(json.dumps(solution,ensure_ascii=False,indent=2)+'\n')
 else:assert json.loads(dest.read_text())==solution
 proof={'method':'Constructed legal route,independent identity-aware replay;not shortest/exhaustive search','floor':len(floor),'blocked':len(BLOCKED),'solution':solution,'trace':trace}
 out=ROOT/'artifacts/verification/north_25_route.json';out.parent.mkdir(parents=True,exist_ok=True);out.write_text(json.dumps(proof,ensure_ascii=False,indent=2)+'\n')
 print('NORTH 25 INDEPENDENT RESULT: '+json.dumps(solution,ensure_ascii=False))
if __name__=='__main__':main()
