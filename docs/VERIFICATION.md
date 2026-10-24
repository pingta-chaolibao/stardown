# 第28关验证记录

Godot `4.6.3.stable.official.7d41c59c4`，选定云端 `/workspace/stardown`，X11/Mesa llvmpipe真实软件渲染。最终矩阵201阶段通过：118项新执行、83项Git基线与历史通过结果均核对的源码不变语法解析复用。[复用指纹与范围](verification/north_28_scope.json)。全部模型、独立路线、28关实际输入/X11大小窗口、导航和能量显示都重新执行；没有复用玩法或画面结果。所有公共core/view/input源码与基线完全相同，没有新机制。

## 用户确认地图与实际解法

7×7、40地板/9阻挡，1绿英雄、9水晶、36目标；3/30/31火龙向下，19火龙向右。7号明确可走，43岩石阻挡；花纹格普通地板，右列/底行完整，未修改确认地形。无哥布林/草丛/机关/栅栏。

独立构造49方向/17次自动单拉（7龙/10晶），实际GridState逐步对照与真实键鼠/屏幕输入通关；四龙均存活且朝向保持，水晶身份保留，不声称最短。2步拉3号龙左移；16步拉19号龙上移，水晶(5,1)挡火；30–32步拉31号龙向右，水晶(5,5)遮挡下方；38/39水晶左移至(3,5)，41/42拉30号龙至(3,4)，水晶挡火后从下方绕行到目标。水晶不被火焰摧毁，完整49步Undo和重开恢复所有位置/方向/计数/生命。

## 输入与画面

长按/echo/重复方向不额外行动；C不计数不触发攻击。真实屏幕按钮执行拉龙/Undo/重开。独立侧路DDRR进入3号龙向下火线死亡；C/R/菜单/加载不能绕过，仅Undo复活。所有动作的英雄、水晶、四龙身份/位置/朝向/生命、17次拉动的类别与计数对照独立模型。7号上角与43岩石、三处关键水晶屏障的实际安全格查询均验证。1280×820、960×615实际图像已查看。

[初始](screenshots/level_28_initial.png) · [19号挡火](screenshots/level_28_action_16.png) · [31号挡火](screenshots/level_28_action_32.png) · [30号挡火](screenshots/level_28_action_42.png) · [通关](screenshots/level_28_completed.png) · [小窗口](screenshots/level_28_compact.png)。

