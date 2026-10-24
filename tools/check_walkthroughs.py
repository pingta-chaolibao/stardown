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
    assert all(hero["kind"] in ("red", "green", "blue") for hero in definitions)
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

    def settle(previous_barriers, advance=True):
        pressure, barriers = {}, {}
        for link in level.get("energy_links", []):
            sources = link["pressure_sources"]
            plates = [tuple(cell) for cell in link.get("plates", [link["plate"]] if "plate" in link else [])]
            assert plates and link.get("activation", "all") == "all"
            assert not set(plates).intersection(monster_cells()), "Monster pressure-source behavior has not been confirmed"
            pressure[link["id"]] = all(("hero" in sources and plate in heroes) or ("crystal" in sources and plate in crystals) for plate in plates)
        all_pressed = all(pressure.values())
        for link in level.get("energy_links", []):
            barriers.update({tuple(cell): not all_pressed for cell in link["barriers"]})
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
        goblin_heroes = []
        for h,cell in enumerate(heroes):
            for i,monster in enumerate(monster_positions):
                if living[h] and monster_living[i] and monster_kinds[i]=="goblin" and abs(cell[0]-monster[0])+abs(cell[1]-monster[1])==1:
                    assert not edge_blocked(cell,monster), "Goblin/fence attack is undefined"
                    goblin_heroes.append(h)
        targets = {}
        goblin_dragons = []
        if advance:
            for i,origin in enumerate(monster_positions):
                if not monster_living[i] or monster_kinds[i]!="fire_dragon":continue
                cell = plus(origin,facings[i]);previous = origin
                while floor(cell) and cell not in bushes and not barriers.get(cell,False) and cell not in crystals:
                    assert not edge_blocked(previous,cell), "Fire/fence interaction is unconfirmed"
                    if cell in heroes and living[heroes.index(cell)]:targets[i] = ("hero",heroes.index(cell));break
                    if cell in monster_cells():targets[i] = ("monster",monster_cells()[cell]);break
                    previous = cell;cell = plus(cell,facings[i])
            for i,goblin in enumerate(monster_positions):
                if not monster_living[i] or monster_kinds[i]!="goblin":continue
                for v,dragon in enumerate(monster_positions):
                    if monster_living[v] and monster_kinds[v]=="fire_dragon" and abs(goblin[0]-dragon[0])+abs(goblin[1]-dragon[1])==1:
                        assert not edge_blocked(goblin,dragon), "Goblin/fence attack is undefined"
                        goblin_dragons.append(v)
        for family,victim in targets.values():
            if family=="hero":living[victim] = False
            else:monster_living[victim] = False
        for victim in goblin_dragons:monster_living[victim] = False
        for h in goblin_heroes:living[h] = False
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
                        or ("crystal" in link["pressure_sources"] and plate in crystals))
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
    assert selection_events == solution.get("selection_events", 0)
    if multi:
        assert evidence["input_events"]==solution["input_events"] and evidence["direction_actions"]==actual_actions and evidence["selection_events"]==selection_events
        assert sum(symbol in DIRECTIONS for symbol in solution["path"]) == solution["directions"]
    return evidence

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
            check_media(item, evidence)
            checked += 1
            print(f"PASS {item['file']}: {item['duration_seconds']}s, {item['frames']} frames, full decode and legal input replay", flush=True)
    print(f"WALKTHROUGH RESULT: {checked} videos passed", flush=True)


if __name__ == "__main__":
    main()
