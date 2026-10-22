# 沉星之序 · 推之英雄（Godot 4 / 2D 基础原型）

**当前只有自编临时测试地图，非原作北部区域第一关。** 用户已确认：红色角色由玩家控制，两枚水晶可以推动，其他障碍是墙体，玩家走到黄色终点判胜；水晶不需要放在目标点。原关截图引用已提供，但此执行环境尚未成功取得可查看的像素，因此原关网格、起点、墙体、水晶与终点坐标尚未核实。当前 12 × 8 布局为自编测试，蓝 / 紫水晶的位置不代表原关。

工程位于选定云端环境的 `/workspace/stardown`。开发、测试与仓库交付均在云端完成，没有读取、迁移或操作用户电脑上的文件。仓库交付分支为 `develop`；没有发布游戏或创建 PR。

## 获取工程

打开 [develop 分支](https://github.com/pingta-chaolibao/stardown/tree/develop)，或[下载 develop 工程 ZIP](https://github.com/pingta-chaolibao/stardown/archive/refs/heads/develop.zip)。将工程在所选云端环境解压后，导入其中的 `project.godot`。源工程包含全部代码、地图、字体、说明和测试，不包含 Godot 引擎与缓存。

仓库附有[初始实际画面](docs/screenshots/initial.png)、[临时目标完成画面](docs/screenshots/temporary-goal.png)和[验证摘要](docs/verification-summary.json)。两张画面均来自云端 Godot 的真实渲染，不是原作关卡截图。

## 运行

本环境已安装 `4.6.3.stable.official.7d41c59c4`。建议用相同版本的 Godot 4 标准版；其他版本尚未验证。不需要 C#、第三方插件或联网运行。中文字体已随工程附带。

在云端 Godot 项目管理器中导入 `project.godot`，打开后按 **F6** 运行 `scenes/main.tscn`，或按 **F5** 运行工程。

云端有图形显示时也可在终端运行：

```bash
cd /workspace/stardown
godot --editor --path .
# 直接运行游戏：godot --path .
```

若云端默认配置目录不可写，可把 Godot 设置和缓存定向到 `/tmp`：

```bash
mkdir -p /tmp/stardown-config /tmp/stardown-data /tmp/stardown-cache
XDG_CONFIG_HOME=/tmp/stardown-config XDG_DATA_HOME=/tmp/stardown-data XDG_CACHE_HOME=/tmp/stardown-cache godot --path /workspace/stardown
```

命令行和无头模式依据 [Godot 官方说明](https://docs.godotengine.org/en/stable/tutorials/editor/command_line_tutorial.html)。`--headless` 可检查逻辑与场景，但使用虚拟渲染器，不能证明画面正常；真实截图检查需要图形显示。

## 操作与范围

| 操作 | 按键 / 界面 |
| --- | --- |
| 移动一格 | 方向键或 WASD；也可点击画面中的四个方向按钮 |
| 撤销最近一次有效移动 | Z、U、Backspace，或“撤销”按钮 |
| 恢复当前地图初始状态 | R，或“重开”按钮 |

每次按下移动一格；长按、系统按键回声与未松开的重复事件不会连续走格。松开再按可继续。窗口失去焦点会清除按键锁定状态。

- 红色小人是只能推的英雄。走向相邻水晶可将其向前推一格；没有拉箱操作。
- 墙、地图边界或第二只水晶会阻挡移动 / 推动；不支持连推多箱。
- 碰墙、受阻推动和重复输入不增加步数，也不写入撤销历史。
- 撤销同时恢复英雄、水晶、步数、推动次数和目标状态。重开清空历史并恢复初始状态。
- 玩家走进黄色终点即完成临时地图；水晶停在终点上不判胜。完成后暂停移动，可撤销或重开；显示“临时目标已达成”，不代表原关通关。
- 没有实现拉箱、机关、敌人或区域切换。终点胜利规则来自用户说明；原关布局还原仍需成功查看截图像素。

临时地图的一个验证走法为：**右 × 5，下，右，上 × 3**。应为 **10 步、7 次推动**，只适用于本测试地图。倒数一步水晶位于终点时不判胜，最后一步玩家进入终点才完成。

## 数据与代码

```text
project.godot                       工程入口与输入动作
scenes/main.tscn                     主场景
levels/temporary_test.json           明确标注来源的临时地图
scripts/core/level_data.gd           JSON 解析、地图数据与校验
scripts/core/grid_state.gd           独立网格规则、状态与撤销历史
scripts/input/step_input.gd          每次物理按键仅产生一次命令
scripts/view/board_view.gd           原创程序绘制；只读逻辑状态
scripts/main.gd                     场景、输入、按钮与提示文字
tests/run_tests.gd                   逻辑、数据与重复输入回归测试
tests/scene_smoke.gd                 实际场景、键鼠、状态与截图检查
tools/verify.py                      一键验证；无需第三方 Python 包
assets/fonts/                       中文字体与 SIL OFL 授权
docs/VERIFICATION.md                本轮检查记录、来源与未验证部分
```

`GridState` 和 `PuzzleLevel` 均为 `RefCounted`，不依赖节点、渲染、计时器、物理或输入事件。画面读取状态，键盘与按钮调用同一命令入口。

地图是 JSON，`terrain` 每行等宽，仅允许 `#` 墙和 `.` 地面；坐标采用左上角为 `[0, 0]` 的 `[x, y]` 整数数组。当前宽、高各限制为 1 至 64 格。`player` 是英雄起点，`crates` 是水晶坐标数组，`exit` 是黄色终点坐标。水晶可以位于终点，英雄与水晶不能重叠。重复、越界、墙内和非整数坐标会被拒绝。可选的 `crystal_colors` 为与水晶数量相同的 `blue` / `purple` 数组；颜色身份在推动、撤销和重开后保持不变。

`schema_version` 当前为 `1`。必须填写 `id`、`title`、`is_temporary`、`source_note`、`terrain`、`player`、`crates`、`targets`、`objective`。本地图 `is_temporary` 为 `true`，来源注明自编；`objective` 为 `player_on_exit`，必须提供有效 `exit`，`targets` 为空。独立测试仍覆盖 `none`（无胜利判定）和 `all_crates_on_targets`（早期基础测试规则，不用于当前地图或原关）；不认识的目标会报错。

可在编辑器中修改主场景根节点的 `level_path`，或编辑现有 JSON 来换测试地图。正式地图仍需先根据截图像素核对，不能用辅助文字坐标替代确认。将来的大尺寸地图可能需要调整视图，当前画面只验证了随附的 12 × 8 临时地图。

## 检查

在云端终端运行：

```bash
cd /workspace/stardown
python3 tools/verify.py
```

脚本顺序执行资源导入、所有 GDScript 的 `--check-only`、逻辑测试、默认主场景启动及实际场景键鼠测试；同时检查退出码和 Godot 错误输出。设置、日志和缓存分别写入临时目录与 `artifacts/`。只读工程会需要一个可写副本。

已有 X11 显示时增加真实渲染检查与截图：

```bash
python3 tools/verify.py --visual --display :97
```

本轮云端使用的临时 Xvfb 路径为 `/tmp/stardown-tools/xvfb/usr/bin/Xvfb`。若该临时文件和显示服务仍存在，上面的命令可直接使用；它们不属于工程依赖，也不保证跨云端会话保留。需要重启显示时可在单独终端运行：

```bash
/tmp/stardown-tools/xvfb/usr/bin/Xvfb :97 -screen 0 1280x820x24 -nolisten tcp -noreset
```

每次运行生成的验证记录位于 `artifacts/verification/report.json`，四张实际渲染截图位于 `artifacts/screenshots/`。生成目录与 Godot 缓存由 `.gitignore` 排除；仓库仅保留 `docs/` 中的验证摘要与两张必要截图。检查结论和限制详见 [验证记录](docs/VERIFICATION.md)。

## 资源

英雄、蓝 / 紫水晶、地面、墙、终点、星点和图标均为本工程原创几何图形，没有将原作截图或素材打包进工程。中文字体从本云端 Debian `fonts-noto-cjk` 包中已有的 Noto Sans CJK 集合提取简体中文字体面，完整保留字形；来源为 [Noto CJK](https://github.com/notofonts/noto-cjk)，授权见 [OFL.txt](assets/fonts/OFL.txt)。工程不需要在线字体服务。
