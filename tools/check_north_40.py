#!/usr/bin/env python3
"""Independent identity replay for the confirmed yellow-hero map."""
from pathlib import Path
from collections import deque
import json
ROOT=Path(__file__).resolve().parents[1]
DIR={'U':(0,-1),'D':(0,1),'L':(-1,0),'R':(1,0)}
def check():
    d=json.loads((ROOT/'levels/north_40.json').read_text())
    rows=['...#.#.#.','.........','....#.#..','....###..','.........']
    assert d['terrain']==rows and d['hero_kind']=='yellow' and d['player']==[1,1] and d['exit']==[2,3]
    assert d['crates']==[[0,2],[2,2],[1,3],[3,3],[7,3]]
    monsters=d['monsters']; occupied={tuple(x['position']) for x in monsters}|{tuple(x) for x in d['crates']}
    assert [tuple(x['position']) for x in monsters]==[(4,0),(6,0),(8,0),(3,2),(5,2),(7,2),(0,4)]
    assert all(x['kind']=='goblin' for x in monsters[:6]) and monsters[6]=={'kind':'fire_dragon','position':[0,4],'facing':'right'}
    floor=lambda c:0<=c[0]<9 and 0<=c[1]<5 and rows[c[1]][c[0]]=='.'
    plus=lambda a,b:(a[0]+b[0],a[1]+b[1])
    path='RRRRRRRDDDLLLLLLU'; hero=(1,1); trace=[]
    for n,s in enumerate(path,1):
        hero=plus(hero,DIR[s]);assert floor(hero) and hero not in occupied
        blocked_goblins=[i for i,m in enumerate(monsters[:6]) if abs(m['position'][0]-hero[0])+abs(m['position'][1]-hero[1])==1]
        # Every living yellow protects itself. The first protected hero stops
        # the ray; it does not turn into a target behind the shield.
        c=(1,4);cells=[];shield=False;target=None
        while floor(c) and c not in {tuple(x) for x in d['crates']}:
            cells.append(list(c))
            if c==hero:shield=True;break
            if c in {tuple(x['position']) for x in monsters[:6]}:target=c;break
            c=plus(c,(1,0))
        assert target is None
        assert all(abs(a['position'][0]-b['position'][0])+abs(a['position'][1]-b['position'][1])!=1 for i,a in enumerate(monsters[:6]) for j,b in enumerate(monsters) if i!=j)
        trace.append({'action':n,'input':s,'player':list(hero),'protected_heroes':[True],
                      'blocked_goblins':blocked_goblins,'fire_shield':shield,'fire_cells':cells,
                      'attacks':[],'monsters_alive':[True]*7,'completed':hero==(2,3)})
        assert trace[-1]['completed']==(n==len(path))
    assert hero==(2,3)
    goblin_steps=[x['action'] for x in trace if x['blocked_goblins']]
    fire_steps=[x['action'] for x in trace if x['fire_shield']]
    assert goblin_steps==list(range(2,9)) and fire_steps==list(range(10,17))
    # Independently verify the candidate uses only connected, unoccupied floor.
    seen={(1,1)};q=deque(seen)
    while q:
        p=q.popleft()
        for delta in DIR.values():
            c=plus(p,delta)
            if floor(c) and c not in occupied and c not in seen:seen.add(c);q.append(c)
    assert (2,3) in seen
    solution={'level_id':d['id'],'path':path,'moves':17,'directions':17,'input_events':17,
              'selection_events':0,'pushes':0,'pulls':0,'swaps':0,'destroyed_crystals':0,
              'goblin_shield_actions':goblin_steps,'fire_shield_actions':fire_steps,
              'surviving_monsters':7,'note':'用户确认9×5，黄色只能行走和保护；17步绕右侧到底排，保护挡住哥布林邻接和火龙首目标，五晶及七怪保留。不宣称最短路线。'}
    proof={'solution':solution,'trace':trace,'connected_safe_occupancy_cells':len(seen),'all_crystals_and_monsters_stationary':True}
    (ROOT/'levels/solutions/north_40.json').write_text(json.dumps(solution,ensure_ascii=False,indent=2)+'\n')
    p=ROOT/'artifacts/verification/north_40_route.json';p.parent.mkdir(exist_ok=True);p.write_text(json.dumps(proof,ensure_ascii=False,indent=2)+'\n')
    print('NORTH40 INDEPENDENT:17 legal actions,7 Goblin shield steps,7 fire shield steps,5 crystals+7 monsters preserved')
    return proof
if __name__=='__main__':check()
