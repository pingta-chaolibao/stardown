#!/usr/bin/env python3
"""Replay level 06 independently, without changing or inventing game rules."""

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DIRECTIONS = {"U": (0, -1), "D": (0, 1), "L": (-1, 0), "R": (1, 0)}


def main():
    level = json.loads((ROOT / "levels/north_06.json").read_text())
    solution = json.loads((ROOT / "levels/solutions/north_06.json").read_text())
    assert level["hero_kind"] == "green" and len(level["crates"]) == 7
    assert len(level["terrain"]) == 7 and all(len(row) == 11 for row in level["terrain"])
    assert level["terrain"][0][3] == level["terrain"][0][7] == "#"
    walkable = {(x, y) for y, row in enumerate(level["terrain"]) for x, tile in enumerate(row) if tile == "."}
    hero = tuple(level["player"])
    crystals = {tuple(cell): identity for identity, cell in enumerate(level["crates"])}
    assert len(level["energy_links"]) == 1
    link = level["energy_links"][0]
    assert link["plate"] == [9, 5] and link["barriers"] == [[7, 6]]
    assert set(link["pressure_sources"]) == {"hero", "crystal"}
    plate, gate, goal = (9, 5), (7, 6), tuple(level["exit"])
    trace, moved_identities, pulls = [], set(), 0
    for index, symbol in enumerate(solution["path"], 1):
        dx, dy = DIRECTIONS[symbol]
        target = (hero[0] + dx, hero[1] + dy)
        pressed = hero == plate or plate in crystals
        assert target in walkable and target not in crystals and not (target == gate and not pressed), (index, "blocked")
        behind = (hero[0] - dx, hero[1] - dy)
        pulled = behind in crystals
        if pulled:
            identity = crystals.pop(behind)
            crystals[hero] = identity
            moved_identities.add(identity)
            pulls += 1
        hero = target
        pressed = hero == plate or plate in crystals
        assert pressed or (hero != gate and gate not in crystals), (index, "death or undefined restoration")
        assert (hero == goal) == (index == len(solution["path"])), (index, "victory timing")
        trace.append({"step": index, "input": symbol, "player": list(hero), "pulls": pulls,
                      "pressed": pressed, "barrier_active": not pressed, "pulled": pulled,
                      "crystals": [{"id": identity, "position": list(cell)} for cell, identity in sorted(crystals.items())]})
    assert len(trace) == solution["moves"] == 65 and pulls == solution["pulls"] == 17 and solution["pushes"] == 0
    assert len(moved_identities) == 7
    assert trace[28]["player"] == [9, 5] and trace[28]["pressed"]
    assert trace[29]["player"] == [9, 4] and trace[29]["pressed"] and crystals[plate] == 6
    assert trace[35]["player"] == [7, 6] and trace[35]["pressed"]
    result = {"solution": solution, "all_seven_crystals_moved": True, "hero_press_step": 29,
              "crystal_handoff_step": 30, "gate_crossing_step": 36, "trace": trace}
    destination = ROOT / "artifacts/verification/north_06_independent.json"
    destination.parent.mkdir(parents=True, exist_ok=True)
    destination.write_text(json.dumps(result, ensure_ascii=False, indent=2) + "\n")
    print("INDEPENDENT RESULT: 65 legal moves, 17 single pulls, 0 pushes; all 7 crystals participate; hero/crystal plate handoff and gate crossing verified")


if __name__ == "__main__":
    main()
