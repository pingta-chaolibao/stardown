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

## Confirmed global pressure and energy rule

The user clarified on 2026-10-23 that all yellow pressure cells in a level form one global AND condition. Only while every yellow cell is occupied do all yellow energy blocks disappear together, allowing movement and sight. Releasing any yellow cell restores all yellow energy blocks. Do not interpret `energy_links` identifiers as independent activation groups.

Level 07 has one yellow plate controlling both yellow barriers. EnergyRules and the independent video checker aggregate every yellow pressure cell before assigning any barrier state. IDs retain local occupancy/progress reports only; they never open barriers independently. The former independent-group test was replaced by the global rule and a dedicated partition/hand-off/death regression. New maps reuse these rules without changing hero or mechanism behavior. Preserve all previously delivered maps, solutions, videos and replay evidence byte-for-byte; adding navigation must still fit both tested window sizes.

## Confirmed eighth map

The user confirmed the original numbered screenshot and matching 2D grid. Level 08 is 7x6 with green hero (1,1), purple crystals (2,1)/(1,2)/(2,2), walls (5,0)/(5,1), static bushes (1,3)/(5,3)/(3,5), yellow plates (1,4)/(3,4)/(5,4), goal (6,0), barrier (6,1), all other internal cells floor. Numbering is row-major 1–42. Preserve JSON schema 1; the user's configuration question did not authorize a format migration. Reuse green automatic nearest-single pulling, static bush collision/sight, global all-plates AND, and undo-only revival. No gray or purple heroes.

## Required walkthrough for every completed level

Level 09 uses the user's corrected blue rule: each direction input checks only that cardinal ray first. If the first visible hero/crystal is a legal target, exchange positions; otherwise try walking one cell. No pushing or pulling. Walls, static bushes and active energy block sight. Keyboard arrows/WASD and screen direction buttons use this same rule; there is no separate skill key or plain-walk bypass. No frame-based rescan: one fresh press is one action; echo and held duplicates are ignored. User acceptance example: from marker 13=(1,1), down walks to 24=(1,2) without noticing side crystal 26=(3,2); then right swaps directly with 26 without landing on 25=(2,2). Levels 01–12 retain their single-hero data. Multi-hero support is shared by the same engine from level 13. For levels 01–12, all solution symbols are uppercase UDLR direction inputs; successful walks and swaps each count as one operation, with a separate swaps counter. Preserve the previous eight maps, solutions, MP4s and replay reports byte-for-byte. JSON schema remains 1.

The user requires one complete gameplay demonstration video for every level. This is part of finishing a level, including future work.

1. Finish and validate the level, then commit its implementation before producing the video.
2. Record the actual Godot viewport, using legal input from the level's initial state to explicit victory. Deterministic keyboard replay is allowed. Include every movement and push at a readable speed; do not teleport, edit game state to win, or substitute a screenshot montage.
3. Store videos under the repository root `video/`, grouped by chapter: `video/chapter_01/level_01.mp4`, `video/chapter_01/level_02.mp4`, and the corresponding numbered paths for later chapters and levels.
4. Prefer browser-compatible H.264, `yuv420p`, and MP4 fast-start. Keep file sizes reasonable. Do not record an unrelated desktop or commit temporary raw AVI files.
5. Verify metadata, duration, nonzero frame count, and full decoding. Inspect the first and final frames for the correct level, initial state, and victory. Retain the replay path and verification evidence.
6. Commit the videos and updated documentation afterward, push normally, and verify the final remote SHA. Report implementation and video commits and the actual repository video links.

`tools/record_playthrough.gd` uses normal press/release events and checked paths from `levels/solutions/`. Run it with Godot Movie Maker, a real display, and `--fixed-fps 30`; it waits 18 frames per input, with initial and victory pauses. Extend the checked paths and recording coverage as new levels are added.

## Confirmed tenth map

Level 10 is the user-confirmed 11x7 blue-hero map in north_10.json. Original marker 4=(3,0) is explicitly corrected to floor; all other cells including earlier question-mark cells are confirmed. Hero=(0,1), single purple crystal=(1,1), exit=(1,5), plate=(10,6), energy=(3,5); middle row y=3 has floor only at x=5 and x=9. No bushes or new rules. Keep the first nine maps, solutions, videos and replay reports byte-for-byte unchanged from 9c879b28bd093773d6af2a9dcf2aa6dccc3c205b. Use the existing blue direction-first target priority and global yellow settlement.

## Confirmed eleventh map and delivery

