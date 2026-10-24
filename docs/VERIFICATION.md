# 第27关与绿色单拉火龙验证

精确Godot `4.6.3.stable.official.7d41c59c4`，选定云端 `/workspace/stardown`，X11/Mesa llvmpipe真实软件渲染。最终矩阵195阶段通过：117新执行、78个Git基线与已通过记录逐文件指纹验证的语法解析复用。[复用指纹与范围](verification/north_27_scope.json)。所有模型、独立路线、27关实际输入/屏幕按钮/X11大小窗口、导航对象池和能量显示均重新执行，不复用玩法或画面通过结果。

## 完整地图与合法路线

用户最后确认完整外围：旧1–72内区不变，右73–79、左80–88、左下89–91、右下92–93；73上方不可走，原9号墙保留。全部旧x+2统一平移到12×9，87地板/6原墙/15场外。角色、目标和全部龙均同样平移，[1–93映射](../levels/mappings/north_27_markers.json)保存原坐标和运行坐标。旧9×8内区少外围的诊断已经作废，不再把它当完整地图，不新增其他拉动操作或猜测地板。

独立构造并逐步复算74方向/3次拉龙，实际GridState与键盘也通关；不声称最短。36步将63号龙下拉至旧(8,7)，49步将38号龙下拉至旧(1,5)，62步将27号龙下拉至旧(8,3)；三龙全部存活且朝向不变，74步英雄存活到旧(0,2)目标。完整74步Undo和通关后重开恢复全部世界。

## 机制与实际画面

绿英雄背离相邻水晶或fire_dragon自动拉一个，不能推、不链拉，不拉英雄/哥布林/未知类型。火龙方向保持；先验证英雄/被拉对象移动边，任何阻挡都不移动不计数，也不触发攻击。成功动作在位移和机关更新后共同采样所有攻击，再统一应用死亡；死攻击者本步已锁定的攻击不取消，下步不攻击。完整撤销恢复位置、方向、生死、压力、能量和行动计数，C保持免费与非撤销选择。

新拉龙独立夹具覆盖四向侧面/背面、只拉近的一个/混合水晶、不推动、侧向不误拉、墙/边界/水晶/草/能量/栅栏原子阻挡、拉后攻击/互杀与撤销、死亡锁。原拉晶和红蓝/哥布林/能量/栅栏/多英雄等全部回归；没有定义火焰跨栅栏或怪物压板。角色能力夹具与正式关卡分开，不能充当第27关通关视频。

实际方向键/WASD、屏幕按钮与重复/echo输入、C、通关Undo/重开、前26关历史隔离、死亡后C/R/菜单不能绕过均检查。合法侧路DD虽走到目标仍被火焰杀死，不判胜；Undo复活。1280×820和960×615控件/外围/固定朝向箭头画面已实际查看。

[初始](screenshots/level_27_initial.png) · [右侧外围](screenshots/level_27_right_perimeter.png) · [拉63](screenshots/level_27_pull_36.png) · [拉38](screenshots/level_27_pull_49.png) · [拉27](screenshots/level_27_pull_62.png) · [胜利](screenshots/level_27_completed.png) · [小窗口](screenshots/level_27_compact.png)。

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
| 05_green_dragon_pull | 71 | 新执行通过 |
| 05_north_27_scene | 443 | 新执行通过 |
| 05_north_26_scene | 217 | 新执行通过 |
| 05_north_25_scene | 1235 | 新执行通过 |
| 05_north_24_scene | 452 | 新执行通过 |
| 05_north_23_scene | 262 | 新执行通过 |
| 05_north_22_scene | 197 | 新执行通过 |
| 05_navigation | 311 | 新执行通过 |
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
| 06_navigation | 323 | 新执行通过 |
| 06_energy_visibility | 168 | 新执行通过 |

## 保护与交付顺序

前26关104份地图/解法/MP4/回放及6份旧导航/能量演示、26旧视频条目字节保持基线e508e804。使用当前引擎和已有依赖，无额外安装。实现先提交并正常推送 `059ac90ffb4997bb3e4a75c1c1d5d1ed34126613`，之后才以真实Godot MovieMaker视口和普通WASD按下/释放录制 `video/chapter_01/level_27.mp4`。正式视频49.4秒、1482帧、1280×820/30fps、H.264/yuv420p、fast-start、572274字节；74有效方向、3次拉龙、0推/交换/C/毁晶，三龙存活且朝向保持。原始AVI未提交，未重录旧视频。

视频全部75个初始/行动状态抽帧采样，18个关键状态与末帧实际查看，包含3次拉动的前后、右侧绕行/右下落脚和明确胜利。全部27段视频本轮完整FFmpeg解码及独立Python逐输入复算通过；新校验器识别绿拉fire_dragon、每步原子位移与共同攻击，不拉其他类型。SHA256：`303051899154861613a57482ba3de8f1838b638767b8df787592711f795fee3f`。媒体另提交并正常推develop，最终远端SHA、HTTP下载字节及再次解码/CI记录以交付核验为准。

未测试实体设备或全部GPU性能。CI以最终远端可见结果为准，本地通过不是CI通过。只云端，无ZIP/forcepush/PR/部署/凭据读取；不重试旧受拒Library路线，使用验证后的固定提交GitHub链接。
