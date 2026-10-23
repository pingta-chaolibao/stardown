#!/usr/bin/env python3
"""Independently search the confirmed eighth map using automatic nearest-only pulls."""
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
    level = json.loads((ROOT / "levels/north_08.json").read_text())
    width, height = len(level["terrain"][0]), len(level["terrain"])
    pack = lambda cell: cell[1] * width + cell[0]
    unpack = lambda cell: (cell % width, cell // width)
    floor = {y * width + x for y, row in enumerate(level["terrain"]) for x, tile in enumerate(row) if tile == "."}
    floor -= {pack(cell) for cell in level["bushes"]}
    link = level["energy_links"][0]
    assert level["hero_kind"] == "green" and link["activation"] == "all" and set(link["pressure_sources"]) == {"hero", "crystal"}
    plates, gate, goal = {pack(cell) for cell in link["plates"]}, pack(link["barriers"][0]), pack(level["exit"])
    initial = (pack(level["player"]), tuple(sorted(pack(cell) for cell in level["crates"])))
    queue, parents, winner = deque([initial]), {initial: None}, None
    undefined, deaths, gate_crystal_states = 0, 0, 0
    while queue:
        state = queue.popleft()
        hero, crystals = state
        occupied = set(crystals)
        opened = plates <= occupied | {hero}
        gate_crystal_states += gate in occupied
        if hero == goal:
            if winner is None:
                winner = state
            continue
        for symbol, (dx, dy) in DIRECTIONS.items():
            x, y = hero % width + dx, hero // width + dy
            if not (0 <= x < width and 0 <= y < height):
                continue
            target = y * width + x
            if target not in floor or target in occupied or (target == gate and not opened):
                continue
            behind_x, behind_y = hero % width - dx, hero // width - dy
            behind = behind_y * width + behind_x if 0 <= behind_x < width and 0 <= behind_y < height else -1
            candidate = (occupied - {behind}) | {hero} if behind in occupied else occupied
            restored = not plates <= candidate | {target}
            if restored and gate in candidate:
                undefined += 1
                continue
            if restored and target == gate:
                deaths += 1
                continue
            following = (target, tuple(sorted(candidate)))
            if following not in parents:
                parents[following] = (state, symbol)
                queue.append(following)
    assert winner is not None, "Confirmed eighth map has no legal solution; do not change the map to fit a search"
    path, cursor = "", winner
    while parents[cursor] is not None:
        cursor, symbol = parents[cursor]
        path = symbol + path
    hero, crystals = initial
    occupied, pulls, events = set(crystals), 0, []
    for index, symbol in enumerate(path, 1):
        dx, dy = DIRECTIONS[symbol]
        x, y = unpack(hero)
        behind = (y - dy) * width + x - dx if 0 <= x - dx < width and 0 <= y - dy < height else -1
        if behind in occupied:
            occupied.remove(behind)
            occupied.add(hero)
            pulls += 1
        hero = (y + dy) * width + x + dx
        count = len(plates & (occupied | {hero}))
        if count == 3 or hero == gate:
            events.append({"step": index, "hero": unpack(hero), "crystals": [unpack(c) for c in sorted(occupied)], "plates_occupied": count, "crossing_gate": hero == gate})
    solution = {"level_id": level["id"], "path": path, "moves": len(path), "pushes": 0, "pulls": pulls,
                "note": "U/D/L/R为上/下/左/右。独立搜索所得绿色单枚自动拉动合法路线，不宣称最优；由Godot模型和正常键盘另行验证。"}
    destination = ROOT / "levels/solutions/north_08.json"
    if args.write_solution:
        destination.write_text(json.dumps(solution, ensure_ascii=False, indent=2) + "\n")
    else:
        assert json.loads(destination.read_text()) == solution
    report = {"living_occupancy_states_exhausted": len(parents), "crystal_colors_ignored_for_search": True,
              "undefined_restoration_transitions": undefined, "death_transitions": deaths, "crystal_on_gate_states": gate_crystal_states,
              "solution": solution, "events": events}
    output = ROOT / "artifacts/verification/north_08_search.json"
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n")
    print(json.dumps(report, ensure_ascii=False, indent=2))
    assert undefined == 0, "Report any reachable unconfirmed crystal restoration before delivery"
    print(f"SEARCH RESULT: {len(parents)} living states; {len(path)} moves, {pulls} pulls, 0 pushes")

if __name__ == "__main__":
    main()