Level 11 is the confirmed 11x7 blue-hero map. Main platform x=0..6/y=0..6 is floor; x=7 is wall except green gate (7,1); right platform x=8..10/y=0..2 is floor, and the twelve lower-right cells are impassable void, displayed differently from walls. Hero=(5,0), exit=(9,1), eight main crystals occupy every odd-coordinate plate except (1,5); orange crystal=(10,1). All nine plates globally AND together; hero or crystal can hold any plate. Mechanism/crystal colors are presentation only, with no matching or separate color groups. The constructed route LLLLLDDDDRDRRUURULD is independently checked, not an exhaustive or shortest-path claim. Keep all previous ten maps, solutions, MP4s and replay reports byte-for-byte from b709b04fc1b9276f50e4546be518813c7434a4f0.

The user now gets the project via Git and explicitly does not need a project ZIP. Deliver the new video, short commit information and test results; do not generate, verify or offer another project ZIP unless the user later changes this request. The implementation-before-recording and separate video commit workflow still applies.

## Confirmed twelfth map

Level 12 is the user-confirmed 7x6 blue-hero map: hero=(1,1), orange/purple/pink crystals=(2,1)/(1,2)/(2,2), bushes=(3,3)/(3,5), yellow plates=(1,4)/(3,4)/(5,4), walls=(5,0)/(5,1), energy=(6,1), exit=(6,0), other internal cells floor and all outside blocked. Top and bottom rows are complete. Pink is presentation only, without new rules. Keep all previous eleven maps, solutions, MP4s and replay reports byte-for-byte from df563998ed43ecadc735e0a60a4c500ffc7f305c. Reuse passive blue exchange, static bushes, global pressure AND, and undo-only revival. Independent search stops at its first victory, not an exhaustive/optimality claim. Git delivery and no additional project ZIP remain the user's preference.


## Confirmed thirteenth map and multi-hero operations

Level 13 is the confirmed 7x7 map in north_13.json, with red=(2,2), blue=(2,4), crystals=(0,1)/(0,4), red circular exits=(0,2)/(0,5), yellow plates=(5,1)/(5,5), gate=(5,3). Keep explicitly confirmed (1,0)/(3,1) floor and (3,6) wall. Both heroes must simultaneously occupy different exits, with no fixed assignment; crystals on exits never count. Initially select blue.

C and the screen switch button cycle selected hero in stable definition order. The user corrected the convention: switching is control selection only, does not count as an operation/step, creates no undo entry, and changes no positions/pressure/life or abilities. Single-hero C is a no-op. Selection must remain tied to hero identity after any push/exchange. Red pushes contiguous mixed lines of heroes and crystals atomically by one cell with no fixed length limit. Passive movement of another hero never triggers its ability. Blue still exchanges only the first visible hero/crystal on the current input ray; no skill key. Green future behavior stays one-crystal auto-pull, never hero pulling. No gray hero.

All heroes, including inactive ones, occupy cells and hold plates. Any hero death globally blocks movement, C, restart and level change until undo revives it. Undo restores every hero position/life, crystals, actual-action counters and mechanisms, while retaining the user's current selected hero. Selection and selection-event telemetry are excluded from world snapshots. Restart explicitly restores initial selection. Current hero has a bright outline/selection ring; inactive heroes retain their red/blue hue with reduced brightness, never grayscale.

The independently revalidated route has 24 counted direction actions, 3 uncounted C selection events (27 total inputs) and 2 swaps; no shortest-path/exhaustive claim and no need to move both crystals. Preserve all prior 12 maps/solutions/MP4s/replays byte-for-byte from 133f20836428f503a8ac6a7be1e579688c1f663f. Continue implementation-before-recording and separate video commit to video/chapter_01/level_13.mp4. Git delivery only, no ZIP.


## User correction: switching is not an action

The user's latest instruction is “切换不算操作不用撤销”. C and the screen switch button change only active selection, with no move count, gameplay switch statistic or undo snapshot. Undo skips intervening selection changes and restores the most recent actual movement/push/swap while retaining current selection. With no history, switching then undo leaves the selection unchanged. Repeat/echo guards and any-hero death lock still apply. Keep actual actions and control selection events separate in solutions, recorder evidence and independent replay: level13 has moves=24, input_events=27, selection_events=3. Re-record its formal video after the fix implementation commit; preserve the old recording in Git history, not as evidence for the corrected behavior. No new map, rule or ZIP work.


## Confirmed fourteenth map

