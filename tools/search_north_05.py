#!/usr/bin/env python3
"""Independently search the confirmed green-hero level using nearest-only pulls."""

from collections import deque
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DIRECTIONS = {"U": (0, -1), "D": (0, 1), "L": (-1, 0), "R": (1, 0)}


def main():
    level = json.loads((ROOT / "levels/north_05.json").read_text())
    expected = json.loads((ROOT / "levels/solutions/north_05.json").read_text())
    assert level["hero_kind"] == "green" and not level.get("energy_links")
    walkable = {(x, y) for y, row in enumerate(level["terrain"]) for x, tile in enumerate(row) if tile == "."}
    walkable -= {tuple(cell) for cell in level.get("bushes", [])}
    initial = (tuple(level["player"]), tuple(sorted(tuple(cell) for cell in level["crates"])))
    queue, parents, winner = deque([initial]), {initial: None}, None
    while queue:
        state = queue.popleft()
        hero, crystals = state
        occupied = set(crystals)
        if hero == tuple(level["exit"]):
            if winner is None:
                winner = state
            continue
        for symbol, (dx, dy) in DIRECTIONS.items():
            target = (hero[0] + dx, hero[1] + dy)
            if target not in walkable or target in occupied:
                continue  # Green never pushes, even if there is space beyond.
            behind = (hero[0] - dx, hero[1] - dy)
            candidate = set(occupied)
            if behind in candidate:
                candidate.remove(behind)
                candidate.add(hero)  # One adjacent crystal only; no line scan.
            following = (target, tuple(sorted(candidate)))
            if following not in parents:
                parents[following] = (state, symbol)
                queue.append(following)
    assert winner is not None, "Confirmed green level has no legal solution"
    path, cursor = "", winner
    while parents[cursor] is not None:
        cursor, symbol = parents[cursor]
        path = symbol + path
    hero, boxes = initial
    occupied, pulls = set(boxes), 0
    for symbol in path:
        dx, dy = DIRECTIONS[symbol]
        behind = (hero[0] - dx, hero[1] - dy)
        if behind in occupied:
            occupied.remove(behind)
            occupied.add(hero)
            pulls += 1
        hero = (hero[0] + dx, hero[1] + dy)
    assert path == expected["path"] and len(path) == expected["moves"] and pulls == expected["pulls"] and expected["pushes"] == 0
    report = {"living_occupancy_states_exhausted": len(parents), "crystal_colors_ignored_for_search": True,
              "hero_kind": "green", "solution": expected, "validated_separately_by": "tests/north_05_regression.gd"}
    destination = ROOT / "artifacts/verification/north_05_search.json"
    destination.parent.mkdir(parents=True, exist_ok=True)
    destination.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n")
    print(f"SEARCH RESULT: {len(parents)} occupancy states; {len(path)} moves, {pulls} pulls, 0 pushes")


if __name__ == "__main__":
    main()
