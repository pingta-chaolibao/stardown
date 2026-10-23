#!/usr/bin/env python3
"""Check a constructed level-eleven route using independent directional/pressure rules."""
from pathlib import Path
import argparse
import json

ROOT = Path(__file__).resolve().parents[1]
DIRS = {"U": (0, -1), "D": (0, 1), "L": (-1, 0), "R": (1, 0)}
PATH = "LLLLLDDDDRDRRUURULD"


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--write-solution", action="store_true")
    args = parser.parse_args()
    level = json.loads((ROOT / "levels/north_11.json").read_text())
    floor = {(x, y) for y, row in enumerate(level["terrain"]) for x, value in enumerate(row) if value == "."}
    plates = {tuple(cell) for cell in level["energy_links"][0]["plates"]}
    gate, goal = (7, 1), tuple(level["exit"])
    assert len(plates) == 9 and len(level["crates"]) == 9 and level["hero_kind"] == "blue"
    player = tuple(level["player"])
    crystals = {tuple(cell): identity for identity, cell in enumerate(level["crates"])}
    trace, swaps = [], 0

    def pressed():
        return sum(cell == player or cell in crystals for cell in plates)

    for index, symbol in enumerate(PATH, 1):
        before_player, before_crystals = player, crystals.copy()
        count_before = pressed()
        active = count_before != len(plates)
        dx, dy = DIRS[symbol]
        adjacent = player[0] + dx, player[1] + dy
        target = adjacent

        def clear(cell):
            return cell in floor and not (active and cell == gate)

        while clear(target) and target not in crystals:
            target = target[0] + dx, target[1] + dy
        if clear(target) and target in crystals:
            identity = crystals.pop(target)
            crystals[player] = identity
            player = target
            swaps += 1
            action = "swap"
        else:
            assert clear(adjacent) and adjacent not in crystals, (index, "blocked", adjacent)
            player = adjacent
            action = "move"
        count = pressed()
        restored = count != len(plates)
        assert not (restored and gate in crystals), "Undefined crystal restoration cannot be used"
        assert not (restored and not active and player == gate), "Constructed route must remain alive"
        assert (player == goal) == (index == len(PATH)), "Victory must first occur on final input"
        trace.append({"number": index, "input": symbol, "action": action,
                      "player_from": before_player, "player": player,
                      "crystals": {str(identity): cell for cell, identity in crystals.items()},
                      "pressed_before": count_before, "pressed": count, "gate_active": restored})
        if index == 11:
            assert player == (1, 5) and count == 9
        if index == 15:
            assert player == (5, 1) and count == 9
        if index == 16:
            assert before_player == (5, 1) and before_crystals[(10, 1)] == 8
            assert player == (10, 1) and crystals[(5, 1)] == 8 and count == 9
    assert swaps == 5 and len(PATH) == 19 and player == goal
    solution = {"level_id": level["id"], "path": PATH, "moves": len(PATH), "pushes": 0,
                "pulls": 0, "swaps": swaps,
                "note": "构造后由独立规则与Godot实际规则/键盘校验的合法路线，不宣称最优或穷举。UDLR为方向输入，本方向首目标优先自动交换。"}
    destination = ROOT / "levels/solutions/north_11.json"
    if args.write_solution:
        destination.write_text(json.dumps(solution, ensure_ascii=False, indent=2) + "\n")
    else:
        assert json.loads(destination.read_text()) == solution
    report = {"method": "constructed route with independent replay; no exhaustive state-space claim",
              "solution": solution, "initial_pressed": 8, "all_pressed_action": 11,
              "hero_at_aligned_plate_action": 15, "orange_exchange_action": 16,
              "victory_action": 19, "trace": trace}
    output = ROOT / "artifacts/verification/north_11_route.json"
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n")
    print(json.dumps({key: value for key, value in report.items() if key != "trace"}, ensure_ascii=False, indent=2))
    print("ROUTE RESULT: 19 legal direction inputs, 5 automatic swaps; all nine plates held from action 11; victory")


if __name__ == "__main__":
    main()
