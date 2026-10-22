# 云端基础原型验证记录

日期：2026-10-22（UTC）。工程：`/workspace/stardown`。本次工作仅在选定 stardown 云端环境中执行。

## 起始状态与环境

- 仓库起始为 `work` 分支、无提交、无工程文件；没有待保留的已有用户改动。未创建第二个项目。
- 检查了 `/AGENTS.md`、`/workspace/AGENTS.md`、仓库及可访问的 `/workspace/.agents`、`/workspace/.codex`；没有发现 AGENTS.md 或相关 SKILL.md。
- 已有引擎：`/usr/local/bin/godot` → `/opt/godot/4.6.3/Godot_v4.6.3-stable_linux.x86_64`。引擎实际输出：`4.6.3.stable.official.7d41c59c4`。
- Godot 设置、缓存与用户数据通过 `XDG_CONFIG_HOME`、`XDG_CACHE_HOME`、`XDG_DATA_HOME` 写到 `/tmp`，避开环境中不可写的默认配置目录。
- 没有操作用户电脑或拉取用户电脑文件。仓库交付目标为 `origin/develop`，没有发布游戏或创建 PR。

## 已运行的检查

最终命令：

```bash
cd /workspace/stardown
python3 tools/verify.py --visual --display :97
```

| 检查 | 实际结果 |
| --- | --- |
| Godot 编辑器无头资源导入 | 通过，退出码 0，无错误输出 |
| 全部 7 个 GDScript 的 `--check-only` | 全部通过，退出码 0 |
| 逻辑与输入单元 / 回归测试 | 13 组、4,662 项检查、0 失败 |
| 默认 `project.godot` 主场景启动 | 通过，运行 10 帧正常退出 |
| 无头实际场景测试 | 84 项检查、0 失败；验证场景及键鼠分发，不代表图形渲染 |
| X11 实际渲染与场景测试 | 92 项检查、0 失败；生成 4 张真实截图 |

逻辑检查覆盖碰墙和地图边界、单格移动、单枚水晶推动、前方有墙 / 水晶 / 边界时受阻、不拉水晶、不连推、无效方向、受阻动作不写历史、逐步撤销与计数恢复、重开与历史清空、玩家进入终点才判胜、水晶位于终点不判胜、无需推动也可抵达终点、完成后撤销 / 重开、无目标时不推断胜利、地图与水晶颜色数据校验、颜色身份保留、重复按键与系统回声、释放与焦点丢失、全部按键映射，以及固定随机种子的 1,000 次移动及逆序撤销。早期基础测试的水晶落点目标仅保留为独立回归用例，不用于当前地图或原关。

实际场景检查通过 Godot 的 `Input.parse_input_event` 注入键盘与鼠标事件，使用真实场景的输入处理、按钮 GUI 命中和状态显示；没有以直接触发按钮信号代替鼠标点击。它验证了移动、推箱、按住去重、撤销、重开、临时目标完成、计数与按钮状态，以及 1280 × 820 下可见控件的边界。

当前临时地图的文档走法 **右 × 5，下，右，上 × 3** 已在逻辑和实际场景测试中通过，结果为 **10 步、7 次推动**。它要求玩家进入黄色终点；水晶位于终点时不判胜。这是自编测试地图的验证走法，不是原关解法。

## 真实画面与来源

云端使用 Xvfb 虚拟 X11 显示 `:97`，运行 Godot 的 GL Compatibility 真实渲染路径，实际驱动输出为：

```text
OpenGL API 4.5 (Core Profile) Mesa 25.0.7-2+deb13u1
Using Device: Mesa - llvmpipe (LLVM 19.1.7, 256 bits)
```

驱动有一条“不支持切换 V-Sync 模式”的警告；没有脚本、加载或渲染错误。截图使用真实视口纹理保存，未把无头模式的空渲染器当作画面证据。

已查看初始和临时目标完成截图，确认中文正常显示、红色小人可辨、蓝 / 紫水晶与黄色终点清晰，临时地图 / 非原关声明与操作提示可见。

仓库内保留的画面证据：

- [初始状态](screenshots/initial.png)。
- [临时目标完成](screenshots/temporary-goal.png)。

每次测试生成的完整截图路径：

- `artifacts/screenshots/01_initial.png`：初始状态。
- `artifacts/screenshots/02_pushed.png`：推动一次后的状态。
- `artifacts/screenshots/03_temporary_goal.png`：临时目标达成，显示非原关通关。
- `artifacts/screenshots/04_restarted.png`：重开后初始位置与计数。

引擎已在云端预装，无需重新安装。仅补充了用于画面验证的临时 Xvfb 工具，未修改系统目录或要求提权：

- 来自 [Debian 官方下载页](https://packages.debian.org/trixie/amd64/xvfb/download)，文件为 `xvfb_21.1.16-1.3+deb13u4_amd64.deb`。
- 从 `https://security.debian.org/debian-security/pool/updates/main/x/xorg-server/` 获取，在执行前核对 SHA-256：`893d87bf159b6de077a929fc796a73c39f837d45310b2076e3eeebebb80552b6`。
- 解压位置 `/tmp/stardown-tools/xvfb`；运行时 `-nolisten tcp`，不开放 TCP 显示端口。它是临时验证工具，不随工程打包，也不是游戏运行依赖。

官方命令行、按键回声和视口接口参考：[命令行](https://docs.godotengine.org/en/stable/tutorials/editor/command_line_tutorial.html)、[InputEventKey](https://docs.godotengine.org/en/stable/classes/class_inputeventkey.html)、[Viewport](https://docs.godotengine.org/en/stable/classes/class_viewport.html)。最终结论以实际引擎与测试结果为依据。

仓库内验证摘要为 [verification-summary.json](verification-summary.json)。每次运行的完整结构化记录与逐项日志位于 `artifacts/verification/report.json`、`artifacts/verification/*.log`。脚本会检查退出码以及 `ERROR` / `SCRIPT ERROR` / `FAIL` 输出，避免仅以 Godot 退出码判断成功。完整生成目录与缓存已从 Git 跟踪中排除；`docs/screenshots/` 仅保留上述两张必要画面证据。

## 未运行或未确认

- 用户已确认红色玩家、两枚可推动水晶、墙体，以及玩家到达黄色终点判胜；水晶不需要放在目标点。原关截图引用已提供，但此云端的官方 Library 物化流程返回 `download failed`，本地未生成文件。图片读取接口仅返回图片指针和文字说明，没有可查看的像素；不能据此确认原关网格、起点、墙体、水晶及终点坐标，也没有使用辅助坐标猜地图。当前仍为自编临时布局，不声称还原北部第一关。
- 未测试其他 Godot 版本、Windows / macOS / 移动端、硬件 GPU、实机键盘与长时间性能；键鼠检查是云端引擎中的自动注入。
- 未导出独立可执行文件，也未安装导出模板。交付物为可导入 Godot 的完整源工程。
- 没有导出或发布游戏，也没有创建 PR。仓库交付使用 `develop` 分支；GitHub CI 状态需以该提交的实际记录为准，云端测试通过不等于 GitHub CI 通过。

基础框架已完成。后续拿到完整关卡截图，再核对地图与正式规则。
