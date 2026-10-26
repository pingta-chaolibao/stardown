"""Independent identity-preserving replay of the confirmed 37th map."""
from pathlib import Path
from collections import deque
import argparse,json
ROOT=Path(__file__).resolve().parents[1]
TERRAIN=['........####','........####','........#...','............','........#...','........####','........####']
PATH='LLLLDDDRRRDDDRRRUURULLLLDDLLLUUURRRDRRRRRRR'
DIRS={'U':(0,-1),'D':(0,1),'L':(-1,0),'R':(1,0)};GATE=(8,3);GOAL=(10,3)
def plus(a,b):return a[0]+b[0],a[1]+b[1]
def floor(c):return 0<=c[0]<12 and 0<=c[1]<7 and TERRAIN[c[1]][c[0]]=='.'
def distance(a,b):return abs(a[0]-b[0])+abs(a[1]-b[1])
def step(state,key):
 hero,crystals,monsters,alive=state;d=DIRS[key];dest=plus(hero,d);objects={c:('c',i) for i,c in enumerate(crystals)};objects.update({c:('m',i) for i,c in enumerate(monsters) if alive[i]});chain=[];end=dest
 while end in objects:chain.append(objects[end]);end=plus(end,d)
 if not floor(end) or any(alive) and end==GATE:return None
 cs=crystals.copy();ms=monsters.copy()
 for kind,i in chain:
  cells=cs if kind=='c' else ms;cells[i]=plus(cells[i],d)
 victims=set();dead=False;fire=[];goblin=[]
 for i in range(1,4):
  if not alive[i]:continue
  if distance(ms[i],dest)==1:dead=True;goblin.append({'from_id':i,'from':ms[i],'to':dest,'hero':0})
  for j in range(4):
   if j!=i and alive[j] and distance(ms[i],ms[j])==1:victims.add(j);goblin.append({'from_id':i,'from':ms[i],'to':ms[j],'monster':j})
 if alive[0]:
  c=plus(ms[0],(1,0));ray=[]
  while floor(c) and c not in cs and not(any(alive) and c==GATE):
   ray.append(c)
   if c==dest:dead=True;fire.append({'dragon':0,'target_kind':'hero','target_id':0,'from':ms[0],'to':c,'cells':ray.copy()});break
   target=next((i for i in range(1,4) if alive[i] and c==ms[i]),None)
   if target is not None:victims.add(target);fire.append({'dragon':0,'target_kind':'monster','target_id':target,'from':ms[0],'to':c,'cells':ray.copy()});break
   c=plus(c,(1,0))
 return {'state':(dest,cs,ms,[a and i not in victims for i,a in enumerate(alive)]),'pushed':bool(chain),'push_chain':chain,'hero_dead':dead,'victims':sorted(victims),'fire':fire,'goblin':goblin}
def verify(write=False):
 d=json.loads((ROOT/'levels/north_37.json').read_text());assert d['terrain']==TERRAIN and d['player']==[4,0] and d['hero_kind']=='red' and d['crates']==[[2,4],[6,5]] and d['exit']==[10,3]
 assert d['monsters']==[{'kind':'fire_dragon','position':[0,1],'facing':'right'},{'kind':'goblin','position':[4,2]},{'kind':'goblin','position':[3,3]},{'kind':'goblin','position':[5,3]}]
 assert d['energy_blocks']==[{'kind':'all_monsters_defeated','position':[8,3]}] and not any(d.get(k) for k in ['energy_links','bushes','fences'])
 m=json.loads((ROOT/'levels/mappings/north_37_markers.json').read_text())['marker_to_runtime_cell'];cells=[(x,y) for y,row in enumerate(TERRAIN) for x,c in enumerate(row) if c=='.' and not(y==4 and x>=9)];expected={str(i+1):list(c) for i,c in enumerate(cells)};expected.update({str(64+i):[9+i,4] for i in range(3)});assert m==expected and len(m)==66
 state=((4,0),[(2,4),(6,5)],[(0,1),(4,2),(3,3),(5,3)],[True]*4);trace=[];pushes=0;attacks=[];fatals={};gate_prefix=None
 for n,k in enumerate(PATH,1):
  for bad in DIRS:
   z=step(state,bad)
   if z and z['hero_dead']:
    reason='fire' if any(a['target_kind']=='hero' for a in z['fire']) else 'monster'
    fatals.setdefault(reason,{'prefix':PATH[:n-1],'direction':bad,'reason':reason})
  z=step(state,k);assert z and not z['hero_dead'],('illegal',n,k,state);state=z['state'];h,cs,ms,alive=state;pushes+=z['pushed']
  if z['fire'] or z['goblin']:attacks.append(n)
  assert (h==GOAL)==(n==len(PATH)),('prematuregoal',n)
  if gate_prefix is None and any(alive):
   q=deque([(state,'')]);seen={(h,tuple(alive))}
   while q:
    s,tail=q.popleft()
    if s[0]==(7,3) and any(s[3]):gate_prefix=PATH[:n]+tail;break
    for key in DIRS:
     w=step(s,key)
     if w and not w['hero_dead'] and not w['pushed']:
      v=w['state'];pk=(v[0],tuple(v[3]))
      if pk not in seen:seen.add(pk);q.append((v,tail+key))
  trace.append({'action':n,'input':k,'player':h,'crystals':cs.copy(),'monsters':ms.copy(),'monster_alive':alive.copy(),'pushes':pushes,'fire':z['fire'],'goblin':z['goblin'],'victims':z['victims'],'barrier_active':any(alive),'completed':h==GOAL,'pushed_chain':z['push_chain']})
 assert not any(state[3]) and fatals and gate_prefix
 death_actions=[row['action'] for row in trace if row['victims']];clear=next(row['action'] for row in trace if not row['barrier_active']);cross=next(row['action'] for row in trace if tuple(row['player'])==GATE)
 sol={'level_id':d['id'],'path':PATH,'moves':len(PATH),'directions':len(PATH),'input_events':len(PATH),'selection_events':0,'pushes':pushes,'pulls':0,'swaps':0,'destroyed_crystals':0,'monster_death_actions':death_actions,'all_monsters_dead_action':clear,'gate_traversal_action':cross,'note':'用户确认12×7，右室下补64–66，其余原编号不变。独立稳定身份逐方向重放，混合链推/共同状态攻击/全怪死亡红门沿用既有规则，不宣称最短方向路线。'}
 p=ROOT/'levels/solutions/north_37.json'
 if write:p.write_text(json.dumps(sol,ensure_ascii=False,indent=2)+'\n')
 else:assert json.loads(p.read_text())==sol
 report={'solution':sol,'trace':trace,'fatal_sides':fatals,'gate_block_prefix':gate_prefix,'attack_actions':attacks,'final_player':state[0],'final_crystals':state[1],'final_monsters':state[2]};p=ROOT/'artifacts/verification/north_37_route.json';p.parent.mkdir(exist_ok=True);p.write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n');print('NORTH37 INDEPENDENT RESULT:',json.dumps({k:v for k,v in report.items() if k!='trace'},ensure_ascii=False));return report
if __name__=='__main__':
 p=argparse.ArgumentParser();p.add_argument('--write-solution',action='store_true');verify(p.parse_args().write_solution)
