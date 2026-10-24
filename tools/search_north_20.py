#!/usr/bin/env python3
"""Independent identity-aware five-object BFS: fences block edges, never sight."""
from array import array
from pathlib import Path
import argparse,json,time
ROOT=Path(__file__).resolve().parents[1]
DIRS={'U':(0,-1),'D':(0,1),'L':(-1,0),'R':(1,0)}
def main():
    parser=argparse.ArgumentParser(description=__doc__);parser.add_argument('--write-solution',action='store_true');args=parser.parse_args();began=time.monotonic()
    level=json.loads((ROOT/'levels/north_20.json').read_text())
    assert level['terrain']==['#.#.#','.....','.....','.....','.###.']
    cells=[(x,y) for y,row in enumerate(level['terrain']) for x,c in enumerate(row) if c=='.'];ids={c:i for i,c in enumerate(cells)};base=len(cells)
    assert base==19 and [h['kind'] for h in level['heroes']]==['red','green','blue']
    initial=tuple(ids[tuple(h['position'])] for h in level['heroes'])+tuple(ids[tuple(c)] for c in level['crates'])
    goals={ids[tuple(c)] for c in level['exits']};fences=set()
    for a,b in level['fences']:
        a,b=ids[tuple(a)],ids[tuple(b)];fences.update(((a,b),(b,a)))
    adjacent=[];rays=[];symbols=list(DIRS)
    for x,y in cells:
        adjacent.append(tuple(ids.get((x+dx,y+dy),-1) for dx,dy in DIRS.values()))
        lines=[]
        for dx,dy in DIRS.values():
            line=[];c=(x+dx,y+dy)
            while c in ids:line.append(ids[c]);c=(c[0]+dx,c[1]+dy)
            lines.append(tuple(line))
        rays.append(lines)
    def encode(s):return (((s[0]*base+s[1])*base+s[2])*base+s[3])*base+s[4]
    def decode(n):
        e,n=n%base,n//base;d,n=n%base,n//base;c,n=n%base,n//base;b,n=n%base,n//base
        return (n,b,c,d,e)
    def transition(state,hero,d):
        origin=state[hero];target=adjacent[origin][d]
        if target<0:return None
        after=list(state);push=pull=swap=0
        visible=next((c for c in rays[origin][d] if c in state),-1) if hero==2 else -1
        if visible>=0:
            after[state.index(visible)]=origin;target=visible;swap=1
        else:
            if (origin,target) in fences:return None
            if hero==0:
                chain=[];end=target
                while end in state:chain.append(end);end=adjacent[end][d]
                if end<0 or any((c,adjacent[c][d]) in fences for c in chain):return None
                for c in reversed(chain):after[state.index(c)]=adjacent[c][d]
                push=int(bool(chain))
            else:
                if target in state:return None
                behind=adjacent[origin][d^1]
                if hero==1 and behind in state[3:]:
                    if (behind,origin) in fences:return None
                    after[state.index(behind)]=origin;pull=1
        after[hero]=target;assert len(set(after))==5
        return tuple(after),push,pull,swap
    previous=array('i',[-2])*(base**5);action=bytearray(base**5);first=encode(initial);previous[first]=-1;queue=array('I',[first]);cursor=0;victory=-1
    while cursor<len(queue):
        n=queue[cursor];cursor+=1;state=decode(n)
        if set(state[:3])==goals:victory=n;break
        for hero in range(3):
            for d in range(4):
                result=transition(state,hero,d)
                if result is None:continue
                nxt=encode(result[0])
                if previous[nxt]!=-2:continue
                previous[nxt]=n;action[nxt]=hero*4+d;queue.append(nxt)
        if cursor%100000==0:print('SEARCH20',cursor,'expanded',len(queue),'visited',flush=True)
    assert victory>=0,f'No victory: {cursor} reachable states exhausted'
    steps=[];n=victory
    while previous[n]>=0:
        old=previous[n];a=action[n];steps.append((decode(old),decode(n),a//4,a%4));n=old
    steps.reverse();selected=2;path='';choices=pushes=pulls=swaps=0;trace=[]
    for move,(before,after,hero,d) in enumerate(steps,1):
        result=transition(before,hero,d);assert result[0]==after
        while selected!=hero:path+='C';selected=(selected+1)%3;choices+=1
        path+=symbols[d];pushes+=result[1];pulls+=result[2];swaps+=result[3]
        trace.append({'move':move,'event':len(path),'hero':level['heroes'][hero]['id'],'input':symbols[d],'heroes':[list(cells[v]) for v in after[:3]],'crystals':[list(cells[v]) for v in after[3:]],'pushes':pushes,'pulls':pulls,'swaps':swaps,'completed':set(after[:3])==goals})
    solution={'level_id':level['id'],'path':path,'moves':len(steps),'directions':len(steps),'input_events':len(path),'selection_events':choices,'pushes':pushes,'pulls':pulls,'swaps':swaps,'destroyed_crystals':0,'note':'独立五对象身份BFS，边栅栏双向挡所有走动和推拉，蓝方向首目标交换忽略栅栏；首次胜利停止，不宣称穷举或最优。'}
    dest=ROOT/'levels/solutions/north_20.json'
    if args.write_solution:dest.write_text(json.dumps(solution,ensure_ascii=False,indent=2)+'\n')
    else:assert json.loads(dest.read_text())==solution
    report={'method':'Independent five-object identity BFS, undirected movement fences and fence-transparent blue sight; first victory,not exhaustive/optimality claim','expanded_states':cursor,'visited_states':len(queue),'pending_states':len(queue)-cursor,'seconds':round(time.monotonic()-began,3),'solution':solution,'trace':trace}
    p=ROOT/'artifacts/verification/north_20_search.json';p.parent.mkdir(parents=True,exist_ok=True);p.write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n')
    print(json.dumps({k:v for k,v in report.items() if k!='trace'},ensure_ascii=False,indent=2),flush=True)
    for row in trace:print(row)
if __name__=='__main__':main()
