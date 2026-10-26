"""Independent stable-ID replay of confirmed level39 and distinct pressure colors."""
from pathlib import Path
T=['....#....#','###.#....#','###.#.....','###.#...#.','..........']
F={(x,y) for y,row in enumerate(T) for x,c in enumerate(row) if c=='.'}
D={'U':(0,-1),'D':(0,1),'L':(-1,0),'R':(1,0)}
PLATES=((5,0),(0,4));ENERGY=((3,1),(3,3));EXITS={(0,0),(1,0)}
INITIAL=(((6,2),(7,2)),(8,0),((0,4),(2,4),(9,3)),7)
def add(a,b):return a[0]+b[0],a[1]+b[1]
def dist(a,b):return abs(a[0]-b[0])+abs(a[1]-b[1])
def barriers(hs,c,ms,a):return tuple(not(p in hs or p==c or any(a>>i&1 and ms[i]==p for i in range(2))) for p in PLATES)
def step(s,hero,k):
 hs,c,ms,a=s;hs=list(hs);ms=list(ms);old_e=barriers(hs,c,ms,a);v=D[k];h=hs[hero];dest=add(h,v);occ={p:('h',i) for i,p in enumerate(hs) if i!=hero}
 if c is not None:occ[c]=('c',0)
 occ.update({p:('m',i) for i,p in enumerate(ms) if a>>i&1})
 solid={p for p,e in zip(ENERGY,old_e) if e}
 if dest not in F or dest in solid:return None
 pushed=[];pulled=None
 if hero==1:
  end=dest
  while end in occ:pushed.append(occ[end]);end=add(end,v)
  if end not in F or end in solid:return None
  for role,i in pushed:
   if role=='c':c=add(c,v)
   elif role=='h':hs[i]=add(hs[i],v)
   else:ms[i]=add(ms[i],v)
 else:
  if dest in occ:return None
  behind=(h[0]-v[0],h[1]-v[1]);target=occ.get(behind)
  if target and (target[0]=='c' or target==('m',2)):
   pulled=target
   if target[0]=='c':c=h
   else:ms[2]=h
 hs[hero]=dest
 if a>>2&1 and ms[2] in PLATES:return None # unconfirmedDragonpressureguard
 e=barriers(hs,c,ms,a);dead=[False,False];reason=['',''];energy_victims=[]
 for p,o,n in zip(ENERGY,old_e,e):
  if n and not o:
   if c==p:c=None
   for i,pos in enumerate(hs):
    if pos==p:dead[i]=True;reason[i]='energy'
   for i,pos in enumerate(ms):
    if a>>i&1 and pos==p:a&=~(1<<i);energy_victims.append(i)
 attack_alive=a;victims=set();fire=[];strikes=[]
 for i in range(2):
  if not(a>>i&1):continue
  for j,pos in enumerate(hs):
   if not dead[j] and dist(ms[i],pos)==1:dead[j]=True;reason[j]='monster';strikes.append({'from':ms[i],'to':pos,'hero':j})
  for j in range(3):
   if i!=j and a>>j&1 and dist(ms[i],ms[j])==1:victims.add(j);strikes.append({'from':ms[i],'to':ms[j],'monster':j})
 # Snapshotheroalivebeforeattackdeaths: Goblin hits do notcancelDragon targets.
 pre_dead=[pos in {p for p,o,n in zip(ENERGY,old_e,e) if n and not o} for pos in hs]
 if a>>2&1:
  q=add(ms[2],(-1,0));ray=[]
  while q in F and q!=c and not any(q==p and x for p,x in zip(ENERGY,e)):
   ray.append(q);hidx=next((i for i,p in enumerate(hs) if p==q and not pre_dead[i]),None)
   if hidx is not None:dead[hidx]=True;reason[hidx]='fire';fire.append({'from':ms[2],'cells':ray.copy(),'target':{'kind':'hero','id':hidx}});break
   midx=next((i for i,p in enumerate(ms) if p==q and a>>i&1),None)
   if midx is not None:victims.add(midx);fire.append({'from':ms[2],'cells':ray.copy(),'target':{'kind':'monster','id':midx}});break
   q=add(q,(-1,0))
 for i in victims:a&=~(1<<i)
 final_e=barriers(hs,c,ms,a)
 for p,o,n in zip(ENERGY,e,final_e):
  if n and not o:
   if c==p:c=None
   for i,pos in enumerate(hs):
    if pos==p:dead[i]=True;reason[i]=reason[i] or 'energy'
   for i,pos in enumerate(ms):
    if a>>i&1 and pos==p:a&=~(1<<i);energy_victims.append(i)
 return {'state':(tuple(hs),c,tuple(ms),a),'dead':any(dead),'hero_dead':dead,'reason':reason,'pushed':pushed,'pulled':pulled,'fire':fire,'goblin':strikes,'victims':sorted(victims),'energy_victims':energy_victims,'barriers':final_e,'attack_alive':attack_alive,'attack_barriers':e}

