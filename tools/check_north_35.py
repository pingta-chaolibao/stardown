"""Independent replay of final user-confirmed12x7 with preserved66marker IDs."""
from pathlib import Path
import json,argparse
from collections import deque
ROOT=Path(__file__).resolve().parents[1]
TERRAIN=['........####','........####','............','........#...','........#...','........####','........####']
PATH='DRUUURUUULLDLLDURRDRRRURDDRDLLLLUULLLDURRRRRRRRRDR'
DIRS={'U':(0,-1),'D':(0,1),'L':(-1,0),'R':(1,0)};GATE=(8,2);GOAL=(10,3)
def plus(a,b):return a[0]+b[0],a[1]+b[1]
def floor(c):return 0<=c[0]<12 and 0<=c[1]<7 and TERRAIN[c[1]][c[0]]=='.'
def distance(a,b):return abs(a[0]-b[0])+abs(a[1]-b[1])
def step(state,key):
 hero,crystals,monsters,alive=state;d=DIRS[key];next_cell=plus(hero,d);objects={p:('c',i) for i,p in enumerate(crystals)};objects.update({p:('m',i) for i,p in enumerate(monsters) if alive[i]});chain=[];end=next_cell
 while end in objects:chain.append(objects[end]);end=plus(end,d)
 if not floor(end) or (any(alive) and end==GATE):return None
 cs=crystals.copy();ms=monsters.copy()
 for family,i in chain:
  cells=cs if family=='c' else ms;cells[i]=plus(cells[i],d)
 victims=set();dead=False;fire=[];goblin=[]
 if alive[1]:
  if distance(ms[1],next_cell)==1:dead=True;goblin.append({'from':ms[1],'to':next_cell,'target':'hero'})
  if alive[0] and distance(ms[1],ms[0])==1:victims.add(0);goblin.append({'from':ms[1],'to':ms[0],'target':'monster0'})
 if alive[0]:
  c=plus(ms[0],(1,0));ray=[]
  while floor(c) and c not in cs and not(any(alive) and c==GATE):
   ray.append(c)
   if c==next_cell:dead=True;fire.append({'dragon':0,'target_kind':'hero','target_id':0,'from':ms[0],'to':c,'cells':ray.copy()});break
   if alive[1] and c==ms[1]:victims.add(1);fire.append({'dragon':0,'target_kind':'monster','target_id':1,'from':ms[0],'to':c,'cells':ray.copy()});break
   c=plus(c,(1,0))
 return {'state':(next_cell,cs,ms,[a and i not in victims for i,a in enumerate(alive)]),'pushed':bool(chain),'hero_dead':dead,'victims':sorted(victims),'fire':fire,'goblin':goblin}
def verify(write=False):
 d=json.loads((ROOT/'levels/north_35.json').read_text());assert d['terrain']==TERRAIN and d['player']==[2,5] and d['hero_kind']=='red' and d['crates']==[[2,1],[3,5]] and d['exit']==[10,3]
 assert d['monsters']==[{'kind':'fire_dragon','position':[0,2],'facing':'right'},{'kind':'goblin','position':[5,4]}]
 assert d['energy_blocks']==[{'kind':'all_monsters_defeated','position':[8,2]}] and d['mechanism_color']=='red'
 assert not any(d.get(k) for k in ['energy_links','bushes','fences'])
 assert set(map(tuple,d['void_cells']))=={(x,y) for y,row in enumerate(TERRAIN) for x,c in enumerate(row) if c=='#'}
 m=json.loads((ROOT/'levels/mappings/north_35_markers.json').read_text())['marker_to_runtime_cell'];old=[(x,0) for x in range(8)]+[(x,1) for x in range(12)]+[(x,2) for x in range(8)]+[(x,2) for x in range(9,12)]+[(x,y) for y in range(3,6) for x in range(8)]+[(x,3) for x in range(9,12)]
 expected={str(i+1):[x,y+1] for i,(x,y) in enumerate(old)};expected.update({str(59+x):[x,0] for x in range(8)});assert m==expected and len(m)==66 and set(map(tuple,m.values()))=={(x,y) for y,row in enumerate(TERRAIN) for x,c in enumerate(row) if c=='.'}
 state=((2,5),[(2,1),(3,5)],[(0,2),(5,4)],[True,True]);pushes=0;trace=[];attacks=[];fatal=None;gate_prefix=None
 for n,key in enumerate(PATH,1):
  if fatal is None:
   for bad in DIRS:
    branch=step(state,bad)
    if branch and branch['hero_dead']:fatal={'prefix':PATH[:n-1],'direction':bad,'prefix_actions':n-1,'reason':'fire' if any(a['target_kind']=='hero' for a in branch['fire']) else 'monster'};break
  out=step(state,key);assert out and not out['hero_dead'],('illegal/fatal',n,key,state);state=out['state'];pushes+=out['pushed'];h,cs,ms,alive=state
  if out['fire'] or out['goblin']:attacks.append(n)
  assert (h==GOAL)==(n==len(PATH)),('prematuregoal',n)
  if gate_prefix is None and any(alive):
   q=deque([(state,'')]);walk_seen={h}
   while q:
    w,tail=q.popleft()
    if w[0]==(7,2):gate_prefix=PATH[:n]+tail;break
    for k in DIRS:
     z=step(w,k)
     if z and not z['hero_dead'] and not z['pushed'] and not z['fire'] and not z['goblin'] and z['state'][0] not in walk_seen:
      walk_seen.add(z['state'][0]);q.append((z['state'],tail+k))
  trace.append({'action':n,'input':key,'player':h,'crystals':cs.copy(),'monsters':ms.copy(),'monster_alive':alive.copy(),'pushes':pushes,'fire':out['fire'],'goblin':out['goblin'],'victims':out['victims'],'barrier_active':any(alive),'completed':h==GOAL})
 assert not any(state[3]) and len(attacks)==1 and fatal and gate_prefix
 sol={'level_id':d['id'],'path':PATH,'moves':len(PATH),'directions':len(PATH),'input_events':len(PATH),'selection_events':0,'pushes':pushes,'pulls':0,'swaps':0,'destroyed_crystals':0,'monster_death_action':attacks[0],'note':'用户补全顶行59–66后确认12×7；原1–58统一下移，未改规则。独立逐输入身份回放复核红人搬运水晶/怪物与同快照龙/哥布林互杀，清怪门同一步消失，不宣称最短方向路线。'}
 p=ROOT/'levels/solutions/north_35.json'
 if write:p.write_text(json.dumps(sol,ensure_ascii=False,indent=2)+'\n')
 else:assert json.loads(p.read_text())==sol
 report={'solution':sol,'trace':trace,'fatal_side':fatal,'gate_block_prefix':gate_prefix,'attack_actions':attacks,'final_player':state[0],'final_crystals':state[1],'final_monsters':state[2],'method':'Independent normal-direction stable-ID replay on FINAL12x7;old12x6audit explicitly superseded.'};output=ROOT/'artifacts/verification/north_35_route.json';output.parent.mkdir(exist_ok=True);output.write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n');print('NORTH35 INDEPENDENT RESULT:',json.dumps({k:v for k,v in report.items() if k!='trace'},ensure_ascii=False));return report
if __name__=='__main__':
 p=argparse.ArgumentParser();p.add_argument('--write-solution',action='store_true');verify(p.parse_args().write_solution)
