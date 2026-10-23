#!/usr/bin/env python3
"""Independent three-hero/one-crystal BFS with free selection and restoring-energy deletion."""
from array import array
from pathlib import Path
import argparse,json,time
ROOT=Path(__file__).resolve().parents[1]
DIRS={'U':(0,-1),'D':(0,1),'L':(-1,0),'R':(1,0)}
def main():
 parser=argparse.ArgumentParser(description=__doc__);parser.add_argument('--write-solution',action='store_true');args=parser.parse_args();began=time.monotonic()
 level=json.loads((ROOT/'levels/north_18.json').read_text())
 assert level['terrain']==['.......','######.','.....#.','..##.#.','..#..#.','#.####.','.......','#.####.']
 cells=[(x,y) for y,row in enumerate(level['terrain']) for x,c in enumerate(row) if c=='.'];ids={c:i for i,c in enumerate(cells)};count=len(cells);base=count+1;gone=count
 assert count==34 and (3,2) in ids and (4,1) not in ids
 initial=tuple(ids[tuple(h['position'])] for h in level['heroes'])+(ids[tuple(level['crates'][0])],)
 assert [h['kind'] for h in level['heroes']]==['red','green','blue']
 goals={ids[tuple(c)] for c in level['exits']};plate=ids[(1,7)];gate=ids[(4,2)]
 adjacent=[];rays=[];symbols=list(DIRS)
 for x,y in cells:
  adjacent.append(tuple(ids.get((x+dx,y+dy),-1) for dx,dy in DIRS.values()))
  lines=[]
  for dx,dy in DIRS.values():
   line=[];c=(x+dx,y+dy)
   while c in ids:line.append(ids[c]);c=(c[0]+dx,c[1]+dy)
   lines.append(tuple(line))
  rays.append(lines)
 def encode(s):return ((s[0]*base+s[1])*base+s[2])*base+s[3]
 def decode(n):
  d,n=n%base,n//base;c,n=n%base,n//base;b,n=n%base,n//base
  return (n,b,c,d)
 def transition(state,hero,d):
  held=plate in state;origin=state[hero];target=adjacent[origin][d]
  if target<0 or (target==gate and not held):return None
  after=list(state);push=pull=swap=0
  if hero==2:
   visible=-1
   for c in rays[origin][d]:
    if c==gate and not held:break
    if c in state:visible=c;break
   if visible>=0:after[state.index(visible)]=origin;target=visible;swap=1
   elif target in state:return None
  elif hero==0:
   chain=[];end=target
   while end in state:chain.append(end);end=adjacent[end][d]
   if end<0 or (end==gate and not held):return None
   for c in reversed(chain):after[state.index(c)]=adjacent[c][d]
   push=int(bool(chain))
  else:
   if target in state:return None
   behind=adjacent[origin][d^1]
   if behind>=0 and behind==state[3]:after[3]=origin;pull=1
  after[hero]=target;now=plate in after;destroy=0
  if held and not now:
   if gate in after[:3]:return None
   if after[3]==gate:after[3]=gone;destroy=1
  assert len(set(after))==4
  return tuple(after),push,pull,swap,destroy
 size=base**4;previous=array('i',[-2])*size;action=bytearray(size);first=encode(initial);previous[first]=-1;queue=array('I',[first]);cursor=0;victory=-1
 while cursor<len(queue):
  n=queue[cursor];cursor+=1;state=decode(n)
  if set(state[:3])==goals:victory=n;break
  for hero in range(3):
   for d in range(4):
    out=transition(state,hero,d)
    if out is None:continue
    nxt=encode(out[0])
    if previous[nxt]!=-2:continue
    previous[nxt]=n;action[nxt]=hero*4+d;queue.append(nxt)
  if cursor%100000==0:print(f'SEARCH18 {cursor} expanded,{len(queue)} visited,{time.monotonic()-began:.1f}s',flush=True)
 assert victory>=0,f'No living victory: {cursor} states exhausted'
 steps=[];n=victory
 while previous[n]>=0:
  old=previous[n];a=action[n];steps.append((decode(old),decode(n),a//4,a%4));n=old
 steps.reverse();selected=2;path='';choices=pushes=pulls=swaps=destroyed=0;trace=[]
 for move,(before,after,hero,d) in enumerate(steps,1):
  out=transition(before,hero,d);assert out[0]==after
  while selected!=hero:path+='C';selected=(selected+1)%3;choices+=1
  path+=symbols[d];pushes+=out[1];pulls+=out[2];swaps+=out[3];destroyed+=out[4]
  trace.append({'move':move,'input_event':len(path),'hero':level['heroes'][hero]['id'],'input':symbols[d],'heroes':[list(cells[v]) for v in after[:3]],'crystal':None if after[3]==gone else list(cells[after[3]]),'plate_held':plate in after,'pushes':pushes,'pulls':pulls,'swaps':swaps,'destroyed':destroyed,'completed':set(after[:3])==goals})
 sol={'level_id':level['id'],'path':path,'moves':len(steps),'directions':len(steps),'input_events':len(path),'selection_events':choices,'pushes':pushes,'pulls':pulls,'swaps':swaps,'destroyed_crystals':destroyed,'note':'独立红绿蓝身份占用BFS含能量再现毁晶状态，首次存活胜利停止，再按身份回放；不宣称穷举或最优。C免费选择不进撤销，蓝色圆盘仅为终点配色。18号可走、12号墙、19号单格能量不变。'}
 dest=ROOT/'levels/solutions/north_18.json'
 if args.write_solution:dest.write_text(json.dumps(sol,ensure_ascii=False,indent=2)+'\n')
 else:assert json.loads(dest.read_text())==sol
 report={'method':'Identity-aware four-object BFS with free selection and restoration deletion;first living victory,no exhaustive/optimality claim','floor_cells':count,'expanded_states':cursor,'visited_states':len(queue),'pending_states':len(queue)-cursor,'seconds':round(time.monotonic()-began,3),'solution':sol,'trace':trace}
 out=ROOT/'artifacts/verification/north_18_search.json';out.parent.mkdir(parents=True,exist_ok=True);out.write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n')
 print(json.dumps({k:v for k,v in report.items() if k!='trace'},ensure_ascii=False,indent=2),flush=True)
 for t in trace:print(t)
if __name__=='__main__':main()
