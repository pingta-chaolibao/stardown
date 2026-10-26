#!/usr/bin/env python3
"""Check committed walkthrough media and independently replay their input evidence."""

from pathlib import Path
from fractions import Fraction
import hashlib
import json
import struct
import subprocess


ROOT = Path(__file__).resolve().parents[1]
DIRECTIONS = {"U": (0, -1), "D": (0, 1), "L": (-1, 0), "R": (1, 0)}


def check_replay(item, directory, require_rendered=True):
    evidence = json.loads((directory / item["replay_report"]).read_text())
    level = json.loads((ROOT / item["level_file"]).read_text())
    solution = json.loads((ROOT / item["solution_file"]).read_text())
    definitions = level.get("heroes", [{"id": "hero_01", "kind": level.get("hero_kind", "red"), "position": level.get("player")}])
    heroes = [tuple(hero["position"]) for hero in definitions]
    selected = next((i for i, hero in enumerate(definitions) if hero["id"] == level.get("active_hero")), 0)
    assert all(hero["kind"] in ("red", "green", "blue", "yellow") for hero in definitions)
    multi = len(heroes) > 1
    crystals = {tuple(cell): identity for identity, cell in enumerate(level["crates"])}
    monster_kinds = [entry["kind"] for entry in level.get("monsters", [])]
    assert all(kind in ("goblin","fire_dragon") for kind in monster_kinds), "Unknown monster kinds need explicit behavior, no goblin default"
    monster_positions = [tuple(entry["position"]) for entry in level.get("monsters", [])]
    monster_living = [True] * len(monster_positions)
    facings = [dict(up=(0,-1),down=(0,1),left=(-1,0),right=(1,0)).get(entry.get("facing")) for entry in level.get("monsters", [])]
    assert all(facings[i] is not None for i,k in enumerate(monster_kinds) if k=="fire_dragon"), "Dragon direction required"
    def monster_cells():
        return {cell: i for i, cell in enumerate(monster_positions) if monster_living[i]}
    bushes = {tuple(cell) for cell in level.get("bushes", [])}
    exits = {tuple(cell) for cell in level.get("exits", [level["exit"]] if "exit" in level else [])}
    initial = evidence["initial_state"]
    assert initial["player"] == list(heroes[selected]) and initial["moves"] == 0
    assert not initial["completed"] and evidence["path"] == solution["path"]
    assert initial["level_id"] == level["id"] == solution["level_id"]
    assert evidence["game_implementation_commit"] == item["game_implementation_commit"]
    if require_rendered:
        assert evidence["display"] == "X11"
    assert len(evidence["trace"]) == len(solution["path"]) == solution.get("input_events",solution["moves"])

    def floor(cell):
        x, y = cell
        return 0 <= y < len(level["terrain"]) and 0 <= x < len(level["terrain"][0]) and level["terrain"][y][x] == "."

    def plus(cell, delta):
        return cell[0] + delta[0], cell[1] + delta[1]

    fences = set()
    for a,b in level.get("fences", []):
        a,b = tuple(a),tuple(b)
        assert floor(a) and floor(b) and abs(a[0]-b[0])+abs(a[1]-b[1]) == 1
        edge = frozenset((a,b))
        assert edge not in fences, "Duplicate/reversed fence edge"
        fences.add(edge)
    def edge_blocked(a,b):
        return frozenset((a,b)) in fences

    clear_cells = set()
    for block in level.get("energy_blocks", []):
        assert block["kind"] == "all_monsters_defeated", "Unknown energy condition must not default to pressure"
        cell = tuple(block["position"])
        assert floor(cell) and cell not in bushes and cell not in clear_cells
        assert all(cell not in [tuple(c) for c in link["barriers"]] and cell not in [tuple(c) for c in link.get("plates", [link["plate"]] if "plate" in link else [])] for link in level.get("energy_links", []))
        clear_cells.add(cell)

    def settle(previous_barriers, advance=True):
        pressure, barriers = {}, {}
        for link in level.get("energy_links", []):
            sources = link["pressure_sources"]
            plates = [tuple(cell) for cell in link.get("plates", [link["plate"]] if "plate" in link else [])]
            assert plates and link.get("activation", "all") == "all"
            assert all(monster_kinds[monster_cells()[p]]=="goblin" for p in set(plates).intersection(monster_cells())), "Only living Goblin pressure is confirmed"
            pressure[link["id"]] = all(("hero" in sources and plate in heroes) or ("crystal" in sources and plate in crystals) or (plate in monster_cells() and monster_kinds[monster_cells()[plate]]=="goblin") for plate in plates)
        color_pressed = {}
        for link in level.get("energy_links", []):
            color=link.get("color",level.get("mechanism_color","yellow"))
            color_pressed[color]=color_pressed.get(color,True) and pressure[link["id"]]
        for link in level.get("energy_links", []):
            barriers.update({tuple(cell): not color_pressed[link.get("color",level.get("mechanism_color","yellow"))] for cell in link["barriers"]})
        barriers.update({cell: any(monster_living) for cell in clear_cells})
        living = [True] * len(heroes)
        for cell, active in barriers.items():
            if active:
                if cell in crystals:
                    assert cell in previous_barriers and not previous_barriers[cell], "Crystal cannot occupy an already-active energy cell"
                    del crystals[cell]
                if not previous_barriers.get(cell, False) and cell in heroes:
                    living[heroes.index(cell)] = False
        for i, cell in enumerate(monster_positions):
            if monster_living[i] and barriers.get(cell, False):
                assert cell in previous_barriers and not previous_barriers[cell], "Monster cannot start in solid energy"
                monster_living[i] = False
        # Sample all attacks from the common state, before attack deaths.
        protected = [living[h] and any(definitions[y]["kind"]=="yellow" and living[y] and abs(cell[0]-heroes[y][0])+abs(cell[1]-heroes[y][1])<=1 for y in range(len(heroes))) for h,cell in enumerate(heroes)]
        goblin_heroes = []
        for h,cell in enumerate(heroes):
            for i,monster in enumerate(monster_positions):
                if living[h] and not protected[h] and monster_living[i] and monster_kinds[i]=="goblin" and abs(cell[0]-monster[0])+abs(cell[1]-monster[1])==1:
                    assert not edge_blocked(cell,monster), "Goblin/fence attack is undefined"
                    goblin_heroes.append(h)
        targets = {}
        goblin_monsters = []
        if advance:
            for i,origin in enumerate(monster_positions):
                if not monster_living[i] or monster_kinds[i]!="fire_dragon":continue
                cell = plus(origin,facings[i]);previous = origin
                while floor(cell) and cell not in bushes and not barriers.get(cell,False) and cell not in crystals:
                    assert not edge_blocked(previous,cell), "Fire/fence interaction is unconfirmed"
                    if cell in heroes and living[heroes.index(cell)]:
                        if not protected[heroes.index(cell)]:targets[i] = ("hero",heroes.index(cell))
                        break
                    if cell in monster_cells():targets[i] = ("monster",monster_cells()[cell]);break
                    previous = cell;cell = plus(cell,facings[i])
            for i,goblin in enumerate(monster_positions):
                if not monster_living[i] or monster_kinds[i]!="goblin":continue
                for v,target in enumerate(monster_positions):
                    if v!=i and monster_living[v] and monster_kinds[v] in ("goblin","fire_dragon") and abs(goblin[0]-target[0])+abs(goblin[1]-target[1])==1:
                        assert not edge_blocked(goblin,target), "Goblin/fence attack is undefined"
                        goblin_monsters.append(v)
        for family,victim in targets.values():
            if family=="hero":living[victim] = False
            else:monster_living[victim] = False
        for victim in goblin_monsters:monster_living[victim] = False
        for h in goblin_heroes:living[h] = False
        # Death releases living-Goblin pressure in the SAME action. Restore
        # energy victims once,without a second attack sample or corpse pressure.
        for link in level.get("energy_links", []):
            sources=link["pressure_sources"]
            plates=[tuple(c) for c in link.get("plates",[link["plate"]] if "plate" in link else [])]
            pressure[link["id"]]=all(("hero" in sources and p in heroes) or ("crystal" in sources and p in crystals) or (p in monster_cells() and monster_kinds[monster_cells()[p]]=="goblin") for p in plates)
        color_pressed={};post={}
        for link in level.get("energy_links", []):
            color=link.get("color",level.get("mechanism_color","yellow"))
            color_pressed[color]=color_pressed.get(color,True) and pressure[link["id"]]
        for link in level.get("energy_links", []):
            post.update({tuple(c):not color_pressed[link.get("color",level.get("mechanism_color","yellow"))] for c in link["barriers"]})
        for cell,active in post.items():
            if active and not barriers.get(cell,False):
                crystals.pop(cell,None)
                if cell in heroes:living[heroes.index(cell)]=False
                for i,pos in enumerate(monster_positions):
                    if monster_living[i] and pos==cell:monster_living[i]=False
        barriers.update(post)
        barriers.update({cell: any(monster_living) for cell in clear_cells})
        return pressure, barriers, living

    pressure, barriers, living = settle({}, advance=False)

    def walkable(cell):
        return floor(cell) and cell not in bushes and not barriers.get(cell, False)

    def completed():
        if level["objective"] == "all_heroes_on_exits":
            return all(living) and set(heroes) == exits
        return all(living) and heroes[selected] in exits

    pushes, pulls, swaps, selection_events, actual_actions = 0, 0, 0, 0, 0
    dragon_pulls = 0

    def check_state(state, moves):
        assert all(living) and state.get("alive", True), "Walkthrough must never use a dead hero"
        assert len(set(heroes)) == len(heroes) and not set(heroes).intersection(crystals)
        assert state["player"] == list(heroes[selected])
        assert state.get("hero_kind", "red") == definitions[selected]["kind"]
        assert state["moves"] == moves and state["pushes"] == pushes
        assert state.get("pulls", 0) == pulls and state.get("swaps", 0) == swaps
        assert state.get("selection_events", 0) == selection_events
        if "dragon_pulls" in solution:assert state["dragon_pulls"] == dragon_pulls
        if multi:
            assert state["history_size"] == moves and "switches" not in state
        assert state["completed"] == completed()
        if multi:
            assert state["active_hero"] == definitions[selected]["id"] and state["active_hero_index"] == selected
            assert state["heroes"] == [{"id": hero["id"], "kind": hero["kind"], "position": list(heroes[i]), "alive": living[i], "selected": i == selected} for i, hero in enumerate(definitions)]
            assert {tuple(cell) for cell in state["exits"]} == exits
            assert state["occupied_exits"] == sum(cell in exits for cell in heroes)
        actual = {tuple(entry["position"]): entry["id"] for entry in state["crystals"]}
        assert actual == crystals
        if monster_positions:
            expected_monsters = [{"id": i, "kind":monster_kinds[i], "position": list(cell), "alive": monster_living[i], **({"facing":list(facings[i])} if monster_kinds[i]=="fire_dragon" else {})} for i,cell in enumerate(monster_positions)]
            assert state["monsters"] == expected_monsters
            assert state.get("death_reason", "") == ""
            assert not set(heroes).intersection(monster_cells()) and not set(crystals).intersection(monster_cells())
        if fences:
            assert {frozenset((tuple(a),tuple(b))) for a,b in state["fences"]} == fences

        for entry in state["crystals"]:
            assert entry["color"] == level["crystal_colors"][entry["id"]]
        if bushes or "bushes" in state:
            assert {tuple(cell) for cell in state["bushes"]} == bushes
        if "plates" in state:
            actual_plates = {(entry["group"], tuple(entry["position"])): entry["pressed"] for entry in state["plates"]}
            expected_plates = {}
            for link in level.get("energy_links", []):
                for cell in link.get("plates", [link["plate"]] if "plate" in link else []):
                    plate = tuple(cell)
                    expected_plates[(link["id"], plate)] = (("hero" in link["pressure_sources"] and plate in heroes)
                        or ("crystal" in link["pressure_sources"] and plate in crystals)
                        or (plate in monster_cells() and monster_kinds[monster_cells()[plate]]=="goblin"))
            assert actual_plates == expected_plates
        if level.get("energy_links") or "pressure" in state:
            assert state["pressure"] == pressure
            assert {tuple(entry["position"]): entry["active"] for entry in state["barriers"]} == barriers

    check_state(initial, 0)
    for index, (symbol, state) in enumerate(zip(solution["path"], evidence["trace"]), 1):
        assert state["input"] == symbol and not completed()
        player = heroes[selected]
        if symbol == "C":
            assert multi and state["action"] == "switch"
            selected = (selected + 1) % len(heroes)
            selection_events += 1
        else:
            actual_actions += 1
            direction = DIRECTIONS[symbol]
            hero_kind = definitions[selected]["kind"]
            target = plus(player, direction)
            visible = target
            if hero_kind == "blue":
                while walkable(visible) and visible not in crystals and visible not in heroes and visible not in monster_cells():
                    visible = plus(visible, direction)
            automatic_swap = hero_kind == "blue" and walkable(visible) and (visible in crystals or visible in heroes or visible in monster_cells())
            assert state.get("action", "move") == ("swap" if automatic_swap else "move")
            if automatic_swap:
                target = visible
                if target in crystals:
                    crystals[player] = crystals.pop(target)
                elif target in monster_cells():
                    monster_positions[monster_cells()[target]] = player
                else:
                    heroes[heroes.index(target)] = player
                swaps += 1
            else:
                assert walkable(target) and not edge_blocked(player,target)
                assert hero_kind == "red" or (target not in crystals and target not in heroes and target not in monster_cells()), "Green/blue cannot push"
                chain = []
                terminal = target
                while terminal in crystals or terminal in heroes or terminal in monster_cells():
                    chain.append(terminal)
                    terminal = plus(terminal, direction)
                assert walkable(terminal)
                assert all(not edge_blocked(cell,plus(cell,direction)) for cell in chain), "Any blocked mixed-chain edge rejects the entire push"
                for cell in reversed(chain):
                    if cell in crystals:
                        crystals[plus(cell, direction)] = crystals.pop(cell)
                    elif cell in monster_cells():
                        monster_positions[monster_cells()[cell]] = plus(cell,direction)
                    else:
                        heroes[heroes.index(cell)] = plus(cell, direction)
                pushes += bool(chain)
                behind = (player[0] - direction[0], player[1] - direction[1])
                if hero_kind == "green" and behind in crystals:
                    assert not edge_blocked(behind,player), "Automatic pull cannot cross a fence"
                    crystals[player] = crystals.pop(behind)
                    pulls += 1
                elif hero_kind == "green" and behind in monster_cells() and monster_kinds[monster_cells()[behind]]=="fire_dragon":
                    assert not edge_blocked(behind,player), "Automatic dragon pull cannot cross a fence"
                    monster_positions[monster_cells()[behind]] = player
                    pulls += 1
                    dragon_pulls += 1
            heroes[selected] = target
            pressure, barriers, living = settle(barriers)
        check_state(state, actual_actions)
        if multi:assert state["event_index"]==index
        assert completed() == (index == len(solution["path"]))
    final = evidence["final_state"]
    check_state(final, solution["moves"])
    assert final["completed"] and pushes == solution["pushes"]
    assert pulls == solution.get("pulls", 0) and swaps == solution.get("swaps", 0)
    assert actual_actions == solution["moves"]
    if "dragon_pulls" in solution:assert dragon_pulls == solution["dragon_pulls"]
    if "crystal_pulls" in solution:assert pulls-dragon_pulls == solution["crystal_pulls"]
    assert selection_events == solution.get("selection_events", 0)
    if multi:
        assert evidence["input_events"]==solution["input_events"] and evidence["direction_actions"]==actual_actions and evidence["selection_events"]==selection_events
        assert sum(symbol in DIRECTIONS for symbol in solution["path"]) == solution["directions"]
    return evidence

