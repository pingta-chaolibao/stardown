#!/usr/bin/env python3
"""Independently replay a constructed multi-hero route, with C as an undoable operation."""
from pathlib import Path
import argparse
import json

ROOT=Path(__file__).resolve().parents[1]
DIRS={"U":(0,-1),"D":(0,1),"L":(-1,0),"R":(1,0)}
PATH="DRRR"+"C"+"URRR"+"C"+"U"+"LLLULLDD"+"C"+"LLLDLLU"


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--write-solution",action="store_true")
    args=parser.parse_args()
    level=json.loads((ROOT/"levels/north_13.json").read_text())
    floor={(x,y) for y,row in enumerate(level["terrain"]) for x,t in enumerate(row) if t=="."}
    heroes=[tuple(h["position"]) for h in level["heroes"]]
    selected=next(i for i,h in enumerate(level["heroes"]) if h["id"]==level["active_hero"])
    crystals={tuple(c):i for i,c in enumerate(level["crates"])}
    goals=set(map(tuple,level["exits"]))
    plates=set(map(tuple,level["energy_links"][0]["plates"]))
    gate=tuple(level["energy_links"][0]["barriers"][0])
    trace=[];pushes=swaps=switches=0
    plus=lambda c,d:(c[0]+d[0],c[1]+d[1])
    for index,symbol in enumerate(PATH,1):
        old_selected=selected
        old_heroes=heroes.copy()
        pressed_before=plates.issubset(set(heroes)|set(crystals))
        active=not pressed_before
        def clear(c):return c in floor and not (active and c==gate)
        def occupied(c):return c in crystals or c in heroes
        if symbol=="C":
            selected=(selected+1)%len(heroes);switches+=1;action="switch"
            assert heroes==old_heroes
        else:
            direction=DIRS[symbol];origin=heroes[selected];target=plus(origin,direction)
            kind=level["heroes"][selected]["kind"]
            seen=target
            if kind=="blue":
                while clear(seen) and not occupied(seen):seen=plus(seen,direction)
            if kind=="blue" and clear(seen) and occupied(seen):
                if seen in heroes:heroes[heroes.index(seen)]=origin
                else:crystals[origin]=crystals.pop(seen)
                heroes[selected]=seen;swaps+=1;action="swap"
            else:
                assert clear(target),(index,"blocked",target)
                chain=[];terminal=target
                while occupied(terminal):chain.append(terminal);terminal=plus(terminal,direction)
                assert not chain or kind=="red"
                assert clear(terminal),(index,"blocked mixed push",terminal)
                for c in reversed(chain):
                    if c in heroes:heroes[heroes.index(c)]=plus(c,direction)
                    else:crystals[plus(c,direction)]=crystals.pop(c)
                heroes[selected]=target
                pushes+=bool(chain);action="push" if chain else "move"
            assert selected==old_selected,"Passive displacement never changes selected identity"
        held=plates.issubset(set(heroes)|set(crystals))
        assert held or gate not in crystals,"Undefined restoration cannot be part of the route"
        assert not (pressed_before and not held and gate in heroes),"No hero may die in the walkthrough"
        assert len(set(heroes)|set(crystals))==len(heroes)+len(crystals)
        complete=set(heroes)==goals
        assert complete==(index==len(PATH)),"Both distinct hero goals must complete only on final action"
        trace.append({"number":index,"input":symbol,"action":action,
                      "selected":level["heroes"][selected]["id"],"heroes":[list(c) for c in heroes],
                      "crystals_by_identity":{str(i):list(c) for c,i in crystals.items()},
                      "all_plates_held":held,"gate_active":not held,"completed":complete})
    assert len(PATH)==27 and switches==3 and swaps==2 and pushes==0
    solution={"level_id":level["id"],"path":PATH,"moves":len(PATH),"directions":len(PATH)-switches,
              "switches":switches,"pushes":pushes,"pulls":0,"swaps":swaps,
              "note":"UDLR为当前英雄方向输入，C为可撤销切换；每次成功方向或C均计一次操作。构造后独立校验，不宣称最优或穷举；不要求水晶移动或对应特定英雄终点。"}
    dest=ROOT/"levels/solutions/north_13.json"
    if args.write_solution:dest.write_text(json.dumps(solution,ensure_ascii=False,indent=2)+"\n")
    else:assert json.loads(dest.read_text())==solution
    report={"method":"constructed route independently replayed; no exhaustive/optimality claim",
            "solution":solution,"all_plates_action":9,"hero_exchange_action":11,
            "blue_goal_action":19,"both_goals_action":27,"trace":trace}
    out=ROOT/"artifacts/verification/north_13_route.json";out.parent.mkdir(parents=True,exist_ok=True)
    out.write_text(json.dumps(report,ensure_ascii=False,indent=2)+"\n")
    print(json.dumps({k:v for k,v in report.items() if k!="trace"},ensure_ascii=False,indent=2))
    print("ROUTE RESULT: 27 operations = 24 directions + 3 C switches; 2 swaps, both heroes on different goals")


if __name__=="__main__":main()
