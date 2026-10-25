"""Independent identity-preserving replay of confirmed level31 and Goblin settlement."""
from pathlib import Path
import json
ROOT=Path(__file__).resolve().parents[1]
TERRAIN=['.......#...','.......#...','.......#...','..#....#...','..##...##.#','..#........','..#........','..#........']
DIRS={'U':(0,-1),'D':(0,1),'L':(-1,0),'R':(1,0)}
GATE=(9,4)
def add(a,b):return a[0]+b[0],a[1]+b[1]
def distance(a,b):return abs(a[0]-b[0])+abs(a[1]-b[1])
def floor(c):return 0<=c[0]<11 and 0<=c[1]<8 and TERRAIN[c[1]][c[0]]=='.'
def replay(path):
    hero=(0,5);crystals=[(8,6),(9,6)];monsters=[(7,5),(0,7)];living=[True,True]
    pushes=0;trace=[];top_used=set();attack_actions=[]
    for action,symbol in enumerate(path,1):
        direction=DIRS[symbol];next_cell=add(hero,direction)
        occupied={c:('crystal',i) for i,c in enumerate(crystals)}
        occupied.update({c:('goblin',i) for i,c in enumerate(monsters) if living[i]})
        chain=[];cell=next_cell
        while cell in occupied:chain.append(occupied[cell]);cell=add(cell,direction)
        assert floor(cell) and not(any(living) and cell==GATE),('blocked chain end',action,cell)
        for family,i in chain:
            if family=='crystal':crystals[i]=add(crystals[i],direction)
            else:monsters[i]=add(monsters[i],direction)
        hero=next_cell;pushes+=bool(chain)
        # All victims use the common post-movement snapshot, never sequential cancellation.
        assert not any(living[i] and distance(hero,c)==1 for i,c in enumerate(monsters)),('hero died',action)
        victims={j for i,a in enumerate(monsters) for j,b in enumerate(monsters) if i!=j and living[i] and living[j] and distance(a,b)==1}
        if victims:attack_actions.append(action)
        for i in victims:living[i]=False
        assert floor(hero) and len(set(crystals))==2 and hero not in crystals
        assert not any(living[i] and c in crystals+[hero] for i,c in enumerate(monsters))
        for c in [hero,*crystals]:
            if c[1]==0:top_used.add(78+c[0])
        complete=hero==(9,2)
        assert complete==(action==len(path)),('premature or missing victory',action)
        trace.append({'action':action,'input':symbol,'player':hero,'crystals':list(crystals),'monsters':list(monsters),'monster_alive':list(living),'pushes':pushes,'barrier_active':any(living),'victims':sorted(victims),'completed':complete})
    assert (len(path),pushes,living)==(96,29,[False,False])
    assert attack_actions==[77] and top_used=={78,79}
    return {'moves':len(path),'pushes':pushes,'monster_death_action':77,'attack_actions':attack_actions,'new_cells_used':sorted(top_used),'final_player':hero,'final_crystals':crystals,'final_monsters':monsters,'trace':trace}
def main():
    level=json.loads((ROOT/'levels/north_31.json').read_text());solution=json.loads((ROOT/'levels/solutions/north_31.json').read_text());mapping=json.loads((ROOT/'levels/mappings/north_31_markers.json').read_text())
    assert level['terrain']==TERRAIN and level['player']==[0,5] and level['hero_kind']=='red'
    assert level['crates']==[[8,6],[9,6]] and level['exit']==[9,2] and level['objective']=='player_on_exit'
    assert level['monsters']==[{'kind':'goblin','position':[7,5]},{'kind':'goblin','position':[0,7]}]
    assert level['energy_blocks']==[{'kind':'all_monsters_defeated','position':[9,4]}]
    assert not any(level.get(k) for k in ['energy_links','bushes','fences'])
    for n in range(1,78):assert mapping['marker_to_runtime_cell'][str(n)]==[(n-1)%11,(n-1)//11+1]
    for n in range(78,89):
        cell=mapping['marker_to_runtime_cell'][str(n)];assert cell==[n-78,0] and floor(cell)==(n!=85)
    report=replay(solution['path']);report.update(method='Constructed route independently replayed against the COMPLETE user-confirmed11x8 terrain;not shortest',level=31,solution=solution)
    assert all(solution[k]==report[k] for k in ['moves','pushes','monster_death_action'])
    output=ROOT/'artifacts/verification/north_31_route.json';output.parent.mkdir(parents=True,exist_ok=True);output.write_text(json.dumps(report,indent=2)+'\n')
    print('NORTH31 INDEPENDENT RESULT:',{k:v for k,v in report.items() if k!='trace'})
if __name__=='__main__':main()
