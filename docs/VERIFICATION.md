# 云端玩法、输入与渲染验证

Godot `4.6.3.stable.official.7d41c59c4`。`python3 tools/verify.py --visual --display :97` 全部 **147步骤通过**，含67脚本解析，全部21关模型、实际输入、X11逐关渲染、虚拟选关和能量显示均0失败。本轮图形环境为Xorg dummy/Mesa llvmpipe；未测试实体手机或所有硬件性能。

## 第二十一关与六黄板

确认13×9地形含68地板、三英雄、六水晶、六黄板、三能量与三个普通绿色目标。用户明确无栅栏；底部97/98/110/111/112可走，111/112有水晶。没有新规则。公共core/input/board/虚拟列表源码与1f50ad2逐字节相同，只新增地图/路线/测试、目录追加与录制范围。

独立构造配合纯走局部BFS（250个局部搜索状态）验证119行动+21免费C、10推8拉10交换。不是全状态穷举，不宣称最优。26首次六板全占、27蓝隔右门换晶接板、63晶接左板、84安全松板/85复开、105六晶占满全部板，119红(6,5)/绿(5,5)/蓝(7,5)三终点胜利。正式路线均存活、六晶无毁坏。模型1687项、无头真实输入599项、X11渲染646项均通过。

64种六板子集仅全占开全部门；英雄/晶体混合占板及三门同步验证。合法前缀43后红离板，能量再现杀死非当前蓝人，C/方向/重开/切关/Back/Esc均不能绕过，只Undo复活并保留当前红选择。合法前缀101后蓝离板，能量再现摧毁中央格晶ID5，一次Undo恢复身份/六板/三开门。独立同地图机关夹具验证一次恢复能量摧毁三晶及同次Undo，夹具不混入正式录像。最初小窗口测试辅助漏C事件已修正，针对复核及本轮完整套件均通过。

## 导航、表现与保护

21关全部从真实虚拟卡片进入/返回，菜单/卡片对象、偏移和选择保持，死亡锁不变；20的两道边栅栏不会泄漏到21。导航无头274项、X11 286项通过。1000/5000合成数据仍为10卡片/11列表子树节点；360/480宽7张、1550宽11张，扩缩容累计创建17张、156次提供器绑定。计时含事件等待，不是设备性能保证。历史导航演示保留594e349的19关流程。

1280×820/960×615窗口三色英雄高亮/非当前保色、全117格、六板占用数、实心及消失能量标记实际查看。正常/小窗口能量格空置、英雄或晶体占据时，边缘虚线仍经像素测试；无界面溢出。旧20关地图/解法/MP4/回放80文件和20媒体条目、6个导航/能量演示文件均与1f50ad2保持原样。

## 完整检查

