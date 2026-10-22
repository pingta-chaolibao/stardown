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

        try:
            report["engine"] = run("00_version", ["--version"]).strip()
            if not re.search(r"(?:^|\n)4\.", report["engine"]):
                raise RuntimeError("Godot 4 is required")
            run("01_import", ["--editor", "--import"])
            scripts = sorted((ROOT / "scripts").rglob("*.gd")) + sorted((ROOT / "tests").rglob("*.gd"))
            for index, script in enumerate(scripts):
                relative = script.relative_to(ROOT).as_posix()
                run(f"02_parse_{index:02}_{script.stem}", ["--check-only", "--script", "res://" + relative])
            run("03_logic", ["--script", "res://tests/run_tests.gd"])
            run("04_main_scene", ["--quit-after", "10", "--audio-driver", "Dummy"])
            run("05_scene_input", ["--script", "res://tests/scene_smoke.gd"])
            if args.visual:
                run("06_render", ["--display-driver", "x11", "--rendering-method", "gl_compatibility",
                                  "--audio-driver", "Dummy", "--script", "res://tests/scene_smoke.gd",
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
