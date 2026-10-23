# Stardown cloud project

- Work in the selected cloud environment. Do not access or operate the user's computer.
- Preserve existing levels and user changes. Use confirmed grids or coordinates; do not guess unresolved map cells or retry a blocked image-transfer route without new authorization relevant to that route.
- The current delivery branch is `develop`. Use normal commits and pushes, preserve remote history, and verify the remote SHA. Do not force-push, create a PR, or publish the game unless separately instructed.
- Run `python3 tools/verify.py --visual --display :97` when changing gameplay, levels, or navigation. A headless run does not prove rendering works. Check an actual legal solution for every new level and keep existing level regressions passing.

## Screenshot confirmation workflow

The user requires this workflow for future maps:

1. Annotate the original screenshot with numbered grid cells. Use green for walkable cells, red for blocked cells, and blue for heroes, crystals, and mechanisms. Keep the numbering consistent with the coordinate inventory.
2. Mark occluded or uncertain cells explicitly as awaiting confirmation. Do not infer collision from roof outlines, tower height, or whether a guessed map is solvable. Blue object markers do not by themselves determine the underlying terrain.
3. Send the annotated original image to the user, apply their corrections, and obtain confirmation before encoding the final playable map.
4. The first annotated level-07 image was an incomplete communication draft and must never be used as the final map. The user confirmed the corrected numbered layout: (8,1) is floor, (8,2) is wall, energy 9 stands at (12,1), and (12,0) is the building boundary. After inspecting the 2D conversion, the user corrected (0,2) to floor, directly below original marker 14 at (0,1); keep the explicitly confirmed walls (4,6)/(6,8). This single correction resolves the conversion: independent search and Godot validate 152 moves / 56 single pulls. Original marker 70=(5,9), 129=(5,10). Do not reopen these confirmations or infer extra openings.

## Confirmed global yellow mechanism rule

The user clarified on 2026-10-23 that all yellow pressure cells in a level form one global AND condition. Only while every yellow cell is occupied do all yellow energy blocks disappear together, allowing movement and sight. Releasing any yellow cell restores all yellow energy blocks. Do not interpret `energy_links` identifiers as independent activation groups.

Level 07 has one yellow plate controlling both yellow barriers. EnergyRules and the independent video checker aggregate every yellow pressure cell before assigning any barrier state. IDs retain local occupancy/progress reports only; they never open barriers independently. The former independent-group test was replaced by the global rule and a dedicated partition/hand-off/death regression. New maps reuse these rules without changing hero or mechanism behavior. Preserve all previously delivered maps, solutions, videos and replay evidence byte-for-byte; adding navigation must still fit both tested window sizes.

## Confirmed eighth map

The user confirmed the original numbered screenshot and matching 2D grid. Level 08 is 7x6 with green hero (1,1), purple crystals (2,1)/(1,2)/(2,2), walls (5,0)/(5,1), static bushes (1,3)/(5,3)/(3,5), yellow plates (1,4)/(3,4)/(5,4), goal (6,0), barrier (6,1), all other internal cells floor. Numbering is row-major 1–42. Preserve JSON schema 1; the user's configuration question did not authorize a format migration. Reuse green automatic nearest-single pulling, static bush collision/sight, global all-plates AND, and undo-only revival. No gray or purple heroes.

## Required walkthrough for every completed level

Level 09 uses the user's corrected blue rule: each direction input checks only that cardinal ray first. If the first visible hero/crystal is a legal target, exchange positions; otherwise try walking one cell. No pushing or pulling. Walls, static bushes and active energy block sight. Keyboard arrows/WASD and screen direction buttons use this same rule; there is no separate skill key or plain-walk bypass. No frame-based rescan: one fresh press is one action; echo and held duplicates are ignored. User acceptance example: from marker 13=(1,1), down walks to 24=(1,2) without noticing side crystal 26=(3,2); then right swaps directly with 26 without landing on 25=(2,2). The single-hero world and reusable hero/crystal classification remain unchanged. All solution symbols are uppercase UDLR direction inputs; successful walks and swaps each count as one operation, with a separate swaps counter. Preserve the previous eight maps, solutions, MP4s and replay reports byte-for-byte. JSON schema remains 1.

The user requires one complete gameplay demonstration video for every level. This is part of finishing a level, including future work.

1. Finish and validate the level, then commit its implementation before producing the video.
2. Record the actual Godot viewport, using legal input from the level's initial state to explicit victory. Deterministic keyboard replay is allowed. Include every movement and push at a readable speed; do not teleport, edit game state to win, or substitute a screenshot montage.
3. Store videos under the repository root `video/`, grouped by chapter: `video/chapter_01/level_01.mp4`, `video/chapter_01/level_02.mp4`, and the corresponding numbered paths for later chapters and levels.
4. Prefer browser-compatible H.264, `yuv420p`, and MP4 fast-start. Keep file sizes reasonable. Do not record an unrelated desktop or commit temporary raw AVI files.
5. Verify metadata, duration, nonzero frame count, and full decoding. Inspect the first and final frames for the correct level, initial state, and victory. Retain the replay path and verification evidence.
6. Commit the videos and updated documentation afterward, push normally, and verify the final remote SHA. Report implementation and video commits and the actual repository video links.

`tools/record_playthrough.gd` uses normal press/release events and checked paths from `levels/solutions/`. Run it with Godot Movie Maker, a real display, and `--fixed-fps 30`; it waits 18 frames per input, with initial and victory pauses. Extend the checked paths and recording coverage as new levels are added.
