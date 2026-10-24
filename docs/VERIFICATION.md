# 云端运行验证

Godot精确版本：`4.6.3.stable.official.7d41c59c4`。完整验证命令`python3 tools/verify.py --visual --display :97`，本轮128步骤全部通过，含57个脚本解析；录制器另行解析。只在云端运行，无ZIP、PR、发布或用户电脑操作。

## 第十九关确认配置

11×7共77格，59地板。红17=(5,1)，绿5=(4,0)，蓝7=(6,0)，初始绿；绿/蓝起点也是橙目标，初始2/3不提前胜利。第三目标21=(9,1)，唯一紫晶13=(1,1)。蓝板57/61/65=(1,5)/(5,5)/(9,5)，蓝能量35/43=(1,3)/(9,3)。70/74=(3,6)/(7,6)为墙，不是草丛。橙目标/蓝机关均只影响显示，不新增匹配或传送规则。

五个共享玩法/输入核心文件与前18关交付e445d2a逐字节相同。LevelData仅扩展orange目标和blue机关显示枚举；BoardView/UI保留旧黄/绿显示，新增蓝色实心/消失虚线和橙色普通目标。19个入口两行10+9，保留原字号/按钮高度和旧棋盘像素对齐，大小窗口全部可操作。

## 独立合法路线

`CCDCDCLDCCRCCDDDCCLCDCRCCDCRRRCLLLUCLLLULLDRRRRLLLCCDCDDDRCUCRCDRRRCCLCRRRCUUCCLLLCUCUCLUUUULUCCR`

63实际方向行动+34免费C=97输入，13推5换0拉0毁晶。独立身份占用BFS含再现删除状态，扩展3574484/访问3755119，余180635，21.802秒首次存活胜利停止，不宣称最优或穷举。

18三英雄同时压三板打开双门；19蓝隔左门交换紫晶，使晶接替左板；30红将晶推中板，34蓝红跨门交换保持占用；36红、49绿分别经过左/右消失能量格；40晶回左板，最终红(4,0)/绿(9,1)/蓝(6,0)同时占三不同目标，晶ID0在(1,5)。没有按英雄颜色匹配。

63次Undo全部还原实际行动世界状态并保持最终蓝选择，34次免费C不进历史；重开恢复初始绿。验证8种三板占用组合、初始双目标、首对象交换/晶交接、红推英雄链、绿不能推英雄、重复/回声输入、屏幕方向/切换、胜利后Undo/重开及18↔19隔离。

合法死亡侧路：正式前缀36，选绿U离开右板，两门同时恢复，杀死左门格非当前红。C/方向/R/关卡选择锁定，一次Undo恢复红生命、所有英雄/晶身份、三板/双门并保留绿；该侧路只测试，不拼入通关视频。

## 完整回归

| 检查 | 结果 |
| --- | --- |
| 03_logic | 13组 / 4662项，0失败 |
| 03_chain_push | 6组 / 701项，0失败 |
| 03_energy | 9组 / 83项，0失败 |
| 03_global_energy | 6组 / 168项，0失败 |
| 03_bush_group | 8组 / 95项，0失败 |
| 03_green_pull | 8组 / 4445项，0失败 |
| 03_blue_swap | 8组 / 129项，0失败 |
| 03_multi_hero | 7组 / 159项，0失败 |
| 03_north_13 | 3组 / 209项，0失败 |
| 03_north_14 | 4组 / 351项，0失败 |
| 03_north_15 | 4组 / 483项，0失败 |
| 03_north_16 | 4组 / 209项，0失败 |
| 03_energy_destruction | 3组 / 21项，0失败 |
| 03_north_17 | 4组 / 448项，0失败 |
| 03_north_18 | 4组 / 855项，0失败 |
| 03_north_19 | 5组 / 741项，0失败 |
| 03_north_01 | 6组 / 344项，0失败 |
| 03_north_02 | 5组 / 239项，0失败 |
| 03_north_03 | 3组 / 1084项，0失败 |
| 03_north_04 | 4组 / 430项，0失败 |
| 03_north_05 | 4组 / 124项，0失败 |
| 03_north_06 | 4组 / 410项，0失败 |
| 03_north_07 | 4组 / 867项，0失败 |
| 03_north_08 | 5组 / 384项，0失败 |
| 03_north_09 | 4组 / 82项，0失败 |
| 03_north_10 | 5组 / 344项，0失败 |
| 03_north_11 | 6组 / 754项，0失败 |
| 03_north_12 | 5组 / 223项，0失败 |
| 05_scene_input | 243项，0失败 |
| 05_north_02_scene | 208项，0失败 |
| 05_north_03_scene | 211项，0失败 |
| 05_north_04_scene | 225项，0失败 |
| 05_north_05_scene | 213项，0失败 |
| 05_north_06_scene | 264项，0失败 |
| 05_north_07_scene | 356项，0失败 |
| 05_north_08_scene | 259项，0失败 |
| 05_north_09_scene | 220项，0失败 |
| 05_north_10_scene | 318项，0失败 |
| 05_north_11_scene | 252项，0失败 |
| 05_north_12_scene | 268项，0失败 |
| 05_north_13_scene | 548项，0失败 |
| 05_north_14_scene | 595项，0失败 |
| 05_north_15_scene | 582项，0失败 |
| 05_north_16_scene | 437项，0失败 |
| 05_north_17_scene | 585项，0失败 |
| 05_north_18_scene | 912项，0失败 |
| 05_north_19_scene | 815项，0失败 |
| 05_energy_visibility | 152项，0失败 |
| 06_render | 253项，0失败 |
| 06_render_north_02 | 214项，0失败 |
| 06_render_north_03 | 219项，0失败 |
| 06_render_north_04 | 233项，0失败 |
| 06_render_north_05 | 221项，0失败 |
| 06_render_north_06 | 278项，0失败 |
| 06_render_north_07 | 376项，0失败 |
| 06_render_north_08 | 275项，0失败 |
| 06_render_north_09 | 230项，0失败 |
| 06_render_north_10 | 332项，0失败 |
| 06_render_north_11 | 268项，0失败 |
| 06_render_north_12 | 288项，0失败 |
| 06_render_north_13 | 564项，0失败 |
| 06_render_north_14 | 619项，0失败 |
| 06_render_north_15 | 614项，0失败 |
| 06_render_north_16 | 465项，0失败 |
| 06_render_north_17 | 621项，0失败 |
| 06_render_north_18 | 954项，0失败 |
| 06_render_north_19 | 874项，0失败 |
| 06_energy_visibility | 188项，0失败 |

