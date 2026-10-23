#!/usr/bin/env python3
"""Independent bounded-by-first-victory search of level twelve's confirmed rules."""
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
    level = json.loads((ROOT / "levels/north_12.json").read_text())
    width, height = len(level["terrain"][0]), len(level["terrain"])
    cell = lambda xy: xy[1] * width + xy[0]
    xy = lambda n: [n % width, n // width]
    bushes = {cell(c) for c in level["bushes"]}
    floor = {y * width + x for y, row in enumerate(level["terrain"]) for x, t in enumerate(row)
             if t == "." and y * width + x not in bushes}
    link = level["energy_links"][0]
    plates, gate, goal = tuple(map(cell, link["plates"])), cell(link["barriers"][0]), cell(level["exit"])
    rays = {}
    for origin in floor:
        for symbol, (dx, dy) in DIRS.items():
            x, y = xy(origin)
            line = []
            x, y = x + dx, y + dy
            while 0 <= x < width and 0 <= y < height and y * width + x in floor:
                line.append(y * width + x)
                x, y = x + dx, y + dy
            rays[origin, symbol] = line

    def pressed(state):
        hero, crystals = state
        return sum(p == hero or p in crystals for p in plates)

    def follow(state, symbol, canonical=True):
        hero, crystals = state
        active = pressed(state) != len(plates)
        line = rays[hero, symbol]
        target = None
        for position in line:
            if active and position == gate:
                break
            if position in crystals:
                target = position
                break
        if target is not None:
            candidate = list(crystals)
            candidate[candidate.index(target)] = hero
            candidate = tuple(sorted(candidate) if canonical else candidate)
            following, result = (target, candidate), "swap"
        elif line and not (active and line[0] == gate):
            following, result = (line[0], crystals), "move"
        else:
            return None, "blocked"
        restored = pressed(following) != len(plates)
        if restored and gate in following[1]:
            return None, "undefined"
        if restored and not active and following[0] == gate:
            return None, "dead"
        return following, result

    ordered_initial = cell(level["player"]), tuple(map(cell, level["crates"]))
    initial = ordered_initial[0], tuple(sorted(ordered_initial[1]))
    queue, parents = deque([initial]), {initial: None}
    winner = None
    expanded = deaths = undefined = 0
    while queue:
        state = queue.popleft()
        if state[0] == goal:
            winner = state
            break
        expanded += 1
        for symbol in DIRS:
            following, result = follow(state, symbol)
            deaths += result == "dead"
            undefined += result == "undefined"
            if following is not None and following not in parents:
                parents[following] = state, symbol
                queue.append(following)
    assert winner is not None, "Confirmed level twelve has no legal solution"
    path, cursor = "", winner
    while parents[cursor] is not None:
        cursor, symbol = parents[cursor]
        path = symbol + path
    state, trace, swaps = ordered_initial, [], 0
    for index, symbol in enumerate(path, 1):
        state, result = follow(state, symbol, canonical=False)
        assert state is not None and (state[0] == goal) == (index == len(path))
        swaps += result == "swap"
        trace.append({"number": index, "input": symbol, "action": result, "player": xy(state[0]),
                      "crystals_by_identity": [xy(c) for c in state[1]],
                      "pressed": pressed(state), "gate_active": pressed(state) != 3})
    solution = {"level_id": level["id"], "path": path, "moves": len(path), "pushes": 0,
                "pulls": 0, "swaps": swaps,
                "note": "独立占用状态搜索在首次胜利停止，颜色身份排列只在搜索去重时忽略；实际路线另按身份与Godot规则/键盘校验。UDLR为方向输入，首目标优先自动交换；不宣称穷举或最优。"}
    destination = ROOT / "levels/solutions/north_12.json"
    if args.write_solution:
        destination.write_text(json.dumps(solution, ensure_ascii=False, indent=2) + "\n")
    else:
        assert json.loads(destination.read_text()) == solution
    report = {"method": "occupancy BFS stopped at first victory; crystal identity permutations ignored only in search",
              "visited_occupancy_states": len(parents), "expanded_occupancy_states": expanded,
              "pending_states_at_first_victory": len(queue), "exhaustive": False,
              "death_transitions_seen": deaths, "undefined_restoration_transitions_seen": undefined,
              "solution": solution, "trace": trace}
    output = ROOT / "artifacts/verification/north_12_search.json"
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n")
    print(json.dumps({k: v for k, v in report.items() if k != "trace"}, ensure_ascii=False, indent=2))
    print(f"SEARCH RESULT: {expanded} states expanded; {len(path)} direction inputs, {swaps} swaps; victory")


if __name__ == "__main__":
    main()