def check_visual_feedback(item, evidence):
    """View telemetry supplements independent world replay,never drives it."""
    if not item.get("visual_feedback_enabled"):
        return
    assert evidence["visual_feedback_enabled"]
    require_targets = item.get("attack_feedback_requires_target", False)
    if require_targets:
        assert evidence["attack_feedback_requires_target"]
    views = evidence["visual_feedback"]
    assert len(views) == len(evidence["trace"])
    previous = evidence["initial_state"]
    for index, (view, current) in enumerate(zip(views, evidence["trace"]), 1):
        assert view["event_index"] == index and view["input"] == current["input"]
        assert view["start_frame"] == evidence["initial_pause_frames"] + (index-1)*evidence["frames_per_input"]
        assert view["settled_at_step_end"] and view["world_unchanged_during_feedback"]
        progresses = []
        for motion in view["motions"]:
            a, b, at = motion["from"], motion["to"], motion["displayed"]
            delta = [b[i]-a[i] for i in range(2)]
            if view["swap"]:
                assert at in (a, b), "Exchange must never interpolate through middle cells"
            else:
                assert abs(delta[0])+abs(delta[1]) == 1
                t = sum((at[i]-a[i])*delta[i] for i in range(2))
                assert 0 <= t <= 1
                assert all(abs(at[i]-(a[i]+t*delta[i])) < 1e-5 for i in range(2))
                progresses.append(t)
        if progresses:
            assert max(progresses)-min(progresses) < 1e-5, "A pushed/pulled chain shares one easing clock"
        expected_deaths = {f"m:{m['id']}" for m, after in zip(previous.get("monsters", []), current.get("monsters", [])) if m["alive"] and not after["alive"]}
        expected_deaths.update(f"c:{c['id']}" for c in previous["crystals"] if c["id"] not in {x["id"] for x in current["crystals"]})
        assert set(view["death_keys"]) == expected_deaths
        ids = [r["dragon"] for r in view["locked_fire"]]
        assert len(ids) == len(set(ids)), "Each dragon emits at most one locked ray per action"
        for ray in view["locked_fire"]:
            if require_targets:
                assert ray["target"], "Empty or blocked sight queries must never trigger attack feedback"
            cell = tuple(ray["from"])
            facing = tuple(ray["facing"])
            for next_cell in ray["cells"]:
                cell = (cell[0]+facing[0], cell[1]+facing[1])
                assert list(cell) == next_cell
            if ray["target"].get("kind") == "monster":
                assert ray["cells"][-1] == current["monsters"][ray["target"]["id"]]["position"]
        if current["input"] == "C":
            assert not view["motions"] and not view["locked_fire"] and not view["death_keys"]
        previous = current
    if item["level"] == 29:
        if require_targets:
            assert [v["event_index"] for v in views if v["locked_fire"]] == [21, 56]
            assert sum(len(v["locked_fire"]) for v in views) == 4
        for action, pair in [(21, (2, 3)), (56, (0, 1))]:
            locked = {r["dragon"]: r["target"] for r in views[action-1]["locked_fire"]}
            assert locked[pair[0]] == {"kind":"monster", "id":pair[1]}
            assert locked[pair[1]] == {"kind":"monster", "id":pair[0]}
    if item["level"] == 30 and require_targets:
        assert not any(v["locked_fire"] for v in views), "Chosen level30 route shields every crossing and triggers no attack"
    if item["level"] == 31:
        assert not any(v["locked_fire"] for v in views)
        assert [v["event_index"] for v in views if v["locked_goblin"]] == [77]
        strikes = views[76]["locked_goblin"]
        assert len(strikes) == 2
        assert {(tuple(s["from"]), tuple(s["to"])) for s in strikes} == {
            ((0, 6), (0, 7)), ((0, 7), (0, 6))}
        assert set(views[76]["death_keys"]) == {"m:0", "m:1"}
        assert [v["event_index"] for v in views if v["energy_changes"]] == [77]
        assert views[76]["energy_changes"] == [{"cell":[9,4], "active":False}]
        assert all(not m["alive"] for m in evidence["final_state"]["monsters"])

    if item["level"] == 32:
        assert not any(v["locked_fire"] for v in views)
        assert [v["event_index"] for v in views if v["locked_goblin"]] == [32]
        strikes = views[31]["locked_goblin"]
        assert len(strikes) == 2
        assert {(tuple(s["from"]), tuple(s["to"])) for s in strikes} == {
            ((0, 3), (0, 4)), ((0, 4), (0, 3))}
        assert set(views[31]["death_keys"]) == {"m:0", "m:1"}
        assert [v["event_index"] for v in views if v["energy_changes"]] == [32]
        assert views[31]["energy_changes"] == [{"cell":[9,3], "active":False}]
        assert all(not m["alive"] for m in evidence["final_state"]["monsters"])

    if item["level"] == 33:
        assert not any(v["locked_fire"] for v in views), "All three enemies are Goblins"
        assert [v["event_index"] for v in views if v["locked_goblin"]] == [58]
        strikes = views[57]["locked_goblin"]
        assert len(strikes) == 4
        assert {(tuple(s["from"]), tuple(s["to"])) for s in strikes} == {
            ((0,6),(1,6)), ((1,6),(0,6)), ((1,6),(2,6)), ((2,6),(1,6))}
        assert set(views[57]["death_keys"]) == {"m:0", "m:1", "m:2"}
        assert [v["event_index"] for v in views if v["energy_changes"]] == [58]
        assert views[57]["energy_changes"] == [{"cell":[8,3], "active":False}]
        assert all(not m["alive"] for m in evidence["final_state"]["monsters"])

    if item["level"] == 34:
        assert not any(v["locked_goblin"] for v in views)
        assert [v["event_index"] for v in views if v["locked_fire"]] == [27]
        locked = {ray["dragon"]:ray["target"] for ray in views[26]["locked_fire"]}
        assert locked == {0:{"kind":"monster","id":1},1:{"kind":"monster","id":0}}
        assert set(views[26]["death_keys"]) == {"m:0","m:1"}
        assert [v["event_index"] for v in views if v["energy_changes"]] == [27]
        assert views[26]["energy_changes"] == [{"cell":[5,2],"active":False}]
        assert all(not m["alive"] for m in evidence["final_state"]["monsters"])

    if item["level"] == 35:
        assert [v["event_index"] for v in views if v["locked_fire"]] == [38]
        assert [v["event_index"] for v in views if v["locked_goblin"]] == [38]
        assert len(views[37]["locked_fire"]) == len(views[37]["locked_goblin"]) == 1
        ray=views[37]["locked_fire"][0]
        assert ray["dragon"]==0 and ray["from"]==[0,4] and ray["facing"]==[1,0] and ray["cells"]==[[1,4]] and ray["target"]=={"kind":"monster","id":1}
        assert views[37]["locked_goblin"]==[{"from":[1,4],"to":[0,4]}]
        assert set(views[37]["death_keys"])=={"m:0","m:1"}
        assert [v["event_index"] for v in views if v["energy_changes"]]==[38] and views[37]["energy_changes"]==[{"cell":[8,2],"active":False}]
        assert all(not m["alive"] for m in evidence["final_state"]["monsters"])

    if item["level"]==36:
        assert not any(v["locked_fire"] or v["locked_goblin"] for v in views)
        assert [v["event_index"] for v in views if v["death_keys"]]==[21]
        assert views[20]["death_keys"]==["m:0"]
        changes={tuple(x["cell"]):x["active"] for x in views[20]["energy_changes"]}
        assert changes=={(5,1):True,(7,3):False}
        assert not evidence["final_state"]["monsters"][0]["alive"]

    if item["level"]==37:
        assert [v["event_index"] for v in views if v["locked_fire"]]==[5,6,30]
        assert [v["event_index"] for v in views if v["locked_goblin"]]==[30]
        for action,target in [(5,1),(6,2),(30,3)]:
            ray=views[action-1]["locked_fire"];assert len(ray)==1 and ray[0]["dragon"]==0 and ray[0]["facing"]==[1,0] and ray[0]["target"]=={"kind":"monster","id":target}
        assert set(views[4]["death_keys"])=={"m:1"} and set(views[5]["death_keys"])=={"m:2"} and set(views[29]["death_keys"])=={"m:0","m:3"}
        assert views[29]["locked_goblin"]==[{"from":[1,3],"to":[0,3]}]
        assert [v["event_index"] for v in views if v["energy_changes"]]==[30] and views[29]["energy_changes"]==[{"cell":[8,3],"active":False}]
        assert all(not m["alive"] for m in evidence["final_state"]["monsters"])



    if item["level"]==38:
        assert [v["event_index"] for v in views if v["locked_fire"]]==[1,2,3,31,32]
        assert not any(v["locked_goblin"] for v in views)
        for action,target in [(1,5),(2,4),(3,3),(31,2),(32,0)]:
            rays=views[action-1]["locked_fire"];assert len(rays)==1 and rays[0]["dragon"]==6 and rays[0]["from"]==[14,4] and rays[0]["facing"]==[-1,0] and rays[0]["target"]=={"kind":"monster","id":target}
            assert set(views[action-1]["death_keys"])=={"m:"+str(target)}
        assert [v["event_index"] for v in views if v["energy_changes"]]==[9,31]
        for action,active in [(9,True),(31,False)]:
            assert {tuple(x["cell"]):x["active"] for x in views[action-1]["energy_changes"]}=={(13,4):active,(0,5):active,(1,5):active,(2,5):active,(3,5):active}
        final=evidence["final_state"];assert [m["id"] for m in final["monsters"] if m["alive"]]==[1,6]
        assert final["monsters"][1]["position"]==[1,0] and final["pressure"]["purple_01"] and final["player"]==[2,7]
        assert evidence["initial_state"]["pressure"]["purple_01"]



    if item["level"]==39:
        assert [v["event_index"] for v in views if v["locked_fire"]]==[28]
        assert not any(v["locked_goblin"] for v in views)
        assert views[27]["locked_fire"]==[{"dragon":2,"from":[9,4],"facing":[-1,0],"cells":[[x,4] for x in range(8,1,-1)],"target":{"kind":"monster","id":1}}]
        assert views[27]["death_keys"]==["m:1"]
        assert [v["event_index"] for v in views if v["energy_changes"]]==[38,67,73]
        for event,active in [(38,False),(67,True),(73,False)]:assert views[event-1]["energy_changes"]==[{"cell":[3,1],"active":active}]
        final=evidence["final_state"];assert [h["position"] for h in final["heroes"]]==[[0,0],[1,0]]
        assert final["crystals"][0]["position"]==[5,0] and [m["id"] for m in final["monsters"] if m["alive"]]==[0,2]
        assert final["pressure"]["blue_01"] and final["pressure"]["yellow_01"] and evidence["selection_events"]==11
        assert final["monsters"][2]["position"]==[9,3] and final["monsters"][2]["facing"]==[-1,0]


    if item["level"]==40:
        assert evidence["initial_state"]["hero_kind"]=="yellow" and all(v["protected_heroes"]==[True] for v in [evidence["initial_state"]]+evidence["trace"])
        assert not any(v["locked_fire"] or v["locked_goblin"] or v["death_keys"] or v["energy_changes"] for v in views)
        for n,view in enumerate(views,1):
            source="goblin" if n in range(2,9) else "fire" if n in range(10,17) else None
            expected=[] if source is None else [{"hero":0,"position":evidence["trace"][n-1]["player"],"source":source}]
            assert view["shield_blocks"]==expected
        final=evidence["final_state"]
        assert final["player"]==[2,3] and (final["moves"],final["pushes"],final["pulls"],final["swaps"])==(17,0,0,0)
        assert all(m["alive"] for m in final["monsters"]) and final["monsters"]==evidence["initial_state"]["monsters"]
        assert final["crystals"]==evidence["initial_state"]["crystals"] and len(final["crystals"])==5
        assert final["monsters"][6]["facing"]==[1,0] and final["barriers"]==[]

    if item["level"]==41:
        assert evidence["path"]=="CUURCDDCRRRRRRCRRUUCRRRRRRRRDD"
        assert evidence["direction_actions"]==25 and evidence["selection_events"]==5 and evidence["final_state"]["swaps"]==1
        assert not any(v["locked_fire"] or v["locked_goblin"] or v["death_keys"] or v["energy_changes"] for v in views)
        assert sum(len(v.get("shield_blocks",[])) for v in views)==10
        final=evidence["final_state"]
        assert final["crystals"]==[] and final["monsters"]==evidence["initial_state"]["monsters"]
        assert len(final["monsters"])==5 and all(m["alive"] for m in final["monsters"])
        assert {tuple(h["position"]) for h in final["heroes"]}=={(8,0),(8,4)}
        assert [h["kind"] for h in final["heroes"]]==["blue","yellow"] and all(h["alive"] for h in final["heroes"])


