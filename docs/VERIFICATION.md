# 第一章前十八关 · 云端验证记录

仅选定云端 `/workspace/stardown`。Godot `4.6.3.stable.official.7d41c59c4`，Git develop交付，无ZIP。

## 独立交付的能量显示优化

实现4fa554befe2f5835339dbf0f8e9e8de517b0e032、短片2ed1f9f611cd4ab6a88c3ddea25ed0c1e75d907f已独立推送并核对图片/MP4实际HTTP200下载、字节与全解码。黄色/绿色消失格使用虚线和浅地纹，实体绘制像素与旧图一致。渲染186、无头150、17模型448、机关21、17实际场景613通过；34合法输入的22.2秒对比短片逐状态回放一致。该短片及17段历史视频不重录；[显示验证](ENERGY_VISIBILITY.md)。

## 第十八关确认配置

7×8全部56格核验，共34地板。15红(0,2)、16绿(1,2)、17蓝(2,2)，初始蓝；紫粉晶1=(0,0)，压板51=(1,7)，能量19=(4,2)。18=(3,2)可走、12=(4,1)墙；三个蓝圆盘目标26/32/33=(4,3)/(3,4)/(4,4)，仅显示颜色，不传送、不匹配英雄。人物头顶1/2/3不是格号。

保持全部红推混合整列、绿自动单晶拉、蓝本方向首目标交换、免费C/Undo保留选择、全局能量杀英雄/毁晶规则。仅新增JSON/入口/蓝色目标显示和测试，五个共享玩法/输入核心与2ed1f9f逐字节相同。已交付的消失能量标记继续可见，18按钮两行9+9，角色高亮/保色。

## 独立合法路线

`CCDCCRDCCLDCDDDCCRCDLCUCCRRRRCCDCRCUCCRUUUUUCCUULCCDCRRRRRRDCCDDDDCDCCDDDDCLCCDCRUCCLCCULCCDLCLLCUCCLCUCCLCCDCLUUCRCCULUCCUCRRCDCCRCDLCDCRD`：78实际行动+61免费C=139输入，26推8拉10换，0毁晶。身份占用BFS含销毁状态，扩展741565、访问760589、余19024，3.127秒首次存活胜利停止，不宣称穷举或最优。

8红推两英雄令绿暂压底板，12绿离板恢复；28蓝交换顶排晶到右端；52红推动绿人与晶混合链；61蓝暂压底板，69交换晶接替压力连续保持。71/73/77绿/蓝/红占开放能量格，虚线边缘在当前/非当前角色叠加时仍可见。72绿进首目标，76蓝进第二个，78红推蓝进最后一个，自身进被空出的目标同时胜利；最终晶ID0持续压(1,7)。

全部78Undo按实际行动恢复英雄/晶身份、压力/门/生死，保持最终红选择；61C不计数/不入历史，重开才恢复蓝。额外验证晶交接后切换再Undo保留绿，再合法重做得到同一世界；混合推边界原子拒绝、重复方向/C回声与屏幕按钮、切关隔离。

合法死亡支路：正式前缀8后选蓝R让路，选红UUURRR到能量，选绿U离板，恢复能量压死未选中红；C/方向/R/切关锁定，唯一Undo复活红且保留绿选择。死亡侧路只测试，不混入正式录像。

## 完整回归

`python3 tools/verify.py --visual --display :97`：123步骤全部通过，含55脚本解析、18关模型/真实输入/X11渲染与能量显示像素专项。录制器另解析。原17视频全解码和独立合法回放通过；第18视频须先提交实现后录制。

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
| 05_scene_input | 241项，0失败 |
| 05_north_02_scene | 206项，0失败 |
| 05_north_03_scene | 209项，0失败 |
| 05_north_04_scene | 223项，0失败 |
| 05_north_05_scene | 211项，0失败 |
| 05_north_06_scene | 262项，0失败 |
| 05_north_07_scene | 354项，0失败 |
| 05_north_08_scene | 257项，0失败 |
| 05_north_09_scene | 218项，0失败 |
| 05_north_10_scene | 316项，0失败 |
| 05_north_11_scene | 250项，0失败 |
| 05_north_12_scene | 266项，0失败 |
| 05_north_13_scene | 543项，0失败 |
| 05_north_14_scene | 590项，0失败 |
| 05_north_15_scene | 578项，0失败 |
| 05_north_16_scene | 433项，0失败 |
| 05_north_17_scene | 581项，0失败 |
| 05_north_18_scene | 907项，0失败 |
| 05_energy_visibility | 151项，0失败 |
| 06_render | 251项，0失败 |
| 06_render_north_02 | 212项，0失败 |
| 06_render_north_03 | 217项，0失败 |
| 06_render_north_04 | 231项，0失败 |
| 06_render_north_05 | 219项，0失败 |
| 06_render_north_06 | 276项，0失败 |
| 06_render_north_07 | 374项，0失败 |
| 06_render_north_08 | 273项，0失败 |
| 06_render_north_09 | 228项，0失败 |
| 06_render_north_10 | 330项，0失败 |
| 06_render_north_11 | 266项，0失败 |
| 06_render_north_12 | 286项，0失败 |
| 06_render_north_13 | 559项，0失败 |
| 06_render_north_14 | 614项，0失败 |
| 06_render_north_15 | 610项，0失败 |
| 06_render_north_16 | 461项，0失败 |
| 06_render_north_17 | 617项，0失败 |
| 06_render_north_18 | 949项，0失败 |
| 06_energy_visibility | 187项，0失败 |

## 实际画面与保留文件

实际查看18关非当前绿人在开放能量格的原图渲染，虚线边缘清楚、蓝色三目标普通圆盘和三角色本色正确。1280×820与960×615真实输入/按钮/高亮及全部导航适配；X11 :97/Mesa llvmpipe/GL Compatibility。前17关地图/解法/视频/回放68文件与8cc3bf09逐字节相同，原17媒体条目不变；能量显示短片/证据与2ed1f9f保持字节。

- [blue_plate](screenshots/level_18_blue_plate.png)
- [compact_blue](screenshots/level_18_compact_blue.png)
- [compact_energy_active](screenshots/level_18_compact_energy_active.png)
- [compact_energy_inactive](screenshots/level_18_compact_energy_inactive.png)
- [compact_green](screenshots/level_18_compact_green.png)
- [compact_red](screenshots/level_18_compact_red.png)
- [completed](screenshots/level_18_completed.png)
- [crystal_handoff](screenshots/level_18_crystal_handoff.png)
- [death_inactive_red](screenshots/level_18_death_inactive_red.png)
- [first_goal](screenshots/level_18_first_goal.png)
- [first_hero_exchange](screenshots/level_18_first_hero_exchange.png)
- [green_energy](screenshots/level_18_green_energy.png)
- [initial](screenshots/level_18_initial.png)
- [mixed_push](screenshots/level_18_mixed_push.png)
- [multi_hero_push](screenshots/level_18_multi_hero_push.png)
- [red_energy](screenshots/level_18_red_energy.png)
- [revived_red](screenshots/level_18_revived_red.png)
- [selected_green](screenshots/level_18_selected_green.png)
- [selected_red](screenshots/level_18_selected_red.png)
- [top_crystal](screenshots/level_18_top_crystal.png)
- [two_goals](screenshots/level_18_two_goals.png)

## 视频交付状态

先提交实现，再录制实际Godot从初始到三英雄胜利，包含新消失能量标记。此实现提交不声称正式第18视频已完成。

未验证其他引擎/平台/硬件GPU/导出程序；临时AVI/帧/缓存不提交。CI仅按可见证据报告。
