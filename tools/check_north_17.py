#!/usr/bin/env python3
"""Construct and independently replay the confirmed three-hero energy-destruction route."""
import argparse,json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
DIRS={'U':(0,-1),'D':(0,1),'L':(-1,0),'R':(1,0)}
SEGMENTS=[('blue','URRRRDLULLRULD'),('red','U'),('green','UUUDD'),('blue','UD'),('green','UUU'+'R'*7+'L'),('red','UUU'),('green','L'*6+'D'),('red','L'*7),('green','DD'),('blue','UD'),('red','RRR'),('green','UUURRR'),('blue','LUL')]
def main():
 parser=argparse.ArgumentParser(description=__doc__);parser.add_argument('--write-solution',action='store_true');args=parser.parse_args()
 level=json.loads((ROOT/'levels/north_17.json').read_text())
 assert level['terrain']==['.........','.#######.','.#..#..#.','.#.....#.','.#..#..#.']
 floor={(x,y) for y,row in enumerate(level['terrain']) for x,c in enumerate(row) if c=='.'}
 heroes=[tuple(h['position']) for h in level['heroes']];crystals={tuple(c):i for i,c in enumerate(level['crates'])};goals=set(map(tuple,level['exits']))
 plates=set(map(tuple,level['energy_links'][0]['plates']));gates=set(map(tuple,level['energy_links'][0]['barriers']))
 assert heroes==[(0,4),(2,4),(8,4)] and len(crystals)==4 and len(floor)==30
 assert goals=={(3,0),(4,0),(2,2)} and plates=={(3,3),(5,3)} and gates=={(0,2),(8,2)}
 selected=1;path='';moves=pushes=pulls=swaps=selections=0;trace=[];deleted=[];held=False
 plus=lambda c,d:(c[0]+d[0],c[1]+d[1])
 for name,segment in SEGMENTS:
  while level['heroes'][selected]['id']!=name:path+='C';selected=(selected+1)%3;selections+=1
  for symbol in segment:
   assert set(heroes)!=goals
   d=DIRS[symbol];origin=heroes[selected];target=plus(origin,d)
   clear=lambda c:c in floor and (held or c not in gates)
   occupied=lambda c:c in heroes or c in crystals
   assert clear(target),(name,symbol,target)
   if name=='blue':
    visible=target
    while clear(visible) and not occupied(visible):visible=plus(visible,d)
    if clear(visible) and occupied(visible):
     if visible in crystals:crystals[origin]=crystals.pop(visible)
     else:heroes[heroes.index(visible)]=origin
     target=visible;swaps+=1
    else:assert not occupied(target)
   elif name=='red':
    chain=[];end=target
    while occupied(end):chain.append(end);end=plus(end,d)
    assert clear(end),(name,symbol,'push terminal',end)
    for c in reversed(chain):
     if c in crystals:crystals[plus(c,d)]=crystals.pop(c)
     else:heroes[heroes.index(c)]=plus(c,d)
    pushes+=bool(chain)
   else:
    assert not occupied(target)
    behind=(origin[0]-d[0],origin[1]-d[1])
    if behind in crystals:crystals[origin]=crystals.pop(behind);pulls+=1
   heroes[selected]=target;previous=held
   held=all(c in heroes or c in crystals for c in plates)
   removed=[]
   if previous and not held:
    assert not gates.intersection(heroes),'Living walkthrough must not restore energy on a hero'
    for c in sorted(gates):
     if c in crystals:removed.append(crystals.pop(c))
   assert not (set(heroes)&set(crystals)) and len(set(heroes))==3
   assert held or not gates.intersection(crystals)
   moves+=1;path+=symbol;deleted+=removed
   trace.append({'move':moves,'input_event':len(path),'hero':name,'input':symbol,'heroes':[list(c) for c in heroes],'crystals_by_id':{str(i):list(c) for c,i in crystals.items()},'all_plates_held':held,'destroyed_ids_this_action':removed,'pushes':pushes,'pulls':pulls,'swaps':swaps,'completed':set(heroes)==goals})
 assert set(heroes)==goals and sorted(deleted)==[0,1,2] and len(crystals)==1
 solution={'level_id':level['id'],'path':path,'moves':moves,'directions':moves,'input_events':len(path),'selection_events':selections,'pushes':pushes,'pulls':pulls,'swaps':swaps,'destroyed_crystals':len(deleted),'note':'构造后逐对象身份独立验证的合法路线，不宣称最优或穷举。UDLR为实际行动，C只免费选择、不进撤销。两次能量再现共摧毁外围三枚水晶，三英雄分占不同目标；地图与障碍视线不变。'}
 dest=ROOT/'levels/solutions/north_17.json'
 if args.write_solution:dest.write_text(json.dumps(solution,ensure_ascii=False,indent=2)+'\n')
 else:assert json.loads(dest.read_text())==solution
 report={'method':'Constructed legal route independently replayed by identity with restoration-edge crystal deletion; no exhaustive/optimality claim','floor_cells':len(floor),'map_and_opaque_obstacles_unchanged':True,'solution':solution,'destroyed_crystal_ids':deleted,'destruction_actions':[t['move'] for t in trace if t['destroyed_ids_this_action']],'trace':trace}
 out=ROOT/'artifacts/verification/north_17_route.json';out.parent.mkdir(parents=True,exist_ok=True);out.write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n')
 print(json.dumps({k:v for k,v in report.items() if k!='trace'},ensure_ascii=False,indent=2))
 for t in trace:
  if t['destroyed_ids_this_action'] or t['completed']:print(t)
if __name__=='__main__':main()
