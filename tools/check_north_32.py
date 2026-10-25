"""Independently replay the user-confirmed level32, preserving entity identities."""
from pathlib import Path
import json
ROOT=Path(__file__).resolve().parents[1]
TERRAIN=['.......#..','.......#..','.......#..','.......##.','..........']
DIRS={'U':(0,-1),'D':(0,1),'L':(-1,0),'R':(1,0)}
GATE=(9,3)
def add(a,b):return a[0]+b[0],a[1]+b[1]
def distance(a,b):return abs(a[0]-b[0])+abs(a[1]-b[1])
def floor(c):return 0<=c[0]<10 and 0<=c[1]<5 and TERRAIN[c[1]][c[0]]=='.'
def replay(path):
    hero=(1,2);crystals=[(2,2),(4,3)];monsters=[(4,2),(0,4)];living=[True,True];pushes=0;trace=[];attacks=[]
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
        complete=hero==(9,1);assert complete==(action==len(path))
        trace.append({'action':action,'input':symbol,'player':hero,'crystals':list(crystals),'monsters':list(monsters),'monster_alive':list(living),'pushes':pushes,'barrier_active':any(living),'victims':sorted(victims),'completed':complete})
    assert (len(path),pushes,living)==(43,12,[False,False]) and attacks==[32]
    return {'moves':len(path),'pushes':pushes,'monster_death_action':32,'attack_actions':attacks,'final_player':hero,'final_crystals':crystals,'final_monsters':monsters,'trace':trace}
def main():
    level=json.loads((ROOT/'levels/north_32.json').read_text());solution=json.loads((ROOT/'levels/solutions/north_32.json').read_text())
    assert level['terrain']==TERRAIN and level['player']==[1,2] and level['hero_kind']=='red'
    assert level['crates']==[[2,2],[4,3]] and level['exit']==[9,1] and level['objective']=='player_on_exit'
    assert level['monsters']==[{'kind':'goblin','position':[4,2]},{'kind':'goblin','position':[0,4]}]
    assert level['energy_blocks']==[{'kind':'all_monsters_defeated','position':[9,3]}] and level['mechanism_color']=='red'
    assert not any(level.get(k) for k in ['energy_links','bushes','fences'])
    for n in range(1,51):assert floor(((n-1)%10,(n-1)//10))==(n not in [8,18,28,38,39])
    report=replay(solution['path']);report.update(method='Constructed route independently replayed on confirmed10x5,29/30floor;not shortest-direction claim',level=32,solution=solution)
    assert all(solution[k]==report[k] for k in ['moves','pushes','monster_death_action'])
    output=ROOT/'artifacts/verification/north_32_route.json';output.parent.mkdir(parents=True,exist_ok=True);output.write_text(json.dumps(report,indent=2)+'\n')
    print('NORTH32 INDEPENDENT RESULT:',{k:v for k,v in report.items() if k!='trace'})
if __name__=='__main__':main()
