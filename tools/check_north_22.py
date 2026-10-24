#!/usr/bin/env python3
"""Independent safe-cell BFS for the confirmed no-crystal/no-ability level22."""
from collections import deque
from pathlib import Path
import json,argparse
ROOT=Path(__file__).resolve().parents[1]
def main():
 p=argparse.ArgumentParser(description=__doc__);p.add_argument('--write-solution',action='store_true');args=p.parse_args()
 d=json.loads((ROOT/'levels/north_22.json').read_text());assert d['terrain']==['#..........','...........','........#..','...........','#..........']
 assert all(m['kind']=='goblin' for m in d['monsters']);monsters={tuple(m['position']) for m in d['monsters']};floor={(x,y) for y,row in enumerate(d['terrain']) for x,c in enumerate(row) if c=='.'};danger={c for c in floor if any(abs(c[0]-m[0])+abs(c[1]-m[1])==1 for m in monsters)}
 assert len(floor)==52 and len(danger)==8 and not d['crates'] and not d.get('fences')
 start=tuple(d['player']);end=tuple(d['exit']);queue=deque([(start,'')]);seen={start};path=None
 while queue:
  cell,route=queue.popleft()
  if cell==end:path=route;break
  for symbol,(dx,dy) in {'U':(0,-1),'D':(0,1),'L':(-1,0),'R':(1,0)}.items():
   nxt=(cell[0]+dx,cell[1]+dy)
   if nxt in floor and nxt not in monsters and nxt not in danger and nxt not in seen:seen.add(nxt);queue.append((nxt,route+symbol))
 assert path
 sol={'level_id':d['id'],'path':path,'moves':len(path),'directions':len(path),'input_events':len(path),'selection_events':0,'pushes':0,'pulls':0,'swaps':0,'destroyed_crystals':0,'note':'独立安全格BFS；本关无可推动的隔晶链，避开三哥布林四向一格攻击范围，不改变最终修正地形。'}
 dest=ROOT/'levels/solutions/north_22.json'
 if args.write_solution:dest.write_text(json.dumps(sol,ensure_ascii=False,indent=2)+'\n')
 else:assert json.loads(dest.read_text())==sol
 out=ROOT/'artifacts/verification/north_22_route.json';out.parent.mkdir(parents=True,exist_ok=True);out.write_text(json.dumps({'visited':len(seen),'solution':sol,'floor':len(floor),'danger':[list(c) for c in sorted(danger)]},indent=2)+'\n');print(json.dumps(sol,ensure_ascii=False))
if __name__=='__main__':main()
