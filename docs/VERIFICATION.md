# 云端玩法、输入与渲染验证

Godot `4.6.3.stable.official.7d41c59c4`。`python3 tools/verify.py --visual --display :97`全部 **168步骤通过**，含75脚本解析、全部24关模型/真实输入/X11渲染、公共规则、虚拟对象池导航与能量显示。云端Xorg dummy/Mesa llvmpipe实际渲染，未测实体设备或所有硬件性能。

首次完整运行在导航测试超时：旧测试对倒数第二关固定按右，而新增目录后该关为23号，右移按正确规则进入哥布林范围死亡，返回被死亡锁阻止。修正测试为执行该关已验证解法的首个实际行动，保留死亡/菜单断言。源码指纹确认仅此测试改变，保留139个无关已通过步骤，重跑该脚本解析和导航、完成剩余检查，未重复成功流程；原失败报告与修正范围保留在云端artifacts。最终完整检查集合全部通过，continuation字段明确标记复用来源。

## 第二十四关：确认修正地图与现有规则

用户最终确认13×11，顶排8–13全部可走；前9排全地面，仅(10..12,9)/(7..12,10)9格界外，共134地面，无内部墙、草丛或栅栏。绿100=(8,7)，晶101=(9,7)，终点1=(0,0)，紫板94=(2,7)，紫能量15=(1,1)，8只goblin在3/32/34/40/68/76/85/121。地图依照已确认文字修正，未重试受阻图片路线，未声称读取原始截图。

独立占用BFS访问2556状态，在首次胜利停止，验证89方向/15次自动单晶拉动、0推/交换/C/毁晶；不作全状态穷尽或最优性声明。70英雄压板开门，71拉晶交接不断压，72拉离紫板恢复实体，76英雄再压/77晶接替永久保持；87英雄通过(1,1)，89到(0,0)胜利。全程8哥布林静止存活，避开29四向危险格。保留绿仅拉最近单晶、无推拉英雄/怪物能力，未改图凑解。

模型828项、实际headless输入452项、X11大小窗口557项通过。逐格143地形/void、29危险、顶排6格修正、八怪身份/存活、初始晶正面不可推、单英雄C不选怪、89步逐步完整Undo与胜利撤销/重开、前23关隔离均检查。合法闭门路线UUULLLLULULL来到(1,2)，上移被实体能量阻挡且不写历史。侧路LL第二步一边拉晶一边进入85哥布林范围死亡；方向/C/R/Esc/返回/API均锁住，Undo复活并恢复水晶/拉动数。该死亡测试不混入正式录像。

## 紫机关、显示适配与组合边界

仅扩展已有mechanism_color枚举与紫色板/实体/消失虚线标记/图例。将同图改为yellow后，初始状态及全部89步快照/结果完全一致；不引入颜色匹配、独立压力组或新玩法。公共移动、怪物、能量结算、输入与对象池实现保持不变。能量重现杀英雄/哥布林、毁晶、完整Undo仍由旧公共模型/独立轨迹夹具覆盖，不在本关正式录像中造不可发生场景。[哥布林说明](MONSTERS.md)。怪物压板与隔栅栏攻击未确认，本关不依赖。

已实际查看1280×820与960×615画面；紫色只用于机关显示，实体亮实心，消失为空地加紫虚线/浅纹样，英雄覆盖仍可认边缘；危险格仅四向锈红，与紫板/绿色终点区分。新增哥布林+机关说明首次布局超18px，已只收紧该组合侧栏间距，保留字号/78px头部/操作入口与旧关布局，并通过全部布局和像素检查。

[初始](screenshots/level_24_initial.png) · [闭门阻挡](screenshots/level_24_closed_gate.png) · [拉晶后死亡](screenshots/level_24_pull_death.png) · [撤销复活](screenshots/level_24_revived.png) · [英雄压板](screenshots/level_24_hero_plate.png) · [晶交接](screenshots/level_24_crystal_handoff.png) · [实体恢复](screenshots/level_24_energy_restored.png) · [撤销恢复开门](screenshots/level_24_restoration_undone.png) · [最终持压](screenshots/level_24_plate_held.png) · [英雄穿能量](screenshots/level_24_open_energy_hero.png) · [小窗覆盖](screenshots/level_24_open_energy_compact.png) · [胜利](screenshots/level_24_completed.png) · [小窗口](screenshots/level_24_compact.png) · [选关](screenshots/level_24_navigation.png)。均实际Godot截图。

## 完整回归与原交付保护

导航所有24真实卡片进入/返回、保留池对象/偏移/选择，1000/5000合成源仅测试；真实池与缩放观测见[JSON记录](verification-summary.json)，不作所有设备性能保证。前23关92份地图/解法/MP4/回放、23原媒体条目及6份导航/能量演示文件保留基线`f21cb9c95c3657b9b4abfed734a1760b32d95b6e`原字节。