| 检查 | 断言项数 | 范围 |
| --- | ---: | --- |
| 03_logic | 4662 | 新执行通过 |
| 03_chain_push | 701 | 新执行通过 |
| 03_energy | 83 | 新执行通过 |
| 03_global_energy | 168 | 新执行通过 |
| 03_bush_group | 95 | 新执行通过 |
| 03_green_pull | 4445 | 新执行通过 |
| 03_blue_swap | 129 | 新执行通过 |
| 03_multi_hero | 159 | 新执行通过 |
| 03_north_13 | 209 | 新执行通过 |
| 03_north_14 | 351 | 新执行通过 |
| 03_north_15 | 483 | 新执行通过 |
| 03_north_16 | 209 | 新执行通过 |
| 03_energy_destruction | 21 | 新执行通过 |
| 03_north_17 | 448 | 新执行通过 |
| 03_north_18 | 855 | 新执行通过 |
| 03_north_19 | 741 | 新执行通过 |
| 03_fences | 199 | 新执行通过 |
| 03_north_20 | 251 | 新执行通过 |
| 03_north_21 | 1687 | 新执行通过 |
| 03_north_28_independent | 独立检查/日志 | 新执行通过 |
| 03_north_28 | 561 | 新执行通过 |
| 03_green_dragon_pull | 80 | 新执行通过 |
| 03_north_27_independent | 独立检查/日志 | 新执行通过 |
| 03_north_27 | 679 | 新执行通过 |
| 03_fire_dragon | 91 | 新执行通过 |
| 03_north_26_independent | 独立检查/日志 | 新执行通过 |
| 03_north_26 | 225 | 新执行通过 |
| 03_monsters | 126 | 新执行通过 |
| 03_monster_independent | 独立检查/日志 | 新执行通过 |
| 03_north_25_independent | 独立检查/日志 | 新执行通过 |
| 03_north_25 | 931 | 新执行通过 |
| 03_north_24_independent | 独立检查/日志 | 新执行通过 |
| 03_north_24 | 828 | 新执行通过 |
| 03_north_23_independent | 独立检查/日志 | 新执行通过 |
| 03_north_23 | 328 | 新执行通过 |
| 03_north_22 | 163 | 新执行通过 |
| 03_north_01 | 344 | 新执行通过 |
| 03_north_02 | 239 | 新执行通过 |
| 03_north_03 | 1084 | 新执行通过 |
| 03_north_04 | 430 | 新执行通过 |
| 03_north_05 | 124 | 新执行通过 |
| 03_north_06 | 410 | 新执行通过 |
| 03_north_07 | 867 | 新执行通过 |
| 03_north_08 | 384 | 新执行通过 |
| 03_north_09 | 82 | 新执行通过 |
| 03_north_10 | 344 | 新执行通过 |
| 03_north_11 | 754 | 新执行通过 |
| 03_north_12 | 223 | 新执行通过 |
| 04_main_scene | 独立检查/日志 | 新执行通过 |
| 05_scene_input | 209 | 新执行通过 |
| 05_north_02_scene | 170 | 新执行通过 |
| 05_north_03_scene | 171 | 新执行通过 |
| 05_north_04_scene | 185 | 新执行通过 |
| 05_north_05_scene | 173 | 新执行通过 |
| 05_north_06_scene | 225 | 新执行通过 |
| 05_north_07_scene | 317 | 新执行通过 |
| 05_north_08_scene | 220 | 新执行通过 |
| 05_north_09_scene | 181 | 新执行通过 |
| 05_north_10_scene | 278 | 新执行通过 |
| 05_north_11_scene | 212 | 新执行通过 |
| 05_north_12_scene | 228 | 新执行通过 |
| 05_north_13_scene | 447 | 新执行通过 |
| 05_north_14_scene | 492 | 新执行通过 |
| 05_north_15_scene | 500 | 新执行通过 |
| 05_north_16_scene | 355 | 新执行通过 |
| 05_north_17_scene | 503 | 新执行通过 |
| 05_north_18_scene | 809 | 新执行通过 |
| 05_north_19_scene | 712 | 新执行通过 |
| 05_north_20_scene | 296 | 新执行通过 |
| 05_north_21_scene | 599 | 新执行通过 |
| 05_north_28_scene | 413 | 新执行通过 |
| 05_green_dragon_pull | 71 | 新执行通过 |
| 05_north_27_scene | 443 | 新执行通过 |
| 05_north_26_scene | 217 | 新执行通过 |
| 05_north_25_scene | 1235 | 新执行通过 |
| 05_north_24_scene | 452 | 新执行通过 |
| 05_north_23_scene | 262 | 新执行通过 |
| 05_north_22_scene | 197 | 新执行通过 |
| 05_navigation | 317 | 新执行通过 |
| 05_energy_visibility | 132 | 新执行通过 |
| 06_render | 219 | 新执行通过 |
| 06_render_north_02 | 176 | 新执行通过 |
| 06_render_north_03 | 179 | 新执行通过 |
| 06_render_north_04 | 193 | 新执行通过 |
| 06_render_north_05 | 181 | 新执行通过 |
| 06_render_north_06 | 239 | 新执行通过 |
| 06_render_north_07 | 337 | 新执行通过 |
| 06_render_north_08 | 236 | 新执行通过 |
| 06_render_north_09 | 191 | 新执行通过 |
| 06_render_north_10 | 292 | 新执行通过 |
| 06_render_north_11 | 228 | 新执行通过 |
| 06_render_north_12 | 248 | 新执行通过 |
| 06_render_north_13 | 463 | 新执行通过 |
| 06_render_north_14 | 516 | 新执行通过 |
| 06_render_north_15 | 532 | 新执行通过 |
| 06_render_north_16 | 383 | 新执行通过 |
| 06_render_north_17 | 539 | 新执行通过 |
| 06_render_north_18 | 851 | 新执行通过 |
| 06_render_north_19 | 771 | 新执行通过 |
| 06_render_north_20 | 326 | 新执行通过 |
| 06_render_north_21 | 646 | 新执行通过 |
| 06_render_north_22 | 241 | 新执行通过 |
| 06_render_north_23 | 338 | 新执行通过 |
| 06_render_north_24 | 557 | 新执行通过 |
| 06_render_north_25 | 1398 | 新执行通过 |
| 06_render_north_26 | 237 | 新执行通过 |
| 06_green_dragon_pull | 73 | 新执行通过 |
| 06_render_north_27 | 461 | 新执行通过 |
| 06_render_north_28 | 437 | 新执行通过 |
| 06_navigation | 329 | 新执行通过 |
| 06_energy_visibility | 168 | 新执行通过 |

## 保护与交付

前27关108份地图/解法/MP4/回放及6份导航/能量旧演示、27旧视频条目保持基线dc04f48原字节。旧第27关界面只将目录总数断言改为当前真实数据量，保留全部玩法断言；新第28关验证实际目录28和视口对象池上界。

实现先提交，再真实Godot MovieMaker与普通合法WASD输入从初始录到明确胜利，保存 `video/chapter_01/level_28.mp4`；此实现阶段视频尚未录制。媒体另提交，全部28视频完整解码与独立合法回放、正常develop推送、远端SHA、HTTP实际下载字节/再次解码与CI查询在交付阶段验证，不提前声称完成。

未测试实体设备或所有GPU性能；CI以最终远端可见记录为准，本地通过不等于CI通过。仅云端，无ZIP/强推/PR/部署/凭据读取，不重试旧受拒Library路线，使用已验证固定提交GitHub链接。
