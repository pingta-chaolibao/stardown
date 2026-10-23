# 第一章前十五关 · 云端验证记录

仅在选定云端 `/workspace/stardown` 开发、Git、测试与录制，Godot `4.6.3.stable.official.7d41c59c4`。用户经Git获取工程，无额外ZIP。

## 第十五关确认布局与实现

11×7，最新更正25号(2,2)不可走，47号(2,4)也不可走，全部77格逐项核验，共40地板。蓝=(4,0)，绿=(3,3)，粉晶=(8,0)，蓝紫=(7,6)，目标=(0,2)/(0,4)，两黄板=(4,3)/(10,3)，能量=(2,3)。上平台仅(6,1)通主平台，下通道(5,5)/(6,5)/(6,6)/(7,6)严格保留，未扩路或改视线求解。初始选蓝。

新增独立north_15.json、入口、解法和测试。蓝按本方向首个可见英雄 / 水晶被动交换，否则走一步；绿只自动拉最近相邻水晶，不推、不拉英雄。全局双板AND、双英雄不同目标、免费C和Undo保留当前选择均复用同一核心。只为蓝绿阵容补齐角色说明、交换 / 拉动统计及十五关导航；两尺寸高亮保色、屏幕按钮与真实键盘一致，无新机制或英雄。

前十四关地图 / 解法 / 视频 / 回放56份文件与1efc54d逐字节一致，原十四媒体条目保留。GridState / EnergyRules / HeroRules / SwapRules / LevelData / StepInput六核心脚本与该基线字节相同。

## 独立合法路线

`CURRRUUCRDCRRCURCDCLLCDRURCDDCRRCRCDCRLDDDDRCDLLLLDUCLCUULDLCUULLLULLLCLCRCUCLLDL`：61实际行动+20免费选择，共81输入；11拉7换0推，包含3次英雄互换和两枚水晶。独立四对象身份占用BFS扩展1019474、访问1044508状态，首次存活胜利停止，尚余25034排队；不宣称穷举或最优。

行动7蓝人优先交换近绿人而非远粉晶，11再次英雄交换，12粉晶交换至上通道，13绿单拉粉晶下行；24先交换近粉晶而非远绿人，32交换底部蓝紫晶；45绿与粉晶压满板。52蓝过能量，55绿拉蓝紫晶接替近板，56蓝绿隔透明能量互换，57绿到上目标，58蓝再过能量，61蓝到下目标，最终粉 / 蓝紫晶占(10,3)/(4,3)。非当前英雄不发动能力，C不记行动 / 撤销；完整61步Undo保持最终蓝选择并恢复世界，重开恢复初始蓝。

## 本关合法死亡与撤销

走至实际行动52蓝位于开放能量格，C选绿再向下离板，能量恢复压死未选中蓝。模型和实际键鼠均验证C / 方向 / R / 切关无法绕过，唯一次Undo恢复全体对象 / 压力 / 生死 / 门且保留绿选择；再次Undo撤蓝刚才真实移动而非C。此处使用本关合法前缀与侧路，没有伪造测试夹具或混入正式录像。另验证25墙、关闭能量挡视线 / 移动、离板再撤销恢复、空历史C后Undo、胜利Undo / 重开和跨关隔离。

## 完整检查

`python3 tools/verify.py --visual --display :97`：103步全部通过，含47脚本解析、全部角色 / 机关 / 多英雄专项、十五关模型 / 真实键鼠 / X11渲染。录制脚本范围扩至15并另解析。十五段视频完整解码和独立合法回放通过。详情见结构化摘要。

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
| 05_scene_input | 229项，0失败 |
| 05_north_02_scene | 194项，0失败 |
| 05_north_03_scene | 197项，0失败 |
| 05_north_04_scene | 211项，0失败 |
| 05_north_05_scene | 199项，0失败 |
| 05_north_06_scene | 250项，0失败 |
| 05_north_07_scene | 342项，0失败 |
| 05_north_08_scene | 245项，0失败 |
| 05_north_09_scene | 206项，0失败 |
| 05_north_10_scene | 304项，0失败 |
| 05_north_11_scene | 238项，0失败 |
| 05_north_12_scene | 254项，0失败 |
| 05_north_13_scene | 513项，0失败 |
| 05_north_14_scene | 560项，0失败 |
| 05_north_15_scene | 554项，0失败 |
| 06_render | 239项，0失败 |
| 06_render_north_02 | 200项，0失败 |
| 06_render_north_03 | 205项，0失败 |
| 06_render_north_04 | 219项，0失败 |
| 06_render_north_05 | 207项，0失败 |
| 06_render_north_06 | 264项，0失败 |
| 06_render_north_07 | 362项，0失败 |
| 06_render_north_08 | 261项，0失败 |
| 06_render_north_09 | 216项，0失败 |
| 06_render_north_10 | 318项，0失败 |
| 06_render_north_11 | 254项，0失败 |
| 06_render_north_12 | 274项，0失败 |
| 06_render_north_13 | 529项，0失败 |
| 06_render_north_14 | 584项，0失败 |
| 06_render_north_15 | 586项，0失败 |

