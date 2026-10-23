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
4. The first annotated level-07 image was an incomplete communication draft and must never be used as the final map. The user confirmed the corrected numbered layout and the final two conversions: (8,1) is floor, (8,2) is wall, energy 9 stands at (12,1), and (12,0) is the building boundary. Python and actual Godot rules both exhausted 1,574 living states without a solution in the resulting integer grid. Keep it out of playable navigation and delivery commits until that concrete conversion contradiction is resolved; do not invent openings or request the whole map again.

## Confirmed global yellow mechanism rule

The user clarified on 2026-10-23 that all yellow pressure cells in a level form one global AND condition. Only while every yellow cell is occupied do all yellow energy blocks disappear together, allowing movement and sight. Releasing any yellow cell restores all yellow energy blocks. Do not interpret `energy_links` identifiers as independent activation groups.

Level 07 is confirmed to have one yellow plate controlling both yellow barriers. EnergyRules and the independent video checker now aggregate every yellow pressure cell before assigning any barrier state. IDs retain local occupancy/progress reports only; they never open barriers independently. The former independent-group test was replaced by the global rule and a dedicated partition/hand-off/death regression. Levels 1–6 have at most one mechanism group, so their map data and intended behavior remain unchanged. Validate this independent core change with all existing levels and real rendering even while level-07 conversion is blocked; repeat affected checks when its final map is resolved.

## Required walkthrough for every completed level

The user requires one complete gameplay demonstration video for every level. This is part of finishing a level, including future work.

1. Finish and validate the level, then commit its implementation before producing the video.
2. Record the actual Godot viewport, using legal input from the level's initial state to explicit victory. Deterministic keyboard replay is allowed. Include every movement and push at a readable speed; do not teleport, edit game state to win, or substitute a screenshot montage.
3. Store videos under the repository root `video/`, grouped by chapter: `video/chapter_01/level_01.mp4`, `video/chapter_01/level_02.mp4`, and the corresponding numbered paths for later chapters and levels.
4. Prefer browser-compatible H.264, `yuv420p`, and MP4 fast-start. Keep file sizes reasonable. Do not record an unrelated desktop or commit temporary raw AVI files.
5. Verify metadata, duration, nonzero frame count, and full decoding. Inspect the first and final frames for the correct level, initial state, and victory. Retain the replay path and verification evidence.
6. Commit the videos and updated documentation afterward, push normally, and verify the final remote SHA. Report implementation and video commits and the actual repository video links.

`tools/record_playthrough.gd` uses normal press/release events and checked paths from `levels/solutions/`. Run it with Godot Movie Maker, a real display, and `--fixed-fps 30`; it waits 18 frames per input, with initial and victory pauses. Extend the checked paths and recording coverage as new levels are added.