Level 14 is the user-confirmed 10x7 red/green map in north_14.json. Latest correction wins: marker6=(5,0) is wall, not floor; keep 8/9/29/50 floor and 64–66 walls. Red=(1,1),green=(1,5),one purple crystal=(3,1),exits=(6,0)/(6,6),yellow plate=(9,3),two barriers=(8,1)/(8,5). Initially select red. Use the same red mixed-line pushing, green automatic nearest-single crystal pulling (never hero pulling), free C selection and undo retaining current choice, both-hero goals and global pressure/death rules. No new mechanism or hero.

Independent search stops at its first victory: 35 actual direction actions,15 uncounted selection events,6 pushes,4 pulls. Red and green both cross their respective open energy cells; green hands pressure to the purple crystal with an automatic single pull. Do not claim shortest/exhaustive. Keep prior 13 maps/solutions/videos/replays byte-identical from 8b00eb9b54574300968c7fa7af5bd493d880dafa. Implementation commit first, then actual video/chapter_01/level_14.mp4 and separate video commit. No ZIP.


## Confirmed fifteenth map

Level 15 is the confirmed 11x7 blue/green map in north_15.json. Latest correction: 25=(2,2) is blocked, and 47=(2,4) remains blocked. Blue=(4,0),green=(3,3),pink crystal=(8,0),blue-purple=(7,6),exits=(0,2)/(0,4),yellow plates=(4,3)/(10,3),energy=(2,3). Initial selection blue. Only (6,1) connects the upper platform; bottom corridor(5,5)/(6,5)/(6,6)/(7,6) stays exact. Do not widen terrain or change sight to solve it.

Reuse passive direction-first blue exchange with first hero/crystal, green automatic nearest-single crystal pull, free C and undo retaining selection, global all-pressure AND, both-hero goals and undo-only revival. No pushing or new mechanism. Independent identity-aware BFS stops at first living victory: 61 actual actions+20free selections,11pulls/7swaps. Actual route uses both crystals and three hero exchanges including across open energy. Legitimate side route:blue inside gate at action52, select green and move down off plate; restored energy kills inactive blue, C/R/load cannot bypass, one undo revives while green remains selected. Do not splice this test into walkthrough.

Preserve previous 14 maps/solutions/MP4s/replays byte-for-byte from 1efc54dbdbe41013cee7fb6136a03b635daf1e87. Commit implementation before recording actual video/chapter_01/level_15.mp4, then separate media commit, normal develop push and verified download. No ZIP.


## Confirmed sixteenth map

Level 16 is the confirmed 11x3 red/blue map in north_16.json: terrain ...##.##..# / ........... / ...##.##..#. Red=(5,1),blue=(5,2),one purple-pink crystal=(10,1),yellow plate=(1,1),energy=(7,1),purple disc goals=(9,0)/(9,2). Third row is complete;33=(10,2) remains blocked. Initially select blue. Purple is goal presentation only, no portal/teleport or new rule. Reuse red mixed pushing, blue direction-first passive exchange, free C, undo retaining selection, global pressure/death and distinct hero goals.

Independent BFS first victory: 15actual actions+3free selections,3swaps,0pushes. Do not claim exhaustive/optimality. Mixed pushing and death tested separately through legal campaign side paths, never spliced into formal walkthrough: ULLLLRCURRRRCLLCLLLLLLLL produces21actions/8pushes including crystal+blue, then a boundary blocks the mixed line. Prefix9 of formal solution plus CLLCLLLC leaves red in open gate and blue on plate;blue down restores energy and kills inactive red, onlyUndo revives while blue remains selected.

Preserve prior 15 maps/solutions/videos/replays byte-identically from f3caa746724876d1eb80a2b30a106d7328832ad2. Keep all gameplay core scripts except the validated exit_color enum unchanged;purple only extends rendering/data presentation.16 readable navigation buttons use two rows. Commit implementation first, then real video/chapter_01/level_16.mp4 and separate media commit, normal develop push and download check. No ZIP.


## Confirmed seventeenth map and global restoration destruction

Level17 is the confirmed9x5 map in north_17.json. Keep terrain and objects exactly as confirmed:32=(4,3) floor,23=(4,2)/41=(4,4) blocked. Heroes green=(0,4),blue=(2,4),red=(8,4),initial blue;crystals=(0,0)/(8,0)/(8,3)/(6,4);goals=(3,0)/(4,0)/(2,2);plates=(3,3)/(5,3);barriers=(0,2)/(8,2). All blocked terrain, including decorative hedges, continues blocking movement and sight. Do not invent transparent hedges, extra passages or new heroes. Three heroes must occupy different goals; color never assigns heroes to goals.

