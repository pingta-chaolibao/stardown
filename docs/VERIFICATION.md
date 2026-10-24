# 云端界面与玩法回归验证

Godot `4.6.3.stable.official.7d41c59c4`。`python3 tools/verify.py --visual --display :97`全部134步骤通过，61脚本解析；所有既有19关模型、真实输入与X11渲染继续验证。新导航无头262项、真实渲染274项。

## 本次入口与导航重构

默认启动独立选关主界面，卡片横向浏览进入真实关卡，关卡内Back/Esc返回。菜单与对象池常驻，不重建全关卡按钮。虚拟范围为数字，数据提供器与节点数量分离；视口拥有逻辑焦点，卡片只是无子节点的程序绘制预览。没有锁关、虚构完成/星数/奖励，也不将压力测试数据加入真实19关。

同一对象池经历全部19关进入/返回，偏移与选择保留。鼠标拖动/滚轮、触摸横滑/取消、键盘首尾/翻页/进入、窗口缩放与回收重绑后点击都经实际事件验证。合法19关死亡侧路验证Back/Esc/API不能绕过死亡，Undo恢复原状态后才允许返回。菜单键盘不会操作隐藏游戏。

## 节点与性能观察

宽1180的列表，1000与5000项均为10张卡片，整个列表子树11节点（含列表本身），切换数据规模不分配新卡片。360/480宽为7张，1550宽为11张；压力场景含扩缩容累计创建17张，快速首中尾跳转复用既有对象。数据提供器总156次绑定调用，没有逐关实例化或隐藏5000个按钮。

本云端X11/Mesa llvmpipe软件渲染观测；压力场景计时包括输入/等待/渲染，非帧率基准或所有设备性能保证。触摸使用实际Godot触摸事件注入，未测试实体手机硬件。架构/详细结果见[NAVIGATION.md](NAVIGATION.md)。

## 完整检查

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
| 05_navigation | 262项，0失败 |
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
| 06_navigation | 274项，0失败 |
| 06_energy_visibility | 168项，0失败 |

## 实际截图

- [navigation_1600x820](screenshots/navigation_1600x820.png)
- [navigation_960x615](screenshots/navigation_960x615.png)
- [navigation_death_locked](screenshots/navigation_death_locked.png)
- [navigation_in_level](screenshots/navigation_in_level.png)
- [navigation_last](screenshots/navigation_last.png)
- [navigation_main](screenshots/navigation_main.png)

## 文件保护与演示

所有core/input/board脚本、19关地图/解法/MP4/回放76文件、章节媒体清单以及能量显示短片/证据与94e007f保持原字节。19段完整解码/独立合法回放通过，能量短片34输入回放通过。旧能量块像素比较继续通过，游戏头部保持78px。

先提交本次已验证实现，再使用实际MovieMaker输入录制独立UI演示。此实现提交不声称正式UI视频已完成；不替换任何历史关卡视频。CI另按远端可见证据报告。
