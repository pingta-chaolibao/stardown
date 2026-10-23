#!/usr/bin/env python3
"""Identity-aware blue/green BFS with free hero selection and independent replay."""
from array import array
from pathlib import Path
import argparse,json,time
ROOT=Path(__file__).resolve().parents[1]
DIRS={'U':(0,-1),'D':(0,1),'L':(-1,0),'R':(1,0)}

def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--write-solution',action='store_true')
    args=parser.parse_args();began=time.monotonic()
    level=json.loads((ROOT/'levels/north_15.json').read_text())
    cells=[(x,y) for y,row in enumerate(level['terrain']) for x,t in enumerate(row) if t=='.']
    ids={c:i for i,c in enumerate(cells)};count=len(cells)
    assert count==40 and (2,2) not in ids and (2,4) not in ids
    initial=tuple(ids[tuple(h['position'])] for h in level['heroes'])+tuple(ids[tuple(c)] for c in level['crates'])
    goals=set(ids[tuple(c)] for c in level['exits']);plates=tuple(ids[tuple(c)] for c in level['energy_links'][0]['plates']);gate=ids[tuple(level['energy_links'][0]['barriers'][0])]
    deltas=list(DIRS.values());symbols=list(DIRS)
    adjacent=[];rays=[]
    for x,y in cells:
        adjacent.append(tuple(ids.get((x+dx,y+dy),-1) for dx,dy in deltas))
        lines=[]
        for dx,dy in deltas:
            line=[];c=(x+dx,y+dy)
            while c in ids:line.append(ids[c]);c=(c[0]+dx,c[1]+dy)
            lines.append(tuple(line))
        rays.append(lines)
    def code(s):return ((s[0]*count+s[1])*count+s[2])*count+s[3]
    def unpack(v):
        a,v=v%count,v//count;b,v=v%count,v//count;c,v=v%count,v//count
        return (v,c,b,a)
    def transition(state,hero,direction):
        held=plates[0] in state and plates[1] in state
        origin=state[hero];target=adjacent[origin][direction]
        if target<0 or (target==gate and not held):return None
        candidate=list(state);pulled=swapped=0
        if hero==0:
            visible=-1
            for c in rays[origin][direction]:
                if c==gate and not held:break
                if c in state:visible=c;break
            if visible>=0:
                candidate[state.index(visible)]=origin;target=visible;swapped=1
            elif target in state:return None
        else:
            if target in state:return None
            behind=adjacent[origin][direction^1]
            if behind in state[2:]:candidate[state.index(behind)]=origin;pulled=1
        candidate[hero]=target;after=tuple(candidate)
        assert len(set(after))==4
        now=plates[0] in after and plates[1] in after
        if not now:
            if gate in after[2:]:return None
            if held and gate in after[:2]:return None
        return after,pulled,swapped
    size=count**4
    predecessor=array('i',[-2])*size;action=bytearray(size)
    first=code(initial);predecessor[first]=-1;queue=array('I',[first]);cursor=0;victory=-1
    while cursor<len(queue):
        encoded=queue[cursor];cursor+=1;state=unpack(encoded)
        if set(state[:2])==goals:victory=encoded;break
        for hero in (0,1):
            for direction in range(4):
                result=transition(state,hero,direction)
                if result is None:continue
                nxt=code(result[0])
                if predecessor[nxt]!=-2:continue
                predecessor[nxt]=encoded;action[nxt]=hero*4+direction;queue.append(nxt)
        if cursor%50000==0:print(f'SEARCH: {cursor} expanded, {len(queue)} visited, {time.monotonic()-began:.1f}s',flush=True)
    assert victory>=0,f'No surviving solution for confirmed grid: {cursor} expanded, {len(queue)} visited'
    steps=[];v=victory
    while predecessor[v]>=0:
        old=predecessor[v];a=action[v];steps.append((unpack(old),unpack(v),a//4,a%4));v=old
    steps.reverse();selected=0;path='';pulls=swaps=selections=0;trace=[]
    for move,(before,after,hero,direction) in enumerate(steps,1):
        result=transition(before,hero,direction);assert result is not None and result[0]==after
        if hero!=selected:path+='C';selected=hero;selections+=1
        path+=symbols[direction];pulls+=result[1];swaps+=result[2]
        trace.append({'move':move,'input_event':len(path),'hero':level['heroes'][hero]['id'],'input':symbols[direction],
                      'heroes':[list(cells[c]) for c in after[:2]],'crystals_by_identity':[list(cells[c]) for c in after[2:]],
                      'all_plates_held':plates[0] in after and plates[1] in after,'pulls':pulls,'swaps':swaps,'completed':set(after[:2])==goals})
    solution={'level_id':level['id'],'path':path,'moves':len(steps),'directions':len(steps),'input_events':len(path),'selection_events':selections,'pushes':0,'pulls':pulls,'swaps':swaps,
              'note':'UDLR计实际行动，C仅免费切换选择、不进撤销。独立蓝绿身份占用BFS首次胜利停止，再按英雄/水晶身份回放；不宣称穷举或最优。25号(2,2)及47号(2,4)保持不可走。'}
    dest=ROOT/'levels/solutions/north_15.json'
    if args.write_solution:dest.write_text(json.dumps(solution,ensure_ascii=False,indent=2)+'\n')
    else:assert json.loads(dest.read_text())==solution
    report={'method':'BFS over identity-aware four-object occupancy with free selection; first living victory, no exhaustive/optimality claim','floor_cells':count,'expanded_states':cursor,'visited_states':len(queue),'pending_states':len(queue)-cursor,'seconds':round(time.monotonic()-began,3),'solution':solution,'trace':trace}
    out=ROOT/'artifacts/verification/north_15_search.json';out.parent.mkdir(exist_ok=True,parents=True);out.write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n')
    print(json.dumps({k:v for k,v in report.items() if k!='trace'},ensure_ascii=False,indent=2))
    print(f'ROUTE RESULT: {len(steps)} actual actions +{selections} selection events, {pulls} pulls, {swaps} swaps, dual victory',flush=True)

if __name__=='__main__':main()
