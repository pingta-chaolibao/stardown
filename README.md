# 沉星之序 · 北部英雄第一关（Godot 4 / 2D）

当前关卡按**用户明确确认的文字坐标**实现：11 列 × 3 行，红色玩家、两枚可推动的蓝 / 紫水晶、四格墙和黄色终点。玩家走到黄色格判胜，水晶不需要放在终点。画面使用原创 2D 几何图形，不声称逐像素复刻。

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

实际画面：[初始状态](docs/screenshots/initial.png)、[通关状态](docs/screenshots/completed.png)、[960 × 615 窗口](docs/screenshots/compact.png)。这些是本工程的 Godot 渲染结果。

## 确认的地图

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

## 操作与通关

| 操作 | 按键 / 界面 |
| --- | --- |
| 移动一格 | 方向键或 WASD；也可点击方向按钮 |
| 撤销最近一次有效移动 | Z、U、Backspace，或“撤销”按钮 |
| 恢复关卡初始状态 | R，或“重开”按钮 |

每次输入让英雄前进一格；相邻水晶紧密排成直线时，可以将整列一起向前推动一格。水晶数量没有 3 或 4 枚的硬上限，受地图空间限制。先扫描整列，只有列末是可走空地才一次移动英雄与全部水晶；列末为墙、地图边界或不可移动障碍时，整次操作不移动、不计步、不写撤销历史。空格会截断水晶列，旁边不在直线上的水晶不会被带动。英雄不能拉水晶。

松开再按可连续操作；长按的系统回声和未松开的重复事件不会多走。步数与推动次数均按成功输入计数，一次推动多枚水晶仍算一步、一次推动。撤销一次恢复上一次整列推动前的全部位置和颜色身份，重开恢复初始状态。

玩家进入黄色终点才判胜。通关后可以撤销最后一步，或重开；撤销恢复玩家、水晶、颜色身份、步数、推动次数和通关状态，重开清空历史并恢复全部初始状态。

一个已验证、两枚水晶均参与的通关路径：**下，右 × 3，上 × 2，右 × 4，下，右**。结果为 **12 步、4 次推动**；蓝水晶最终在 `(5,2)`，紫水晶最终在 `(9,0)`，玩家在 `(9,1)`。这是一条验证路径，不宣称最优解。

## 工程结构与数据

- `levels/north_01.json`：当前用户确认关卡，也是默认主场景读取的地图。
- `scripts/core/level_data.gd`：JSON 解析与坐标校验。
- `scripts/core/grid_state.gd`：不依赖节点、渲染、计时器或物理的独立网格规则及撤销历史。
- `scripts/input/step_input.gd`：按键去重与释放处理。
- `scripts/view/board_view.gd`：只读网格状态的原创几何绘制；适配横向长廊。
- `scripts/main.gd`、`scenes/main.tscn`：输入、按钮、布局与通关提示。
- `tests/run_tests.gd`：保留的通用逻辑 / 输入回归；早期沙盒仅作为 `tests/fixtures/` 下的测试数据，不作为当前关卡。
- `tests/north_01_regression.gd`：确认坐标、两枚水晶受阻、通关路径、撤销重开与连续输入回归。
- `tests/chain_push_regression.gd`：2 / 3 / 4 / 8 / 60 枚水晶的四方向连推、原子阻挡、边界、空格截断、旁侧水晶、撤销重开和输入去重。
- `tests/scene_smoke.gd`：真实场景键鼠、通关状态与两种窗口尺寸检查。
- `tools/verify.py`：一键验证。

地图使用 schema 1。`terrain` 中 `#` 是墙、`.` 是地板，行宽相同，宽高各为 1 至 64。`player`、`crates`、`exit` 使用 `[x,y]` 整数坐标；`crystal_colors` 按水晶身份指定 `blue` / `purple`。当前 `is_temporary=false`，`objective=player_on_exit`，`targets=[]`。非法、重复、墙内或越界坐标会被拒绝。

## 验证

```bash
cd /workspace/stardown
python3 tools/verify.py
```

该命令执行资源导入、所有脚本解析、通用逻辑测试、连推回归、第一关回归、默认主场景启动和键鼠场景检查。已有 X11 显示时加上真实渲染与截图：

```bash
python3 tools/verify.py --visual --display :97
```

本轮云端的临时 Xvfb 在 `/tmp/stardown-tools/xvfb/usr/bin/Xvfb`，它不是游戏依赖，跨会话可能不保留。需要时可在单独云端终端启动：

```bash
/tmp/stardown-tools/xvfb/usr/bin/Xvfb :97 -screen 0 1280x820x24 -nolisten tcp -noreset
```

运行生成的日志与截图在 `artifacts/`，缓存与完整生成目录不纳入 Git；必要的验证摘要和三张画面证据保留在 `docs/`。详见[验证记录](docs/VERIFICATION.md)和[结构化摘要](docs/verification-summary.json)。无头模式使用虚拟渲染器，只能证明逻辑 / 场景运行，画面结论来自实际 X11 / Mesa 渲染。

中文字体已随工程附带，来自本云端 Debian 包内的 [Noto CJK](https://github.com/notofonts/noto-cjk)，授权见 [OFL.txt](assets/fonts/OFL.txt)。英雄、水晶、墙、地板、终点和图标均为原创几何图形，没有将原作截图打包进工程。命令行参数参考 [Godot 官方文档](https://docs.godotengine.org/en/stable/tutorials/editor/command_line_tutorial.html)。