## 实际渲染与保留文件

实际Godot/X11、GL Compatibility软件渲染，1280×820与960×615。已查看正确起点、蓝色双门/三板和橙色目标，能量消失后的蓝虚线/地纹在当前/非当前绿人及红人占据时仍可辨。像素检查覆盖实体蓝色、空格浅地纹、边框交替虚线；小窗口按实际像素尺度检查线段和间隙，避免固定像素阈值受抗锯齿误判。

原18关地图/解法/MP4/回放72文件及18媒体条目与e445d2aea0e7aa7ddf2c5f21c16f1be3c9cc35af原字节/原值相同，能量显示短片及证据与2ed1f9f相同。18段历史视频完整解码和独立合法回放已通过。

- [all_plates](screenshots/level_19_all_plates.png)
- [compact_blue](screenshots/level_19_compact_blue.png)
- [compact_energy_active](screenshots/level_19_compact_energy_active.png)
- [compact_energy_inactive](screenshots/level_19_compact_energy_inactive.png)
- [compact_green](screenshots/level_19_compact_green.png)
- [compact_red](screenshots/level_19_compact_red.png)
- [completed](screenshots/level_19_completed.png)
- [crystal_handoff](screenshots/level_19_crystal_handoff.png)
- [death_inactive_red](screenshots/level_19_death_inactive_red.png)
- [first_exchange](screenshots/level_19_first_exchange.png)
- [green_energy](screenshots/level_19_green_energy.png)
- [hero_handoff](screenshots/level_19_hero_handoff.png)
- [inactive_green_energy](screenshots/level_19_inactive_green_energy.png)
- [initial](screenshots/level_19_initial.png)
- [middle_crystal](screenshots/level_19_middle_crystal.png)
- [multi_hero_push](screenshots/level_19_multi_hero_push.png)
- [red_energy](screenshots/level_19_red_energy.png)
- [restored_energy](screenshots/level_19_restored_energy.png)
- [revived_red](screenshots/level_19_revived_red.png)
- [second_crystal_swap](screenshots/level_19_second_crystal_swap.png)
- [selected_blue](screenshots/level_19_selected_blue.png)
- [selected_red](screenshots/level_19_selected_red.png)
- [two_goals](screenshots/level_19_two_goals.png)

## 正式第十九关视频状态

实现先提交并正常推送`8e8951bf4411142096cb20d1c8ac244967dd6687`，核对远端后才以Godot `4.6.3.stable.official.7d41c59c4` Movie Maker、普通WASD/C按下释放录制[第十九关](../video/chapter_01/level_19.mp4)。录制后源码、地图、界面和测试未修改。

实际63.2秒/1896帧、1129788字节，H.264 High/yuv420p/1280×820/30fps、fast-start、无音轨。共97输入：63实际方向行动（45普通走、13推、5本方向首目标交换、0拉）及34免费C；最终历史63条。初始绿/蓝占两个目标仍未胜利，结束红(4,0)/绿(9,1)/蓝(6,0)分占三不同目标，唯一紫晶ID0留(1,5)，全程存活且未销毁晶体。没有坐标写入、强制胜利、静态拼接或夹具/死亡侧路混入。

已实际查看编码后0/196/340/664/682/718/898/1006/1060/1168/1384/1420/1492/1744/1798/1895帧、全部五次交换和34次C后的画面，覆盖正确起点、三板/双门联动、晶/英雄接板、红绿过门、保色高亮和明确三目标胜利。消失能量格蓝色虚线/地纹清楚可见。初始及每个输入后98个采样帧均不同；5fps采样316帧中307个不同。初始2秒、每输入0.6秒、胜利3秒。

`python3 tools/check_walkthroughs.py`全部19视频通过：逐方向重新计算首目标、英雄/晶身份、推拉换、全局压力/能量、生死与再现毁晶、计数/选择、目标；同时校验哈希、元数据/帧数/时长/尺寸、fast-start及完整解码。前18份媒体条目原值、72份交付文件原字节，以及能量显示对比短片和证据均保留。新MP4 SHA256：`7c51c48c4d46327616f59ae0c39835c811304d52c6956f5b3d36815330567ab8`。

CI只按可见证据报告；没有验证其他平台、引擎版本、硬件GPU或导出程序。临时AVI/帧/缓存不提交。