| 检查 | 通过项数 |
| --- | ---: |
| 03_logic | 4662，0失败 |
| 03_chain_push | 701，0失败 |
| 03_energy | 83，0失败 |
| 03_global_energy | 168，0失败 |
| 03_bush_group | 95，0失败 |
| 03_green_pull | 4445，0失败 |
| 03_blue_swap | 129，0失败 |
| 03_multi_hero | 159，0失败 |
| 03_north_13 | 209，0失败 |
| 03_north_14 | 351，0失败 |
| 03_north_15 | 483，0失败 |
| 03_north_16 | 209，0失败 |
| 03_energy_destruction | 21，0失败 |
| 03_north_17 | 448，0失败 |
| 03_north_18 | 855，0失败 |
| 03_north_19 | 741，0失败 |
| 03_fences | 199，0失败 |
| 03_north_20 | 251，0失败 |
| 03_north_21 | 1687，0失败 |
| 03_monsters | 126，0失败 |
| 03_north_24 | 828，0失败 |
| 03_north_23 | 328，0失败 |
| 03_north_22 | 163，0失败 |
| 03_north_01 | 344，0失败 |
| 03_north_02 | 239，0失败 |
| 03_north_03 | 1084，0失败 |
| 03_north_04 | 430，0失败 |
| 03_north_05 | 124，0失败 |
| 03_north_06 | 410，0失败 |
| 03_north_07 | 867，0失败 |
| 03_north_08 | 384，0失败 |
| 03_north_09 | 82，0失败 |
| 03_north_10 | 344，0失败 |
| 03_north_11 | 754，0失败 |
| 03_north_12 | 223，0失败 |
| 05_scene_input | 209，0失败 |
| 05_north_02_scene | 170，0失败 |
| 05_north_03_scene | 171，0失败 |
| 05_north_04_scene | 185，0失败 |
| 05_north_05_scene | 173，0失败 |
| 05_north_06_scene | 225，0失败 |
| 05_north_07_scene | 317，0失败 |
| 05_north_08_scene | 220，0失败 |
| 05_north_09_scene | 181，0失败 |
| 05_north_10_scene | 278，0失败 |
| 05_north_11_scene | 212，0失败 |
| 05_north_12_scene | 228，0失败 |
| 05_north_13_scene | 447，0失败 |
| 05_north_14_scene | 492，0失败 |
| 05_north_15_scene | 500，0失败 |
| 05_north_16_scene | 355，0失败 |
| 05_north_17_scene | 503，0失败 |
| 05_north_18_scene | 809，0失败 |
| 05_north_19_scene | 712，0失败 |
| 05_north_20_scene | 296，0失败 |
| 05_north_21_scene | 599，0失败 |
| 05_north_24_scene | 452，0失败 |
| 05_north_23_scene | 262，0失败 |
| 05_north_22_scene | 197，0失败 |
| 05_navigation | 293，0失败 |
| 05_energy_visibility | 132，0失败 |
| 06_render | 219，0失败 |
| 06_render_north_02 | 176，0失败 |
| 06_render_north_03 | 179，0失败 |
| 06_render_north_04 | 193，0失败 |
| 06_render_north_05 | 181，0失败 |
| 06_render_north_06 | 239，0失败 |
| 06_render_north_07 | 337，0失败 |
| 06_render_north_08 | 236，0失败 |
| 06_render_north_09 | 191，0失败 |
| 06_render_north_10 | 292，0失败 |
| 06_render_north_11 | 228，0失败 |
| 06_render_north_12 | 248，0失败 |
| 06_render_north_13 | 463，0失败 |
| 06_render_north_14 | 516，0失败 |
| 06_render_north_15 | 532，0失败 |
| 06_render_north_16 | 383，0失败 |
| 06_render_north_17 | 539，0失败 |
| 06_render_north_18 | 851，0失败 |
| 06_render_north_19 | 771，0失败 |
| 06_render_north_20 | 326，0失败 |
| 06_render_north_21 | 646，0失败 |
| 06_render_north_22 | 241，0失败 |
| 06_render_north_23 | 338，0失败 |
| 06_render_north_24 | 557，0失败 |
| 06_navigation | 305，0失败 |
| 06_energy_visibility | 168，0失败 |

独立Python24关搜索与怪物3种实际模型轨迹复核/3种状态篡改拒绝/3种未知kind拒绝也包含完整步骤。解析同时检查退出码和日志，未只凭退出码宣称通过。

## 录制与交付状态

正式第24关视频尚未录制。先提交验证实现，再以Godot MovieMaker实际视口、普通WASD按下释放，从初始到明确胜利。后续全部24视频完整解码与独立合法回放，单独媒体提交、正常推develop、远端SHA/实际HTTP字节/下载后解码/CI核验。未完成前不声称视频已交付。只云端，无ZIP；实体设备未测。
