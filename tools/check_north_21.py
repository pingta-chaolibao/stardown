#!/usr/bin/env python3
"""Independently construct and replay a staged level21 route; no optimality claim."""
from pathlib import Path
from collections import deque
import json,argparse
ROOT=Path(__file__).resolve().parents[1]
DIRS={'U':(0,-1),'D':(0,1),'L':(-1,0),'R':(1,0)}
class Puzzle:
 def __init__(self):
  self.level=json.loads((ROOT/'levels/north_21.json').read_text());d=self.level
  self.floor={(x,y) for y,row in enumerate(d['terrain']) for x,c in enumerate(row) if c=='.'}
  self.plates={tuple(c) for c in d['energy_links'][0]['plates']};self.gates={tuple(c) for c in d['energy_links'][0]['barriers']};self.goals={tuple(c) for c in d['exits']}
  self.initial=tuple(tuple(h['position']) for h in d['heroes'])+tuple(map(tuple,d['crates']));self.state=self.initial;self.selected=0;self.path='';self.trace=[];self.counts=[0,0,0,0];self.stages={};self.walk_search_states=0
 def held(self,state):return self.plates.issubset(state)
 def transition(self,s,hero,symbol):
  dx,dy=DIRS[symbol];origin=s[hero];held=self.held(s);after=list(s);push=pull=swap=destroyed=0
  def plus(c):return(c[0]+dx,c[1]+dy)
  def clear(c):return c in self.floor and not(c in self.gates and not held)
  target=plus(origin)
  if hero==2:
   cell=target;visible=None
   while clear(cell):
    if cell in s:visible=cell;break
    cell=plus(cell)
   if visible is not None:after[s.index(visible)]=origin;target=visible;swap=1
   elif not clear(target) or target in s:return None
  elif hero==0:
   chain=[];cell=target
   while clear(cell) and cell in s:chain.append(cell);cell=plus(cell)
   if not clear(cell):return None
   for c in reversed(chain):after[s.index(c)]=plus(c)
   push=int(bool(chain))
  else:
   if not clear(target) or target in s:return None
   behind=(origin[0]-dx,origin[1]-dy)
   if behind in s[3:]:after[s.index(behind)]=origin;pull=1
  after[hero]=target
  if held and not self.held(after):
   if self.gates.intersection(after[:3]):return None
   for i in range(3,len(after)):
    if after[i] in self.gates:after[i]=None;destroyed+=1
  assert len([c for c in after if c is not None])==len({c for c in after if c is not None})
  return tuple(after),(push,pull,swap,destroyed)
 def do(self,hero,path):
  for symbol in path:
   while self.selected!=hero:self.path+='C';self.selected=(self.selected+1)%3
   out=self.transition(self.state,hero,symbol);assert out is not None,('illegal',len(self.trace)+1,hero,symbol,self.state)
   self.state,delta=out;self.path+=symbol;self.counts=[a+b for a,b in zip(self.counts,delta)]
   self.trace.append({'move':len(self.trace)+1,'input_event':len(self.path),'hero':self.level['heroes'][hero]['id'],'input':symbol,'heroes':self.state[:3],'crystals':self.state[3:],'plate_count':len(self.plates.intersection(self.state)),'all_plates_held':self.held(self.state),'pushes':self.counts[0],'pulls':self.counts[1],'swaps':self.counts[2],'destroyed':self.counts[3],'completed':set(self.state[:3])==self.goals})
 def go(self,hero,cell):
  cell=tuple(cell);first=self.state;queue=deque([(first,'')]);seen={first}
  while queue:
   s,path=queue.popleft();self.walk_search_states+=1
   if s[hero]==cell:self.do(hero,path);return
   for symbol in DIRS:
    out=self.transition(s,hero,symbol)
    if out is None or any(out[1]) or out[0] in seen:continue
    seen.add(out[0]);queue.append((out[0],path+symbol))
  raise AssertionError(('no pure-walk path',hero,cell,self.state))
 def stage(self,name):
  self.stages[name]=len(self.trace);print(name,len(self.trace),self.state,'plates',len(self.plates.intersection(self.state)),flush=True)
 def construct(self):
  self.go(0,(1,1));self.do(0,'R');self.go(0,(3,2));self.do(0,'U');self.go(0,(0,2));self.stage('left_setup')
  self.go(1,(5,1));self.do(1,'D');self.go(1,(7,0));self.stage('middle_setup')
  self.go(2,(12,1));self.do(2,'L');self.go(2,(12,2));self.do(2,'U');self.go(2,(10,0));self.stage('first_all_six')
  self.do(2,'D');self.stage('lower_crystal_replaces_blue')
  self.go(2,(6,4));self.do(2,'D');self.stage('bottom_crystal_lifted')
  self.go(2,(2,2));self.do(2,'L');self.stage('red_freed')
  self.go(0,(7,4));self.do(0,'LLLL');self.go(0,(2,5));self.do(0,'UU');self.stage('crystal_at_left_gate_exit')
  self.do(2,'R');self.stage('left_plate_crystal_handoff')
  self.do(0,'D');self.do(2,'D');self.stage('blue_red_clear_left_corridor')
  self.go(2,(7,1));self.do(2,'L');self.go(0,(7,2));self.do(1,'L');self.stage('safe_single_plate_release')
  self.do(0,'U');self.stage('middle_crystal_repositions_top_plate')
  self.go(1,(6,8));self.do(1,'L');self.go(1,(6,7));self.do(1,'UUUUUU');self.stage('last_crystal_pulled_above_gate')
  self.go(0,(7,2));self.do(0,'L');self.do(2,'D');self.stage('six_crystals_hold_all_plates')
  self.do(0,'DDD');self.go(1,(5,5));self.do(2,'RDR');self.do(0,'DDD');self.stage('victory')
  assert set(self.state[:3])==self.goals and self.held(self.state) and self.counts[3]==0
  sol={'level_id':self.level['id'],'path':self.path,'moves':len(self.trace),'directions':len(self.trace),'input_events':len(self.path),'selection_events':self.path.count('C'),'pushes':self.counts[0],'pulls':self.counts[1],'swaps':self.counts[2],'destroyed_crystals':self.counts[3],'note':'独立构造的六板接替路线，单英雄纯步行局部BFS与每次完整动作重算；非全状态搜索，不宣称最短或穷举。C免费，明确无栅栏。'}
  return sol
if __name__=='__main__':
 p=argparse.ArgumentParser(description=__doc__);p.add_argument('--write-solution',action='store_true');args=p.parse_args();game=Puzzle();sol=game.construct();dest=ROOT/'levels/solutions/north_21.json'
 if args.write_solution:dest.write_text(json.dumps(sol,ensure_ascii=False,indent=2)+'\n')
 else:assert json.loads(dest.read_text())==sol
 out=ROOT/'artifacts/verification/north_21_route.json';out.parent.mkdir(parents=True,exist_ok=True);out.write_text(json.dumps({'method':'Constructed legal stages with identity-preserving independent transition; local walk-only BFS,not exhaustive/optimal','walk_search_states':game.walk_search_states,'solution':sol,'stages':game.stages,'trace':game.trace},ensure_ascii=False,indent=2)+'\n');print(json.dumps(sol,ensure_ascii=False,indent=2))
