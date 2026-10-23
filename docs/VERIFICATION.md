# 第一章前十六关 · 云端验证记录

仅在选定云端 `/workspace/stardown` 开发、测试与录制。Godot `4.6.3.stable.official.7d41c59c4`；用户通过Git获取工程，无额外ZIP。

## 第十六关确认地图与实现

11×3，全部33格逐项核验，23地板；红=(5,1)，蓝=(5,2)，初始选蓝；唯一粉紫晶=(10,1)，黄板=(1,1)，能量=(7,1)，紫色普通圆盘目标=(9,0)/(9,2)。第三排完整，33号(10,2)保持不可走。紫色是终点显示，不传送、不增加机制；绿色/紫色目标换色对照的整条路线状态一致。

新增north_16.json、独立解法、入口和专项。复用红推英雄/水晶混合整列、蓝输入方向首可见英雄/水晶被动交换、全局压力/死亡、免费C/Undo保留选择、双英雄不同目标。仅扩展LevelData的exit_color枚举及普通目标绘制；五个游戏规则/输入核心与f3caa746逐字节相同。16个导航按钮改为每行8个的两行，保持可读标题。

前十五关地图、解法、MP4、回放共60份文件与f3caa746逐字节一致，原十五媒体条目保留。

## 独立合法路线与侧路验证

`ULLLLRCURRRRCLUCLD`：15次实际行动+3次免费C，共18输入，3交换/0推拉。独立三对象身份占用BFS扩展2298、访问2757状态，首次存活胜利停止，余459排队；不宣称穷举或最优。行动1蓝/红互换，5蓝踩板，6与粉紫晶交换并由晶接替压力，9红过门，12蓝优先交换近红人，13蓝正常走到上紫目标，15红到下目标双胜利。C不改变世界或行动/历史长度；15次逆向Undo保持当前红选择并恢复全部世界，重开恢复初始蓝。

合法侧路`ULLLLRCURRRRCLLCLLLLLLLL`共21实际行动/3免费C/8推/4换，含红推动蓝人与水晶的混合列；再次左推遇界外时整次不动、无计数/历史，一次Undo恢复整列及压力。另测红推动蓝到上格、蓝被动移位不发动交换、闭门/视线/边界与方向重复输入。

合法正式前缀9行动后`CLLCLLLC`让红留在开放能量格、蓝留在压板，晶已移出能量格；蓝向下离板恢复能量压死未选中红。方向/C/R/切关不能绕过，一次Undo恢复所有位置、压力、生死且保持蓝选择。该侧路不混入正式视频。既有屏障恢复遇水晶仍未定义，保护保留；未增破坏规则，不宣称全状态空间没有未定义转移。

## 完整检查

`python3 tools/verify.py --visual --display :97`：108步骤全部通过，含49脚本解析、全部模型/真实输入与十六关X11渲染。全部十六视频完整解码与独立合法回放通过。录制工具支持1–16，另行解析。

