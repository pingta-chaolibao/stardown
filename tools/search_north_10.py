#!/usr/bin/env python3
"""Independently search blue directional swaps and the confirmed level-ten plate."""
from collections import deque
from pathlib import Path
import argparse
import json

ROOT = Path(__file__).resolve().parents[1]
DIRS = {"U": (0, -1), "D": (0, 1), "L": (-1, 0), "R": (1, 0)}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--write-solution", action="store_true")
    args = parser.parse_args()
    level = json.loads((ROOT / "levels/north_10.json").read_text())
    assert level["hero_kind"] == "blue" and len(level["crates"]) == 1 and not level.get("bushes")
    floor = {(x, y) for y, row in enumerate(level["terrain"]) for x, value in enumerate(row) if value == "."}
    link = level["energy_links"][0]
    plate, gate, goal = tuple(link["plate"]), tuple(link["barriers"][0]), tuple(level["exit"])
    initial = (tuple(level["player"]), tuple(level["crates"][0]))
    queue = deque([initial])
    parents = {initial: None}
    winner = None
    deaths = undefined = victories = crystal_on_gate = 0

    def plus(cell, direction):
        return cell[0] + direction[0], cell[1] + direction[1]

    def follow(state, symbol):
        hero, crystal = state
        active = hero != plate and crystal != plate
        direction = DIRS[symbol]
        adjacent = plus(hero, direction)

        def clear(cell):
            return cell in floor and not (active and cell == gate)

        target = adjacent
        while clear(target) and target != crystal:
            target = plus(target, direction)
        if clear(target) and target == crystal:
            following = target, hero
        elif clear(adjacent):
            following = adjacent, crystal
        else:
            return None, "blocked"
        new_hero, new_crystal = following
        restored = new_hero != plate and new_crystal != plate
        if restored and new_crystal == gate:
            return None, "undefined"
        if restored and not active and new_hero == gate:
            return None, "dead"
        return following, "swap" if new_crystal != crystal else "move"

    while queue:
        state = queue.popleft()
        crystal_on_gate += state[1] == gate
        if state[0] == goal:
            victories += 1
            if winner is None:
                winner = state
            continue
        for symbol in DIRS:
            following, result = follow(state, symbol)
            deaths += result == "dead"
            undefined += result == "undefined"
            if following is not None and following not in parents:
                parents[following] = state, symbol
                queue.append(following)
    assert winner is not None, "Confirmed level ten has no legal solution"
    path, cursor = "", winner
    while parents[cursor] is not None:
        cursor, symbol = parents[cursor]
        path = symbol + path
    state, trace, swaps = initial, [], 0
    for index, symbol in enumerate(path, 1):
        state, action = follow(state, symbol)
        assert state is not None
        swaps += action == "swap"
        trace.append({"number": index, "input": symbol, "action": action,
                      "player": state[0], "crystal": state[1],
                      "plate_pressed": plate in state, "gate_active": plate not in state})
    solution = {"level_id": level["id"], "path": path, "moves": len(path), "pushes": 0,
                "pulls": 0, "swaps": swaps,
                "note": "UDLR为普通方向输入；有本方向合法首目标就自动交换，否则走一格。独立搜索后由Godot实际规则与键盘验证，不宣称最优。"}
    destination = ROOT / "levels/solutions/north_10.json"
    if args.write_solution:
        destination.write_text(json.dumps(solution, ensure_ascii=False, indent=2) + "\n")
    else:
        assert json.loads(destination.read_text()) == solution
    report = {"living_identity_states_exhausted": len(parents), "victory_states": victories,
              "death_transitions": deaths, "undefined_restoration_transitions": undefined,
              "crystal_on_gate_states": crystal_on_gate, "user_corrected_floor": [3, 0],
              "solution": solution, "trace": trace}
    output = ROOT / "artifacts/verification/north_10_search.json"
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n")
    print(json.dumps(report, ensure_ascii=False, indent=2))
    print(f"SEARCH RESULT: {len(parents)} living states; {len(path)} direction inputs, {swaps} swaps; "
          f"{deaths} deaths, {undefined} undefined transitions")


if __name__ == "__main__":
    main()
