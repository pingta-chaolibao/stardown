#!/usr/bin/env python3
"""Independent stable-identity direction replay for purple/yellow cooperation."""
from pathlib import Path
from collections import deque
import json
ROOT=Path(__file__).resolve().parents[1]
DIR={'U':(0,-1),'D':(0,1),'L':(-1,0),'R':(1,0)}
ROWS=['.#######.','.#.#.#.#.','.........','.##.#.##.','.#######.']
FLOOR={(x,y) for y,row in enumerate(ROWS) for x,c in enumerate(row) if c=='.'}
plus=lambda p,d:(p[0]+d[0],p[1]+d[1])
distance=lambda a,b:abs(a[0]-b[0])+abs(a[1]-b[1])
INITIAL=((0,0),(0,4),(2,1),(4,1),(6,1),(3,3),(5,3))
DEAD=(-1,-1)
def move(state,selected,symbol):
    d=DIR[symbol];a=list(state);origin=a[selected];target=plus(origin,d);swapped=False
    if selected==0:
        c=target
        while c in FLOOR:
            if c in a:
                other=a.index(c);a[selected],a[other]=a[other],a[selected];swapped=True;break
            c=plus(c,d)
    if not swapped:
        if target not in FLOOR or target in a:return None
        a[selected]=target
    protected=[distance(a[0],a[1])<=1,True]
    living=[i for i in range(2,7) if a[i]!=DEAD]
    attack_positions=tuple(a)
    hero_victims=[h for h in range(2) if not protected[h] and any(distance(a[h],a[m])==1 for m in living)]
    monster_victims=[m for m in living if any(m!=j and distance(a[m],a[j])==1 for j in living)]
    if hero_victims:return None
    for m in monster_victims:a[m]=DEAD
    return tuple(a),{'swapped':swapped,'protected_heroes':protected,'monster_victims':[m-2 for m in monster_victims],
      'blocked_goblins':[m-2 for m in living if any(protected[h] and distance(a[h],attack_positions[m])==1 for h in range(2))],
      'shield_blocks':[{'hero':h,'position':list(a[h]),'source':'goblin'} for h in range(2)
                       if protected[h] and any(distance(a[h],attack_positions[m])==1 for m in living)]}
def solved(s):return {s[0],s[1]}=={(8,0),(8,4)}
def check():
    d=json.loads((ROOT/'levels/north_41.json').read_text())
    assert d['terrain']==ROWS and d['swap_hero_color']=='purple' and len(FLOOR)==22
    assert d['heroes']==[{'id':'purple','kind':'blue','position':[0,0]},{'id':'yellow','kind':'yellow','position':[0,4]}]
    assert d['active_hero']=='purple' and d['objective']=='all_heroes_on_exits' and d['exits']==[[8,0],[8,4]] and d['crates']==[]
    assert d['monsters']==[{'kind':'goblin','position':list(p)} for p in INITIAL[2:]]
    # Selection is free and has no game-state effect,so search choices include
    # either hero without folding a selection event into an action.
    q=deque([INITIAL]);parents={INITIAL:None};goal=None
    while q:
        s=q.popleft()
        if solved(s):goal=s;break
        for h in range(2):
            for symbol in DIR:
                result=move(s,h,symbol)
                if result is None:continue
                after,_=result
                if after not in parents:
                    parents[after]=(s,h,symbol);q.append(after)
        assert len(parents)<1000000,'Bounded search exceeded;do not change confirmed map'
    assert goal is not None,'No legal route found;diagnose without changing rules'
    choices=[];s=goal
    while parents[s] is not None:
        before,h,symbol=parents[s];choices.append((h,symbol));s=before
    choices.reverse();state=INITIAL;selected=0;actions=0;swaps=0;trace=[];path=''
    def record(symbol,event):
        trace.append({'event_index':len(trace)+1,'input':symbol,'selected':selected,'actions':actions,'swaps':swaps,
          'heroes':[list(c) for c in state[:2]],'hero_alive':[True,True],
          'monster_positions':[list(c) for c in state[2:]],'monster_alive':[c!=DEAD for c in state[2:]],
          'protected_heroes':[distance(state[0],state[1])<=1,True],'completed':solved(state),**event})
    for h,symbol in choices:
        if selected!=h:selected=h;path+='C';record('C',{'swapped':False,'monster_victims':[],'shield_blocks':[]})
        result=move(state,selected,symbol);assert result is not None;state,event=result
        actions+=1;swaps+=event['swapped'];path+=symbol;record(symbol,event)
        assert solved(state)==(actions==len(choices))
    solution={'level_id':d['id'],'path':path,'moves':actions,'directions':actions,'input_events':len(path),
      'selection_events':path.count('C'),'pushes':0,'pulls':0,'swaps':swaps,'destroyed_crystals':0,
      'surviving_monsters':sum(p!=DEAD for p in state[2:]),
      'note':'用户确认22可走格9×5；紫色被动交换与黄色正交保护协作，免费切换不推进攻击，两英雄分别到右侧两目标。稳定ID独立回放，不宣称最短。'}
    (ROOT/'levels/solutions/north_41.json').write_text(json.dumps(solution,ensure_ascii=False,indent=2)+'\n')
    proof={'solution':solution,'trace':trace,'visited_states':len(parents),'initial':[list(p) for p in INITIAL],
      'final':[list(p) for p in state],'no_map_or_rule_changes':True}
    p=ROOT/'artifacts/verification/north_41_route.json';p.parent.mkdir(exist_ok=True);p.write_text(json.dumps(proof,ensure_ascii=False,indent=2)+'\n')
    print('NORTH41 INDEPENDENT:',json.dumps(solution,ensure_ascii=False),'visited',len(parents))
    return proof
if __name__=='__main__':check()
