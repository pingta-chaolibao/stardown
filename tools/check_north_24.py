#!/usr/bin/env python3
"""Independent green-single-pull/plate/energy/Goblin search for confirmed level24."""
from collections import deque
from pathlib import Path
import argparse,json

ROOT=Path(__file__).resolve().parents[1]
DIRS={"U":(0,-1),"D":(0,1),"L":(-1,0),"R":(1,0)}
MONSTERS=((2,0),(5,2),(7,2),(0,3),(2,5),(10,5),(6,6),(3,9))
FLOOR={(x,y) for y in range(11) for x in range(13) if not(y==9 and x>=10 or y==10 and x>=7)}
DANGER={c for c in FLOOR if any(abs(c[0]-m[0])+abs(c[1]-m[1])==1 for m in MONSTERS)}
PLATE,GATE=(2,7),(1,1)

def step(state,symbol):
    hero,crystal=state;dx,dy=DIRS[symbol];nxt=(hero[0]+dx,hero[1]+dy)
    active=PLATE not in state
    if nxt not in FLOOR or nxt in MONSTERS or nxt==crystal or active and nxt==GATE:return None
    pulled=crystal==(hero[0]-dx,hero[1]-dy)
    cc=hero if pulled else crystal
    restored=not active and PLATE not in (nxt,cc)
    if restored and cc==GATE:cc=None
    dead=(restored and nxt==GATE) or nxt in DANGER
    return (nxt,cc),{"pulled":pulled,"active":PLATE not in (nxt,cc),"dead":dead}

def main():
    p=argparse.ArgumentParser(description=__doc__);p.add_argument('--write-solution',action='store_true');args=p.parse_args()
    d=json.loads((ROOT/'levels/north_24.json').read_text())
    assert d['terrain']==['.............']*9+['..........###','.......######']
    assert d['player']==[8,7] and d['hero_kind']=='green' and d['crates']==[[9,7]] and d['exit']==[0,0]
    assert d['mechanism_color']=='purple' and [(m['kind'],tuple(m['position'])) for m in d['monsters']]==[('goblin',m) for m in MONSTERS]
    assert d['energy_links']==[{'id':'purple_01','plate':[2,7],'barriers':[[1,1]],'pressure_sources':['hero','crystal']}]
    assert not d.get('fences') and not d.get('bushes') and len(FLOOR)==134 and len(DANGER)==29
    assert all((x,0) in FLOOR for x in range(7,13))
    start=((8,7),(9,7));queue=deque([start]);parents={start:None};found=None
    while queue:
        state=queue.popleft()
        if state[0]==(0,0):found=state;break
        for symbol in DIRS:
            result=step(state,symbol)
            if result and not result[1]['dead'] and result[0] not in parents:
                parents[result[0]]=(state,symbol);queue.append(result[0])
    assert found,'No legal route in the user-confirmed map under existing rules'
    symbols=[];state=found
    while parents[state]:state,symbol=parents[state];symbols.append(symbol)
    path=''.join(reversed(symbols));state=start;pulls=0;trace=[]
    for n,symbol in enumerate(path,1):
        result=step(state,symbol);assert result and not result[1]['dead'];state,info=result;pulls+=info['pulled']
        trace.append({'action':n,'input':symbol,'hero':state[0],'crystal':state[1],**info})
    assert state==((0,0),PLATE)
    solution={'level_id':d['id'],'path':path,'moves':len(path),'directions':len(path),'input_events':len(path),'selection_events':0,'pushes':0,'pulls':pulls,'swaps':0,'destroyed_crystals':0,'note':'独立身份占用BFS；绿自动仅拉单晶、压板联动/能量恢复、静止哥布林四向威胁。保留用户顶排8–13全部可走，不为求解改图；首次胜利停止，不宣称穷举或最优。'}
    target=ROOT/'levels/solutions/north_24.json'
    if args.write_solution:target.write_text(json.dumps(solution,ensure_ascii=False,indent=2)+'\n')
    else:assert json.loads(target.read_text())==solution
    proof={'visited':len(parents),'solution':solution,'floor':134,'danger':[list(c) for c in sorted(DANGER)],'trace':trace}
    out=ROOT/'artifacts/verification/north_24_route.json';out.parent.mkdir(parents=True,exist_ok=True);out.write_text(json.dumps(proof,ensure_ascii=False,indent=2)+'\n')
    print('NORTH 24 INDEPENDENT RESULT: '+json.dumps(solution,ensure_ascii=False))
    print('KEY ACTIONS '+str([t for t in trace if t['pulled'] or not t['active'] and (t['crystal']==PLATE or t['hero']==GATE)]))

if __name__=='__main__':main()
