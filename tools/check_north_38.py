"""Independent stable-identity normal-input replay of confirmed purple pressure level38."""
from pathlib import Path
D={'U':(0,-1),'D':(0,1),'L':(-1,0),'R':(1,0)}
T=['.........######']*4+['...............']+['....#....######']*3
F={(x,y) for y,row in enumerate(T) for x,c in enumerate(row) if c=='.'}
PLATE=(1,0);ENERGY={(13,4),(0,5),(1,5),(2,5),(3,5)};GOAL=(2,7)
INITIAL=((6,7),((1,0),(3,1),(0,3),(8,4),(10,4),(12,4),(14,4)),127)
def add(a,b):return a[0]+b[0],a[1]+b[1]
def dist(a,b):return abs(a[0]-b[0])+abs(a[1]-b[1])
def active(h,ms,a):return not(h==PLATE or any(a>>i&1 and ms[i]==PLATE for i in range(6)))
def step(s,k):
 h,oldms,a=s;ms=list(oldms);d=D[k];old_e=active(h,ms,a);q=add(h,d);target=None
 while q in F and not(old_e and q in ENERGY):
  target=next((i for i,p in enumerate(ms) if a>>i&1 and p==q),None)
  if target is not None:break
  q=add(q,d)
 if target is not None:ms[target]=h;h=q
 else:
  q=add(h,d)
  if q not in F or (old_e and q in ENERGY):return None
  h=q
 if a>>6&1 and ms[6]==PLATE:return None # confirmed guard:dragon pressure remains undefined
 e=active(h,ms,a);dead=False;reason='';energy_victims=[]
 if e and not old_e:
  if h in ENERGY:dead=True;reason='energy'
  for i in range(7):
   if a>>i&1 and ms[i] in ENERGY:a&=~(1<<i);energy_victims.append(i)
 attack_alive=a;fire=[];strikes=[];victims=set();hero_monster=False;hero_fire=False
 for i in range(6):
  if not(a>>i&1):continue
  if not dead and dist(ms[i],h)==1:hero_monster=True;strikes.append({'from':ms[i],'to':h,'hero':0})
  for j in range(7):
   if j!=i and a>>j&1 and dist(ms[i],ms[j])==1:victims.add(j);strikes.append({'from':ms[i],'to':ms[j],'monster':j})
 if a>>6&1:
  q=add(ms[6],(-1,0));ray=[]
  while q in F and not(e and q in ENERGY):
   ray.append(q)
   if not dead and q==h:hero_fire=True;fire.append({'from':ms[6],'cells':ray.copy(),'target':{'kind':'hero','id':0}});break
   j=next((i for i,p in enumerate(ms) if a>>i&1 and p==q),None)
   if j is not None:victims.add(j);fire.append({'from':ms[6],'cells':ray.copy(),'target':{'kind':'monster','id':j}});break
   q=add(q,(-1,0))
 for i in victims:a&=~(1<<i)
 if hero_monster:dead=True;reason='monster'
 if hero_fire:dead=True;reason='fire'
 final_e=active(h,ms,a)
 if final_e and not e:
  if h in ENERGY:dead=True;reason=reason or 'energy'
  for i in range(7):
   if a>>i&1 and ms[i] in ENERGY:a&=~(1<<i);energy_victims.append(i)
 return {'state':(h,tuple(ms),a),'swap':target,'dead':dead,'reason':reason,'fire':fire,'goblin':strikes,'attack_alive':attack_alive,'attack_energy':e,'energy_victims':energy_victims,'victims':sorted(victims),'active':final_e}

ROOT=Path(__file__).resolve().parents[1]
PATH='UUUUUUULDRDDLDRURRUDDURDDDDLULLDDDDR'

