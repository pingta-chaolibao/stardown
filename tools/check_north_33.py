"""Independently replay the user-confirmed level33, preserving entity identities."""
from pathlib import Path
import json
ROOT=Path(__file__).resolve().parents[1]
TERRAIN=['........####', '........####', '........#...', '............', '........#...', '........####', '........####']
DIRS={'U':(0,-1),'D':(0,1),'L':(-1,0),'R':(1,0)}
GATE=(8,3)
def add(a,b):return a[0]+b[0],a[1]+b[1]
def distance(a,b):return abs(a[0]-b[0])+abs(a[1]-b[1])
def floor(c):return 0<=c[0]<12 and 0<=c[1]<7 and TERRAIN[c[1]][c[0]]=='.'
def replay(path):
    hero=(2,3);crystals=[(6,3),(4,5)];monsters=[(1,2),(4,3),(0,6)];living=[True,True,True];pushes=0;trace=[];attacks=[]
    for action,symbol in enumerate(path,1):
        direction=DIRS[symbol];next_cell=add(hero,direction)
        occupied={c:('crystal',i) for i,c in enumerate(crystals)}
        occupied.update({c:('goblin',i) for i,c in enumerate(monsters) if living[i]})
        chain=[];cell=next_cell
        while cell in occupied:chain.append(occupied[cell]);cell=add(cell,direction)
        assert floor(cell) and not(any(living) and cell==GATE),('blocked chain end',action,cell)
        for family,i in chain:
            actors=crystals if family=='crystal' else monsters;actors[i]=add(actors[i],direction)
        hero=next_cell;pushes+=bool(chain)
        assert not any(living[i] and distance(hero,c)==1 for i,c in enumerate(monsters)),('hero died',action)
        victims={j for i,a in enumerate(monsters) for j,b in enumerate(monsters) if i!=j and living[i] and living[j] and distance(a,b)==1}
        if victims:attacks.append(action)
        for i in victims:living[i]=False
        assert floor(hero) and len(set(crystals))==2 and hero not in crystals
        assert not any(living[i] and c in crystals+[hero] for i,c in enumerate(monsters))
        complete=hero==(10,3);assert complete==(action==len(path))
        trace.append({'action':action,'input':symbol,'player':hero,'crystals':list(crystals),'monsters':list(monsters),'monster_alive':list(living),'pushes':pushes,'barrier_active':any(living),'victims':sorted(victims),'completed':complete})
    assert (len(path),pushes,living,attacks)==(68,21,[False,False,False],[58])
    death=attacks[0]
    return {'moves':len(path),'pushes':pushes,'monster_death_action':death,'attack_actions':attacks,'final_player':hero,'final_crystals':crystals,'final_monsters':monsters,'trace':trace}
def main():
    level=json.loads((ROOT/'levels/north_33.json').read_text());solution=json.loads((ROOT/'levels/solutions/north_33.json').read_text())
    assert level['terrain']==TERRAIN and level['player']==[2,3] and level['hero_kind']=='red'
    assert level['crates']==[[6,3],[4,5]] and level['exit']==[10,3] and level['objective']=='player_on_exit'
    assert level['monsters']==[{'kind':'goblin','position':list(c)} for c in [(1,2),(4,3),(0,6)]]
    assert level['energy_blocks']==[{'kind':'all_monsters_defeated','position':[8,3]}] and level['mechanism_color']=='red'
    assert not any(level.get(k) for k in ['energy_links','bushes','fences'])
    assert set(map(tuple,level['void_cells']))=={(x,y) for y,row in enumerate(TERRAIN) for x,c in enumerate(row) if c=='#'}
    assert all(floor((x,y)) for y in range(7) for x in range(8))
    assert all(floor((x,y)) for y in [2,3,4] for x in [9,10,11])
    report=replay(solution['path']);report.update(method='Constructed route independently replayed on confirmed12x7 main floor and right platform;not shortest-direction claim',level=33,solution=solution)
    assert all(solution[k]==report[k] for k in ['moves','pushes','monster_death_action'])
    output=ROOT/'artifacts/verification/north_33_route.json';output.parent.mkdir(parents=True,exist_ok=True);output.write_text(json.dumps(report,indent=2)+'\n')
    print('NORTH33 INDEPENDENT RESULT:',{k:v for k,v in report.items() if k!='trace'})
if __name__=='__main__':main()
