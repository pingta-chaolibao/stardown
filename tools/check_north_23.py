#!/usr/bin/env python3
"""Independently check the confirmed 77-floor, ten-Goblin map and a safe route."""
from collections import Counter, deque
from pathlib import Path
import argparse
import json

ROOT = Path(__file__).resolve().parents[1]
MONSTERS = [(2, 0), (10, 0), (3, 1), (7, 2), (0, 3), (4, 4), (0, 5), (8, 5), (1, 6), (7, 6)]
OVERLAP = {(0, 4), (0, 6), (1, 5), (2, 1), (3, 0), (7, 5), (8, 6)}
DIRS = {"U": (0, -1), "D": (0, 1), "L": (-1, 0), "R": (1, 0)}

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--write-solution", action="store_true")
    args = parser.parse_args()
    level = json.loads((ROOT / "levels/north_23.json").read_text())
    assert level["terrain"] == ["..........."] * 7
    assert level["player"] == [0, 0] and level["exit"] == [9, 6] and level["hero_kind"] == "red"
    assert [(m["kind"], tuple(m["position"])) for m in level["monsters"]] == [("goblin", p) for p in MONSTERS]
    assert not any(level.get(k) for k in ("crates", "bushes", "energy_links", "fences"))
    floor = {(x, y) for y in range(7) for x in range(11)}
    risk = Counter(c for c in floor for m in MONSTERS if abs(c[0]-m[0])+abs(c[1]-m[1]) == 1)
    assert len(risk) == 26 and {c for c, n in risk.items() if n > 1} == OVERLAP
    assert (0, 6) in floor and risk[(0, 6)] == 2  # Marker 67 is floor, yet dangerous.
    queue, seen, path = deque([((0, 0), "")]), {(0, 0)}, None
    while queue:
        cell, route = queue.popleft()
        if cell == (9, 6):
            path = route
            break
        for symbol, (dx, dy) in DIRS.items():
            nxt = (cell[0]+dx, cell[1]+dy)
            if nxt in floor and nxt not in MONSTERS and nxt not in risk and nxt not in seen:
                seen.add(nxt)
                queue.append((nxt, route+symbol))
    assert path, "Confirmed map has no safe route under existing Goblin rules"
    solution = {"level_id": level["id"], "path": path, "moves": len(path), "directions": len(path),
                "input_events": len(path), "selection_events": 0, "pushes": 0, "pulls": 0,
                "swaps": 0, "destroyed_crystals": 0,
                "note": "独立安全格BFS；77格全地面、10只静止哥布林，避开26个四向危险格与7个重叠格。67可走但受两只威胁，不改地图或规则。"}
    target = ROOT / "levels/solutions/north_23.json"
    if args.write_solution:
        target.write_text(json.dumps(solution, ensure_ascii=False, indent=2)+"\n")
    else:
        assert json.loads(target.read_text()) == solution
    proof = {"visited": len(seen), "solution": solution, "floor": len(floor),
             "danger": [list(c) for c in sorted(risk)], "overlapping_danger": [list(c) for c in sorted(OVERLAP)]}
    out = ROOT / "artifacts/verification/north_23_route.json"
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(json.dumps(proof, ensure_ascii=False, indent=2)+"\n")
    print("NORTH 23 INDEPENDENT RESULT: "+json.dumps(solution, ensure_ascii=False))

if __name__ == "__main__":
    main()
