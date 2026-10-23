#!/usr/bin/env python3
"""Independently search the user-confirmed seventh grid with automatic single pulls."""

from collections import deque
import argparse
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DIRECTIONS = {"U": (0, -1), "D": (0, 1), "L": (-1, 0), "R": (1, 0)}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--write-solution", action="store_true")
    args = parser.parse_args()
    level = json.loads((ROOT / "levels/north_07.json").read_text())
    assert level["hero_kind"] == "green" and len(level["crates"]) == 1
    floor = {(x, y) for y, row in enumerate(level["terrain"]) for x, tile in enumerate(row) if tile == "."}
    plates = {tuple(link["plate"]) for link in level["energy_links"]}
    gates = {tuple(cell) for link in level["energy_links"] for cell in link["barriers"]}
    initial = (tuple(level["player"]), tuple(level["crates"][0]))
    queue, parents, winner = deque([initial]), {initial: None}, None
    deaths, unresolved = 0, []

    def pressed(hero, crystal):
        return plates <= {hero, crystal}

    def follow(state, symbol):
        nonlocal deaths
        hero, crystal = state
        dx, dy = DIRECTIONS[symbol]
        target = (hero[0] + dx, hero[1] + dy)
        if target not in floor or target == crystal or (target in gates and not pressed(*state)):
            return None
        behind = (hero[0] - dx, hero[1] - dy)
        next_crystal = hero if behind == crystal else crystal
        if not pressed(target, next_crystal):
            if next_crystal in gates:
                unresolved.append((state, symbol))
                return None  # Undefined interaction is reported, never invented.
            if target in gates:
                deaths += 1
                return None
        return target, next_crystal

    while queue:
        state = queue.popleft()
        if state[0] == tuple(level["exit"]):
            if winner is None:
                winner = state
            continue
        for symbol in DIRECTIONS:
            following = follow(state, symbol)
            if following is not None and following not in parents:
                parents[following] = (state, symbol)
                queue.append(following)
    def path_for(cursor):
        path = ""
        while parents[cursor] is not None:
            cursor, symbol = parents[cursor]
            path = symbol + path
        return path

    output = ROOT / "artifacts/verification/north_07_search.json"
    output.parent.mkdir(parents=True, exist_ok=True)
    if winner is None:
        checkpoints = []
        for crystal in ((6, 5), (5, 5), (7, 6), (6, 6)):
            states = [state for state in parents if state[1] == crystal]
            cursor = min(states, key=lambda state: len(path_for(state)))
            hero = cursor[0]
            blocked_targets = []
            for symbol, (dx, dy) in DIRECTIONS.items():
                target = hero[0] + dx, hero[1] + dy
                if target not in floor or target == crystal:
                    blocked_targets.append({"input": symbol, "target": target, "reason": "wall" if target not in floor else "crystal_cannot_push"})
            next_positions = set()
            for state in states:
                for symbol in DIRECTIONS:
                    following = follow(state, symbol)
                    if following is not None and following[1] != crystal:
                        next_positions.add(following[1])
            checkpoints.append({"crystal": crystal, "hero": hero, "path": path_for(cursor),
                                "hero_positions_at_this_crystal": len(states), "blocked_hero_targets": blocked_targets,
                                "possible_next_crystal_positions": sorted(next_positions)})
        report = {"solvable": False, "living_occupancy_states_exhausted": len(parents),
                  "crystal_positions": sorted({state[1] for state in parents}, key=lambda cell: (cell[1], cell[0])),
                  "crystal_on_plate_states": sum(state[1] in plates for state in parents),
                  "hero_on_exit_states": 0, "death_transitions": deaths,
                  "undefined_crystal_restoration_transitions": len(unresolved),
                  "checkpoints": checkpoints,
                  "note": "Integer conversion diagnostic only. Do not alter confirmed cells to make the solver succeed."}
        output.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n")
        print(json.dumps(report, ensure_ascii=False, indent=2))
        raise SystemExit("MAP BLOCKER: no legal solution in the current integer conversion")
    path, cursor = "", winner
    while parents[cursor] is not None:
        cursor, symbol = parents[cursor]
        path = symbol + path
    state, pulls, events = initial, 0, []
    for index, symbol in enumerate(path, 1):
        following = follow(state, symbol)
        assert following is not None
        pulls += following[1] != state[1]
        if pressed(*state) != pressed(*following) or following[0] in gates or following[1] in plates:
            events.append({"step": index, "hero": following[0], "crystal": following[1], "open": pressed(*following)})
        state = following
    solution = {"level_id": level["id"], "path": path, "moves": len(path), "pushes": 0, "pulls": pulls,
                "note": "U/D/L/R 为上/下/左/右。独立搜索所得合法单拉路线，供 Godot 模型、实际输入及录制验证；不宣称最优。"}
    destination = ROOT / "levels/solutions/north_07.json"
    if args.write_solution:
        destination.write_text(json.dumps(solution, ensure_ascii=False, indent=2) + "\n")
    else:
        assert json.loads(destination.read_text()) == solution
    report = {"living_occupancy_states_exhausted": len(parents), "death_transitions": deaths,
              "undefined_crystal_restoration_transitions": len(unresolved), "solution": solution, "events": events}
    output.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n")
    print(json.dumps(report, ensure_ascii=False, indent=2))
    assert not unresolved, "Report the minimal undefined-interaction trigger before delivery"
    print(f"SEARCH RESULT: {len(parents)} living states; {len(path)} moves, {pulls} pulls, 0 pushes")


if __name__ == "__main__":
    main()
