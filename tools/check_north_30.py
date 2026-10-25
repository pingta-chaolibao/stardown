"""Independent level30 identity replay and fixed-facing,first-target fire checks."""
from pathlib import Path
import json
ROOT=Path(__file__).resolve().parents[1]
TERRAIN=['######.##','.........','.........','.........','##.######']
DIRS={'U':(0,-1),'D':(0,1),'L':(-1,0),'R':(1,0)}
ROLES=['red','green','blue']
INITIAL=((0,1),(0,2),(0,3),(8,2),(6,0),(2,4))
GOALS={(8,1),(7,2),(8,3)}
FACINGS={4:(0,1),5:(0,-1)}
def plus(a,b):return (a[0]+b[0],a[1]+b[1])
def floor(c):return 0<=c[1]<5 and 0<=c[0]<9 and TERRAIN[c[1]][c[0]]=='.'
def fire_targets(state):
    targets=[]
    for source,direction in FACINGS.items():
        cell=plus(state[source],direction)
        while floor(cell) and cell!=state[3]:
            if cell in state:
                target=state.index(cell)
                assert target!=source
                targets.append((source,target));break
            cell=plus(cell,direction)
    return targets
def transition(state,selected,symbol):
    direction=DIRS[symbol];origin=state[selected];destination=plus(origin,direction)
    assert floor(destination),('blocked walk',state,selected,symbol)
    after=list(state);push=pull=swap=0
    target=None
    if selected==2:
        cell=destination
        while floor(cell):
            if cell in state:target=state.index(cell);break
            cell=plus(cell,direction)
    if target is not None:
        after[selected],after[target]=state[target],origin;swap=1
    elif selected==0:
        chain=[];cell=destination
        while cell in state:
            chain.append(state.index(cell));cell=plus(cell,direction)
        assert floor(cell),('blocked push',chain,cell)
        for identity in reversed(chain):after[identity]=plus(state[identity],direction)
        after[selected]=destination;push=int(bool(chain))
    else:
        assert destination not in state,('non-red cannot push',state,selected,symbol)
        after[selected]=destination
        behind=(origin[0]-direction[0],origin[1]-direction[1])
        if selected==1 and behind in state:
            identity=state.index(behind)
            if identity>=3:after[identity]=origin;pull=1
    assert len(set(after))==6 and all(floor(c) for c in after)
    assert not fire_targets(after),('unsafe constructed prefix',after,fire_targets(after))
    return tuple(after),push,pull,swap
def main():
    level=json.loads((ROOT/'levels/north_30.json').read_text());solution=json.loads((ROOT/'levels/solutions/north_30.json').read_text());path=solution['path']
    assert level['terrain']==TERRAIN and len(TERRAIN)==5 and all(len(row)==9 for row in TERRAIN)
    assert [tuple(h['position']) for h in level['heroes']]==list(INITIAL[:3]) and [h['kind'] for h in level['heroes']]==ROLES and level['active_hero']=='blue'
    assert level['crates']==[[8,2]] and {tuple(c) for c in level['exits']}==GOALS and level['objective']=='all_heroes_on_exits'
    assert level['monsters']==[{'kind':'fire_dragon','position':[6,0],'facing':'down'},{'kind':'fire_dragon','position':[2,4],'facing':'up'}]
    assert not any(level.get(k) for k in ['energy_links','fences','bushes'])
    state=INITIAL;selected=2;moves=pushes=pulls=swaps=choices=0;trace=[]
    for event,symbol in enumerate(path,1):
        before=state
        if symbol=='C':selected=(selected+1)%3;choices+=1;continue
        state,p,q,s=transition(state,selected,symbol);moves+=1;pushes+=p;pulls+=q;swaps+=s
        complete=set(state[:3])==GOALS
        assert complete==(event==len(path)),('premature or missing victory',event,state)
        trace.append({'action':moves,'event':event,'hero':ROLES[selected],'input':symbol,'heroes':state[:3],
            'crystal':state[3],'dragons':state[4:],'pushes':pushes,'pulls':pulls,'swaps':swaps,'completed':complete,'attack_targets':[]})
    assert (moves,choices,pushes,pulls,swaps)==(40,11,3,3,7)
    assert state[4:]==INITIAL[4:]
    report={'method':'Constructed route with independent identity replay and per-action first-target fire checks;not shortest or exhaustive',
        'path':path,'moves':moves,'selection_events':choices,'input_events':len(path),'pushes':pushes,'pulls':pulls,'swaps':swaps,
        'all_dragons_alive_and_fixed':True,'attack_events':0,'final_state':state,'trace':trace}
    report['solution']=solution
    assert all(report[k]==solution[k] for k in ['moves','selection_events','input_events','pushes','pulls','swaps'])
    output=ROOT/'artifacts/verification/north_30_route.json';output.parent.mkdir(parents=True,exist_ok=True);output.write_text(json.dumps(report,indent=2)+'\n')
    print('NORTH30 INDEPENDENT RESULT:',{k:v for k,v in report.items() if k!='trace'})
    for row in trace:print(row)
if __name__=='__main__':main()
