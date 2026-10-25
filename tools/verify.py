#!/usr/bin/env python3
"""Run Godot import, parse, logic, and scene checks using only stdlib Python."""

import argparse
import datetime as dt
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tempfile
import time


ROOT = Path(__file__).resolve().parents[1]
ERROR = re.compile(r"(?:SCRIPT ERROR:|\bERROR:|^FAIL[: ])", re.MULTILINE)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--godot", help="Godot 4 executable (default: godot or godot4 on PATH)")
    parser.add_argument("--visual", action="store_true", help="Also run the real renderer and save screenshots; needs an existing X11 DISPLAY")
    parser.add_argument("--display", help="Use this X11 display for --visual, e.g. :97")
    args = parser.parse_args()
    engine = args.godot or shutil.which("godot") or shutil.which("godot4")
    if not engine:
        parser.error("Godot 4 was not found. Install from https://godotengine.org/download/ first.")
    if args.visual and not (args.display or os.environ.get("DISPLAY")):
        parser.error("--visual needs an X11 display. Set DISPLAY or pass --display; headless does not render images.")

    output = ROOT / "artifacts" / "verification"
    output.mkdir(parents=True, exist_ok=True)
    report = {
        "time_utc": dt.datetime.now(dt.timezone.utc).isoformat(),
        "root": str(ROOT),
        "visual_requested": args.visual,
        "steps": [],
    }
    status = 0
    with tempfile.TemporaryDirectory(prefix="stardown-check-") as temp:
        env = os.environ.copy()
        # All engine settings/caches stay in a temporary cloud directory.
        for key, folder in (("XDG_CONFIG_HOME", "config"), ("XDG_DATA_HOME", "data"), ("XDG_CACHE_HOME", "cache")):
            destination = Path(temp) / folder
            destination.mkdir()
            env[key] = str(destination)
        if args.display:
            env["DISPLAY"] = args.display

        def run(label, options, visual=False):
            command = [engine, "--path", str(ROOT)] + ([] if visual else ["--headless"]) + options
            run_env = env.copy()
            if visual:
                run_env["LIBGL_ALWAYS_SOFTWARE"] = "1"
            began = time.monotonic()
            try:
                process = subprocess.run(command, env=run_env, cwd=ROOT, text=True,
                                         stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                                         timeout=90, check=False)
                log, returncode = process.stdout, process.returncode
            except subprocess.TimeoutExpired as exc:
                log = exc.stdout or b""
                if isinstance(log, bytes):
                    log = log.decode("utf-8", errors="replace")
                log += "\nERROR: verification timed out after 90 seconds.\n"
                returncode = 124
            (output / (label + ".log")).write_text(log, encoding="utf-8")
            passed = returncode == 0 and not ERROR.search(log)
            report["steps"].append({"name": label, "passed": passed, "exit_code": returncode,
                                    "seconds": round(time.monotonic() - began, 3)})
            print(f"{'PASS' if passed else 'FAIL'} {label}", flush=True)
            for line in log.splitlines():
                if "RESULT:" in line or "CAPTURE:" in line or "OpenGL API" in line:
                    print("  " + line, flush=True)
            if not passed:
                print(log, file=sys.stderr)
                raise RuntimeError(label)
            return log

        def run_python(label, relative):
            began = time.monotonic()
            process = subprocess.run([sys.executable, str(ROOT / relative)], cwd=ROOT, env=env,
                                     text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                                     timeout=90, check=False)
            log = process.stdout
            (output / (label + ".log")).write_text(log, encoding="utf-8")
            passed = process.returncode == 0 and not ERROR.search(log)
            report["steps"].append({"name": label, "passed": passed, "exit_code": process.returncode,
                                    "seconds": round(time.monotonic() - began, 3)})
            print(f"{'PASS' if passed else 'FAIL'} {label}", flush=True)
            for line in log.splitlines():
                if "RESULT:" in line: print("  " + line, flush=True)
            if not passed:
                print(log, file=sys.stderr)
                raise RuntimeError(label)

        try:
            report["engine"] = run("00_version", ["--version"]).strip()
            if not re.search(r"(?:^|\n)4\.", report["engine"]):
                raise RuntimeError("Godot 4 is required")
            run("01_import", ["--editor", "--import"])
            scripts = sorted((ROOT / "scripts").rglob("*.gd")) + sorted((ROOT / "tests").rglob("*.gd"))
            for index, script in enumerate(scripts):
                relative = script.relative_to(ROOT).as_posix()
                run(f"02_parse_{index:02}_{script.stem}", ["--check-only", "--script", "res://" + relative])
            run("02_record_visual_feedback", ["--check-only", "--script", "res://tools/record_visual_feedback.gd"])
            run("02_record_playthrough", ["--check-only", "--script", "res://tools/record_playthrough.gd"])
            run("03_feedback", ["--script", "res://tests/feedback_regression.gd"])
            run("03_monster_clear_energy", ["--script", "res://tests/monster_clear_energy_regression.gd"])
            run("03_logic", ["--script", "res://tests/run_tests.gd"])
            run("03_chain_push", ["--script", "res://tests/chain_push_regression.gd"])
            run("03_energy", ["--script", "res://tests/energy_regression.gd"])
            run("03_global_energy", ["--script", "res://tests/global_energy_regression.gd"])
            run("03_bush_group", ["--script", "res://tests/bush_and_group_regression.gd"])
            run("03_green_pull", ["--script", "res://tests/green_pull_regression.gd"])
            run("03_blue_swap", ["--script", "res://tests/blue_swap_regression.gd"])
            run("03_multi_hero", ["--script", "res://tests/multi_hero_regression.gd"])
            run("03_north_13", ["--script", "res://tests/north_13_regression.gd"])
            run("03_north_14", ["--script", "res://tests/north_14_regression.gd"])
            run("03_north_15", ["--script", "res://tests/north_15_regression.gd"])
            run("03_north_16", ["--script", "res://tests/north_16_regression.gd"])
            run("03_energy_destruction", ["--script", "res://tests/energy_destruction_regression.gd"])
            run("03_north_17", ["--script", "res://tests/north_17_regression.gd"])
            run("03_north_18", ["--script", "res://tests/north_18_regression.gd"])
            run("03_north_19", ["--script", "res://tests/north_19_regression.gd"])
            run("03_fences", ["--script", "res://tests/fence_regression.gd"])
            run("03_north_20", ["--script", "res://tests/north_20_regression.gd"])
            run("03_north_21", ["--script", "res://tests/north_21_regression.gd"])
            run_python("03_north_29_independent", "tools/check_north_29.py")
            run("03_north_29", ["--script", "res://tests/north_29_regression.gd"])
            run_python("03_north_30_independent", "tools/check_north_30.py")
            run("03_north_30", ["--script", "res://tests/north_30_regression.gd"])
            run_python("03_north_31_independent", "tools/check_north_31.py")
            run("03_north_31", ["--script", "res://tests/north_31_regression.gd"])
            run_python("03_north_32_independent", "tools/check_north_32.py")
            run("03_north_32", ["--script", "res://tests/north_32_regression.gd"])
            run_python("03_north_28_independent", "tools/check_north_28.py")
            run("03_north_28", ["--script", "res://tests/north_28_regression.gd"])
            run("03_green_dragon_pull", ["--script", "res://tests/green_dragon_pull_regression.gd"])
            run_python("03_north_27_independent", "tools/check_north_27.py")
            run("03_north_27", ["--script", "res://tests/north_27_regression.gd"])
            run("03_fire_dragon", ["--script", "res://tests/fire_dragon_regression.gd"])
            run_python("03_north_26_independent", "tools/check_north_26.py")
            run("03_north_26", ["--script", "res://tests/north_26_regression.gd"])
            run("03_monsters", ["--script", "res://tests/monster_regression.gd"])
            run_python("03_monster_independent", "tools/check_monster_replays.py")
            run_python("03_north_25_independent", "tools/check_north_25.py")
            run("03_north_25", ["--script", "res://tests/north_25_regression.gd"])
            run_python("03_north_24_independent", "tools/check_north_24.py")
            run("03_north_24", ["--script", "res://tests/north_24_regression.gd"])
            run_python("03_north_23_independent", "tools/check_north_23.py")
            run("03_north_23", ["--script", "res://tests/north_23_regression.gd"])
            run("03_north_22", ["--script", "res://tests/north_22_regression.gd"])
            run("03_north_01", ["--script", "res://tests/north_01_regression.gd"])
            run("03_north_02", ["--script", "res://tests/north_02_regression.gd"])
            run("03_north_03", ["--script", "res://tests/north_03_regression.gd"])
            run("03_north_04", ["--script", "res://tests/north_04_regression.gd"])
            run("03_north_05", ["--script", "res://tests/north_05_regression.gd"])
            run("03_north_06", ["--script", "res://tests/north_06_regression.gd"])
            run("03_north_07", ["--script", "res://tests/north_07_regression.gd"])
            run("03_north_08", ["--script", "res://tests/north_08_regression.gd"])
            run("03_north_09", ["--script", "res://tests/north_09_regression.gd"])
            run("03_north_10", ["--script", "res://tests/north_10_regression.gd"])
            run("03_north_11", ["--script", "res://tests/north_11_regression.gd"])
            run("03_north_12", ["--script", "res://tests/north_12_regression.gd"])
            run("04_main_scene", ["--quit-after", "10", "--audio-driver", "Dummy"])
            run("05_feedback", ["--script", "res://tests/feedback_scene.gd"])
            run("05_monster_clear_energy", ["--script", "res://tests/monster_clear_energy_scene.gd"])
            run("05_scene_input", ["--script", "res://tests/scene_smoke.gd"])
            run("05_north_02_scene", ["--script", "res://tests/north_02_scene.gd"])
            run("05_north_03_scene", ["--script", "res://tests/north_03_scene.gd"])
            run("05_north_04_scene", ["--script", "res://tests/north_04_scene.gd"])
            run("05_north_05_scene", ["--script", "res://tests/north_05_scene.gd"])
            run("05_north_06_scene", ["--script", "res://tests/north_06_scene.gd"])
            run("05_north_07_scene", ["--script", "res://tests/north_07_scene.gd"])
            run("05_north_08_scene", ["--script", "res://tests/north_08_scene.gd"])
            run("05_north_09_scene", ["--script", "res://tests/north_09_scene.gd"])
            run("05_north_10_scene", ["--script", "res://tests/north_10_scene.gd"])
            run("05_north_11_scene", ["--script", "res://tests/north_11_scene.gd"])
            run("05_north_12_scene", ["--script", "res://tests/north_12_scene.gd"])
            run("05_north_13_scene", ["--script", "res://tests/north_13_scene.gd"])
            run("05_north_14_scene", ["--script", "res://tests/north_14_scene.gd"])
            run("05_north_15_scene", ["--script", "res://tests/north_15_scene.gd"])
            run("05_north_16_scene", ["--script", "res://tests/north_16_scene.gd"])
            run("05_north_17_scene", ["--script", "res://tests/north_17_scene.gd"])
            run("05_north_18_scene", ["--script", "res://tests/north_18_scene.gd"])
            run("05_north_19_scene", ["--script", "res://tests/north_19_scene.gd"])
            run("05_north_20_scene", ["--script", "res://tests/north_20_scene.gd"])
            run("05_north_21_scene", ["--script", "res://tests/north_21_scene.gd"])
            run("05_north_29_scene", ["--script", "res://tests/north_29_scene.gd"])
            run("05_north_30_scene", ["--script", "res://tests/north_30_scene.gd"])
            run("05_north_31_scene", ["--script", "res://tests/north_31_scene.gd"])
            run("05_north_32_scene", ["--script", "res://tests/north_32_scene.gd"])
            run("05_north_28_scene", ["--script", "res://tests/north_28_scene.gd"])
            run("05_green_dragon_pull", ["--script", "res://tests/green_dragon_pull_scene.gd"])
            run("05_north_27_scene", ["--script", "res://tests/north_27_scene.gd"])
            run("05_north_26_scene", ["--script", "res://tests/north_26_scene.gd"])
            run("05_north_25_scene", ["--script", "res://tests/north_25_scene.gd"])
            run("05_north_24_scene", ["--script", "res://tests/north_24_scene.gd"])
            run("05_north_23_scene", ["--script", "res://tests/north_23_scene.gd"])
            run("05_north_22_scene", ["--script", "res://tests/north_22_scene.gd"])
            run("05_navigation", ["--script", "res://tests/navigation_scene.gd"])
            run("05_energy_visibility", ["--script", "res://tests/energy_visibility_scene.gd"])
            if args.visual:
                run("06_feedback", ["--display-driver", "x11", "--rendering-method", "gl_compatibility", "--audio-driver", "Dummy", "--script", "res://tests/feedback_scene.gd", "--", "--capture-dir=" + str(ROOT / "artifacts" / "feedback" / "screenshots")], visual=True)
                run("06_monster_clear_energy", ["--display-driver", "x11", "--rendering-method", "gl_compatibility", "--audio-driver", "Dummy", "--script", "res://tests/monster_clear_energy_scene.gd", "--", "--capture-dir=" + str(ROOT / "artifacts" / "screenshots")], visual=True)
                run("06_render", ["--display-driver", "x11", "--rendering-method", "gl_compatibility",
                                  "--audio-driver", "Dummy", "--script", "res://tests/scene_smoke.gd",
                                  "--", "--capture-dir=" + str(ROOT / "artifacts" / "screenshots")], visual=True)
                run("06_render_north_02", ["--display-driver", "x11", "--rendering-method", "gl_compatibility",
                                          "--audio-driver", "Dummy", "--script", "res://tests/north_02_scene.gd",
                                          "--", "--capture-dir=" + str(ROOT / "artifacts" / "screenshots")], visual=True)
                run("06_render_north_03", ["--display-driver", "x11", "--rendering-method", "gl_compatibility",
                                          "--audio-driver", "Dummy", "--script", "res://tests/north_03_scene.gd",
                                          "--", "--capture-dir=" + str(ROOT / "artifacts" / "screenshots")], visual=True)
                run("06_render_north_04", ["--display-driver", "x11", "--rendering-method", "gl_compatibility",
                                          "--audio-driver", "Dummy", "--script", "res://tests/north_04_scene.gd",
                                          "--", "--capture-dir=" + str(ROOT / "artifacts" / "screenshots")], visual=True)
                run("06_render_north_05", ["--display-driver", "x11", "--rendering-method", "gl_compatibility",
                                          "--audio-driver", "Dummy", "--script", "res://tests/north_05_scene.gd",
                                          "--", "--capture-dir=" + str(ROOT / "artifacts" / "screenshots")], visual=True)
                run("06_render_north_06", ["--display-driver", "x11", "--rendering-method", "gl_compatibility",
                                          "--audio-driver", "Dummy", "--script", "res://tests/north_06_scene.gd",
                                          "--", "--capture-dir=" + str(ROOT / "artifacts" / "screenshots")], visual=True)
                run("06_render_north_07", ["--display-driver", "x11", "--rendering-method", "gl_compatibility",
                                          "--audio-driver", "Dummy", "--script", "res://tests/north_07_scene.gd",
                                          "--", "--capture-dir=" + str(ROOT / "artifacts" / "screenshots")], visual=True)
                run("06_render_north_08", ["--display-driver", "x11", "--rendering-method", "gl_compatibility",
                                          "--audio-driver", "Dummy", "--script", "res://tests/north_08_scene.gd",
                                          "--", "--capture-dir=" + str(ROOT / "artifacts" / "screenshots")], visual=True)
                run("06_render_north_09", ["--display-driver", "x11", "--rendering-method", "gl_compatibility",
                                          "--audio-driver", "Dummy", "--script", "res://tests/north_09_scene.gd",
                                          "--", "--capture-dir=" + str(ROOT / "artifacts" / "screenshots")], visual=True)
                run("06_render_north_10", ["--display-driver", "x11", "--rendering-method", "gl_compatibility",
                                          "--audio-driver", "Dummy", "--script", "res://tests/north_10_scene.gd",
                                          "--", "--capture-dir=" + str(ROOT / "artifacts" / "screenshots")], visual=True)

                run("06_render_north_11", ["--display-driver", "x11", "--rendering-method", "gl_compatibility",
                                          "--audio-driver", "Dummy", "--script", "res://tests/north_11_scene.gd",
                                          "--", "--capture-dir=" + str(ROOT / "artifacts" / "screenshots")], visual=True)

                run("06_render_north_12", ["--display-driver", "x11", "--rendering-method", "gl_compatibility",
                                          "--audio-driver", "Dummy", "--script", "res://tests/north_12_scene.gd",
                                          "--", "--capture-dir=" + str(ROOT / "artifacts" / "screenshots")], visual=True)

                run("06_render_north_13", ["--display-driver", "x11", "--rendering-method", "gl_compatibility",
                                          "--audio-driver", "Dummy", "--script", "res://tests/north_13_scene.gd",
                                          "--", "--capture-dir=" + str(ROOT / "artifacts" / "screenshots")], visual=True)

                run("06_render_north_14", ["--display-driver", "x11", "--rendering-method", "gl_compatibility",
                                          "--audio-driver", "Dummy", "--script", "res://tests/north_14_scene.gd",
                                          "--", "--capture-dir=" + str(ROOT / "artifacts" / "screenshots")], visual=True)

                run("06_render_north_15", ["--display-driver", "x11", "--rendering-method", "gl_compatibility",
                                          "--audio-driver", "Dummy", "--script", "res://tests/north_15_scene.gd",
                                          "--", "--capture-dir=" + str(ROOT / "artifacts" / "screenshots")], visual=True)

                run("06_render_north_16", ["--display-driver", "x11", "--rendering-method", "gl_compatibility",
                                          "--audio-driver", "Dummy", "--script", "res://tests/north_16_scene.gd",
                                          "--", "--capture-dir=" + str(ROOT / "artifacts" / "screenshots")], visual=True)
                run("06_render_north_17", ["--display-driver", "x11", "--rendering-method", "gl_compatibility",
                                          "--audio-driver", "Dummy", "--script", "res://tests/north_17_scene.gd",
                                          "--", "--capture-dir=" + str(ROOT / "artifacts" / "screenshots")], visual=True)
                run("06_render_north_18", ["--display-driver", "x11", "--rendering-method", "gl_compatibility",
                                          "--audio-driver", "Dummy", "--script", "res://tests/north_18_scene.gd",
                                          "--", "--capture-dir=" + str(ROOT / "artifacts" / "screenshots")], visual=True)
                run("06_render_north_19", ["--display-driver", "x11", "--rendering-method", "gl_compatibility",
                                          "--audio-driver", "Dummy", "--script", "res://tests/north_19_scene.gd",
                                          "--", "--capture-dir=" + str(ROOT / "artifacts" / "screenshots")], visual=True)
                run("06_render_north_20", ["--display-driver", "x11", "--rendering-method", "gl_compatibility",
                                          "--audio-driver", "Dummy", "--script", "res://tests/north_20_scene.gd",
                                          "--", "--capture-dir=" + str(ROOT / "artifacts" / "screenshots")], visual=True)
                run("06_render_north_21", ["--display-driver", "x11", "--rendering-method", "gl_compatibility",
                                          "--audio-driver", "Dummy", "--script", "res://tests/north_21_scene.gd",
                                          "--", "--capture-dir=" + str(ROOT / "artifacts" / "screenshots")], visual=True)
                run("06_render_north_22", ["--display-driver", "x11", "--rendering-method", "gl_compatibility",
                                          "--audio-driver", "Dummy", "--script", "res://tests/north_22_scene.gd",
                                          "--", "--capture-dir=" + str(ROOT / "artifacts" / "screenshots")], visual=True)
                run("06_render_north_23", ["--display-driver", "x11", "--rendering-method", "gl_compatibility",
                                          "--audio-driver", "Dummy", "--script", "res://tests/north_23_scene.gd",
                                          "--", "--capture-dir=" + str(ROOT / "artifacts" / "screenshots")], visual=True)
                run("06_render_north_24", ["--display-driver", "x11", "--rendering-method", "gl_compatibility",
                                          "--audio-driver", "Dummy", "--script", "res://tests/north_24_scene.gd",
                                          "--", "--capture-dir=" + str(ROOT / "artifacts" / "screenshots")], visual=True)
                run("06_render_north_25", ["--display-driver", "x11", "--rendering-method", "gl_compatibility",
                                          "--audio-driver", "Dummy", "--script", "res://tests/north_25_scene.gd",
                                          "--", "--capture-dir=" + str(ROOT / "artifacts" / "screenshots")], visual=True)
                run("06_render_north_26", ["--display-driver", "x11", "--rendering-method", "gl_compatibility",
                                          "--audio-driver", "Dummy", "--script", "res://tests/north_26_scene.gd",
                                          "--", "--capture-dir=" + str(ROOT / "artifacts" / "screenshots")], visual=True)
                run("06_green_dragon_pull", ["--display-driver", "x11", "--rendering-method", "gl_compatibility",
                                          "--audio-driver", "Dummy", "--script", "res://tests/green_dragon_pull_scene.gd",
                                          "--", "--capture-dir=" + str(ROOT / "artifacts" / "screenshots")], visual=True)
                run("06_render_north_27", ["--display-driver", "x11", "--rendering-method", "gl_compatibility",
                                          "--audio-driver", "Dummy", "--script", "res://tests/north_27_scene.gd",
                                          "--", "--capture-dir=" + str(ROOT / "artifacts" / "screenshots")], visual=True)
                run("06_render_north_29", ["--display-driver", "x11", "--rendering-method", "gl_compatibility", "--audio-driver", "Dummy", "--script", "res://tests/north_29_scene.gd", "--", "--capture-dir=" + str(ROOT / "artifacts" / "screenshots")], visual=True)
                run("06_render_north_30", ["--display-driver", "x11", "--rendering-method", "gl_compatibility", "--audio-driver", "Dummy", "--script", "res://tests/north_30_scene.gd", "--", "--capture-dir=" + str(ROOT / "artifacts" / "screenshots")], visual=True)
                run("06_render_north_31", ["--display-driver", "x11", "--rendering-method", "gl_compatibility", "--audio-driver", "Dummy", "--script", "res://tests/north_31_scene.gd", "--", "--capture-dir=" + str(ROOT / "artifacts" / "screenshots")], visual=True)
                run("06_render_north_32", ["--display-driver", "x11", "--rendering-method", "gl_compatibility", "--audio-driver", "Dummy", "--script", "res://tests/north_32_scene.gd", "--", "--capture-dir=" + str(ROOT / "artifacts" / "screenshots")], visual=True)
                run("06_render_north_28", ["--display-driver", "x11", "--rendering-method", "gl_compatibility",
                                          "--audio-driver", "Dummy", "--script", "res://tests/north_28_scene.gd",
                                          "--", "--capture-dir=" + str(ROOT / "artifacts" / "screenshots")], visual=True)
                run("06_navigation", ["--display-driver", "x11", "--rendering-method", "gl_compatibility",
                                          "--audio-driver", "Dummy", "--script", "res://tests/navigation_scene.gd",
                                          "--", "--capture-dir=" + str(ROOT / "artifacts" / "screenshots")], visual=True)
                run("06_energy_visibility", ["--display-driver", "x11", "--rendering-method", "gl_compatibility",
                                          "--audio-driver", "Dummy", "--script", "res://tests/energy_visibility_scene.gd",
                                          "--", "--capture-dir=" + str(ROOT / "artifacts" / "screenshots")], visual=True)

        except (RuntimeError, OSError) as exc:
            report["error"] = str(exc)
            status = 1

    report["passed"] = status == 0
    (output / "report.json").write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"Verification {'passed' if status == 0 else 'failed'}; evidence: {output}", flush=True)
    return status


if __name__ == "__main__":
    sys.exit(main())