The user clarified a global base rule: absent/passable energy permits crystals; when energy reappears, heroes and monsters there are killed and crystals there are destroyed. Implement this in common EnergyRules settlement, not as a level17 exception. Destruction occurs only on the absent->active edge, not while energy remains absent/active or at cold load. Invalid initial crystal/active-energy overlap stays invalid. Compute candidate occupancy, all-pressure AND, all barriers and all life/crystal consequences once; commit one undo snapshot. Undo restores destroyed crystal identities, all hero life, pressure and barriers, retaining current selection. Plate/barrier coordinates are disjoint, so destruction cannot silently change plate occupancy. Monsters currently have only declared killed semantics; do not add monster gameplay.

This rule supersedes all earlier documentation describing crystal restoration as unconfirmed. The former42-state outer proof assumed no deletions; permanently opening gates removes the destruction mechanism and is not a superset of valid play. Keep the diagnostic as historical local evidence, not a reason to question the confirmed layout. The constructed independent route has66actual actions+15freeC,2pushes/11pulls/3swaps;action21 destroys two outer crystals simultaneously,53 destroys the third. No exhaustive/optimality claim. A legal side path after prefix15 moves green onto left energy, then blue releases a plate:inactive green dies and right crystal is destroyed, oneUndo restores both. Do not splice this into the formal walkthrough.

Preserve previous16 maps/solutions/MP4s/replays,64files and16media manifest entries, byte-for-byte from7f03ee639eadfc5ac74ac35721bae54b809cd2cb. Update obsolete rule-guard tests to confirmed behavior, run all regressions, then implementation commit before actual video/chapter_01/level_17.mp4 and separate media commit. Three-hero UI must show all roles/highlights/stats and freeC,17navigation buttons must fit both sizes. Normal Git develop push, verify download/remote/CI, noZIP.


## Confirmed eighteenth map

Level18 is the confirmed7x8 map in north_18.json. Red=(0,2),green=(1,2),blue=(2,2),initial blue;single purple-pink crystal=(0,0);ordinary blue disc goals=(4,3)/(3,4)/(4,4),plate=(1,7),yellow energy=(4,2). Marker18=(3,2) is floor,12=(4,1) wall,19=(4,2) is the one bottom-anchored energy cell. Head labels1/2/3 identify heroes, not grid cells. Keep all terrain exactly, no new rule or portal/color matching. FreeC/undo retaining selection,three distinct hero goals,red mixed pushing,green single-crystal pulling,blue current-direction passive exchange and global energy restoration semantics remain.

Independent identity-aware BFS (including crystal deletion states) stops at first living victory:78actual actions,61freeC,26pushes/8pulls/10swaps,no crystal destruction on the chosen route. Do not claim exhaustive/optimality. The route first uses green then blue as temporary plate holders;action69 blue exchanges crystal onto bottom plate;71/73/77 green/blue/red occupy the open energy cell;78 red pushes blue into the last goal while entering the vacated goal. Show the newly delivered dashed absent-energy mark in the new video. Blue goal color is presentation only, keeping all original marker colors intact.

Preserve previous17 maps/solutions/MP4s/replays (68files) byte-for-byte from8cc3bf09f700ce4071dd59c53b2b8d8cedf3e254 and the separately delivered energy visibility demo from2ed1f9f611cd4ab6a88c3ddea25ed0c1e75d907f. Implementation commit before actual video/chapter_01/level_18.mp4,then separate media commit,normal Git develop push,download/remote/CI verification;noZIP. Keep the energy-visibility work's independent commits4fa554b/2ed1f9f and its download links.

## Confirmed nineteenth map

Level19 is the confirmed11x7 map in north_19.json. Red=(5,1),green=(4,0),blue=(6,0),initial green;purple crystal=(1,1). Ordinary orange goals=(4,0)/(6,0)/(9,1),so green and blue start on two goals without completing the level. Blue plates=(1,5)/(5,5)/(9,5),blue barriers=(1,3)/(9,3). Markers70=(3,6)/74=(7,6) are blocked decorative pillars,not bushes. All three plates globally AND-open both barriers. Orange goals and blue mechanisms are presentation only; never add color matching,independent groups,new hero abilities or altered visibility.

Independent four-object identity-aware BFS with restoration deletion stops at first living victory:63actual actions+34freeC,13pushes/5swaps/0pulls/0destroyed. No optimality/exhaustive claim. Three heroes first hold all plates,then blue swaps the distant crystal through open left energy onto the plate;red moves it to middle,blue/red exchange and later crystal handoff keep IDs/pressure atomic. Red and green cross the two open energy cells;three heroes finish on distinct goals. A legal side path after action36 selects green and moves up off right plate,killing inactive red in left energy;onlyUndo revives and retains green. Do not splice this test into the formal movie.

