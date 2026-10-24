# 云端玩法、输入与渲染验证

Godot `4.6.3.stable.official.7d41c59c4`。`python3 tools/verify.py --visual --display :97` 全部 **162步骤通过**，含73脚本解析、全部23关模型/实际输入/X11渲染、公共规则、虚拟对象池导航与能量显示，无失败。云端Xorg dummy/Mesa llvmpipe实际渲染；未测实体设备或所有硬件性能。

## 第二十三关：全地面与十只哥布林

用户确认11×7全77格地面：红(0,0)1号，绿终点(9,6)76号，10只goblin在3/11/15/30/34/49/56/64/68/74。67=(0,6)是地面，但受到(0,5)/(1,6)两只哥布林威胁。无内部墙、草丛、水晶、压力板、能量、栅栏或新能力。危险地面不等于不可走地形，进入危险即死亡。

独立安全格BFS验证`DRDRDDDRDRRURUULUUURRRDRDDDRDDL`：31次正常方向步行，0推/拉/交换/C，全部十怪静止存活。26个四向危险格含7个重叠格：(0,4)/(0,6)/(1,5)/(2,1)/(3,0)/(7,5)/(8,6)。路线第二步(1,1)为安全斜角，第11步(5,6)穿过下方安全通路，第30步(10,6)从边角接近，第31步到76胜利。没有为求解修改确认地图或规则。

模型328项，真实headless输入262项，X11含大小窗口338项通过。逐格77地形/26危险/7重叠、边界阻挡、十怪ID/类型、完整路线与逐步Undo、通关后Undo/重开、前22关切换隔离均检查。合法侧路DRDR后屏幕Up进入(2,1)双重危险，第5步立即死亡；普通方向/C/R/Esc/返回/切关API均不能绕过，屏幕Undo完整恢复到第4步。该死亡测试不混入正式通关视频。

## 公共规则保持与实际画面

未修改公共core/input/view/场景/虚拟列表实现；仅追加确认JSON、目录入口、测试和录制允许编号。复用goblin明确kind、静止四向击杀，不含斜角；未知未来类型拒绝，不默认哥布林。红隔晶混合链推、蓝换怪、绿只拉晶、能量先杀怪再结算存活怪攻击、死人不攻击和原子Undo仍由原有怪物126项和相关公共回归覆盖。[怪物说明](MONSTERS.md)。哥布林压板/隔栅栏攻击仍未确认，本关不依赖，不擅定用户规则。

1280×820与960×615实际画面已查看，十只尖角哥布林区别红英雄；锈红危险格仅覆盖四向并正确合并重叠，没有斜角误标。小窗口先前3个单侧像素断言因1.3px边框缩放至亚像素而不符；改为检查自身四边、危险至少2边与安全格0边后通过。未改变渲染/玩法以迁就测试。死亡白叉/原因与Undo复活清楚。

[初始](screenshots/level_23_initial.png) · [重叠死亡](screenshots/level_23_overlap_death.png) · [撤销复活](screenshots/level_23_revived.png) · [安全斜角](screenshots/level_23_diagonal_safe.png) · [下方通路](screenshots/level_23_lower_passage.png) · [胜利](screenshots/level_23_completed.png) · [小窗口](screenshots/level_23_compact.png) · [虚拟选关](screenshots/level_23_navigation.png)。均为实际Godot。

## 导航、旧交付保护与完整检查

23个真实目录卡片均可进入/返回，保持池对象/滚动偏移/选择；压力源1000/5000只用于测试，不加虚构正式关。实际对象池观察见[JSON验证](verification-summary.json)，不是所有设备性能保证。保留前22关88份地图/解法/MP4/回放、22原媒体条目和6个导航/能量演示文件原字节，基线`dc5e6dea6031825378191c54c5fdd59f14022ff9`。

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
| 05_north_23_scene | 262，0失败 |
| 05_north_22_scene | 197，0失败 |
| 05_navigation | 286，0失败 |
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
| 06_navigation | 298，0失败 |
| 06_energy_visibility | 168，0失败 |

额外Python独立关卡搜索与3个实际GridState怪物轨迹复核、3种状态篡改拒绝、3种未知类型拒绝均包含在完整步骤里。脚本解析通过的退出码及日志同时检查，未把只看进程退出当解析成功。

## 录制与交付状态

实现先提交并正常推送`1c07a0651f35b80109b3c4424c8bb56c1b98135c`，核对远端后使用Godot MovieMaker实际视口、普通WASD按下释放完成正式录制。源码/地图/规则/录制器在录制后未改。MP4为307754字节、708帧/23.6秒，H.264 High/yuv420p/1280×820/30fps/fast-start，无音轨。

实际查看编码首帧0、末帧707及全部31输入后帧（52+18×事件序号），确认开场哥布林提示、十怪静止存活、26四向危险格含7重叠、左侧/下方/右侧安全绕行、正确起终点及明确胜利。初始+31事件后32采样帧均不同，5fps118采样中102不同；初始2秒、每方向0.6秒、胜利3秒，没有瞬移、强制胜利、静态拼接或死亡夹具混入。

`python3 tools/check_walkthroughs.py`全部23视频完整解码与独立合法回放通过；按原JSON逐输入重新计算哥布林类型/位置/存活/四向威胁及全部旧规则、计数与目标，核对哈希/编码/帧数/时长/fast-start。前22关88份地图/解法/MP4/回放、22原媒体条目及6份UI/能量演示均原字节。

[实际通关MP4](../video/chapter_01/level_23.mp4) · [完整逐输入状态](../video/chapter_01/level_23_replay.json)。SHA256：`38c513a4c680a619392662dabb054dbcbf88cf238a1ba97b39cb1aa7f6bc6b0f`。媒体与证据单独提交、正常推develop；远端SHA/实际HTTP字节与下载后解码、CI按最终交付核验另报，不把本地通过当CI通过。无ZIP，未测实体设备。