def check_media(item, evidence):
    path = ROOT / item["file"]
    data = path.read_bytes()
    assert len(data) == item["bytes"] and hashlib.sha256(data).hexdigest() == item["sha256"]
    probe = json.loads(subprocess.check_output([
        "ffprobe", "-v", "error", "-select_streams", "v:0", "-show_entries",
        "stream=codec_name,pix_fmt,width,height,avg_frame_rate,nb_frames:format=duration", "-of", "json", str(path)
    ]))
    stream = probe["streams"][0]
    assert stream["codec_name"] == "h264" and stream["pix_fmt"] == "yuv420p"
    assert [stream["width"], stream["height"]] == item["dimensions"]
    assert Fraction(stream["avg_frame_rate"]) == item["fps"] == evidence["fps"]
    expected = evidence["initial_pause_frames"] + len(evidence["path"]) * evidence["frames_per_input"] + evidence["victory_pause_frames"]
    assert int(stream["nb_frames"]) == item["frames"] == expected
    assert abs(float(probe["format"]["duration"]) - expected / evidence["fps"]) < 0.05
    assert item["initial_and_final_frames_reviewed"]
    atoms = []
    offset = 0
    while offset + 8 <= len(data):
        size, kind = struct.unpack(">I4s", data[offset:offset + 8])
        if size == 1:
            size = struct.unpack(">Q", data[offset + 8:offset + 16])[0]
        if size == 0:
            size = len(data) - offset
        assert size >= 8
        atoms.append(kind)
        offset += size
    assert atoms.index(b"moov") < atoms.index(b"mdat")
    subprocess.run(["ffmpeg", "-v", "error", "-xerror", "-i", str(path), "-f", "null", "-"],
                   check=True, stdout=subprocess.DEVNULL)


def main():
    manifests = sorted((ROOT / "video").glob("chapter_*/verification.json"))
    assert manifests, "No chapter video verification manifest found"
    checked = 0
    for manifest in manifests:
        report = json.loads(manifest.read_text())
        for item in report["videos"]:
            evidence = check_replay(item, manifest.parent)
            check_visual_feedback(item, evidence)
            check_media(item, evidence)
            checked += 1
            print(f"PASS {item['file']}: {item['duration_seconds']}s, {item['frames']} frames, full decode and legal input replay", flush=True)
    print(f"WALKTHROUGH RESULT: {checked} videos passed", flush=True)


if __name__ == "__main__":
    main()