| 检查 | 结果 |
| --- | --- |
| 03_logic | 13组 / 4662项，0失败 |
| 03_chain_push | 6组 / 701项，0失败 |
| 03_energy | 9组 / 83项，0失败 |
| 03_global_energy | 6组 / 168项，0失败 |
| 03_bush_group | 8组 / 95项，0失败 |
| 03_green_pull | 8组 / 4444项，0失败 |
| 03_blue_swap | 8组 / 129项，0失败 |
| 03_multi_hero | 7组 / 159项，0失败 |
| 03_north_13 | 3组 / 209项，0失败 |
| 03_north_14 | 4组 / 351项，0失败 |
| 03_north_15 | 4组 / 483项，0失败 |
| 03_north_16 | 4组 / 209项，0失败 |
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
| 05_scene_input | 237项，0失败 |
| 05_north_02_scene | 202项，0失败 |
| 05_north_03_scene | 205项，0失败 |
| 05_north_04_scene | 219项，0失败 |
| 05_north_05_scene | 207项，0失败 |
| 05_north_06_scene | 258项，0失败 |
| 05_north_07_scene | 350项，0失败 |
| 05_north_08_scene | 253项，0失败 |
| 05_north_09_scene | 214项，0失败 |
| 05_north_10_scene | 312项，0失败 |
| 05_north_11_scene | 246项，0失败 |
| 05_north_12_scene | 262项，0失败 |
| 05_north_13_scene | 533项，0失败 |
| 05_north_14_scene | 580项，0失败 |
| 05_north_15_scene | 570项，0失败 |
| 05_north_16_scene | 425项，0失败 |
| 06_render | 247项，0失败 |
| 06_render_north_02 | 208项，0失败 |
| 06_render_north_03 | 213项，0失败 |
| 06_render_north_04 | 227项，0失败 |
| 06_render_north_05 | 215项，0失败 |
| 06_render_north_06 | 272项，0失败 |
| 06_render_north_07 | 370项，0失败 |
| 06_render_north_08 | 269项，0失败 |
| 06_render_north_09 | 224项，0失败 |
| 06_render_north_10 | 326项，0失败 |
| 06_render_north_11 | 262项，0失败 |
| 06_render_north_12 | 282项，0失败 |
| 06_render_north_13 | 549项，0失败 |
| 06_render_north_14 | 604项，0失败 |
| 06_render_north_15 | 602项，0失败 |
| 06_render_north_16 | 453项，0失败 |

## 实际画面

实际查看1280×820初始、960×615红选中、合法混合推和未选中红死亡画面，核对紫色双目标、33墙、粉紫晶、单板门、当前描边/脚圈与非当前保色。X11 :97 / Mesa llvmpipe / GL Compatibility，两种窗口的真实键盘/鼠标/屏幕切换与全部导航适配。原十五关截图保留。

- [blue_plate](screenshots/level_16_blue_plate.png)
- [compact_blue](screenshots/level_16_compact_blue.png)
- [compact_red](screenshots/level_16_compact_red.png)
- [completed](screenshots/level_16_completed.png)
- [crystal_handoff](screenshots/level_16_crystal_handoff.png)
- [death_inactive_red](screenshots/level_16_death_inactive_red.png)
- [first_goal](screenshots/level_16_first_goal.png)
- [first_hero_exchange](screenshots/level_16_first_hero_exchange.png)
- [initial](screenshots/level_16_initial.png)
- [mixed_push](screenshots/level_16_mixed_push.png)
- [near_hero_exchange](screenshots/level_16_near_hero_exchange.png)
- [red_gate](screenshots/level_16_red_gate.png)
- [revived_red](screenshots/level_16_revived_red.png)
- [selected_red](screenshots/level_16_selected_red.png)

## 视频交付状态

实现先提交并推送于 `f86a27452145b7cd7926f93290a7be4cdff138bf`，远端核对后才开始Godot Movie Maker录制。实际WASD/C按下释放，18输入包含15实际行动、3免费选择、3交换/0推拉；12普通走，最终历史15。录制后源码 / 关卡 / 测试 / 界面未变。

MP4为234029字节、15.8秒 / 474帧，H.264 High、yuv420p、1280×820、30fps、fast-start、无音轨。实际查看编码后0/70/142/160/178/232/286/304/322/340/376/473帧，核对初始、全部交换和C、晶压板接替、红过门、两紫目标正常走入与双胜利；没有传送机制。初始/每次输入后19帧状态均不同，5fps采样68个不同画面；初始2秒、每输入0.6秒、胜利3秒。

十六段视频完整解码、哈希 / 元数据 / 帧数 / 时长 / fast-start和独立合法回放通过。独立逐事件重算两英雄、选中、水晶身份、方向首目标、压力 / 能量 / 生死、15行动与3选择及双目标。C不计行动和历史。原十五媒体 / 回放 / 清单条目保留；合法推列和死亡支路只作测试，不混入正式视频。推送后另实际下载验证字节和完整解码。

临时日志、帧、原始AVI和缓存不提交。未验证其他平台、引擎、硬件GPU或导出程序；CI仅按远端可见证据报告。