ROOT=Path(__file__).resolve().parents[1]
PATH='UCUUCRRDLULCDUCRCDDRRDULULCUCDCLUCUULLCRRRDULLDUUULDLDDDLLUUUULLLCRRDLDLUDDDLLUUUULL'

def verify(write=False):
 import json
 d=json.loads((ROOT/'levels/north_39.json').read_text());assert d['terrain']==T and d['heroes']==[{'id':'green','kind':'green','position':[6,2]},{'id':'red','kind':'red','position':[7,2]}] and d['active_hero']=='green' and d['crates']==[[8,0]] and set(map(tuple,d['exits']))==EXITS and not d['energy_blocks']
 assert d['monsters']==[{'kind':'goblin','position':[0,4]},{'kind':'goblin','position':[2,4]},{'kind':'fire_dragon','position':[9,3],'facing':'left'}]
 assert d['energy_links']==[{'id':'blue_01','color':'blue','plates':[[5,0]],'activation':'all','barriers':[[3,1]],'pressure_sources':['hero','crystal']},{'id':'yellow_01','color':'yellow','plates':[[0,4]],'activation':'all','barriers':[[3,3]],'pressure_sources':['hero','crystal']}]
 m=json.loads((ROOT/'levels/mappings/north_39_markers.json').read_text())['marker_to_runtime_cell'];cells=[(x,y) for y,row in enumerate(T) for x,c in enumerate(row) if c=='.' and (x,y)!=(9,2)];expect={str(i+1):list(c) for i,c in enumerate(cells)};expect['34']=[9,2];assert m==expect
 s=INITIAL;active=0;moves=pushes=pulls=dragon_pulls=0;trace=[];fatal={};blocked={};fire_actions=[];goblin_actions=[];blue_changes=[];last_e=barriers(*s)
 for ev,k in enumerate(PATH,1):
  for who in [0,1]:
   for bad in D:
    z=step(s,who,bad)
    prefix=PATH[:ev-1]+('C' if active!=who else '')
    if z and z['dead']:
     reason='fire' if 'fire' in z['reason'] else ('monster' if 'monster' in z['reason'] else 'energy')
     fatal.setdefault(reason,{'prefix':prefix,'direction':bad,'hero_dead':z['hero_dead']})
    q=add(s[0][who],D[bad])
    if not z and q in ENERGY and last_e[ENERGY.index(q)]:blocked.setdefault(str(ENERGY.index(q)),{'prefix':prefix,'direction':bad,'cell':q})
  if k=='C':active=1-active;z={'pushed':[],'pulled':None,'fire':[],'goblin':[],'victims':[],'energy_victims':[],'barriers':last_e,'attack_alive':s[3],'attack_barriers':last_e}
  else:
   z=step(s,active,k);assert z and not z['dead'],(ev,k,s,z);s=z['state'];moves+=1;pushes+=bool(z['pushed']);pulls+=z['pulled'] is not None;dragon_pulls+=z['pulled']==('m',2)
   if z['fire']:fire_actions.append(moves)
   if z['goblin']:goblin_actions.append(moves)
   if z['barriers'][0]!=last_e[0]:blue_changes.append(moves)
  assert (set(s[0])==EXITS)==(ev==len(PATH))
  trace.append({'event':ev,'input':k,'selected':active,'actions':moves,'selection_events':PATH[:ev].count('C'),'heroes':s[0],'crystal':s[1],'monsters':s[2],'monster_alive':[bool(s[3]>>i&1) for i in range(3)],'pushes':pushes,'pulls':pulls,'dragon_pulls':dragon_pulls,'barriers':z['barriers'],'fire':z['fire'],'goblin':z['goblin'],'pushed':z['pushed'],'pulled':z['pulled'],'victims':z['victims'],'energy_victims':z['energy_victims'],'attack_monster_alive':[bool(z['attack_alive']>>i&1) for i in range(3)],'completed':set(s[0])==EXITS});last_e=z['barriers']
 # Legal side prefixes use the confirmed map and normal actions only.
 def replay_side(prefix):
  world=INITIAL;selected=0
  for symbol in prefix:
   if symbol=='C':selected=1-selected;continue
   result=step(world,selected,symbol);assert result and not result['dead'],('badsideprefix',prefix,symbol);world=result['state']
  return world,selected
 event23=next(row['event'] for row in trace if row['actions']==23 and row['input']!='C')
 prefix=PATH[:event23]+'C'+'LLDLLUU';world,selected=replay_side(prefix);assert world[0][selected]==(3,2) and step(world,selected,'U') is None and barriers(*world)[0]
 blocked['0']={'prefix':prefix,'direction':'U','cell':[3,1]}
 event22=next(row['event'] for row in trace if row['actions']==22 and row['input']!='C')
 prefix=PATH[:event22]+'R'+'C'+'DD'+'C'+'LLDDLLL';world,selected=replay_side(prefix);assert world[0][selected]==(3,4) and step(world,selected,'U') is None and barriers(*world)[1]
 blocked['1']={'prefix':prefix,'direction':'U','cell':[3,3]}
 assert moves==73 and PATH.count('C')==11 and pushes==7 and pulls==8 and dragon_pulls==1 and s[3]==5 and s[1]==PLATES[0] and s[2][0]==PLATES[1] and last_e==(False,False) and fire_actions==[22] and not goblin_actions and blue_changes==[29,56,62]
 sol={'level_id':d['id'],'path':PATH,'moves':moves,'directions':moves,'input_events':len(PATH),'selection_events':PATH.count('C'),'pushes':pushes,'pulls':pulls,'dragon_pulls':dragon_pulls,'crystal_pulls':pulls-dragon_pulls,'swaps':0,'destroyed_crystals':0,'fire_attack_actions':fire_actions,'blue_energy_changes_actions':blue_changes,'surviving_monsters':2,'note':'用户确认10×5与新增34，绿/红协作、蓝黄两色压板各控制对应屏障，同色仍全板AND。73行动11免费切换，7推8拉(1龙7晶)，仅22步火龙击杀首个哥布林；最终晶压蓝板、活哥布林压黄板，双英雄到双目标。稳定ID独立回放，不宣称最短。'}
 p=ROOT/'levels/solutions/north_39.json'
 if write:p.write_text(json.dumps(sol,ensure_ascii=False,indent=2)+'\n')
 else:assert json.loads(p.read_text())==sol
 report={'solution':sol,'trace':trace,'fatal_sides':fatal,'blocked_energy_sides':blocked,'final_heroes':s[0],'final_crystal':s[1],'final_monsters':s[2],'final_monster_alive':[bool(s[3]>>i&1) for i in range(3)],'no_monster_clear_gate':True}
 p=ROOT/'artifacts/verification/north_39_route.json';p.parent.mkdir(exist_ok=True);p.write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n');print('NORTH39 INDEPENDENT RESULT:',json.dumps({k:v for k,v in report.items() if k!='trace'},ensure_ascii=False));return report
if __name__=='__main__':
 import argparse
 p=argparse.ArgumentParser();p.add_argument('--write-solution',action='store_true');verify(p.parse_args().write_solution)
