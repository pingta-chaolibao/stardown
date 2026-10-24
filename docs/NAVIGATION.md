# 横向虚拟选关主界面

启动显示第一章19张真实关卡的数据目录，只有可视窗口和两侧有限预载范围绑定到卡片对象。鼠标拖动/滚轮、触屏横滑、方向左右/Home/End/PageUp/PageDown与Enter/空格均可操作。按卡片进入关卡，Back/Esc返回。选关保存的是浏览位置和逻辑选择，没有伪造关卡完成、锁关、星数或奖励。

## 结构与边界

- `scripts/view/virtual_level_strip.gd`：数字content_extent/scroll_offset，独立item_count/Callable数据源；步距282（卡片260、间隔22）。对象池上限min(N,ceil(viewport_width/282)+5)，两侧各两项预载，槽位index%capacity。滚动仅移动/重绑池内节点。窗口容量变化才增减卡片，数据长度不决定节点数量。
- `scripts/view/level_card.gd`：程序绘制底板、真实布局缩略图、关号/能力/尺寸/晶体数；保留已有字体。hover/pressed/selected/focus有不同反馈，样式缓存，不创建每关场景/模型。卡片没有子节点和焦点/索引闭包。
- `scripts/view/level_menu.gd`：持久章节界面和真实19关数据目录，不含合成关卡。列表自身保有键盘焦点，逻辑索引与被回收节点分离。
- `scripts/main.gd`：菜单与游戏界面互斥显示；移除旧全关卡按钮。进入关卡才重置该关模型；返回本身不改变世界，菜单按键不操作隐藏游戏。菜单和池不随游戏UI重建而销毁。

鼠标/单指拖动超过10px即抑制点击，离开原卡片也继续捕获释放；取消触摸不转换为模拟鼠标点击。一次只捕获一个触点。滚轮/触控板平移和有限惯性更新横向偏移，浏览中的选择随可见中心移动。键盘可以直接首尾/翻页，进入时停止惯性并冻结上下文。resize/source更新取消按下手势、夹取偏移，防止回收后旧点击串关。焦点留在稳定视口，不移交给卡片。

任意英雄死亡时，返回按钮禁用，Esc/back_to_menu/select_level同时拒绝。只能Undo复活，不能靠主界面重进绕过。C免费与Undo保留当前英雄不变。`start_in_level`仅为录制/测试工具的启动前标志；默认关闭，不提供运行中死亡复位入口。

## 运行证据

`tests/navigation_scene.gd`先真实点击进入全部19关再返回，断言同一菜单/卡片ID、偏移/选择与各关初始模型；另以合法死亡侧路验证导航锁。独立1000/5000项测试源只存在于测试创建的列表中，不修改正式目录。首/中/末跳转、快速逆向、绑定后的点击、取消/重绑/缩放期间的手势、键盘回收焦点、空源释放和真实大小窗口交互均覆盖。

1180逻辑宽：1000和5000项均为10卡片/11个列表子树节点。360/480宽为7卡片，1550宽为11卡片；测试扩缩容累计创建17卡片、156次提供器调用。示例观测JSON记录在`docs/verification-summary.json`的level_navigation。计时为本云端软件渲染下含事件等待的测试总时长，不能视为帧率基准或所有设备保证。

完整回归134步骤/61解析全部通过；新导航无头与X11测试分别262/274项。原19段视频不重录，76份关卡交付文件和章节清单/能量短片原字节保留。底层core/input/board全部未改，旧能量像素对照及34事件演示回放通过。1280×820、960×615、1600×820均有实际渲染；5000源另独立调整逻辑视口宽度，验证池大小随容量变化。

## 实际画面

[主界面](screenshots/navigation_main.png) · [末端卡片](screenshots/navigation_last.png) · [关卡内返回入口](screenshots/navigation_in_level.png) · [死亡锁](screenshots/navigation_death_locked.png) · [小窗口](screenshots/navigation_960x615.png) · [宽窗口](screenshots/navigation_1600x820.png)

UI视频会在实现提交后录制到`video/ui/level_navigation.mp4`，与关卡通关视频分开。`tools/record_navigation.gd`只注入真实鼠标/滚轮/触摸/键盘事件，不写滚动、选择索引或世界坐标；`--verify-only`可预演同一流程。正式演示需真实渲染与MovieMaker，不能用静态截图拼接。
