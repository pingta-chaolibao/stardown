# 沉星之序 · 第一章前五关（Godot 4 / 2D）

第一章前五关按确认的文字网格实现。前四关是红色推之英雄，可整列推水晶；第五关是绿色拉之英雄，只能自动拉最近一枚。第一关是 11 × 3、黄色终点；第二关是 11 × 7、10 枚水晶；第三关加入压力板与能量屏障；第四关加入独立草丛与三板同时触发的屏障；第五关沿用第一关布局，改变英雄能力。第二至五关使用绿色终点，玩家抵达才判胜。画面为原创 2D 几何图形，不声称逐像素复刻。

开发、测试与 Git 操作均在选定云端 `/workspace/stardown` 完成，没有读取、迁移或操作用户电脑。交付分支为 `develop`；不发布游戏、不创建 PR。

## 获取与运行

打开 [develop 分支](https://github.com/pingta-chaolibao/stardown/tree/develop)，或[下载工程 ZIP](https://github.com/pingta-chaolibao/stardown/archive/refs/heads/develop.zip)。在所选云端环境解压，使用 Godot 导入其中的 `project.godot`，按 **F5** 运行。

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

## 通关演示视频

| 第一章关卡 | 实际运行视频 | 时长 |
| --- | --- | --- |
| 第一关 | [观看 / 下载 MP4](video/chapter_01/level_01.mp4) | 12.2 秒 |
| 第二关 | [观看 / 下载 MP4](video/chapter_01/level_02.mp4) | 21.2 秒 |
| 第三关 | [观看 / 下载 MP4](video/chapter_01/level_03.mp4) | 17.6 秒 |
| 第四关 | [观看 / 下载 MP4](video/chapter_01/level_04.mp4) | 25.4 秒 |

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

## 操作与通关

| 操作 | 按键 / 界面 |
| --- | --- |
| 切换第一至第五关 | 顶部关卡按钮；存活时可切换，从该关初始状态开始，清空撤销历史 |
| 移动一格 | 方向键或 WASD；也可点击方向按钮 |
| 撤销最近一次有效移动 | Z、U、Backspace，或“撤销”按钮 |
| 恢复关卡初始状态 | 存活时按 R，或“重开”按钮；死亡时只能撤销 |

每次输入让英雄前进一格。红英雄可将相邻直线整列水晶推一格，没有 3 或 4 枚的硬上限；只有列末可走且为空才原子移动，受阻不计数、不写历史。空格截断水晶列，旁侧水晶不被带动。红英雄不能拉。绿英雄只能在背离紧邻水晶移动时自动拉最近一枚，不能推或拉整列。

松开再按可连续操作；长按回声和未松开的重复事件不会多走。步数、推动、拉动分别计数，一次整列推仍只算一步 / 一推。撤销一次恢复上次推、拉或行走前的全部位置、颜色身份、统计与机关生死状态，重开恢复初始状态。

存活玩家进入当前关卡的终点才判胜（第一关黄色、第二至五关绿色）。通关后可以撤销最后一步，或重开；撤销恢复玩家、水晶、颜色身份、步数、推动 / 拉动次数、压力、屏障、生死和通关状态，重开清空历史并恢复全部初始状态。

第一关已验证、两枚水晶均参与的通关路径：**下，右 × 3，上 × 2，右 × 4，下，右**。结果为 **12 步、4 次推动**；蓝水晶最终在 `(5,2)`，紫水晶最终在 `(9,0)`，玩家在 `(9,1)`。这是一条验证路径，不宣称最优解。

## 工程结构与数据

- `levels/north_01.json` 至 `levels/north_05.json`：五关数据，默认进入第一关。
- `levels/solutions/`：逐输入验证的五关通关路径，供测试与演示回放使用。
- `scripts/core/level_data.gd`：JSON 解析与坐标校验。
- `scripts/core/energy_rules.gd`：纯占用谓词和机关结算，提供可配置压力来源。
- `scripts/core/bush_obstacle.gd`：独立静态草丛类型，明确不可移动 / 交换与阻挡能力。
- `scripts/core/hero_rules.gd`：红推 / 绿拉能力，未支持的角色数据会被拒绝。
- `scripts/core/grid_state.gd`：不依赖节点、渲染、计时器或物理的独立网格规则及撤销历史。
- `scripts/input/step_input.gd`：按键去重与释放处理。
- `scripts/view/board_view.gd`：只读网格状态的原创几何绘制；适配横向长廊。
- `scripts/main.gd`、`scenes/main.tscn`：输入、按钮、布局与通关提示。
- `tests/run_tests.gd`：保留的通用逻辑 / 输入回归；早期沙盒仅作为 `tests/fixtures/` 下的测试数据，不作为当前关卡。
- `tests/north_01_regression.gd`：确认坐标、两枚水晶受阻、通关路径、撤销重开与连续输入回归。
- `tests/north_02_regression.gd`、`tests/north_02_scene.gd`：第二关 77 格地形 / 10 枚水晶、实际通关、阻挡、胜利后撤销重开、切关隔离与界面回归。
- `tests/energy_regression.gd`：压力保持 / 解除、移动与视线、死亡只能撤销复活、未确认边界的独立测试。
- `tests/north_03_regression.gd`、`tests/north_03_scene.gd`：第三关解法、352 状态可达性、完整状态撤销重开、切关隔离、真实输入与画面适配。
- `tests/bush_and_group_regression.gd`：草丛阻挡、全部 8 种三板组合、混合压力来源、原子交接、死亡撤销与数据校验。
- `tests/north_04_regression.gd`、`tests/north_04_scene.gd`：第四关 42 格布局、实际通关、草丛受阻、三板开门、撤销重开、切关与重复输入。
- `tests/green_pull_regression.gd`：四方向单拉、连列仅拉近的一枚、不可推、侧移、受阻、角色隔离、机关 / 死亡撤销与 1,000 次随机动作完整逆序撤销。
- `tests/north_05_regression.gd`、`tests/north_05_scene.gd`：第五关解法、实际输入、绿色形象 / 拉动统计、切关与两种窗口尺寸。
- `tests/chain_push_regression.gd`：2 / 3 / 4 / 8 / 60 枚水晶的四方向连推、原子阻挡、边界、空格截断、旁侧水晶、撤销重开和输入去重。
- `tests/scene_smoke.gd`：真实场景键鼠、通关状态与两种窗口尺寸检查。
- `tools/verify.py`：一键验证。

地图使用 schema 1。`terrain` 以 `#` / `.` 表示墙 / 地板，宽高各 1 至 64；`player`、`crates`、`exit` 使用 `[x,y]` 整数坐标。`hero_kind` 为 `red` / `green`，省略默认红色；`crystal_colors` 按身份指定 `blue` / `purple`。五关均为 `is_temporary=false`、`objective=player_on_exit`、`targets=[]`。`exit_color` 为 `yellow` / `green`，默认 yellow；非法、重复、墙内或越界坐标会被拒绝。`bushes` 定义独立草丛，`energy_links` 定义压力板与屏障。第三关单板 `plate` 保持原样，第四关用 `plates` 与 `activation=all`。

## 验证

```bash
cd /workspace/stardown
python3 tools/verify.py
```

该命令执行资源导入、所有脚本解析、通用逻辑、红推 / 绿拉与机关回归、五关回归、默认场景启动、切关和键鼠检查。已有 X11 显示时加上真实渲染与截图：

```bash
python3 tools/verify.py --visual --display :97
```

本轮云端的临时 Xvfb 在 `/tmp/stardown-tools/xvfb/usr/bin/Xvfb`，它不是游戏依赖，跨会话可能不保留。需要时可在单独云端终端启动：

```bash
/tmp/stardown-tools/xvfb/usr/bin/Xvfb :97 -screen 0 1280x820x24 -nolisten tcp -noreset
```

运行日志与截图在 `artifacts/`，缓存与完整生成目录不纳入 Git；必要的验证摘要和五关画面保留在 `docs/`。详见[验证记录](docs/VERIFICATION.md)和[结构化摘要](docs/verification-summary.json)。无头模式只能证明逻辑 / 场景运行，画面结论来自实际 X11 / Mesa 渲染。

中文字体已随工程附带，来自本云端 Debian 包内的 [Noto CJK](https://github.com/notofonts/noto-cjk)，授权见 [OFL.txt](assets/fonts/OFL.txt)。英雄、水晶、墙、地板、终点和图标均为原创几何图形，没有将原作截图打包进工程。命令行参数参考 [Godot 官方文档](https://docs.godotengine.org/en/stable/tutorials/editor/command_line_tutorial.html)。
