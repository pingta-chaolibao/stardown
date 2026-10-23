# 第一章前十七关 · 云端验证记录

Godot `4.6.3.stable.official.7d41c59c4`，仅选定云端 `/workspace/stardown`。Git develop交付，用户不需要ZIP。

## 确认地图与统一底层机制

9×5全部45格核验，30地板；32=(4,3)地板，23=(4,2)/41=(4,4)不可走，所有墙/绿篱仍挡移动与视线。绿(0,4)、蓝(2,4)、红(8,4)，初始蓝；4晶(0,0)/(8,0)/(8,3)/(6,4)，3目标(3,0)/(4,0)/(2,2)，板(3,3)/(5,3)，能量(0,2)/(8,2)。没有为解法开墙、透明障碍或新增通路。

用户最新确认的全局底层规则：能量消失时可放晶，再现时杀死格内英雄/怪物、摧毁格内水晶。公共EnergyRules返回剩余水晶与生死，GridState原子提交；只在消失→实体的边沿摧毁，不在持续消失/激活或初始化任意销毁。多个能量块同时结算，Undo恢复被毁晶ID/颜色、全体英雄生死和板门，保留当前选择。板/门不重叠，所以删除能量格水晶不影响板占用。怪物只有killed类别语义声明，当前没有怪物玩法/生命周期测试。

原42状态外围诊断没有晶体删除状态，把门永久开会取消销毁能力，因此并非有效无解证明；不再质疑已确认布局。先前临时只读透明障碍假设未被采纳、未进入实现。

## 合法路线与原子撤销

`URRRRDLULLRULDCUCUUUDDCUDCCUUURRRRRRRLCCUUUCLLLLLLDCCLLLLLLLCDDCUDCRRRCUUURRRCLUL`：66实际行动+15免费C=81输入，2推11拉3换。构造后独立按所有英雄/晶ID与能量再现删除逐步验证，不宣称最优或穷举。14蓝/内晶压满双板，20左右晶留在消失能量格，21离板同时销毁ID0/2；绿上顶排拉右上晶向左，红推到(0,0)，绿拉入左能量，53离板销毁ID1。57红到(4,0)，63绿到(3,0)，66蓝到(2,2)，唯一剩晶ID3在(5,3)。

模型/真实输入在两次销毁后额外C再Undo，验证恢复所有被毁晶和压力且保持新选择，再合法重做得到同一世界。全部66次逆向Undo恢复初始4晶/3英雄，重开初始蓝；3英雄不同目标、非当前不触发能力、C不计操作/历史、按键回声去重、屏幕按钮和切关隔离均覆盖。

合法死亡支路：正式前缀15后让绿走UU到左开放能量，再选蓝上移离板；同次恢复杀死未选中绿、摧毁右晶2。C/方向/R/切关锁定，单次Undo复活绿并恢复右晶、全部压力/能量且保留蓝。该支路只作专项验证，不混入正式通关视频。独立夹具另覆盖三门同时恢复、两晶毁灭+另一英雄死亡、跨数据组AND和初始/持续状态不误销毁。

## 完整检查

`python3 tools/verify.py --visual --display :97`：115步骤全部通过，含52脚本解析、全部共享规则与十七关模型/实际键鼠/X11渲染。录制器另解析，支持1–17；旧16段视频已用新底层完整解码和独立合法回放。

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
| 05_scene_input | 239项，0失败 |
| 05_north_02_scene | 204项，0失败 |
| 05_north_03_scene | 207项，0失败 |
| 05_north_04_scene | 221项，0失败 |
| 05_north_05_scene | 209项，0失败 |
| 05_north_06_scene | 260项，0失败 |
| 05_north_07_scene | 352项，0失败 |
| 05_north_08_scene | 255项，0失败 |
| 05_north_09_scene | 216项，0失败 |
| 05_north_10_scene | 314项，0失败 |
| 05_north_11_scene | 248项，0失败 |
| 05_north_12_scene | 264项，0失败 |
| 05_north_13_scene | 538项，0失败 |
| 05_north_14_scene | 585项，0失败 |
| 05_north_15_scene | 574项，0失败 |
| 05_north_16_scene | 429项，0失败 |
| 05_north_17_scene | 577项，0失败 |
| 06_render | 249项，0失败 |
| 06_render_north_02 | 210项，0失败 |
| 06_render_north_03 | 215项，0失败 |
| 06_render_north_04 | 229项，0失败 |
| 06_render_north_05 | 217项，0失败 |
| 06_render_north_06 | 274项，0失败 |
| 06_render_north_07 | 372项，0失败 |
| 06_render_north_08 | 271项，0失败 |
| 06_render_north_09 | 226项，0失败 |
| 06_render_north_10 | 328项，0失败 |
| 06_render_north_11 | 264项，0失败 |
| 06_render_north_12 | 284项，0失败 |
| 06_render_north_13 | 554项，0失败 |
| 06_render_north_14 | 609项，0失败 |
| 06_render_north_15 | 606项，0失败 |
| 06_render_north_16 | 457项，0失败 |
| 06_render_north_17 | 613项，0失败 |

## 实际画面与保留文件

实际查看960×615绿选中及第一次再现销毁两晶画面：三英雄保色/当前脚圈描边、四统计、17导航两行9+8、2板2能量、目标和不可走装饰位置均核对。两尺寸1280×820/960×615无溢出，X11 :97 / Mesa llvmpipe / GL Compatibility。前16关地图/解法/视频/回放64份文件与7f03ee639eadfc5ac74ac35721bae54b809cd2cb逐字节相同，旧16媒体清单条目保留。

- [all_plates](screenshots/level_17_all_plates.png)
- [compact_blue](screenshots/level_17_compact_blue.png)
- [compact_green](screenshots/level_17_compact_green.png)
- [compact_red](screenshots/level_17_compact_red.png)
- [completed](screenshots/level_17_completed.png)
- [crystals_on_energy](screenshots/level_17_crystals_on_energy.png)
- [death_and_destruction](screenshots/level_17_death_and_destruction.png)
- [first_destruction](screenshots/level_17_first_destruction.png)
- [first_goal](screenshots/level_17_first_goal.png)
- [green_escape](screenshots/level_17_green_escape.png)
- [initial](screenshots/level_17_initial.png)
- [revived_and_restored](screenshots/level_17_revived_and_restored.png)
- [second_crystal_on_energy](screenshots/level_17_second_crystal_on_energy.png)
- [second_destruction](screenshots/level_17_second_destruction.png)
- [selected_green](screenshots/level_17_selected_green.png)
- [selected_red](screenshots/level_17_selected_red.png)
- [top_crystal_pull](screenshots/level_17_top_crystal_pull.png)
- [two_goals](screenshots/level_17_two_goals.png)

## 视频交付状态

实现验证完成，须先提交实现后用实际Godot视口和合法WASD/C初始至三英雄胜利录制。本实现提交不声称第17关正式视频已完成。

临时日志/原始AVI/编码帧/缓存不提交。没有验证其他平台、引擎、硬件GPU或导出程序；CI仅按可见证据报告。