def verify(write=False):
 import json
 d=json.loads((ROOT/'levels/north_38.json').read_text());assert d['terrain']==T and d['player']==[6,7] and d['hero_kind']=='blue' and d['swap_hero_color']=='purple' and d['crates']==[] and d['exit']==[2,7] and d['mechanism_color']=='purple'
 assert not d.get('energy_blocks') and not d.get('bushes') and not d.get('fences')
 link=d['energy_links'][0];assert link['id']=='purple_01' and link['plates']==[[1,0]] and set(map(tuple,link['barriers']))==ENERGY and link['activation']=='all'
 assert d['monsters']==[{'kind':'goblin','position':list(p)} for p in INITIAL[1][:6]]+[{'kind':'fire_dragon','position':[14,4],'facing':'left'}]
 mapping=json.loads((ROOT/'levels/mappings/north_38_markers.json').read_text())['marker_to_runtime_cell'];expect={str(i+1):[x,y] for i,(x,y) in enumerate(( (x,y) for y,row in enumerate(T) for x,c in enumerate(row) if c=='.'))};assert mapping==expect and len(mapping)==75 and mapping['41']==[4,4]
 s=INITIAL;trace=[];swaps=0;fatal={};pressure_changes=[];previous=active(*s);fire_actions=[];goblin_actions=[];blocked_side=None
 for n,k in enumerate(PATH,1):
  for bad in D:
   z=step(s,bad)
   if z and z['dead']:fatal.setdefault(z['reason'],{'prefix':PATH[:n-1],'direction':bad})
   if not z and add(s[0],D[bad]) in ENERGY and active(*s):blocked_side=blocked_side or {'prefix':PATH[:n-1],'direction':bad,'player':s[0]}
  z=step(s,k);assert z and not z['dead'],(n,k,s,z);s=z['state'];h,ms,a=s;swaps+=z['swap'] is not None
  if z['active']!=previous:pressure_changes.append(n)
  if z['fire']:fire_actions.append(n)
  if z['goblin']:goblin_actions.append(n)
  assert (h==GOAL)==(n==len(PATH))
  trace.append({'action':n,'input':k,'player':h,'monsters':ms,'monster_alive':[bool(a>>i&1) for i in range(7)],'swaps':swaps,'barrier_active':z['active'],'pressure_active':not z['active'],'target':z['swap'],'fire':z['fire'],'goblin':z['goblin'],'energy_victims':z['energy_victims'],'attack_victims':z['victims'],'attack_monster_alive':[bool(z['attack_alive']>>i&1) for i in range(7)],'attack_energy':z['attack_energy'],'completed':h==GOAL})
  previous=z['active']
 assert len(PATH)==36 and swaps==10 and s[2]==66 and s[1][1]==PLATE and not active(*s) and fire_actions==[1,2,3,31,32] and not goblin_actions and pressure_changes==[9,31]
 assert blocked_side and fatal
 sol={'level_id':d['id'],'path':PATH,'moves':len(PATH),'directions':len(PATH),'input_events':len(PATH),'selection_events':0,'pushes':0,'pulls':0,'swaps':swaps,'destroyed_crystals':0,'pressure_energy_changes_actions':pressure_changes,'fire_attack_actions':fire_actions,'surviving_monsters':2,'note':'用户确认15×8、41可走、紫压板不是清怪能量。独立稳定身份逐输入回放；36行动10交换，最终活哥布林压板保持能量消失，仍有两怪存活。非最短路径声明。'}
 p=ROOT/'levels/solutions/north_38.json'
 if write:p.write_text(json.dumps(sol,ensure_ascii=False,indent=2)+'\n')
 else:assert json.loads(p.read_text())==sol
 report={'solution':sol,'trace':trace,'fatal_sides':fatal,'energy_blocked_side':blocked_side,'final_player':s[0],'final_monsters':s[1],'final_monster_alive':[bool(s[2]>>i&1) for i in range(7)],'initial_Goblin_holds_plate':True,'not_a_clear_monsters_gate':True}
 p=ROOT/'artifacts/verification/north_38_route.json';p.parent.mkdir(exist_ok=True);p.write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n');print('NORTH38 INDEPENDENT RESULT:',json.dumps({k:v for k,v in report.items() if k!='trace'},ensure_ascii=False));return report
if __name__=='__main__':
 import argparse
 p=argparse.ArgumentParser();p.add_argument('--write-solution',action='store_true');verify(p.parse_args().write_solution)
