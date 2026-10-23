# 沉星之序 · 第一章前十六关（Godot 4 / 2D）

第一章前十六关按确认的文字网格实现。前四关是红色推之英雄，可整列推水晶；第五至八关是绿色拉之英雄，只能自动拉最近一枚；第九至十二关是蓝色交换英雄，能走路但不能推拉。第一关是 11 × 3、黄色终点；第二关是 11 × 7、10 枚水晶；第三关加入压力板与能量屏障；第四关加入独立草丛与三板联动；第五关沿用第一关布局，改变英雄能力；第六关结合绿色单拉和单板屏障；第七关是一枚紫晶与单板双屏障的城堡通道；第八关结合绿色单拉、三紫晶、草丛与三板联动；第九关加入方向输入被动交换，第十关结合蓝英雄与单板屏障；第十一关是九绿板联动与隔门橙晶交换；第十二关结合蓝英雄、三色水晶、两草丛与三黄板；第十三关加入红 / 蓝双英雄、C 切换、混合整列推动与双终点；第十四关为红 / 绿协作、单黄板双能量门，6号(5,0)按用户最新更正保留墙；第十五关为蓝 / 绿协作，两水晶与双板单门，25号(2,2)按最新更正不可走；第十六关为红 / 蓝协作、单板单门与两个紫色圆盘终点，圆盘只作目标显示。第二至十二关使用绿色终点，玩家抵达才判胜；第十三至十六关需要两名英雄同时分占两个不同终点，不限定英雄对应。画面为原创 2D 几何图形，不声称逐像素复刻。

开发、测试与 Git 操作均在选定云端 `/workspace/stardown` 完成，没有读取、迁移或操作用户电脑。交付分支为 `develop`；不发布游戏、不创建 PR。

压力机关遵循用户确认的底层全局 AND：**所有压力板同时被英雄或水晶占住，所有能量块才一起消失**；黄色 / 绿色仅为关卡显示配色；任一解除就全部恢复。数据组标识只用于占用诊断，不代表独立开门。第七关复用该规则，用户对二维图补正 `(0,2)` 为地板后，152 步 / 56 次单拉路线已验证；没有为解法改动其他确认格或规则。

## 获取与运行

