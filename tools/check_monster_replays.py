#!/usr/bin/env python3
"""Independent logic-only check of real GridState fixture traces; never movie evidence."""
import copy,json
from pathlib import Path
from check_walkthroughs import ROOT,check_replay
folder=ROOT/'artifacts/verification/monster_replay_cases'
for name in ('blue_swap','red_push','energy_kills_first'):
 item={'replay_report':name+'_replay.json','level_file':str((folder/(name+'_level.json')).relative_to(ROOT)),'solution_file':str((folder/(name+'_solution.json')).relative_to(ROOT)),'game_implementation_commit':'model_fixture_no_video'}
 evidence=check_replay(item,folder,require_rendered=False)
 assert evidence['display']=='headless','These fixtures report actual headless model execution, not rendered video'
 print('PASS independent logic fixture',name,flush=True)
 # A wrong monster identity/position must fail even when all hero counters match.
 path=folder/(name+'_replay.json');raw=path.read_bytes();bad=copy.deepcopy(evidence);bad['trace'][0]['monsters'][0]['position']=[8,8]
 try:
  path.write_text(json.dumps(bad));rejected=False
  try:check_replay(item,folder,require_rendered=False)
  except AssertionError:rejected=True
  assert rejected,'Independent checker must reject corrupted monster state'
 finally:path.write_bytes(raw)
 # Matching unknown kind in both configuration and telemetry must be rejected,
 # rather than inheriting Goblin's stationary/cardinal behavior.
 level_path=ROOT/item['level_file'];level_raw=level_path.read_bytes();unknown=json.loads(level_raw);unknown['monsters'][0]['kind']='future_monster';bad=copy.deepcopy(evidence)
 for state in [bad['initial_state'],*bad['trace'],bad['final_state']]:state['monsters'][0]['kind']='future_monster'
 try:
  level_path.write_text(json.dumps(unknown));path.write_text(json.dumps(bad));rejected=False
  try:check_replay(item,folder,require_rendered=False)
  except AssertionError:rejected=True
  assert rejected,'Unknown future monster kind must never default to Goblin behavior'
 finally:level_path.write_bytes(level_raw);path.write_bytes(raw)
print('MONSTER INDEPENDENT REPLAY RESULT: 3 real model fixtures +3 state corruption +3 unknown-kind rejections passed; no media claims')
