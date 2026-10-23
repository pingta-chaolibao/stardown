#!/usr/bin/env python3
"""Independently exhaust level-04 living occupancy states and verify its route."""

from collections import deque
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DIRECTIONS = {"U": (0, -1), "D": (0, 1), "L": (-1, 0), "R": (1, 0)}


def main():
    level = json.loads((ROOT / "levels/north_04.json").read_text())
    expected = json.loads((ROOT / "levels/solutions/north_04.json").read_text())
    width, height = len(level["terrain"][0]), len(level["terrain"])

    def pack(cell):
        return cell[1] * width + cell[0]

    walkable = {y * width + x for y, row in enumerate(level["terrain"]) for x, value in enumerate(row) if value == "."}
    walkable -= {pack(cell) for cell in level["bushes"]}
    assert len(level["energy_links"]) == 1
    link = level["energy_links"][0]
    assert link["activation"] == "all" and set(link["pressure_sources"]) == {"hero", "crystal"}
    plates = {pack(cell) for cell in link["plates"]}
    assert len(link["barriers"]) == 1
    gate, goal = pack(link["barriers"][0]), pack(level["exit"])
    initial = (pack(level["player"]), tuple(sorted(pack(cell) for cell in level["crates"])))
    parents = {initial: None}
    queue = deque([initial])
    winner = None
    undefined = False
    crystal_enters_gate = False
    while queue:
        state = queue.popleft()
        hero, boxes = state
        occupied = set(boxes)
        active = not plates.issubset(occupied | {hero})
        crystal_enters_gate |= gate in occupied
        if hero == goal:
            if winner is None:
                winner = state
            continue  # Normal game input freezes at victory; undo adds no new worlds.
        for symbol, (dx, dy) in DIRECTIONS.items():
            def next_cell(cell):
                x, y = cell % width + dx, cell // width + dy
                return y * width + x if 0 <= x < width and 0 <= y < height else -1

            target = next_cell(hero)
            if target not in walkable or (active and target == gate):
                continue
            chain, terminal = [], target
            while terminal in occupied:
                chain.append(terminal)
                terminal = next_cell(terminal)
            if terminal not in walkable or (active and terminal == gate):
                continue
            candidate = (occupied - set(chain)) | {next_cell(cell) for cell in chain}
            restored = not plates.issubset(candidate | {target})
            if restored and gate in candidate:
                undefined = True
                continue  # Diagnose the unconfirmed rule; never invent a result.
            if restored and not active and target == gate:
                continue  # A dead hero can only undo to an already visited world.
            following = (target, tuple(sorted(candidate)))
            if following not in parents:
                parents[following] = (state, symbol)
                queue.append(following)
    assert winner is not None, "Confirmed map has no solution"
    path, cursor = "", winner
    while parents[cursor] is not None:
        cursor, symbol = parents[cursor]
        path = symbol + path
    hero, boxes = initial
    pushes = 0
    for symbol in path:
        dx, dy = DIRECTIONS[symbol]
        step = dy * width + dx
        target, terminal, chain = hero + step, hero + step, []
        while terminal in boxes:
            chain.append(terminal)
            terminal += step
        pushes += bool(chain)
        boxes = tuple(sorted((set(boxes) - set(chain)) | {cell + step for cell in chain}))
        hero = target
    assert path == expected["path"] and len(path) == expected["moves"] and pushes == expected["pushes"]
    assert not crystal_enters_gate and not undefined, "Unconfirmed crystal/barrier rule is reachable"
    report = {"living_occupancy_states_exhausted": len(parents), "crystal_colors_ignored_for_search": True,
              "solution": expected, "crystal_enters_barrier": crystal_enters_gate,
              "undefined_transition_found": undefined, "path_validated_separately_by": "tests/north_04_regression.gd"}
    destination = ROOT / "artifacts/verification/north_04_search.json"
    destination.parent.mkdir(parents=True, exist_ok=True)
    destination.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n")
    print(f"SEARCH RESULT: {len(parents)} living occupancy states; {len(path)} moves / {pushes} pushes; undefined interaction unreachable")


if __name__ == "__main__":
    main()
