# 关卡通关演示

项目约定：**每完成一关，都必须提供对应的实际游戏通关视频**，保存在仓库根目录 `video/` 下并按章节分组。先完成、验证并提交关卡实现，再录制并另行提交视频与文档。未来关卡沿用此约定。

## 第一章

| 关卡 | 视频 | 时长 / 帧数 | 实际通关 |
| --- | --- | --- | --- |
| 第一关 | [level_01.mp4](chapter_01/level_01.mp4) | 12.2 秒 / 366 帧 | 12 步、4 次推动，黄色终点 |
| 第二关 | [level_02.mp4](chapter_01/level_02.mp4) | 21.2 秒 / 636 帧 | 27 步、12 次推动，绿色终点 |
| 第三关 | [level_03.mp4](chapter_01/level_03.mp4) | 17.6 秒 / 528 帧 | 21 步、4 次推动，压板后通过能量格到绿色终点 |

三份视频分别约 152 KiB、280 KiB、242 KiB，均为 1280 × 820、30 fps、H.264 High、`yuv420p`、MP4 fast-start。仅记录 Godot 游戏视口，无音轨。第一帧为正确初始状态，最后一帧为明确胜利状态；关卡标题和编号始终可见。

画面由 Godot 4.6.3 Movie Maker 实际渲染。`tools/record_playthrough.gd` 只在初始化时选择关卡，之后通过普通键盘按下 / 释放事件回放 `levels/solutions/` 中的路径，不直接修改坐标或强制胜利。每次输入间隔 18 帧（0.6 秒），初始停留 60 帧，胜利停留 90 帧，包含每次移动和推动。

第一 / 二关实现先提交于 `e8b88cc2d4e2e6fd32a1a8712af2bd61654237e9`，第三关实现先提交于 `77b208c53142e3b310f4ed2093bc23afb5e7367b`；各自视频均在对应实现提交完成并推送后开始制作。第三关没有改动前两份媒体文件。

## 验证证据

- [媒体、哈希和首尾查看记录](chapter_01/verification.json)
- [第一关合法输入与逐步状态](chapter_01/level_01_replay.json)
- [第二关合法输入与逐步状态](chapter_01/level_02_replay.json)
- [第三关合法输入、压力 / 屏障 / 存活逐步状态](chapter_01/level_03_replay.json)

已用 FFmpeg 完整解码三份 MP4；ffprobe 核对编码、像素格式、尺寸、帧率、帧数和时长；核对 `moov` 在 `mdat` 之前。已从编码后的视频提取并实际查看各自的第一帧、最后一帧，另看过第二关中段与第三关英雄压板 / 水晶压板画面。第三关首帧是 `(0,1)` 的红英雄、`(5,1)` 的紫水晶与激活屏障；末帧英雄在 `(9,1)` 明确胜利，水晶压住 `(1,1)` 的黄板，屏障消失。

逐输入证据经独立 Python 规则回放核对，检查移动、整列推动、颜色身份、压力 / 屏障 / 生死与最终胜利。第三关 77 个不同采样画面，21 次输入均合法，英雄全程存活；没有剪接、瞬移或测试夹具画面。

重新检查已提交的视频：

```bash
python3 tools/check_walkthroughs.py
```

## 在云端重新录制

需要 Godot 4.6.3、真实显示（本云端可用 `:97`）和 FFmpeg。以下以第一关为例；第二 / 三关将编号和文件名改为 2 / `level_02` 或 3 / `level_03`：

```bash
mkdir -p /tmp/stardown-recordings
DISPLAY=:97 LIBGL_ALWAYS_SOFTWARE=1 \
XDG_CONFIG_HOME=/tmp/stardown-config XDG_CACHE_HOME=/tmp/stardown-cache XDG_DATA_HOME=/tmp/stardown-data \
STARDOWN_RECORDING_COMMIT="$(git rev-parse HEAD)" \
godot --path . --display-driver x11 --rendering-method gl_compatibility --audio-driver Dummy \
  --write-movie /tmp/stardown-recordings/level_01.avi --fixed-fps 30 --disable-vsync \
  --script res://tools/record_playthrough.gd -- \
  --level=1 --report=/tmp/stardown-recordings/level_01_replay.json

ffmpeg -i /tmp/stardown-recordings/level_01.avi -an -c:v libx264 -preset medium -crf 23 \
  -profile:v high -vf 'scale=in_range=pc:out_range=tv:in_color_matrix=bt601:out_color_matrix=bt709,format=yuv420p' \
  -pix_fmt yuv420p -color_range tv -colorspace bt709 -color_primaries bt709 -color_trc bt709 \
  -movflags +faststart video/chapter_01/level_01.mp4
```

录制器通过 [Engine.get_write_movie_path](https://docs.godotengine.org/en/stable/classes/class_engine.html#class-engine-method-get-write-movie-path) 确认 Movie Maker 已启用，并检查真实渲染器、每次合法输入及最终胜利。原始 AVI 和临时帧只留在云端 `/tmp` 或 `artifacts/`，不提交仓库。重新录制后须重新核对并更新章节验证记录，不复用旧哈希或首尾查看结论。