通过 Git 获取 [develop 分支](https://github.com/pingta-chaolibao/stardown/tree/develop)，在所选云端环境使用 Godot 导入 `project.godot`，按 **F5** 运行。用户已选择通过 Git 获取工程，交付提供逐关通关视频。

已验证的精确版本：`4.6.3.stable.official.7d41c59c4`（标准版）。不需要 C#、插件、在线字体或导出模板。有图形显示时，终端最简运行方式：

```bash
cd /workspace/stardown
godot --path .
```

本云端默认配置目录若不可写，可将设置、缓存和用户数据指定到 `/tmp`：

```bash
mkdir -p /tmp/stardown-config /tmp/stardown-cache /tmp/stardown-data
XDG_CONFIG_HOME=/tmp/stardown-config XDG_CACHE_HOME=/tmp/stardown-cache XDG_DATA_HOME=/tmp/stardown-data godot --path /workspace/stardown
```

实际画面：[初始状态](docs/screenshots/initial.png)、[通关状态](docs/screenshots/completed.png)、[960 × 615 窗口](docs/screenshots/compact.png)。第二关画面：[初始状态](docs/screenshots/level_02_initial.png)、[通关状态](docs/screenshots/level_02_completed.png)、[小窗口](docs/screenshots/level_02_compact.png)。这些是本工程的 Godot 渲染结果。

第三关画面：[初始状态](docs/screenshots/level_03_initial.png)、[英雄踩板后](docs/screenshots/level_03_plate_pressed.png)、[通关状态](docs/screenshots/level_03_completed.png)、[小窗口](docs/screenshots/level_03_compact.png)。

第四关画面：[初始状态](docs/screenshots/level_04_initial.png)、[三板压满](docs/screenshots/level_04_all_plates.png)、[通关状态](docs/screenshots/level_04_completed.png)、[小窗口](docs/screenshots/level_04_compact.png)。

第五关画面：[绿色英雄初始](docs/screenshots/level_05_initial.png)、[第一次拉动](docs/screenshots/level_05_first_pull.png)、[通关](docs/screenshots/level_05_completed.png)、[小窗口](docs/screenshots/level_05_compact.png)。

第六关画面：[初始](docs/screenshots/level_06_initial.png)、[英雄踩板](docs/screenshots/level_06_hero_plate.png)、[屏障关闭受阻](docs/screenshots/level_06_gate_blocked.png)、[水晶接替压板](docs/screenshots/level_06_crystal_plate.png)、[过门](docs/screenshots/level_06_crossing.png)、[通关](docs/screenshots/level_06_completed.png)、[小窗口](docs/screenshots/level_06_compact.png)。

第七关画面：[初始](docs/screenshots/level_07_initial.png)、[补正地板的绕行](docs/screenshots/level_07_new_floor.png)、[紫晶持续压板](docs/screenshots/level_07_plate_held.png)、[过门](docs/screenshots/level_07_crossing.png)、[通关](docs/screenshots/level_07_completed.png)、[小窗口](docs/screenshots/level_07_compact.png)。

## 通关演示视频

| 第一章关卡 | 实际运行视频 | 时长 |
| --- | --- | --- |
| 第一关 | [观看 / 下载 MP4](video/chapter_01/level_01.mp4) | 12.2 秒 |
| 第二关 | [观看 / 下载 MP4](video/chapter_01/level_02.mp4) | 21.2 秒 |
| 第三关 | [观看 / 下载 MP4](video/chapter_01/level_03.mp4) | 17.6 秒 |
| 第四关 | [观看 / 下载 MP4](video/chapter_01/level_04.mp4) | 25.4 秒 |
| 第五关 | [观看 / 下载 MP4](video/chapter_01/level_05.mp4) | 19.4 秒 |
| 第六关 | [观看 / 下载 MP4](video/chapter_01/level_06.mp4) | 44.0 秒 |
| 第七关 | [观看 / 下载 MP4](video/chapter_01/level_07.mp4) | 96.2 秒 |
| 第八关 | [观看 / 下载 MP4](video/chapter_01/level_08.mp4) | 38.6 秒 |
| 第九关 | [观看 / 下载 MP4](video/chapter_01/level_09.mp4) | 10.4 秒 |
| 第十关 | [观看 / 下载 MP4](video/chapter_01/level_10.mp4) | 37.4 秒 |
| 第十一关 | [观看 / 下载 MP4](video/chapter_01/level_11.mp4) | 16.4 秒 |
| 第十二关 | [观看 / 下载 MP4](video/chapter_01/level_12.mp4) | 20.6 秒 |
| 第十三关 | [观看 / 下载 MP4](video/chapter_01/level_13.mp4) | 21.2 秒 |
| 第十四关 | [观看 / 下载 MP4](video/chapter_01/level_14.mp4) | 35.0 秒 |
| 第十五关 | [观看 / 下载 MP4](video/chapter_01/level_15.mp4) | 53.6 秒 |
| 第十六关 | 实现提交后录制 | 待验证 |

视频从正确初始状态到明确胜利，由 Godot 实际渲染与合法键盘回放录制；1280 × 820、30 fps、H.264 / yuv420p，已完整解码并查看首尾。详情、回放证据和重录命令见 [video/README.md](video/README.md)。

**今后每完成一关，都须先提交关卡实现，再制作并提交对应通关视频，按章节保存在仓库根目录 `video/chapter_XX/level_YY.mp4`。** 项目工作约定也已写入 [AGENTS.md](AGENTS.md)。

## 确认的地图

### 第一关

坐标从左上角 `[0,0]` 开始，x 向右、y 向下。11 × 3 矩形外部全部不可走，其余内部格除以下四格墙外均为地板。

| 元素 | 坐标 |
| --- | --- |
| 红色玩家 | `(1,1)` |
| 墙 | `(3,0)`、`(3,1)`、`(7,1)`、`(7,2)` |
| 蓝水晶 | `(3,2)` |
| 紫水晶 | `(7,0)` |
| 黄色终点 | `(9,1)` |

```text
...#...P...
.R.#...#.E.
...B...#...
```

`R` 玩家，`B` 蓝水晶，`P` 紫水晶，`E` 终点，`#` 墙，`.` 地板。布局与规则以用户对上述坐标的明确确认为依据，不依赖此前无法物化的截图。本轮没有重试图片传输。

### 第二关

11 列 × 7 行，坐标同样从 `[0,0]` 起算，矩形外不可走：

```text
...#...#...
R..VB....BV
...#...#...
#########V#
...#...#...
.GB..VBVV..
...#...#...
```

`R` 是红色玩家 `(0,1)`，`G` 是绿色终点 `(1,5)`，`B` 是蓝水晶，`V` 是紫水晶。蓝水晶在 `(4,1)/(9,1)/(2,5)/(6,5)`；紫水晶在 `(3,1)/(10,1)/(9,3)/(5,5)/(7,5)/(8,5)`。用户明确确认的 `(10,3)` 是墙、`(10,2)` 是地板。其余布局依照主对话识别并确认的网格，没有改图以迁就解法。

第二关的实际规则验证路径为 `RRRRURRDRRDRDDLDLLULLDLLULD`，其中 U/D/L/R 是上/下/左/右。共 **27 步、12 次推动**，包含多水晶连推；先由独立状态搜索找到，再由 Godot 模型和实际键盘入口逐步验证。路径不宣称步数最优。

### 第三关

11 列 × 3 行，地图外不可走；下列布局来自用户分别确认的坐标与机关规则：

```text
...#...#...
RY...V.#.G.
...#...X...
```

`R` 红色玩家 `(0,1)`；`Y` 黄色压力板 `(1,1)`；`V` 紫水晶 `(5,1)`；`G` 绿色终点 `(9,1)`；`X` 黄色能量块 `(7,2)`。固定墙是 `(3,0)/(3,2)/(7,0)/(7,1)`，其他内部格为地板。

英雄或水晶压住黄板时，相连能量块消失，移动与视线均可穿过；离板后恢复，同时阻挡移动与视线。若恢复格有英雄，英雄死亡，只能撤销上一步复活；死亡时不能移动、重开或切关。一次动作统一结算全部位置、压力、屏障和生死，撤销整体恢复。

实际验证路线：`RRRRURRDLLLLRRRRDRRUR`，**21 步、4 次推动**。先绕到水晶右侧，将其向左推到黄板，再穿过打开的能量格进入绿色终点。初次踩板、离板、持续压板均在正常路线中出现。详见 [机关规则与未定义边界](docs/ENERGY_RULES.md)；屏障恢复格有水晶的行为尚未确认，已穷举本关 352 个合法状态，证明本关不会触发该边界。

### 第四关

7 列 × 6 行，最上与最下边缘均计入完整可走行；坐标来自主对话核对并确认的最终文字规格，地图外不可走：

```text
.....#G
.RB..#X
.VB....
...T...
TY.Y.Y.
.......
```

红英雄 `(1,1)`；水晶 `(2,1)/(1,2)/(2,2)`，使用原创蓝 / 紫配色；草丛 `T` 在 `(3,3)/(0,4)`；黄色压力板 `Y` 在 `(1,4)/(3,4)/(5,4)`；固定墙 `(5,0)/(5,1)`；目的地 `G` 在 `(6,0)`，独立能量格 `X` 在 `(6,1)`。其余内部格是普通地板，灰色英雄及草丛转水晶均未实现。

草丛是独立静态类型，不能推、不能交换，同时挡英雄、水晶通行与视线。三块黄板必须全部被英雄或水晶同时占据才开门，任何一块解除就恢复屏障；死亡与仅撤销复活规则沿用第三关。

Godot 已验证路线 `RDDLDRRRUUULULDDDLDRUUULDDURRRRRUU`，**34 步、13 次推动**。最终三枚水晶分别持续压住三块板，英雄经过 `(6,1)` 到达 `(6,0)`。独立搜索工具 `python3 tools/search_north_04.py` 可重现解法与 234,773 个按位置去重的存活状态检查；实际规则、颜色身份和正常键盘入口另由 Godot 回归验证，不宣称最优解。

### 第五关：绿色拉之英雄

11 列 × 3 行，地形与第一关相同；绿色英雄 `(1,1)`，蓝水晶 `(3,2)`、紫水晶 `(7,0)`，墙 `(3,0)/(3,1)/(7,1)/(7,2)`，绿色终点 `(9,1)`。其余内格地板、外部不可走，未新增机关或角色。

```text
...#...V...
.H.#...#.G.
...B...#...
```

`H` 为绿色英雄。用户确认操作是**背离相邻水晶移动时自动拉最近一枚到英雄原位置**，后面相连的水晶不跟随。绿色不能推水晶；前方被任何障碍或水晶挡住时，英雄与后方水晶均不动。没有额外拉动按键，也不拉其他英雄。

Godot 已验证路线 `DRLLURRDRRUURRLLDRRURRDR`，**24 步、8 次拉动、0 次推动**，两枚水晶均参与。可以用 `python3 tools/search_north_05.py` 重现独立搜索；详见[红绿英雄规则](docs/HERO_RULES.md)。

### 第六关：绿色单拉与单板屏障

11 列 × 7 行。最上排 `(3,0)/(7,0)` 经用户确认均为固定墙；能量块仅 `(7,6)` 一格。最终文本布局如下，`H` 绿英雄、`B/V` 蓝 / 紫水晶、`G` 绿目标、`Y` 黄板、`X` 能量格：

```text
...#B..#...
H..V...#.B.
...#..B....
#########.#
..VB...#...
.G.#...#.Y.
...#...X.V.
```

英雄 `(0,1)`；蓝晶 `(4,0)/(9,1)/(6,2)/(3,4)`；紫晶 `(3,1)/(2,4)/(9,6)`；目的地 `(1,5)`；板 `(9,5)`；能量格 `(7,6)`。`y=3` 除 `(9,3)` 通道外整排墙，另有 `(3,0)/(7,0)/(3,2)/(7,1)/(3,5)/(3,6)/(7,4)/(7,5)`；其余内部地板、外部阻挡。没有新增草丛或角色。

直接复用已确认规则：绿色自动只拉相邻一枚，英雄或水晶压板可开门，解除压力即恢复移动 / 视线阻挡，死亡只能撤销复活。关卡使用原单板 `plate` 数据格式，核心规则文件没有修改。

构造并验证的路线为 `RRLLURRDRRDRUURDULDDRRRRDDRDLURDDLLLLULLURDLDRURULLLRRRDDLLUULLDL`，**65 步、17 拉、0 推**，七枚水晶均参与。第 29 步英雄踩板，第 30 步将下方紫晶拉上板持续供能，第 36 步过门，第 65 步进入左下目标。`python3 tools/check_north_06.py` 独立逐步回放，再由 Godot 模型与正常键盘入口验证；不宣称最优解。

### 第七关：绿色单拉与单板双屏障

17 列 × 11 行。依据用户修正并确认的原图编号布局；用户检查二维转换后明确补正原 14 号下方 `(0,2)` 可走，其余格保持原样。`(4,6)/(6,8)` 仍为墙；编号 70 对应 `(5,9)`、129 对应 `(5,10)`。绿英雄 `H` 在 `(11,5)`，紫晶 `V` 在 `(9,0)`，黄板 `Y` 在 `(12,5)`，两处能量格 `X` 在 `(12,1)/(15,4)`，绿终点 `G` 在 `(14,2)`：

```text
#########V..#####
...#........X...#
...#....#...#.G.#
#..#....#####...#
#..####.#..####X#
#.......#..HY....
#..##...#...##...
#####...##.######
#####.###..##....
###..............
###...###########
```

绿色英雄自动拉最近一枚、不能推。单黄板同时控制两道屏障；113 步英雄踩板，114 步紫晶接替，115 步继续拉离黄板使两门关闭；123 / 124 步从另一侧交接并留晶压板，149 步穿过上方能量格，152 步进入终点。

实际模型与正常键盘验证路线为：

```text
DLDDDLLLLLUUUURRUUUURRDRURULLDLLLDRDDDDLULLLLLURUUULDLURRDDLDDDRURRRRDLDDDDLULDRRURRRRRRRRRRULLDLLLLURUUUULDDRRURRRRRDLLULLLDLDDDLLLLLUUUURRUUUURRRRRRDR
```

共 **152 步、56 次单枚拉动、0 次推动**，不宣称最优。`python3 tools/search_north_07.py` 可复现独立搜索；Python 与 Godot 都遍历 2,853 个存活位置状态，未出现未定义屏障恢复。初版非通关诊断片段只用于定位转换，不替代正式通关视频。

### 第八关：绿色单拉、草丛与三板联动

7 × 6，原图编号与平面图均经用户确认，按逐行 1–42 编号：绿英雄 9，三紫晶 10 / 16 / 17，墙 6 / 13，目标 7，能量 14，草 23 / 27 / 39，黄板 30 / 32 / 34。`H` 英雄、`V` 紫晶、`T` 草、`Y` 黄板、`X` 能量格、`G` 目的地：

```text
.....#G
.HV..#X
.VV....
.T...T.
.Y.Y.Y.
...T...
```

英雄 `(1,1)`；三紫晶 `(2,1)/(1,2)/(2,2)`；墙 `(5,0)/(5,1)`；草 `(1,3)/(5,3)/(3,5)`；黄板 `(1,4)/(3,4)/(5,4)`；目标 `(6,0)`、能量 `(6,1)`。其余内部地板，边界外不可走。完全复用绿色自动单拉不推、静态草丛、全局三板 AND 和死亡只能撤销复活；没有新增英雄或迁移 JSON 配置格式。

独立搜索与 Godot 验证的合法路线：

```text
URRDDDLDDLULUURRDDDLLUUURRURDLDRURRRDDLLUULDDRUDDRURUUUU
```

**56 步、17 拉、0 推**，三枚紫晶均参与，不宣称最优。51 步英雄与两枚水晶压满三板，52 步拉第三枚紫晶接替并持续开门，55 步过能量格，56 步进入目标。独立 Python 与 Godot 均穷举 21,291 个存活位置状态，没有未定义恢复转移；`python3 tools/search_north_08.py` 可复现。

第八关画面：[初始](docs/screenshots/level_08_initial.png)、[草丛阻挡](docs/screenshots/level_08_bush_blocked.png)、[三晶压板](docs/screenshots/level_08_all_plates.png)、[过门](docs/screenshots/level_08_crossing.png)、[胜利](docs/screenshots/level_08_completed.png)、[小窗口](docs/screenshots/level_08_compact.png)。

### 第九关：蓝色被动交换英雄

11 × 3，原图编号及二维格图经用户确认：蓝英雄 13 号 `(1,1)`，紫晶 8 号 `(7,0)`，蓝紫晶 26 号 `(3,2)`，四墙 `(3,0)/(3,1)/(7,1)/(7,2)`，终点 21 号 `(9,1)`，其余内格为空地、外部阻挡。地形与第一 / 五关相同。

```text
...#...V...
.H.#...#.G.
...C...#...
```

`H` 蓝英雄，`V` 紫晶，`C` 蓝紫晶，`G` 绿色终点。蓝英雄每次方向键 / WASD 或屏幕方向输入，只查看该方向：有合法可见英雄 / 水晶就与第一个目标自动交换，没有目标才尝试走一格；不能推拉。墙、草和激活能量格阻挡视线。没有独立技能键，也不能绕过可见目标选择只走一格。当前关卡仍只有一个英雄，独立规则及测试覆盖英雄 / 水晶目标分类，没有新增多英雄关卡。

重新求解的合法路线 `DRRUURRDR`：全大写 UDLR 都是普通方向输入，自动根据本方向视线决定交换或行走。共 **9 次有效操作：7 次行走、2 次交换，0 推 / 拉**。第 2 次从 `(1,2)` 与 `(3,2)` 下方水晶交换，第 6 次从 `(4,0)` 与 `(7,0)` 紫晶交换，最后进入 `(9,1)`。`python3 tools/search_north_09.py` 独立检查 318 个保留水晶身份的可达状态，实际路径另由 Godot 模型与正常输入验证，不宣称最优。详见 [英雄规则](docs/HERO_RULES.md)。

验收例子：13 向下到 24，不受右侧水晶影响；24 按右直接与 26 交换，不经过 25。长按不连动，松开再按才处理新输入。

第九关画面：[初始](docs/screenshots/level_09_initial.png)、[下方自动交换](docs/screenshots/level_09_first_swap.png)、[上方自动交换](docs/screenshots/level_09_second_swap.png)、[胜利](docs/screenshots/level_09_completed.png)、[小窗口](docs/screenshots/level_09_compact.png)。

### 第十关：蓝色交换与单板屏障

用户确认11×7原图编号与二维图，并明确把4号 `(3,0)` 改为空地，其余格（包含原问号格）全部正确。蓝英雄12号 `(0,1)`，唯一紫晶13号 `(1,1)`，终点57号 `(1,5)`，能量块59号 `(3,5)`，黄板77号 `(10,6)`；没有草丛或新角色。

```text
.......#...
HV.#.......
.......#...
#####.###.#
...#...#...
.G.X.......
...#...#...Y
```

`H` 蓝英雄，`V` 紫晶，`G` 绿色终点，`X` 黄色能量块，`Y` 黄色压力板。中间第4行只有 `(5,3)/(9,3)` 两条通道。方向输入被动交换、不能推拉、英雄或水晶压板、全部黄板AND控制全部能量块、死亡仅撤销复活均复用既有规则。

独立搜索遍历2,560个存活身份状态；路线 `URDRURRRLDDRRRRDDDURDRRDRDDDRLUUUURRRDRDDDDRULLLLLLLLL` 为 **54次方向输入、5次自动交换、0推拉**，不宣称最优。第6步实际走过用户更正的 `(3,0)`；第44步英雄踩板，第45步与紫晶交换让水晶接替压板，第52步穿过 `(3,5)`，第54步到达 `(1,5)`。未发现可达死亡、屏障格水晶或未定义恢复转移；死亡只能撤销复活另在蓝英雄机制夹具回归，未把夹具拍作通关。

实际画面：[初始](docs/screenshots/level_10_initial.png)、[更正地板](docs/screenshots/level_10_corrected_floor.png)、[英雄压板](docs/screenshots/level_10_hero_plate.png)、[水晶接替](docs/screenshots/level_10_crystal_plate.png)、[过门](docs/screenshots/level_10_crossing.png)、[胜利](docs/screenshots/level_10_completed.png)、[小窗口](docs/screenshots/level_10_compact.png)。

### 第十一关：九绿板与隔门交换

用户确认了原图编号、二维布局和全部机制。11×7，蓝英雄 `(5,0)`，绿色终点 `(9,1)`；主平台 x=0..6、y=0..6 全地板；隔墙 x=7 只有 `(7,1)` 是绿色能量门所在的地板；右平台 x=8..10、y=0..2 全地板，右下12格是界外并留空显示。

```text
.....H.#...
.C.C.C.X.GO
.......#...
.C.C.C.#~~~
.......#~~~
.Y.C.C.#~~~
.......#~~~
```

`C` 为八枚主平台水晶，其下各有一块绿板；`Y` 是唯一空绿板 `(1,5)`，九板为 x=1/3/5 与 y=1/3/5 的全部组合。`O` 是第九枚橙水晶 `(10,1)`；`X` 是能量门，`~` 仅在这张说明图中表示界外，JSON仍以不可通行地形加 `void_cells` 显示注解表达。所有九块板同时被英雄或水晶占住才开门，任意一块松开就关门。颜色不匹配、不分组，不改变压板或交换规则。

构造并独立校验的合法路线 `LLLLLDDDDRDRRUURULD`，**19次方向输入、5次自动交换、0推拉**。第11步英雄进入 `(1,5)` 压满九板；之后依次交换到 `(3,5)`、`(5,5)`、`(5,3)`、`(5,1)`，压力连续保持。第16步沿右方向穿过已开放的视线，与 `(10,1)` 橙晶交换；橙晶接替 `(5,1)` 压板，英雄到右平台，再上、左、下进入终点。路线不是穷举或最优性证明。全部512种九板占用组合及颜色不影响规则均有模型回归。

实际画面：[初始](docs/screenshots/level_11_initial.png)、[压满九板](docs/screenshots/level_11_all_plates.png)、[与橙晶对齐](docs/screenshots/level_11_aligned.png)、[隔门交换](docs/screenshots/level_11_orange_exchange.png)、[通关](docs/screenshots/level_11_completed.png)、[离板关门](docs/screenshots/level_11_released.png)、[界外受阻](docs/screenshots/level_11_void.png)、[小窗口](docs/screenshots/level_11_compact.png)。后两张是规则验证的侧路，未拼接进正式通关录像。

### 第十二关：被动交换、草丛与三黄板

用户确认7×6原图编号与二维图无误，最上与最下排都是完整格。蓝英雄9号 `(1,1)`；橙晶10号 `(2,1)`、紫晶16号 `(1,2)`、粉红晶17号 `(2,2)`；草丛25/39号 `(3,3)/(3,5)`；黄板30/32/34号 `(1,4)/(3,4)/(5,4)`；墙6/13号 `(5,0)/(5,1)`；能量14号 `(6,1)`；终点7号 `(6,0)`。其余格空地，界外不可走。

```text
.....#G
.HO..#E
.VP....
...T...
.Y.Y.Y.
...T...
```

`H`蓝英雄，`O/V/P`橙/紫/粉红水晶，`T`草丛，`Y`黄板，`E`能量格，`G`终点。粉红仅是新显示配色，无新机制。沿本次方向首目标被动交换，不能推拉；草丛挡移动 / 视线、不能移动交换；三板全压才开门，解除就恢复，死亡只能撤销复活。

合法路线 `DDDURRDRRLDDRLURRRDDDRURUU`：**26次方向输入、7次自动交换、0推拉**。独立占用搜索扩展182,249个状态、访问193,533个状态，在首次胜利停止，忽略颜色身份排列只用于搜索去重，不是穷举或最优性声明。路线另按橙/紫/粉红身份逐步回放；第22步英雄压满三板，第23步粉红晶接替 `(5,4)` 持续开门，第25步通过 `(6,1)`，第26步到 `(6,0)`。最终橙/紫/粉红分别留在 `(1,4)/(3,4)/(5,4)`，没有颜色匹配条件。

实际画面：[初始](docs/screenshots/level_12_initial.png)、[首次交换](docs/screenshots/level_12_first_swap.png)、[紫晶压板](docs/screenshots/level_12_purple_plate.png)、[两板占用](docs/screenshots/level_12_two_plates.png)、[英雄压满](docs/screenshots/level_12_hero_plate.png)、[粉红接替](docs/screenshots/level_12_crystal_plate.png)、[过门](docs/screenshots/level_12_crossing.png)、[通关](docs/screenshots/level_12_completed.png)、[离板恢复](docs/screenshots/level_12_released.png)、[小窗口](docs/screenshots/level_12_compact.png)。离板截图是独立规则侧路，不拼接进正式通关录像。

## 操作与通关

| 操作 | 按键 / 界面 |
| --- | --- |
| 切换第一至第十六关 | 顶部关卡按钮；存活时可切换，从该关初始状态开始，清空撤销历史 |
| 方向输入 | 方向键或 WASD；也可点击方向按钮；蓝英雄优先交换本方向可见目标 |
| 多英雄切换 | C 或屏幕「切换 C」；只改变选择，不计步、不写撤销历史，不移动或触发能力 |
| 蓝色被动交换 | 方向键 / WASD / 屏幕方向：有可见目标优先交换，否则走一格 |
| 撤销最近一次有效移动 | Z、U、Backspace，或“撤销”按钮 |
| 恢复关卡初始状态 | 存活时按 R，或“重开”按钮；死亡时只能撤销 |

红 / 绿英雄每次有效移动前进一格；蓝英雄每次方向输入先沿本方向查目标，有目标直接交换两端，否则走一格。红英雄可将相邻直线整列英雄或水晶（包括混合排列）推一格，没有 3 或 4 枚的硬上限；只有列末可走且为空才原子移动，受阻不计数、不写历史。空格截断水晶列，旁侧水晶不被带动。红英雄不能拉。蓝英雄不能推拉，交换每次计一次有效操作和一次交换。绿英雄只能在背离紧邻水晶移动时自动拉最近一枚，不能推或拉整列。

松开再按可连续操作；长按回声和未松开的重复事件不会多走。步数（蓝色为有效操作数）、推动、拉动、交换分别计数；整列推或交换均只算一次有效操作，另记一次对应技能。撤销一次恢复上次实际推、拉、交换或行走前的全部英雄位置、水晶颜色身份、实际行动统计与机关生死状态；撤销保留用户当前选中的英雄，重开恢复初始状态。多英雄 C 不计操作、不计步，也不写撤销历史；单英雄 C 保持无操作。

前十二关存活玩家进入当前关卡的终点才判胜（第一关黄色、第二至十二关绿色）；第十三至十六关要求所有英雄同时分占不同终点，水晶不计。任意英雄死亡会锁住移动、C、重开与切关，只能撤销恢复。通关后可以撤销最后一步，或重开；撤销恢复全部英雄、水晶、颜色身份、实际操作数、推动 / 拉动 / 交换次数、压力、屏障、生死和通关状态，并保持当前选中英雄，重开清空历史并恢复全部初始状态。

第一关已验证、两枚水晶均参与的通关路径：**下，右 × 3，上 × 2，右 × 4，下，右**。结果为 **12 步、4 次推动**；蓝水晶最终在 `(5,2)`，紫水晶最终在 `(9,0)`，玩家在 `(9,1)`。这是一条验证路径，不宣称最优解。

## 工程结构与数据

- `levels/north_01.json` 至 `levels/north_16.json`：十六关数据，默认进入第一关。
- `levels/solutions/`：逐输入验证的十六关通关路径，供测试与演示回放使用。
- `scripts/core/level_data.gd`：JSON 解析与坐标校验。
- `scripts/core/energy_rules.gd`：纯占用谓词和机关结算，提供可配置压力来源。
- `scripts/core/bush_obstacle.gd`：独立静态草丛类型，明确不可移动 / 交换与阻挡能力。
- `scripts/core/hero_rules.gd`：红推 / 绿拉 / 蓝色被动交换能力，未支持的角色数据会被拒绝。
- `scripts/core/grid_state.gd`：不依赖节点、渲染、计时器或物理的独立网格规则及撤销历史。
- `scripts/core/swap_rules.gd`：纯数据四向首目标查询及交换计划；英雄 / 水晶分类与静态视线遮挡。
- `scripts/input/step_input.gd`：按键去重与释放处理。
- `scripts/view/board_view.gd`：只读网格状态的原创几何绘制；适配横向长廊。
- `scripts/main.gd`、`scenes/main.tscn`：输入、按钮、布局与通关提示。
- `tests/north_16_regression.gd`、`tests/north_16_scene.gd`：第十六关33格、紫目标显示、合法解、混合列/死亡侧路、两窗口真实键鼠与切换撤销。
- `tests/run_tests.gd`：保留的通用逻辑 / 输入回归；早期沙盒仅作为 `tests/fixtures/` 下的测试数据，不作为当前关卡。
- `tests/north_01_regression.gd`：确认坐标、两枚水晶受阻、通关路径、撤销重开与连续输入回归。
- `tests/north_02_regression.gd`、`tests/north_02_scene.gd`：第二关 77 格地形 / 10 枚水晶、实际通关、阻挡、胜利后撤销重开、切关隔离与界面回归。
- `tests/energy_regression.gd`：压力保持 / 解除、移动与视线、死亡只能撤销复活、未确认边界的独立测试。
- `tests/global_energy_regression.gd`：全局 AND 在不同数据分组下的一致性、跨组交接 / 关门死亡、原子撤销和未定义恢复保护。
- `tests/north_03_regression.gd`、`tests/north_03_scene.gd`：第三关解法、352 状态可达性、完整状态撤销重开、切关隔离、真实输入与画面适配。
- `tests/bush_and_group_regression.gd`：草丛阻挡、全部 8 种三板组合、混合压力来源、原子交接、死亡撤销与数据校验。
- `tests/north_04_regression.gd`、`tests/north_04_scene.gd`：第四关 42 格布局、实际通关、草丛受阻、三板开门、撤销重开、切关与重复输入。
- `tests/green_pull_regression.gd`：四方向单拉、连列仅拉近的一枚、不可推、侧移、受阻、角色隔离、机关 / 死亡撤销与 1,000 次随机动作完整逆序撤销。
- `tests/north_05_regression.gd`、`tests/north_05_scene.gd`：第五关解法、实际输入、绿色形象 / 拉动统计、切关与两种窗口尺寸。
- `tests/north_06_regression.gd`、`tests/north_06_scene.gd`：第六关 77 格 / 七水晶、单板开闭、受阻拉动、压力接替、过门、通关和完整撤销；复用既有绿色死亡夹具。
- `tests/north_07_regression.gd`、`tests/north_07_scene.gd`：187 格确认布局、补正地板、152 步合法通关、两门同步、闭门受阻、完整撤销重开、切关与真实渲染。
- `tests/north_08_regression.gd`、`tests/north_08_scene.gd`：42 格确认布局、三紫晶 / 三草 / 三板、56 步通关、压力交接、三处草阻挡、撤销重开和历史隔离。
- `tests/blue_swap_regression.gd`：四向首目标、输入方向限定与目标优先、角色隔离、遮挡、压力 / 死亡原子撤销和未定义保护。
- `tests/north_09_regression.gd`、`tests/north_09_scene.gd`：确认坐标、9 次操作通关、真实方向键 / WASD / 屏幕方向被动交换、重复输入、胜利撤销重开和切关隔离。
- `tests/north_10_regression.gd`、`tests/north_10_scene.gd`：77格确认布局与4号更正、54次方向输入通关、首目标交换、闭门阻挡、压板接替、撤销重开及切关隔离。
- `tools/search_north_10.py`：保留水晶身份、考虑视线与机关结算的独立可达性搜索。
- `tests/north_11_regression.gd`、`tests/north_11_scene.gd`：77格地板 / 墙 / 界外、九板512种AND组合、19次方向通关、绿色显示 / 橙晶交换、色彩无规则影响、撤销重开和历史隔离。
- `tools/check_north_11.py`：独立校验构造路线的方向首目标、占用与九板联动，不宣称穷举或最优。
- `tests/north_12_regression.gd`、`tests/north_12_scene.gd`：42格确认布局、三色身份、26次方向通关、两处草丛及门遮挡、压板交接、撤销重开和历史隔离。
- `tools/search_north_12.py`：独立占用搜索与保留颜色身份的路线复核，首次胜利即停止。
- `tests/chain_push_regression.gd`：2 / 3 / 4 / 8 / 60 枚水晶的四方向连推、原子阻挡、边界、空格截断、旁侧水晶、撤销重开和输入去重。
- `tests/scene_smoke.gd`：真实场景键鼠、通关状态与两种窗口尺寸检查。
- `tools/verify.py`：一键验证。

地图使用 schema 1。`terrain` 以 `#` / `.` 表示墙 / 地板，宽高各 1 至 64；`player`、`crates`、`exit` 使用 `[x,y]` 整数坐标。`hero_kind` 为 `red` / `green` / `blue`，省略默认红色；`crystal_colors` 按身份指定 `blue` / `purple` / `blue_purple` / `orange` / `pink` / `purple_pink`，颜色仅影响显示。前十二关均为 `is_temporary=false`、`objective=player_on_exit`、`targets=[]`。第十三关使用可选 `heroes` 数组与 `active_hero`，以及 `exits` / `objective=all_heroes_on_exits`，仍为 schema 1；旧格式不迁移。`exit_color` 为 `yellow` / `green` / `red` / `purple`（紫色仅显示普通终点，不传送），默认 yellow；非法、重复、墙内或越界坐标会被拒绝。`bushes` 定义独立草丛，`energy_links` 定义压力板与屏障。第三 / 六 / 七 / 十关用单板 `plate`，第四 / 八 / 十一 / 十二关用 `plates` 与 `activation=all`。`mechanism_color` 可为 `yellow`（默认）或 `green`，仅为机关显示配色；`void_cells` 可标记地图内不可通行地形为留空的界外，不改变碰撞 / 视线。

## 验证

```bash
cd /workspace/stardown
python3 tools/verify.py
```

该命令执行资源导入、所有脚本解析、通用逻辑、红推 / 绿拉 / 蓝色交换与机关回归、十五关回归、默认场景启动、切关和键鼠检查。已有 X11 显示时加上真实渲染与截图：

```bash
python3 tools/verify.py --visual --display :97
```

本轮云端的临时 Xvfb 在 `/tmp/stardown-tools/xvfb/usr/bin/Xvfb`，它不是游戏依赖，跨会话可能不保留。需要时可在单独云端终端启动：

```bash
/tmp/stardown-tools/xvfb/usr/bin/Xvfb :97 -screen 0 1280x820x24 -nolisten tcp -noreset
```

运行日志与截图在 `artifacts/`，缓存与完整生成目录不纳入 Git；必要的验证摘要和十六关画面保留在 `docs/`。详见[验证记录](docs/VERIFICATION.md)和[结构化摘要](docs/verification-summary.json)。无头模式只能证明逻辑 / 场景运行，画面结论来自实际 X11 / Mesa 渲染。

中文字体已随工程附带，来自本云端 Debian 包内的 [Noto CJK](https://github.com/notofonts/noto-cjk)，授权见 [OFL.txt](assets/fonts/OFL.txt)。英雄、水晶、墙、地板、终点和图标均为原创几何图形，没有将原作截图打包进工程。命令行参数参考 [Godot 官方文档](https://docs.godotengine.org/en/stable/tutorials/editor/command_line_tutorial.html)。


## 第十三关：红蓝双英雄与双终点

7×7 用户确认布局，编号为 `y*7+x+1`，坐标从零开始。`R` 红英雄 (2,2)，`H` 蓝英雄 (2,4)，初始选中蓝；`B/V` 两水晶 (0,1)/(0,4)，`G` 两个红色圆形终点 (0,2)/(0,5)，`Y` 黄板，`E` 能量格，`#` 墙：

```text
...#...
B#...Y.
G#R#...
#####E#
V#H#...
G#...Y.
...#...
```

C 循环切换当前英雄，屏幕下方也有「切换 C」。当前英雄有明亮描边与脚下选择圈；非当前英雄压暗并保留红蓝本色，不与未来灰英雄混淆。只有选中英雄接收方向输入，其他英雄继续占位、压板，也能被推动 / 交换。被动移位不发动该英雄能力，不更改选中身份。

红英雄可推紧密连排的英雄和水晶，含混合长列；末端阻挡则整次不动。蓝英雄按本次输入方向与首个可见英雄或水晶交换，否则走一格。所有位置、压力、屏障和死亡在一次动作后统一结算。两黄板需同时被任意英雄或水晶占据，能量格才开放；任意英雄死亡都禁止 C、移动、重开和切关，只能撤销复活。两名英雄须同时分占不同终点，水晶占目标无效。

构造并独立验证的路线：`DRRRCURRRCULLLULLDDCLLLDLLU`。`UDLR` 为当前英雄方向，`C` 仅切换选择；共 **24 次实际行动 + 3 次不计数切换（27 次输入事件）**，其中 2 次交换、0 推拉。不是最短或穷举声明。第8次实际行动（输入事件9）两英雄压满双板；第9次实际行动（事件11）蓝人与红人隔开放能量格交换，选中仍是蓝；第17次实际行动（事件19）蓝人到上目标；第24次实际行动（事件27）红人到下目标。只需移动上方水晶，下方水晶保持原位即可通关。

多英雄数据增量例子（完整配置见 `levels/north_13.json`）：

```json
{
  "heroes": [
    {"id":"red", "kind":"red", "position":[2,2]},
    {"id":"blue", "kind":"blue", "position":[2,4]}
  ],
  "active_hero":"blue",
  "exits":[[0,2],[0,5]],
  "exit_color":"red",
  "objective":"all_heroes_on_exits"
}
```

`heroes` 不与旧 `player` / `hero_kind` 混用，`exit` 不与 `exits` 混用。英雄 ID、坐标和目标须唯一且合法，全部英雄目标数量须等于英雄数。原十二关仍直接加载旧 JSON，同一 `GridState` 内规范化为单英雄，不复制引擎。测试见 `multi_hero_regression.gd`、`north_13_regression.gd`、`north_13_scene.gd`；独立合法路线检查 `python3 tools/check_north_13.py`。


第十三关实际画面：[初始蓝高亮](docs/screenshots/level_13_initial.png)、[切换红高亮](docs/screenshots/level_13_selected_red.png)、[双板开放](docs/screenshots/level_13_both_plates.png)、[英雄互换](docs/screenshots/level_13_hero_exchange.png)、[第一名英雄到目标](docs/screenshots/level_13_first_goal.png)、[双英雄胜利](docs/screenshots/level_13_completed.png)、[小窗口蓝](docs/screenshots/level_13_compact_blue.png)、[小窗口红](docs/screenshots/level_13_compact_red.png)。

[第十三关修正版通关视频](video/chapter_01/level_13.mp4)已从实际Godot初始到双英雄胜利重新录制：21.2秒 / 636帧，24次实际行动、3次不计数选择事件。三次C保持当时4/8/17的操作数，最终显示24。全部十三段视频完整解码与独立合法回放通过，原十二份媒体保持。


### 切换与撤销的最新约定

用户更正：**“切换不算操作不用撤销”**。C 和屏幕切换只改变当前选择，不增加步数 / 操作，不显示游戏切换计数，也不创建撤销快照。选择属于操作界面状态，世界快照不保存选中身份。撤销直接恢复最近一次真实移动 / 推动 / 交换，保持用户当前选择；无历史时，切换再撤销仍保留选择。重开 / 重新载入才恢复初始蓝英雄选中。任意英雄死亡后仍禁止C、重开和切关，只能撤销复活。

求解和录像将两类数据分开：`moves=24` 是实际行动数，`input_events=27` 是总按键事件数，`selection_events=3` 仅为控制事件记录，不是可撤销游戏统计。


## 第十四关：红绿协作与单板双门

10×7 用户确认布局；最新纠正**6号(5,0)为墙**，覆盖核对图的旧标记；8/9/29/50号为空地、64–66号为墙，其余确认格保留。红英雄(1,1)、绿英雄(1,5)，初始选红；唯一紫晶(3,1)，两个终点(6,0)/(6,6)，单黄板(9,3)，两个能量门(8,1)/(8,5)。以下`R`红人、`H`绿人、`V`水晶、`X`终点、`Y`黄板、`E`能量门：

```text
...###X..#
.R.V.###E#
####.#....
####....#Y
...#.#....
.H...###E#
...###X..#
```

复用同一引擎：红可推英雄 / 水晶混合连续列，绿只在背离紧邻水晶移动时自动拉最近一枚，不推水晶、不拉英雄；非当前英雄被推时不发动能力。C和屏幕按钮只选择，不计操作、不进撤销，撤销保持当前选择；重开恢复红选中。两名英雄同时分占不同目标才胜利。单黄板由任意英雄或水晶保持时双门同时消失，离板同时恢复；任意英雄死亡仍只能撤销复活。

合法路径 `RRCRRRUUUDCRCRCDCRCDRCUCRDRCRCUCRCUCDCRUULLCDLDDLL`，**35次实际方向行动 +15次免费选择 =50个输入事件**，6次推动、4次单晶拉动、0交换。独立身份占用搜索扩展20,282、访问22,496个状态，在首次胜利时停止，尚余2,214个排队状态，不宣称穷举或最优。

实际行动15红人推动水晶与绿人混合列，非当前绿人不多拉；行动24绿人占板双门开放；行动26红人过上门，29到上目标；行动30绿人自动拉紫晶接替压板，32过下门，35到下目标通关。不按英雄颜色匹配终点。普通几何配色用于可读性，无颜色匹配条件。

新数据 `levels/north_14.json`、解法 `levels/solutions/north_14.json`，独立搜索 / 回放 `python3 tools/search_north_14.py`，模型与实际输入测试 `tests/north_14_regression.gd` / `tests/north_14_scene.gd`。顶部14关入口在1280×820与960×615适配；鼠标测试将逻辑坐标按视口最终变换转换到实际窗口坐标，小窗口也以真实按钮事件验证绿色选中。第十四关已在实现提交后录制 `video/chapter_01/level_14.mp4`，第十三关修正版保留。


第十四关实际画面：[初始](docs/screenshots/level_14_initial.png)、[绿选中](docs/screenshots/level_14_selected_green.png)、[混合连推](docs/screenshots/level_14_mixed_push.png)、[绿占板](docs/screenshots/level_14_hero_plate.png)、[红过上门](docs/screenshots/level_14_red_gate.png)、[首目标](docs/screenshots/level_14_first_goal.png)、[紫晶接替](docs/screenshots/level_14_crystal_plate.png)、[绿过下门](docs/screenshots/level_14_green_gate.png)、[通关](docs/screenshots/level_14_completed.png)、[离板恢复](docs/screenshots/level_14_released.png)、[小窗口红](docs/screenshots/level_14_compact_red.png)、[小窗口绿](docs/screenshots/level_14_compact_green.png)。离板是合法规则侧路，未混入正式通关录像。

[第十四关完整通关视频](video/chapter_01/level_14.mp4)为35秒 / 1050帧，包含35次实际行动、15次不计数切换、6推4拉；红 / 绿均走过对应能量门，再同时分占两目标。十四段视频已完整解码、独立合法回放并核对编码与时长，详见[视频记录](video/README.md)。


## 第十五关：蓝绿协作、两晶双板与能量通道

11×7用户确认布局；**25号(2,2)按最新纠正不可走，47号(2,4)也不可走**。上平台x=4..8/y=0仅由(6,1)接主平台，下方只保留(5,5)/(6,5)/(6,6)/(7,6)通道。蓝英雄(4,0)、绿英雄(3,3)，初始选蓝；粉晶(8,0)、蓝紫晶(7,6)，双目标(0,2)/(0,4)，黄板(4,3)/(10,3)，黄色能量(2,3)。以下S蓝人、H绿人、P粉晶、V蓝紫晶、G终点、Y黄板、E能量：

```text
####S...P##
######.####
G.#........
..EHY....#Y
G.#........
#####..####
######.V###
```

没有新增机制。蓝按本次方向与首个可见英雄或水晶被动交换，无目标才走一步，不能推拉；绿只自动拉背后相邻一个水晶，不推、不拉英雄。C只选择，不计操作、不写历史，Undo恢复最近实际行动且保留当前选择；当前高亮，其他保留蓝 / 绿本色压暗。两板同时被任意英雄 / 水晶占据才能开能量格，关闭挡移动和视线；两英雄分占不同目标才通关，无固定对应。

路线 `CURRRUUCRDCRRCURCDCLLCDRURCDDCRRCRCDCRLDDDDRCDLLLLDUCLCUULDLCUULLLULLLCLCRCUCLLDL`：**61次实际行动 +20次免费选择 =81次输入**，11次单晶拉动、7次自动交换、0推。其中三次为英雄互换，两枚水晶均参与。独立身份占用BFS扩展1,019,474、访问1,044,508个状态，首次存活胜利停止，尚余25,034排队；不宣称穷举或最优。

行动7蓝人优先交换近绿人而非远粉晶，12交换粉晶至上通道，13绿人单拉粉晶下行；32蓝人交换底部蓝紫晶；45绿人和粉晶压满双板；52蓝人穿能量格，55绿人拉蓝紫晶接替近板，56蓝绿隔开放能量互换；57绿到上目标，61蓝到下目标。最终粉晶 / 蓝紫晶分别停在(10,3)/(4,3)，保持开门。

本关还可用合法侧路验证死亡：走到行动52蓝人位于开放能量格，C选绿后向下离开近板，能量恢复压死未选中蓝人；方向、C、R和切关全部被锁住，唯Undo复活蓝人并保留绿选中。此侧路只作机制测试，不混入正式通关视频。

数据 `levels/north_15.json`，解法 `levels/solutions/north_15.json`，独立搜索与身份回放 `python3 tools/search_north_15.py`，模型 / 实际输入测试 `north_15_regression.gd` / `north_15_scene.gd`。复用既有核心规则，只为蓝绿阵容补齐说明与交换 / 拉动统计，15关导航在1280×820及960×615适配。已在实现提交后录制 `video/chapter_01/level_15.mp4`，前十四关及其视频保持。


第十五关实际画面：[初始](docs/screenshots/level_15_initial.png)、[绿选中](docs/screenshots/level_15_selected_green.png)、[首次英雄交换](docs/screenshots/level_15_first_hero_exchange.png)、[粉晶单拉](docs/screenshots/level_15_pink_pull.png)、[近晶优先](docs/screenshots/level_15_nearest_crystal.png)、[底部晶交换](docs/screenshots/level_15_lower_crystal.png)、[双板开门](docs/screenshots/level_15_all_plates.png)、[蓝过门](docs/screenshots/level_15_blue_gate.png)、[蓝紫晶接替](docs/screenshots/level_15_crystal_handoff.png)、[隔门英雄换位](docs/screenshots/level_15_gate_hero_exchange.png)、[首目标](docs/screenshots/level_15_first_goal.png)、[通关](docs/screenshots/level_15_completed.png)、[侧路死亡](docs/screenshots/level_15_death_inactive_blue.png)、[撤销复活](docs/screenshots/level_15_revived_blue.png)、[小窗口蓝](docs/screenshots/level_15_compact_blue.png)、[小窗口绿](docs/screenshots/level_15_compact_green.png)。死亡 / 复活是本关合法侧路验证，不混入正式录像。

[第十五关完整通关视频](video/chapter_01/level_15.mp4)：53.6秒 / 1608帧，61实际行动、20免费选择、11拉7换0推，七次交换（其中三次英雄互换）与两枚水晶全部参与。十五段视频已完整解码与独立合法回放，详见[视频记录](video/README.md)。


## 第十六关：红蓝协作、单板能量与紫色双终点

11×3用户确认布局，完整第三行，**33号(10,2)不可走**。红英雄(5,1)、蓝英雄(5,2)，初始选蓝；唯一粉紫晶(10,1)、黄板(1,1)、黄色能量(7,1)、紫色圆盘目标(9,0)/(9,2)。其余地形按下图，界外阻挡。`R`红人、`S`蓝人、`V`粉紫晶、`G`普通紫色终点、`Y`黄板、`E`能量：

```text
...##.##.G#
.Y...R.E..V
...##S##.G#
```

紫色圆盘只是终点配色，不增加传送或其他机制。红人可推动英雄 / 水晶混合整列；蓝人仅按本次输入方向与首可见英雄 / 水晶被动交换，否则走一步。C与屏幕切换只选中，不计行动、不写历史；Undo恢复最近实际行动并保持当前选择。单板由任意英雄或水晶压住开门；离板恢复移动 / 视线阻挡，任意英雄死亡只能撤销。两英雄同时分占不同目标才胜利。

合法路线 `ULLLLRCURRRRCLUCLD`：**15次实际行动 +3次免费切换 =18次输入**，3次交换、0推拉。独立身份占用BFS扩展2,298、访问2,757个状态，在首次存活胜利停止，剩余459排队，不宣称穷举或最优。行动1蓝与红交换；5蓝踩板；6与远端粉紫晶交换，水晶接替压板；9红通过能量；12蓝优先与近红人交换；13蓝正常走到上目标，15红到下目标胜利，无传送。

另用本关合法侧路验证红推混合列及死亡：`ULLLLRCURRRRCLLCLLLLLLLL`为21次行动 / 8推 / 4换，末步同时推水晶与蓝人到左端，再推被边界原子阻挡；一次Undo恢复整列。正式路线行动9之后 `CLLCLLLC` 将红留在开门格、蓝留在黄板；蓝向下离板会压死未选中红，C / 移动 / 重开 / 切关均锁定，Undo复活红且保留蓝选择。这些是测试侧路，不混入正式通关录像。

配置 `levels/north_16.json`、解法 `levels/solutions/north_16.json`、独立搜索 `python3 tools/search_north_16.py`，模型 / 真实输入测试 `north_16_regression.gd` / `north_16_scene.gd`。关卡入口改为每行8个的两行按钮，1280×820与960×615仍清晰可见。复用全部游戏核心，仅扩展已校验的 `exit_color=purple` 显示枚举与普通圆盘绘制。前十五关地图、解法、MP4、回放保持原字节；第十六关须在实现提交后才录制。

第十六关实际画面：[初始蓝选中](docs/screenshots/level_16_initial.png)、[红选中](docs/screenshots/level_16_selected_red.png)、[蓝压板](docs/screenshots/level_16_blue_plate.png)、[水晶接替](docs/screenshots/level_16_crystal_handoff.png)、[红过门](docs/screenshots/level_16_red_gate.png)、[双目标胜利](docs/screenshots/level_16_completed.png)、[合法混合连推](docs/screenshots/level_16_mixed_push.png)、[未选中红死亡](docs/screenshots/level_16_death_inactive_red.png)、[撤销复活](docs/screenshots/level_16_revived_red.png)、[小窗口蓝](docs/screenshots/level_16_compact_blue.png)、[小窗口红](docs/screenshots/level_16_compact_red.png)。