## 实际画面与正式通关视频

实际查看初始、960×615绿选中及能量恢复压死未选中蓝的侧路画面，角色本色 / 当前描边脚圈、粉 / 蓝紫晶、双板单门、25/47墙与窄通路均核对。X11 :97 / Mesa llvmpipe / GL Compatibility，两窗口1280×820和960×615全部入口与统计适配；旧十四关截图保留。

- [初始](screenshots/level_15_initial.png)
- [绿选中](screenshots/level_15_selected_green.png)
- [首次英雄交换](screenshots/level_15_first_hero_exchange.png)
- [粉晶单拉](screenshots/level_15_pink_pull.png)
- [近水晶优先](screenshots/level_15_nearest_crystal.png)
- [底部水晶](screenshots/level_15_lower_crystal.png)
- [双板开放](screenshots/level_15_all_plates.png)
- [蓝过门](screenshots/level_15_blue_gate.png)
- [紫晶接替](screenshots/level_15_crystal_handoff.png)
- [隔门英雄互换](screenshots/level_15_gate_hero_exchange.png)
- [首目标](screenshots/level_15_first_goal.png)
- [双英雄胜利](screenshots/level_15_completed.png)
- [实际侧路死亡](screenshots/level_15_death_inactive_blue.png)
- [撤销复活](screenshots/level_15_revived_blue.png)
- [小窗口蓝](screenshots/level_15_compact_blue.png)
- [小窗口绿](screenshots/level_15_compact_green.png)

实现先提交并推送于 `4fa7ea61c8beba80269ab4db9c0bf33ccb43a362`，核对远端后才用Godot Movie Maker实际视口、正常WASD/C按下释放录制。录制后源码 / 关卡 / 界面 / 测试未再更改。MP4为903187字节、53.6秒 / 1608帧，1280×820、30fps、H.264 High、yuv420p、fast-start、无音轨。

包含全部81输入：61实际行动（43普通走、11自动单拉、7自动交换）和20免费选择；最终历史61条。编码后0 / 70 / 214 / 376 / 664 / 844 / 1132 / 1276 / 1348 / 1384 / 1420 / 1607帧已实际查看，七次交换结果及二十次C之后画面也逐一查看，确认初始蓝、免费C、窄通路 / 25与47墙、双晶 / 三次英雄互换、双板 / 能量 / 接替与双目标。初始及每次输入后82个采样画面均不同，5fps另采样257个不同画面；初始停留2秒，每输入0.6秒，胜利3秒。

十五段视频完整解码、哈希、元数据 / 帧数 / 时长 / fast-start及独立合法回放通过。独立Python逐事件重算两英雄 / 选中 / 双晶身份、首目标交换 / 单晶拉动、压力 / 能量 / 生死、实际行动 / 控制选择和双目标；C不计数不写历史。原十四份媒体 / 回放 / 条目保留，推送后另实际下载核对字节与完整解码。死亡 / 复活图片是本关合法侧路验证，不混入正式通关录像。临时日志 / 帧 / 原始AVI / 缓存不提交；未验证其他平台、引擎、硬件GPU或导出程序。屏障恢复遇水晶仍是既有未定义边界，保护保留且通关不用该交互，不宣称全状态空间无此边界。CI仅按远端可见证据报告。