| 检查 | 结果 |
| --- | --- |
| 03_logic | 4662项，0失败 |
| 03_chain_push | 701项，0失败 |
| 03_energy | 83项，0失败 |
| 03_global_energy | 168项，0失败 |
| 03_bush_group | 95项，0失败 |
| 03_green_pull | 4445项，0失败 |
| 03_blue_swap | 129项，0失败 |
| 03_multi_hero | 159项，0失败 |
| 03_north_13 | 209项，0失败 |
| 03_north_14 | 351项，0失败 |
| 03_north_15 | 483项，0失败 |
| 03_north_16 | 209项，0失败 |
| 03_energy_destruction | 21项，0失败 |
| 03_north_17 | 448项，0失败 |
| 03_north_18 | 855项，0失败 |
| 03_north_19 | 741项，0失败 |
| 03_fences | 199项，0失败 |
| 03_north_20 | 251项，0失败 |
| 03_north_21 | 1687项，0失败 |
| 03_north_01 | 344项，0失败 |
| 03_north_02 | 239项，0失败 |
| 03_north_03 | 1084项，0失败 |
| 03_north_04 | 430项，0失败 |
| 03_north_05 | 124项，0失败 |
| 03_north_06 | 410项，0失败 |
| 03_north_07 | 867项，0失败 |
| 03_north_08 | 384项，0失败 |
| 03_north_09 | 82项，0失败 |
| 03_north_10 | 344项，0失败 |
| 03_north_11 | 754项，0失败 |
| 03_north_12 | 223项，0失败 |
| 04_main_scene | 通过 |
| 05_scene_input | 209项，0失败 |
| 05_north_02_scene | 170项，0失败 |
| 05_north_03_scene | 171项，0失败 |
| 05_north_04_scene | 185项，0失败 |
| 05_north_05_scene | 173项，0失败 |
| 05_north_06_scene | 225项，0失败 |
| 05_north_07_scene | 317项，0失败 |
| 05_north_08_scene | 220项，0失败 |
| 05_north_09_scene | 181项，0失败 |
| 05_north_10_scene | 278项，0失败 |
| 05_north_11_scene | 212项，0失败 |
| 05_north_12_scene | 228项，0失败 |
| 05_north_13_scene | 447项，0失败 |
| 05_north_14_scene | 492项，0失败 |
| 05_north_15_scene | 500项，0失败 |
| 05_north_16_scene | 355项，0失败 |
| 05_north_17_scene | 503项，0失败 |
| 05_north_18_scene | 809项，0失败 |
| 05_north_19_scene | 712项，0失败 |
| 05_north_20_scene | 296项，0失败 |
| 05_north_21_scene | 599项，0失败 |
| 05_navigation | 274项，0失败 |
| 05_energy_visibility | 132项，0失败 |
| 06_render | 219项，0失败 |
| 06_render_north_02 | 176项，0失败 |
| 06_render_north_03 | 179项，0失败 |
| 06_render_north_04 | 193项，0失败 |
| 06_render_north_05 | 181项，0失败 |
| 06_render_north_06 | 239项，0失败 |
| 06_render_north_07 | 337项，0失败 |
| 06_render_north_08 | 236项，0失败 |
| 06_render_north_09 | 191项，0失败 |
| 06_render_north_10 | 292项，0失败 |
| 06_render_north_11 | 228项，0失败 |
| 06_render_north_12 | 248项，0失败 |
| 06_render_north_13 | 463项，0失败 |
| 06_render_north_14 | 516项，0失败 |
| 06_render_north_15 | 532项，0失败 |
| 06_render_north_16 | 383项，0失败 |
| 06_render_north_17 | 539项，0失败 |
| 06_render_north_18 | 851项，0失败 |
| 06_render_north_19 | 771项，0失败 |
| 06_render_north_20 | 326项，0失败 |
| 06_render_north_21 | 646项，0失败 |
| 06_navigation | 286项，0失败 |
| 06_energy_visibility | 168项，0失败 |

## 实际画面

[初始](screenshots/level_21_initial.png) · [六板压满](screenshots/level_21_all_six_plates.png) · [右门晶接板](screenshots/level_21_right_crystal_handoff.png) · [蓝过能量](screenshots/level_21_blue_crossing.png) · [安全再现](screenshots/level_21_safe_restoration.png) · [六晶占板](screenshots/level_21_six_crystal_plates.png) · [三英雄胜利](screenshots/level_21_completed.png) · [小窗口消失格有英雄](screenshots/level_21_compact_occupied_energy.png)。[21关虚拟选关](screenshots/level_21_navigation.png)。死亡与毁晶支路为独立测试截图，非正式通关视频。

## 录制与交付状态

实现先提交并正常推送 `c48e84313f7b997e75f412cc697bfe5b55409e8a`，核对远端后才用Godot MovieMaker实际视口及普通WASD/C按下释放录制；录制后源码/地图/录制器未改。第21关MP4为1372739字节、2670帧/89秒，H.264 High/yuv420p/1280×820/30fps/fast-start，无音轨。完整解码和元数据/哈希检查通过；实际查看首帧0、末帧2669、58个选定状态（含初始），覆盖全部21次C、10推8拉10交换、六板接替和三门开闭/过门/明确胜利。初始+140输入后141帧均不同，5fps采445帧中436不同。

`python3 tools/check_walkthroughs.py` 全部21视频完整解码与独立合法回放通过：逐事件重新计算身份/方向首目标/推拉换/占位/六板三门/生死毁晶/实际计数和目标，另核对帧数、时长、尺寸、格式和fast-start。前20关80份地图/解法/MP4/回放、20媒体条目和6份UI/能量演示文件与1f50ad2原样。正式录像没有状态编辑、强制胜利、静态拼接或死亡/毁晶夹具支路。

[实际通关视频](../video/chapter_01/level_21.mp4) · [140输入完整状态](../video/chapter_01/level_21_replay.json)；SHA256 `b62ade42dd975b6e4cbc1e0432adb1de7696c8dfa8fcb94b00ed33c6312dd222`。视频/验证另行提交并正常推develop，交付无需ZIP。最终远端、HTTP下载与CI按实际可见证据另报；本地通过不等于CI运行。
