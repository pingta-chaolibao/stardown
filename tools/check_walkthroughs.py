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


def check_replay(item, directory):
    evidence = json.loads((directory / item["replay_report"]).read_text())
    level = json.loads((ROOT / item["level_file"]).read_text())
    solution = json.loads((ROOT / item["solution_file"]).read_text())
    player = tuple(level["player"])
    hero_kind = level.get("hero_kind", "red")
    assert hero_kind in ("red", "green")
    crystals = {tuple(cell): identity for identity, cell in enumerate(level["crates"])}
    bushes = {tuple(cell) for cell in level.get("bushes", [])}
    initial = evidence["initial_state"]
    assert initial["player"] == level["player"] and initial["moves"] == 0
    assert not initial["completed"] and evidence["path"] == solution["path"]
    assert initial["level_id"] == level["id"] == solution["level_id"]
    assert evidence["game_implementation_commit"] == item["game_implementation_commit"]
    assert evidence["display"] == "X11"
    assert len(evidence["trace"]) == solution["moves"]

    def floor(cell):
        x, y = cell
        return 0 <= y < len(level["terrain"]) and 0 <= x < len(level["terrain"][0]) and level["terrain"][y][x] == "."

    def plus(cell, delta):
        return cell[0] + delta[0], cell[1] + delta[1]

    def settle(previous_barriers):
        pressure, barriers = {}, {}
        for link in level.get("energy_links", []):
            sources = link["pressure_sources"]
            plates = [tuple(cell) for cell in link.get("plates", [link["plate"]] if "plate" in link else [])]
            assert plates and link.get("activation", "all") == "all"
            pressed = all(("hero" in sources and player == plate) or ("crystal" in sources and plate in crystals) for plate in plates)
            pressure[link["id"]] = pressed
            barriers.update({tuple(cell): not pressed for cell in link["barriers"]})
        alive = True
        for cell, active in barriers.items():
            if active:
                # This interaction is undefined; no published walkthrough may use it.
                assert cell not in crystals, "Unconfirmed crystal/barrier interaction"
                if not previous_barriers.get(cell, False) and cell == player:
                    alive = False
        return pressure, barriers, alive

    pressure, barriers, alive = settle({})

    def walkable(cell):
        return floor(cell) and cell not in bushes and not barriers.get(cell, False)

    def check_mechanisms(state):
        assert alive and state.get("alive", True)
        assert state.get("hero_kind", "red") == hero_kind
        if bushes or "bushes" in state:
            assert {tuple(cell) for cell in state["bushes"]} == bushes
        if "plates" in state:
            actual_plates = {(entry["group"], tuple(entry["position"])): entry["pressed"] for entry in state["plates"]}
            expected_plates = {}
            for link in level.get("energy_links", []):
                for cell in link.get("plates", [link["plate"]] if "plate" in link else []):
                    plate = tuple(cell)
                    expected_plates[(link["id"], plate)] = (("hero" in link["pressure_sources"] and player == plate)
                        or ("crystal" in link["pressure_sources"] and plate in crystals))
            assert actual_plates == expected_plates
        if level.get("energy_links") or "pressure" in state:
            assert state["pressure"] == pressure
            actual = {tuple(entry["position"]): entry["active"] for entry in state["barriers"]}
            assert actual == barriers

    def check_crystals(state):
        actual = {tuple(entry["position"]): entry["id"] for entry in state["crystals"]}
        assert actual == crystals
        for entry in state["crystals"]:
            assert entry["color"] == level["crystal_colors"][entry["id"]]

    check_crystals(initial)
    check_mechanisms(initial)
    pushes, pulls = 0, 0
    for index, (symbol, state) in enumerate(zip(solution["path"], evidence["trace"]), 1):
        assert state["input"] == symbol
        direction = DIRECTIONS[symbol]
        target = plus(player, direction)
        assert walkable(target)
        assert hero_kind == "red" or target not in crystals, "Green hero cannot push"
        chain = []
        terminal = target
        while terminal in crystals:
            chain.append(terminal)
            terminal = plus(terminal, direction)
        assert walkable(terminal)
        for cell in reversed(chain):
            crystals[plus(cell, direction)] = crystals.pop(cell)
        pushes += bool(chain)
        behind = (player[0] - direction[0], player[1] - direction[1])
        if hero_kind == "green" and behind in crystals:
            crystals[player] = crystals.pop(behind)
            pulls += 1
        player = target
        pressure, barriers, alive = settle(barriers)
        assert state["player"] == list(player)
        assert state["moves"] == index and state["pushes"] == pushes
        assert state.get("pulls", 0) == pulls
        assert state["completed"] == (player == tuple(level["exit"])) == (index == solution["moves"])
        check_crystals(state)
        check_mechanisms(state)
    final = evidence["final_state"]
    assert final["player"] == level["exit"] and final["completed"]
    assert final["moves"] == solution["moves"] and final["pushes"] == solution["pushes"]
    assert final.get("pulls", 0) == solution.get("pulls", 0) == pulls
    check_crystals(final)
    check_mechanisms(final)
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
