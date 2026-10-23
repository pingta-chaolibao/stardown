#!/usr/bin/env python3
"""Independent red/green world-state search; selection is free control, not an action."""
from collections import deque
from pathlib import Path
import argparse,json
ROOT=Path(__file__).resolve().parents[1]
DIRS={'U':(0,-1),'D':(0,1),'L':(-1,0),'R':(1,0)}

def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--write-solution',action='store_true')
    args=parser.parse_args()
    level=json.loads((ROOT/'levels/north_14.json').read_text())
    floor={(x,y) for y,row in enumerate(level['terrain']) for x,t in enumerate(row) if t=='.'}
    initial=tuple(tuple(h['position']) for h in level['heroes'])+(tuple(level['crates'][0]),)
    exits={tuple(c) for c in level['exits']}
    plate=tuple(level['energy_links'][0]['plate'])
    gates=set(map(tuple,level['energy_links'][0]['barriers']))
    plus=lambda c,d:(c[0]+d[0],c[1]+d[1])
    def transition(state,hero,direction):
        held=plate in state
        clear=lambda c:c in floor and (held or c not in gates)
        origin=state[hero];target=plus(origin,direction)
        if not clear(target):return None
        candidate=list(state);pushed=pulled=0
        if hero==0:
            chain=[];end=target
            while end in state:
                chain.append(end);end=plus(end,direction)
            if not clear(end):return None
            for c in reversed(chain):candidate[state.index(c)]=plus(c,direction)
            pushed=int(bool(chain))
        else:
            if target in state:return None
            behind=(origin[0]-direction[0],origin[1]-direction[1])
            if behind==state[2]:candidate[2]=origin;pulled=1
        candidate[hero]=target
        after=tuple(candidate)
        assert len(set(after))==3
        if plate not in after:
            # Never use the undefined crystal/barrier case or a lethal restoration.
            if after[2] in gates:return None
            if held and any(c in gates for c in after[:2]):return None
        return after,pushed,pulled
    previous={initial:None};queue=deque([initial]);expanded=0;victory=None
    while queue:
        state=queue.popleft();expanded+=1
        if set(state[:2])==exits:victory=state;break
        for hero in (0,1):
            for symbol,direction in DIRS.items():
                result=transition(state,hero,direction)
                if result is None:continue
                nxt,pushed,pulled=result
                if nxt in previous:continue
                previous[nxt]=(state,hero,symbol,pushed,pulled);queue.append(nxt)
    assert victory is not None,f'Confirmed grid has no surviving route: {expanded} expanded, {len(previous)} visited'
    steps=[];state=victory
    while previous[state] is not None:
        before,hero,symbol,pushed,pulled=previous[state]
        steps.append((before,state,hero,symbol,pushed,pulled));state=before
    steps.reverse()
    path='';selected=0;pushes=pulls=selections=0;trace=[]
    for move,(before,after,hero,symbol,pushed,pulled) in enumerate(steps,1):
        assert transition(before,hero,DIRS[symbol])==(after,pushed,pulled)
        if hero!=selected:path+='C';selected=hero;selections+=1
        path+=symbol;pushes+=pushed;pulls+=pulled
        trace.append({'move':move,'input_event':len(path),'hero':level['heroes'][hero]['id'],'input':symbol,
                      'heroes':[list(c) for c in after[:2]],'crystal':list(after[2]),'plate_held':plate in after,
                      'pushes':pushes,'pulls':pulls,'completed':set(after[:2])==exits})
    solution={'level_id':level['id'],'path':path,'moves':len(steps),'directions':len(steps),'input_events':len(path),
              'selection_events':selections,'pushes':pushes,'pulls':pulls,'swaps':0,
              'note':'UDLR为实际方向行动，C仅切换选择，不计步、不进撤销。独立世界占用搜索在首次胜利停止，再按英雄/水晶身份回放，不宣称穷举或最优。6号(5,0)保持墙。'}
    dest=ROOT/'levels/solutions/north_14.json'
    if args.write_solution:dest.write_text(json.dumps(solution,ensure_ascii=False,indent=2)+'\n')
    else:assert json.loads(dest.read_text())==solution
    report={'method':'BFS over identity-aware occupancy, free selection; stops at first surviving victory; no exhaustive/optimality claim',
            'expanded_states':expanded,'visited_states':len(previous),'pending_states':len(queue),'solution':solution,'trace':trace}
    out=ROOT/'artifacts/verification/north_14_search.json';out.parent.mkdir(exist_ok=True,parents=True)
    out.write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n')
    print(json.dumps({k:v for k,v in report.items() if k!='trace'},ensure_ascii=False,indent=2))
    print(f'ROUTE RESULT: {len(steps)} actual actions + {selections} selection events; {pushes} pushes, {pulls} pulls, dual victory')

if __name__=='__main__':main()
