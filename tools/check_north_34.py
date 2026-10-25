"""Independent fixed-identity replay:green single pulls,crystal shielding,common fire."""
from pathlib import Path
import json,argparse
ROOT=Path(__file__).resolve().parents[1]
TERRAIN=['.....####','.....#...','.........','.....#...','.....####']
PATH='URRUULLDRDDLULURRLURRRDLDLDRURRRR'
DIRS={'U':(0,-1),'D':(0,1),'L':(-1,0),'R':(1,0)}
FACINGS=[(-1,0),(1,0)];GATE=(5,2);GOAL=(7,2)
def add(a,b):return a[0]+b[0],a[1]+b[1]
def floor(c):return 0<=c[0]<9 and 0<=c[1]<5 and TERRAIN[c[1]][c[0]]=='.'
def step(before,key):
 h,c,positions,living=before;d=DIRS[key];target=add(h,d)
 if not floor(target) or target==c or any(a and p==target for p,a in zip(positions,living)) or (any(living) and target==GATE):return None
 behind=(h[0]-d[0],h[1]-d[1]);crystal=c;monsters=positions.copy();pulled=None
 if behind==c:crystal=h;pulled='crystal'
 else:
  for i,p in enumerate(positions):
   if living[i] and p==behind:monsters[i]=h;pulled=i;break
 attacks=[];victims=set();hero_dead=False
 for i,p in enumerate(monsters):
  if not living[i]:continue
  cell=add(p,FACINGS[i]);ray=[]
  while floor(cell) and cell!=crystal and not(any(living) and cell==GATE):
   ray.append(cell)
   if cell==target:attacks.append({'dragon':i,'target_kind':'hero','target_id':0,'from':p,'to':cell,'cells':ray.copy()});hero_dead=True;break
   j=next((j for j,q in enumerate(monsters) if j!=i and living[j] and q==cell),None)
   if j is not None:attacks.append({'dragon':i,'target_kind':'monster','target_id':j,'from':p,'to':cell,'cells':ray.copy()});victims.add(j);break
   cell=add(cell,FACINGS[i])
 alive=[a and i not in victims for i,a in enumerate(living)]
 return {'state':(target,crystal,monsters,alive),'pulled':pulled,'attacks':attacks,'victims':sorted(victims),'hero_dead':hero_dead}
def verify(write=False):
 level=json.loads((ROOT/'levels/north_34.json').read_text())
 assert level['terrain']==TERRAIN and level['player']==[1,3] and level['hero_kind']=='green' and level['crates']==[[3,3]] and level['exit']==[7,2]
 assert level['monsters']==[{'kind':'fire_dragon','position':[0,0],'facing':'left'},{'kind':'fire_dragon','position':[4,0],'facing':'right'}]
 assert level['energy_blocks']==[{'kind':'all_monsters_defeated','position':[5,2]}] and level['mechanism_color']=='red'
 assert not any(level.get(k) for k in ['energy_links','bushes','fences'])
 assert set(map(tuple,level['void_cells']))=={(x,y) for y,row in enumerate(TERRAIN) for x,c in enumerate(row) if c=='#'}
 state=((1,3),(3,3),[(0,0),(4,0)],[True,True]);trace=[];pulls=0;dragon_pulls=0;crystal_pulls=0;attacks=[];fatal=None
 for n,key in enumerate(PATH,1):
  if fatal is None:
   for bad in DIRS:
    branch=step(state,bad)
    if branch and branch['hero_dead']:fatal={'prefix':PATH[:n-1],'direction':bad,'prefix_actions':n-1};break
  out=step(state,key);assert out and not out['hero_dead'],('illegal/fatal',n,key,state)
  state=out['state'];h,c,positions,living=state
  if out['pulled'] is not None:
   pulls+=1
   if out['pulled']=='crystal':crystal_pulls+=1
   else:dragon_pulls+=1
  if out['attacks']:attacks.append(n)
  assert (h==GOAL)==(n==len(PATH)),('prematurevictory',n)
  trace.append({'action':n,'input':key,'player':h,'crystals':[c],'monsters':positions.copy(),'monster_alive':living.copy(),'pulls':pulls,'dragon_pulls':dragon_pulls,'crystal_pulls':crystal_pulls,'pulled':out['pulled'],'attacks':out['attacks'],'victims':out['victims'],'barrier_active':any(living),'completed':h==GOAL})
 assert not any(state[3]) and len(attacks)==1 and fatal
 sol={'level_id':level['id'],'path':PATH,'moves':len(PATH),'directions':len(PATH),'input_events':len(PATH),'selection_events':0,'pushes':0,'pulls':pulls,'dragon_pulls':dragon_pulls,'crystal_pulls':crystal_pulls,'swaps':0,'destroyed_crystals':0,'monster_death_action':attacks[0],'note':'确认9×5布局，绿色自动单拉且火龙朝向不变。水晶遮挡后拉离火线，触发两龙同快照互杀，清怪能量同一步消失；构造路线独立逐步复核，不宣称最短或穷尽。'}
 p=ROOT/'levels/solutions/north_34.json'
 if write:p.write_text(json.dumps(sol,ensure_ascii=False,indent=2)+'\n')
 else:assert json.loads(p.read_text())==sol
 report={'solution':sol,'trace':trace,'fatal_side':fatal,'final_player':state[0],'final_crystal':state[1],'final_monsters':state[2],'attack_actions':attacks,'method':'Independent stable-ID green single pull/common first-target fire replay;not engine calls.'}
 output=ROOT/'artifacts/verification/north_34_route.json';output.parent.mkdir(exist_ok=True);output.write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n')
 print('NORTH34 INDEPENDENT RESULT:',json.dumps({k:v for k,v in report.items() if k!='trace'},ensure_ascii=False))
 return report
if __name__=='__main__':
 parser=argparse.ArgumentParser();parser.add_argument('--write-solution',action='store_true');verify(parser.parse_args().write_solution)
