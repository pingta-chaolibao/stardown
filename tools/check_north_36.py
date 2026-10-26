"""Independent stable-identity input replay of the confirmed 36th map."""
from pathlib import Path
import argparse,json
ROOT=Path(__file__).resolve().parents[1]
TERRAIN=['.......####','.......####','.......#...','...........','.......#...','.......####','.......####']
PATH='LRRLDRDUULLDDRRRUUUDRUURRR'
PLATES={(1,1),(1,5),(5,5)};YELLOW=(5,1);RED=(7,3);GOAL=(9,3)
DIRS={'U':(0,-1),'D':(0,1),'L':(-1,0),'R':(1,0)}
def plus(a,b):return a[0]+b[0],a[1]+b[1]
def floor(c):return 0<=c[0]<11 and 0<=c[1]<7 and TERRAIN[c[1]][c[0]]=='.'
def pressure(s):
 h,cs,g,alive=s
 return {p:p==h or p in cs.values() or (alive and p==g) for p in PLATES}
def yellow(s):return not all(pressure(s).values())
def step(s,key):
 h,cs,g,alive=s;cs=cs.copy();d=DIRS[key];old_y=yellow(s)
 def blocked(c):return not floor(c) or c==YELLOW and old_y or c==RED and alive
 q=plus(h,d);target=None
 while not blocked(q):
  if q in cs.values():target=('crystal',next(i for i,c in cs.items() if c==q));break
  if alive and q==g:target=('goblin',0);break
  q=plus(q,d)
 if target:
  if target[0]=='crystal':cs[target[1]]=h
  else:g=h
  h=q
 else:
  q=plus(h,d)
  if blocked(q):return None
  h=q
 events=[];dead=False
 if yellow((h,cs,g,alive)) and not old_y:
  if h==YELLOW:dead=True
  for i in list(cs):
   if cs[i]==YELLOW:del cs[i]
  if alive and g==YELLOW:alive=False;events.append('energy_kills_goblin')
 if alive and abs(h[0]-g[0])+abs(h[1]-g[1])==1:dead=True
 return {'state':(h,cs,g,alive),'swap':target,'dead':dead,'events':events}
def verify(write=False):
 d=json.loads((ROOT/'levels/north_36.json').read_text())
 assert d['terrain']==TERRAIN and d['hero_kind']=='blue' and d['swap_hero_color']=='purple' and d['player']==[2,3] and d['crates']==[[3,2],[3,4]] and d['exit']==[9,3]
 assert d['monsters']==[{'kind':'goblin','position':[4,3]}] and d['energy_blocks']==[{'kind':'all_monsters_defeated','position':[7,3]}]
 link=d['energy_links'][0];assert set(map(tuple,link['plates']))==PLATES and link['barriers']==[[5,1]] and link['activation']=='all'
 s=((2,3),{0:(3,2),1:(3,4)},(4,3),True);trace=[];swaps=0;death=None;gate=None;fatal=None
 for n,k in enumerate(PATH,1):
  if fatal is None:
   for bad in DIRS:
    z=step(s,bad)
    if z and z['dead']:fatal={'prefix':PATH[:n-1],'direction':bad};break
  z=step(s,k);assert z and not z['dead'],(n,k,s);before=s;s=z['state'];h,cs,g,alive=s
  swaps+=bool(z['swap'])
  if before[3] and not alive:death=n
  if h==RED:gate=n
  assert (h==GOAL)==(n==len(PATH))
  trace.append({'action':n,'input':k,'player':list(h),'crystals':{str(i):list(c) for i,c in cs.items()},'goblin':list(g),'goblin_alive':alive,'yellow_active':yellow(s),'red_active':alive,'swaps':swaps,'target':z['swap'],'events':z['events'],'pressure':{str(p):v for p,v in pressure(s).items()}})
 if fatal is None:
  side=((2,3),{0:(3,2),1:(3,4)},(4,3),True)
  for k in 'DRU':
   z=step(side,k);assert z and not z['dead'];side=z['state']
  assert step(side,'R')['dead'];fatal={'prefix':'DRU','direction':'R'}
 assert not s[3] and death and gate and fatal
 sol={'level_id':d['id'],'path':PATH,'moves':len(PATH),'directions':len(PATH),'input_events':len(PATH),'selection_events':0,'pushes':0,'pulls':0,'swaps':swaps,'destroyed_crystals':2-len(s[1]),'monster_death_action':death,'gate_traversal_action':gate,'note':'用户确认完整11×7及活哥布林压板；既有交换能力blue，紫色只显示。独立稳定身份逐输入回放，非最短声明。'}
 p=ROOT/'levels/solutions/north_36.json'
 if write:p.write_text(json.dumps(sol,ensure_ascii=False,indent=2)+'\n')
 else:assert json.loads(p.read_text())==sol
 report={'solution':sol,'trace':trace,'fatal_side':fatal,'all_monsters_dead':not s[3],'final_player':list(s[0]),'final_crystals':{str(i):list(c) for i,c in s[1].items()},'initial_goblin_pressure_confirmed':True}
 p=ROOT/'artifacts/verification/north_36_route.json';p.parent.mkdir(exist_ok=True);p.write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n')
 print('NORTH36 INDEPENDENT RESULT:',json.dumps({k:v for k,v in report.items() if k!='trace'},ensure_ascii=False));return report
if __name__=='__main__':
 p=argparse.ArgumentParser();p.add_argument('--write-solution',action='store_true');verify(p.parse_args().write_solution)
