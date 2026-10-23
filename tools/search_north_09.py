#!/usr/bin/env python3
"""Independent direction-driven nearest-swap search; each input first checks its own ray."""
from collections import deque
import argparse
import json
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]
DIRS={"U":(0,-1),"D":(0,1),"L":(-1,0),"R":(1,0)}

def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--write-solution',action='store_true')
    args=parser.parse_args()
    level=json.loads((ROOT/'levels/north_09.json').read_text())
    floor={(x,y) for y,row in enumerate(level['terrain']) for x,t in enumerate(row) if t=='.'}
    assert level['hero_kind']=='blue' and not level.get('energy_links') and not level.get('bushes')
    initial=(tuple(level['player']),tuple(tuple(c) for c in level['crates']))
    queue=deque([initial]);parents={initial:None};winner=None
    def follow(state,symbol):
        hero,crystals=state;dx,dy=DIRS[symbol]
        adjacent=(hero[0]+dx,hero[1]+dy)
        target=adjacent
        while target in floor:
            if target in crystals:
                candidate=list(crystals);candidate[candidate.index(target)]=hero
                return target,tuple(candidate)
            target=(target[0]+dx,target[1]+dy)
        return (adjacent,crystals) if adjacent in floor and adjacent not in crystals else None
    while queue:
        state=queue.popleft()
        if state[0]==tuple(level['exit']):
            if winner is None:winner=state
            continue
        for symbol in 'UDLR':
            following=follow(state,symbol)
            if following is not None and following not in parents:
                parents[following]=(state,symbol);queue.append(following)
    assert winner is not None,'Confirmed ninth level has no legal solution'
    path='';cursor=winner
    while parents[cursor] is not None:
        cursor,symbol=parents[cursor];path=symbol+path
    state=initial;swaps=0
    for symbol in path:
        following=follow(state,symbol);swaps+=following[1]!=state[1];state=following
    solution={'level_id':level['id'],'path':path,'moves':len(path),'pushes':0,'pulls':0,'swaps':swaps,
              'note':'UDLR均为普通方向输入：只检查本方向，优先与第一个可见目标交换，否则走一格；moves计有效操作。独立合法路线，不宣称最优。'}
    dest=ROOT/'levels/solutions/north_09.json'
    if args.write_solution:dest.write_text(json.dumps(solution,ensure_ascii=False,indent=2)+'\n')
    else:assert json.loads(dest.read_text())==solution
    state=initial;events=[]
    for index,symbol in enumerate(path,1):
        before=state;state=follow(state,symbol);assert state is not None
        if state[1]!=before[1]:events.append({'action_number':index,'input':symbol,'hero_from':before[0],'hero_to':state[0],'crystals':state[1]})
    report={'living_identity_states_exhausted':len(parents),'solution':solution,'swap_events':events}
    output=ROOT/'artifacts/verification/north_09_search.json';output.parent.mkdir(parents=True,exist_ok=True)
    output.write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n')
    print(json.dumps(report,ensure_ascii=False,indent=2))
    print(f'SEARCH RESULT: {len(parents)} identity states; {len(path)} actions, {swaps} swaps')

if __name__=='__main__':main()
