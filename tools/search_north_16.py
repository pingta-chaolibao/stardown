#!/usr/bin/env python3
"""Independent red/blue occupancy BFS; C selection is free and purple goals are inert."""
from collections import deque
from pathlib import Path
import argparse,json
ROOT=Path(__file__).resolve().parents[1]
DIRS={'U':(0,-1),'D':(0,1),'L':(-1,0),'R':(1,0)}

def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--write-solution',action='store_true');args=parser.parse_args()
    level=json.loads((ROOT/'levels/north_16.json').read_text())
    floor={(x,y) for y,row in enumerate(level['terrain']) for x,t in enumerate(row) if t=='.'}
    initial=tuple(tuple(h['position']) for h in level['heroes'])+(tuple(level['crates'][0]),)
    exits=set(map(tuple,level['exits']));plate=tuple(level['energy_links'][0]['plate']);gate=tuple(level['energy_links'][0]['barriers'][0])
    plus=lambda p,d:(p[0]+d[0],p[1]+d[1])
    def transition(state,hero,direction):
        held=plate in state;clear=lambda c:c in floor and (held or c!=gate)
        origin=state[hero];target=plus(origin,direction)
        if not clear(target):return None
        candidate=list(state);pushed=swapped=0
        if hero==1:
            visible=target
            while clear(visible) and visible not in state:visible=plus(visible,direction)
            if clear(visible) and visible in state:
                candidate[state.index(visible)]=origin;target=visible;swapped=1
            elif target in state:return None
        else:
            chain=[];end=target
            while end in state:chain.append(end);end=plus(end,direction)
            if not clear(end):return None
            for c in reversed(chain):candidate[state.index(c)]=plus(c,direction)
            pushed=int(bool(chain))
        candidate[hero]=target;after=tuple(candidate);assert len(set(after))==3
        if plate not in after:
            if after[2]==gate:return None
            if held and gate in after[:2]:return None
        return after,pushed,swapped
    previous={initial:None};queue=deque([initial]);expanded=0;victory=None
    while queue:
        state=queue.popleft();expanded+=1
        if set(state[:2])==exits:victory=state;break
        for hero in (0,1):
            for symbol,direction in DIRS.items():
                result=transition(state,hero,direction)
                if result is None:continue
                nxt,pushed,swapped=result
                if nxt in previous:continue
                previous[nxt]=(state,hero,symbol,pushed,swapped);queue.append(nxt)
    assert victory is not None,f'No surviving route for confirmed map: {expanded} expanded, {len(previous)} visited'
    steps=[];state=victory
    while previous[state] is not None:
        before,hero,symbol,pushed,swapped=previous[state];steps.append((before,state,hero,symbol,pushed,swapped));state=before
    steps.reverse();selected=next(i for i,h in enumerate(level['heroes']) if h['id']==level['active_hero'])
    path='';pushes=swaps=selections=0;trace=[]
    for move,(before,after,hero,symbol,pushed,swapped) in enumerate(steps,1):
        assert transition(before,hero,DIRS[symbol])==(after,pushed,swapped)
        if hero!=selected:path+='C';selected=hero;selections+=1
        path+=symbol;pushes+=pushed;swaps+=swapped
        trace.append({'move':move,'input_event':len(path),'hero':level['heroes'][hero]['id'],'input':symbol,'heroes':[list(c) for c in after[:2]],'crystal':list(after[2]),'plate_held':plate in after,'pushes':pushes,'swaps':swaps,'completed':set(after[:2])==exits})
    solution={'level_id':level['id'],'path':path,'moves':len(steps),'directions':len(steps),'input_events':len(path),'selection_events':selections,'pushes':pushes,'pulls':0,'swaps':swaps,
              'note':'UDLR计真实行动，C仅免费选择、不进撤销。独立红蓝身份占用BFS首次存活胜利停止，再按身份回放；不宣称穷举或最优。紫色圆盘只为终点显示，33号保持不可走。'}
    dest=ROOT/'levels/solutions/north_16.json'
    if args.write_solution:dest.write_text(json.dumps(solution,ensure_ascii=False,indent=2)+'\n')
    else:assert json.loads(dest.read_text())==solution
    report={'method':'identity-aware occupancy BFS with free selection; first living victory; no exhaustive/optimality claim','floor_cells':len(floor),'expanded_states':expanded,'visited_states':len(previous),'pending_states':len(queue),'solution':solution,'trace':trace}
    out=ROOT/'artifacts/verification/north_16_search.json';out.parent.mkdir(exist_ok=True,parents=True);out.write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n')
    print(json.dumps({k:v for k,v in report.items() if k!='trace'},ensure_ascii=False,indent=2))
    for t in trace:print(t)
    print(f'ROUTE RESULT: {len(steps)} actual actions+{selections} free selections,{pushes} pushes,{swaps} swaps,dual victory')

if __name__=='__main__':main()
