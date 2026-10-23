# 第一章前十四关 · 云端验证记录

工程仅在选定云端 `/workspace/stardown` 开发、Git、测试与录制。Godot `4.6.3.stable.official.7d41c59c4`。用户通过Git获取工程，无额外ZIP。

## 第十三关修正已单独交付

C不计操作、不进撤销、Undo保留当前选择已实现于b24f147，视频与验证已推送8b00eb9。21.2秒 / 636帧、24实际行动+3免费选择。93步检查与全部十三视频合法回放通过，实际下载HTTP200、332454字节，哈希与完整解码一致；交付完成后才开始第十四关，两关提交分开。

## 第十四关确认地图与实现

10×7，最新更正6号(5,0)是墙，覆盖核对图旧标记。8/9/29/50为空地，64–66墙，全部70格逐项核验。红=(1,1)，绿=(1,5)，唯一紫晶=(3,1)，双目标=(6,0)/(6,6)，单黄板=(9,3)，双门=(8,1)/(8,5)，无草丛。初始选红。

独立north_14.json与入口、解法和测试；红混合整列推、绿自动单晶拉、单板双门移动 / 视线、双英雄不同目标和死亡仅Undo全部复用同一引擎，没有新增机制。C和屏幕选择免费且不写历史，Undo保留当前选择；重开恢复初始红。

界面根据阵容显示推动 / 拉动，选择绿色时正确显示绿色角色与高亮，非当前英雄保留原色压暗。14关中文导航在1280×820和960×615适配。发现测试鼠标原来未换算窗口缩放，已使用视口final_transform生成实际窗口输入坐标，并增加小窗口真实点击确实选绿的断言；没有改动游戏规则来迁就测试。

前十三关地图 / 解法 / 视频 / 回放52份文件与8b00eb9逐字节一致，原十三份媒体条目保留。GridState / EnergyRules / HeroRules / SwapRules / LevelData / StepInput六个核心脚本与该基线字节相同。

## 独立合法路线与Godot验证

`RRCRRRUUUDCRCRCDCRCDRCUCRDRCRCUCRCUCDCRUULLCDLDDLL`：35次实际方向行动、15次免费选择，共50个输入事件；6推、4拉、0换。独立身份占用BFS扩展20282、访问22496状态，首次胜利停止，尚余2214排队；选择不计费，红绿 / 水晶身份保留，不宣称最短或穷举。

行动15红人原子推动紫晶与绿人混合列，非当前绿人不增加拉动；24绿占板双门开放，26红过上门，29红到上目标；30绿自动单拉紫晶接替压板，不发生中间闭门；32绿过下门，35绿到下目标，双英雄同时胜利。全部C不改变世界 / 压力 / 行动计数 / 历史。35次逆序Undo恢复世界并保留最终绿选中，重开才恢复红。

合法侧路验证绿在水晶接替前离板，两门同时恢复移动 / 视线阻挡，一次Undo同步恢复。绿正面对晶不能推；背离自动拉一枚。切换后Undo直接恢复上一真实行动且保持当前英雄。死亡锁定 / 仅撤销复活由共用多英雄和机关专项回归，未伪造本关死亡情节。

## 完整检查

`python3 tools/verify.py --visual --display :97`：98步全部通过，含45脚本解析、角色 / 机关 / 多英雄专项、十四关模型、十四关真实键鼠与X11渲染。录制脚本范围扩至14，另解析检查。前十三段视频已完整解码与独立合法回放。详见结构化摘要。

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
| 05_scene_input | 227项，0失败 |
| 05_north_02_scene | 192项，0失败 |
| 05_north_03_scene | 195项，0失败 |
| 05_north_04_scene | 209项，0失败 |
| 05_north_05_scene | 197项，0失败 |
| 05_north_06_scene | 248项，0失败 |
| 05_north_07_scene | 340项，0失败 |
| 05_north_08_scene | 243项，0失败 |
| 05_north_09_scene | 204项，0失败 |
| 05_north_10_scene | 302项，0失败 |
| 05_north_11_scene | 236项，0失败 |
| 05_north_12_scene | 252项，0失败 |
| 05_north_13_scene | 508项，0失败 |
| 05_north_14_scene | 555项，0失败 |
| 06_render | 237项，0失败 |
| 06_render_north_02 | 198项，0失败 |
| 06_render_north_03 | 203项，0失败 |
| 06_render_north_04 | 217项，0失败 |
| 06_render_north_05 | 205项，0失败 |
| 06_render_north_06 | 262项，0失败 |
| 06_render_north_07 | 360项，0失败 |
| 06_render_north_08 | 259项，0失败 |
| 06_render_north_09 | 214项，0失败 |
| 06_render_north_10 | 316项，0失败 |
| 06_render_north_11 | 252项，0失败 |
| 06_render_north_12 | 272项，0失败 |
| 06_render_north_13 | 524项，0失败 |
| 06_render_north_14 | 579项，0失败 |

## 实际画面与待录制

已实际查看初始与小窗口绿选中，核对6号墙、红 / 绿 / 紫晶位置、单板双门及目标。X11 :97、Mesa llvmpipe、GL Compatibility，原十三关截图保留；真实录制只捕获Godot视口。

- [初始](screenshots/level_14_initial.png)
- [绿选中](screenshots/level_14_selected_green.png)
- [混合连推](screenshots/level_14_mixed_push.png)
- [绿占板](screenshots/level_14_hero_plate.png)
- [红过上门](screenshots/level_14_red_gate.png)
- [首目标](screenshots/level_14_first_goal.png)
- [紫晶接替](screenshots/level_14_crystal_plate.png)
- [绿过下门](screenshots/level_14_green_gate.png)
- [双英雄胜利](screenshots/level_14_completed.png)
- [离板双门恢复](screenshots/level_14_released.png)
- [小窗口红](screenshots/level_14_compact_red.png)
- [小窗口绿真实鼠标选择](screenshots/level_14_compact_green.png)

实现先提交并推送，再录制实际初始至胜利的video/chapter_01/level_14.mp4，独立验证后另提交。此实现提交尚未声称第十四段视频完成。离板截图为合法侧路测试，不混入正式通关录像。

临时日志、截图帧、原始AVI和生成缓存不提交。未验证其他平台 / 引擎 / 硬件GPU / 导出程序。屏障恢复遇水晶仍未确认，现有候选动作保护保留；通关路径不使用该边界，不声称整个状态空间穷举。CI按可见远端结果报告。