Preserve all previous18 maps/solutions/MP4s/replays (72files) and18manifest entries frome445d2aea0e7aa7ddf2c5f21c16f1be3c9cc35af;preserve the visibility demo/evidence from2ed1f9f. Gameplay core stays unchanged;only data/presentation enum extensions and navigation/test/recording coverage.19buttons use two rows10+9 fitting both window sizes. Commit implementation before actual video/chapter_01/level_19.mp4,then separate media commit,normal Git develop push and download/remote/CI verification;noZIP.


## Virtualized level-selection main screen

Default startup shows a persistent LevelMenu sibling of the game UI. All19 real maps remain unchanged. Main'sLEVEL_PATHS is the catalog authority;synthetic1000/5000 sources belong only to tests. No lock/completion/reward data is invented. virtual_level_strip.gd stores a numeric content extent and offset,keeps at most ceil(viewport_width/282)+5 cards (clamped to item count),and rebinds modulo pool slots with2 prefetch items per side. Cards own no focus or event closures;the stable viewport owns logical focus,hit-testing and activation. Mouse drag threshold10px,single-touch capture,canceled-touch/mouse-emulation suppression,finite inertia,wheel/pan andkeyboardHome/End/Page/Left/Right/Enter are tested. Resize/source changes cancel a pressed gesture and resize the pool. Preserve context and exact pool objects through normal enter/return;do not rebuild all buttons.

Game BackToLevels/Escape and select_level/back_to_menu APIs share the any-hero death lock. OnlyUndo may revive;return/reenter must never bypass it. Returning itself leaves the world unchanged;choosing a card starts that map fresh. Menu keyboard input must never control hidden gameplay. C/Undo/energy rules remain unchanged. start_in_level is an explicit startup-only harness flag for future actual walkthrough recorders,not a death-reset action.

Existing UI regressions select levels through real Back/card input via common test helpers. Keep all gameplay assertions,including death controls;test BackToLevels instead of removed old navigation buttons. Only pooled preview cards are exempt from whole-viewport layout assertions because the parent clips their bounded offscreen preload;navigation_scene.gd separately tests clip/pool/bindings. Keep the game header at78px and original font sizes so old board/energy pixel references remain aligned.

Run full tools/verify.py --visual --display :97 and navigation pressure/input/render tests. Retain original19 maps/solutions/MP4/replay files(76files),chapter manifest and energy demo byte-for-byte from94e007f1223102d53e17602a3bf75d750405b97f. UI demo is separate video/ui/level_navigation.mp4,not a20th level walkthrough. Commit validated implementation before actual MovieMaker recording,then a separate demo/evidence commit and normal develop push. NoZIP/forcepush/PR/deploy/credentials/usercomputer.


## Confirmed twentieth map and shared fences

Level20 is the user-confirmed5x5 map in north_20.json. Blue=(2,1),green=(0,4),red=(4,4),initial blue;crystals=(1,0)/(3,0),goals=(1,2)/(2,2)/(3,2). F1=(0,3)↔(0,4),F2=(4,3)↔(4,4),no plates/energy. All three heroes must occupy distinct goals. Keep terrain and object positions unchanged.

Fences are optional schema1 edge pairs in `fences`,not cell obstacles. Normalize undirected endpoints;validate in-bounds integer floor coordinates,orthogonal adjacency and duplicate/reversed duplicates. Block both directions of walking and every participating mixed-chain push or single-crystal pull edge atomically. A blocked mandatory green pull rejects the entire walk/pull;no partial move. Blue's input-direction first-target sight and exchange ignore fences,while walls/bushes/active energy retain sight blocking. Blue with no target must still obey movement edges. No ability changes,no extra heroes.

Independent identity-aware search first victory:30actual directions+13freeC,2pushes/2pulls/11swaps,6fence-crossing swaps;not an optimality/exhaustive claim. Keep all19 prior maps/solutions/MP4s/replays(76files),19manifest entries and energy/navigation demo files byte-for-byte fromca9b06e8f5efef704d6af7e59c97b5634336fa85. Append20 to persistent virtual catalog with bounded pool;do not restore all-level buttons. Full visual verification,implementation commit before actual video/chapter_01/level_20.mp4,then separate media commit and normalGitdevelop push/download/SHA checks. NoZIP,forcepush,PR,deployment,credentials or usercomputer.
