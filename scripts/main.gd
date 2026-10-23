extends Control
## Thin application/controller layer; all gameplay state is owned by GridState.

const Level = preload("res://scripts/core/level_data.gd")
const State = preload("res://scripts/core/grid_state.gd")
const KeySteps = preload("res://scripts/input/step_input.gd")
const Board = preload("res://scripts/view/board_view.gd")
const UI_FONT = preload("res://assets/fonts/NotoSansCJKsc-Regular.otf")
const TEXT := Color("e3e9e6")
const MUTED := Color("92a8b5")
const GOLD := Color("dfbb78")
const MINT := Color("9bc9c1")
const LEVEL_PATHS := ["res://levels/north_01.json", "res://levels/north_02.json", "res://levels/north_03.json", "res://levels/north_04.json", "res://levels/north_05.json", "res://levels/north_06.json", "res://levels/north_07.json", "res://levels/north_08.json", "res://levels/north_09.json", "res://levels/north_10.json", "res://levels/north_11.json"]
const LEVEL_TITLES := ["第一关", "第二关", "第三关", "第四关", "第五关", "第六关", "第七关", "第八关", "第九关", "第十关", "第十一关"]

@export_file("*.json") var level_path: String = "res://levels/north_01.json"

var model := State.new()
var key_steps := KeySteps.new()
var board: Board
var moves_label: Label
var pushes_label: Label
var pulls_label: Label
var swaps_label: Label
var progress_label: Label
var status_label: Label
var undo_button: Button
var restart_button: Button
var current_level_index: int = 0
var ui_root: Control


func _ready() -> void:
	var ui_theme := Theme.new()
	ui_theme.default_font = UI_FONT
	ui_theme.default_font_size = 16
	theme = ui_theme
	resized.connect(queue_redraw)
	get_window().focus_exited.connect(key_steps.clear)
	var level := Level.from_file(level_path)
	if not model.load_level(level):
		_show_error(level.error if not level.error.is_empty() else model.last_mechanism_error)
		return
	current_level_index = LEVEL_PATHS.find(level_path)
	_build_ui()
	_refresh("按方向：有可见目标就交换，否则走一格。" if model.level.hero_kind=="blue" else "%s水晶腾出道路，再走到%s。" % ["拉动" if model.level.hero_kind == "green" else "推动", _goal_name()])


func select_level(index: int) -> bool:
	if not model.alive:
		_refresh("英雄已死亡，仅可撤销恢复。", Board.CORAL)
		return false
	if index < 0 or index >= LEVEL_PATHS.size():
		return false
	var definition := Level.from_file(LEVEL_PATHS[index])
	if not model.load_level(definition):
		return false
	current_level_index = index
	level_path = LEVEL_PATHS[index]
	key_steps.clear()
	if ui_root != null:
		remove_child(ui_root)
		ui_root.queue_free()
	_build_ui()
	_refresh("已进入%s，走到%s即可完成。" % [model.level.title, _goal_name()])
	return true


func _goal_name() -> String:
	return "绿色终点" if model.level.exit_color == "green" else "黄色终点"


func _goal_color() -> Color:
	return Color("78dd99") if model.level.exit_color == "green" else GOLD


func _plate_name() -> String:
	return "绿板" if model.level.mechanism_color=="green" else "黄板"


func _mechanism_tint() -> Color:
	return Board.MECHANISM_GREEN if model.level.mechanism_color=="green" else GOLD


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("0b1520"))
	for i in 64:
		var point := Vector2(fmod(i * 173.3 + 23, size.x), fmod(i * 97.7 + 41, size.y))
		draw_circle(point, 1.0 if i % 4 else 1.4, Color(0.45, 0.63, 0.68, 0.12))


func _unhandled_key_input(event: InputEvent) -> void:
	var command := key_steps.command_for_event(event)
	if not command.is_empty() and model.level != null:
		apply_command(command)
		get_viewport().set_input_as_handled()


func apply_command(command: Dictionary) -> void:
	if model.level == null:
		return
	board.blocked = false
	match command.get("action"):
		&"move":
			var direction: Vector2i = command.get("direction", Vector2i.ZERO)
			var result := model.try_move(direction)
			if result in [&"moved", &"pushed", &"pulled", &"swapped", &"cannot_push", &"wall", &"crate_blocked", &"energy_blocked", &"bush_blocked", &"died"]:
				board.facing = direction
			match result:
				&"cannot_push":
					board.blocked = true
					_refresh("蓝色英雄不能推拉；按方向自动交换可见目标。" if model.level.hero_kind=="blue" else "绿色英雄只能拉，不能推；请绕到水晶前方再背离它移动。", GOLD)
				&"swapped":
					_refresh("已与本次输入方向的第一个可见目标交换。")
				&"pulled":
					_refresh("最近一枚水晶跟到英雄原位置，后面的水晶保持不动。")
				&"bush_blocked":
					board.blocked = true
					_refresh("草丛阻挡通行，无法推动或交换。", GOLD)
				&"wall":
					board.blocked = true
					_refresh("前方是墙，换个方向试试。", GOLD)
				&"energy_blocked":
					board.blocked = true
					_refresh("能量屏障阻挡通行，需要压住全部%s。" % _plate_name(), _mechanism_tint())
				&"rule_unresolved":
					_refresh(model.last_mechanism_error, GOLD)
				&"dead", &"died":
					_refresh("英雄已死亡，仅可撤销恢复。", Board.CORAL)
				&"crate_blocked":
					board.blocked = true
					_refresh("整列水晶末端被挡住了，无法推动。", GOLD)
				&"pushed":
					_refresh("相邻水晶整列前进一格。英雄只能推，不能拉。")
				&"moved":
					_refresh("每次按下移动一格；松开后可再次移动。")
				&"complete":
					_refresh("已抵达终点，可撤销或重开。", GOLD)
		&"undo":
			var undone := model.undo()
			_refresh("已撤销最近一步。" if undone else "当前没有可撤销的步骤。")
		&"restart":
			if model.restart():
				board.facing = Vector2i.DOWN
				_refresh("已重开%s。" % model.level.title)
			else:
				_refresh("英雄已死亡，仅可撤销恢复。", Board.CORAL)


func _refresh(message: String, color: Color = MINT) -> void:
	moves_label.text = "%02d" % model.moves
	if pushes_label != null:
		pushes_label.text = "%02d" % model.pushes
	if pulls_label != null:
		pulls_label.text = "%02d" % model.pulls
	if swaps_label!=null:
		swaps_label.text="%02d" % model.swaps
	if model.level.objective == "player_on_exit":
		progress_label.text = "已抵达终点" if model.is_complete() else "玩家抵达即可完成"
	elif model.level.objective == "all_crates_on_targets":
		progress_label.text = "%d / %d 测试落点" % [model.occupied_targets(), model.level.targets.size()]
	else:
		progress_label.text = "未设置胜利判定"
	for link in model.level.energy_links:
		if link["plates"].size() > 1:
			var count := model.pressure_progress(link["id"])
			progress_label.text = "%s · %s %d / %d" % ["已抵达终点" if model.is_complete() else "玩家到终点完成", _plate_name(), count.x, count.y]
	undo_button.disabled = model.history_size() == 0
	restart_button.disabled = not model.alive
	for node_name in ["MoveLeft", "MoveRight", "MoveUp", "MoveDown"]:
		var button := find_child(node_name, true, false) as Button
		if button != null:
			button.disabled = not model.alive
	for index in LEVEL_PATHS.size():
		var button := find_child("Level%02d" % (index + 1), true, false) as Button
		if button != null:
			button.disabled = not model.alive or index == current_level_index
	if not model.alive:
		progress_label.text = "英雄已死亡"
		status_label.text = "英雄已死亡。\n只能撤销到屏障恢复前的状态复活。"
		status_label.add_theme_color_override("font_color", Board.CORAL)
	elif model.is_complete():
		status_label.text = "已抵达终点！\n可撤销最后一步，或重新开始。"
		if model.level.is_temporary:
			status_label.text = "临时目标已达成！\n这是测试布局。"
		status_label.add_theme_color_override("font_color", _goal_color())
	else:
		status_label.text = message
		status_label.add_theme_color_override("font_color", color)
	board.queue_redraw()


func _build_ui() -> void:
	var margin := MarginContainer.new()
	ui_root = margin
	add_child(margin)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 36)
	var layout := _vbox(20)
	margin.add_child(layout)
	_build_header(layout)
	var main_row := _hbox(24)
	main_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(main_row)
	_build_board(main_row)
	_build_sidebar(main_row)
	_build_footer(layout)


func _build_header(parent: VBoxContainer) -> void:
	var row := _hbox(10)
	row.custom_minimum_size.y = 76
	parent.add_child(row)
	var emblem := _label("✦", 52, GOLD)
	emblem.custom_minimum_size.x = 58
	row.add_child(emblem)
	var titles := _vbox(0)
	row.add_child(titles)
	titles.add_child(_label("STARDOWN  /  NORTHERN REALM", 12, MINT))
	titles.add_child(_label("沉星之序", 34, TEXT))
	_spacer(row)
	for index in LEVEL_PATHS.size():
		var button := _button(LEVEL_TITLES[index], "Level%02d" % (index + 1))
		button.disabled = index == current_level_index
		button.custom_minimum_size.x = 68 if LEVEL_PATHS.size() > 10 else 76
		button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		button.tooltip_text = "切换关卡并从初始状态开始"
		button.pressed.connect(select_level.bind(index))
		row.add_child(button)
	# The board already labels its source; keep header space for level navigation.
	if LEVEL_PATHS.size()<=8:
		var badge := _panel(Color("1b2a33"), Color("394c54"), 10)
		badge.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		badge.add_child(_label("用户确认布局  /  原创 2D" if not model.level.is_temporary else "临时测试布局", 13, GOLD))
		row.add_child(badge)


func _build_board(parent: HBoxContainer) -> void:
	var card := _panel(Color("122330"), Color("293e4b"), 18)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(card)
	var content := _vbox(10)
	card.add_child(content)
	var header := _hbox(10)
	content.add_child(header)
	var title := _vbox(2)
	header.add_child(title)
	title.add_child(_label(model.level.title, 20, TEXT))
	var caption := "NORTHERN REALM / %02d     ·     %d × %d" % [current_level_index + 1, model.level.width, model.level.height]
	if model.level.is_temporary:
		caption = "SANDBOX     ·     自编机制测试"
	title.add_child(_label(caption, 12, MUTED))
	_spacer(header)
	var badge := _panel(Color("2d302d"), Color("665d43"), 7)
	badge.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	badge.add_child(_label("布局已确认" if not model.level.is_temporary else "临时", 12, GOLD))
	header.add_child(badge)
	board = Board.new()
	board.name = "Board"
	board.model = model
	board.custom_minimum_size = Vector2(560, 350)
	board.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(board)
	var legend := _hbox(12)
	content.add_child(legend)
	legend.add_child(_label("● 英雄", 13, Board.HERO_BLUE if model.level.hero_kind=="blue" else (Board.HERO_GREEN if model.level.hero_kind == "green" else Board.CORAL)))
	legend.add_child(_label("◆ 水晶", 13, Color("9cc5f5")))
	legend.add_child(_label("◇ 终点", 13, _goal_color()))
	if not model.level.energy_links.is_empty():
		legend.add_child(_label("▣ 压力板", 13, _mechanism_tint()))
		legend.add_child(_label("▤ 能量块", 13, _mechanism_tint()))
	if not model.level.bushes.is_empty():
		legend.add_child(_label("♣ 草丛", 13, Color("a1b76a")))
	_spacer(legend)
	for entry in [["←", Vector2i.LEFT, "Left"], ["↑", Vector2i.UP, "Up"], ["↓", Vector2i.DOWN, "Down"], ["→", Vector2i.RIGHT, "Right"]]:
		var button := _button(entry[0], "Move" + entry[2])
		button.custom_minimum_size = Vector2(36, 36)
		button.tooltip_text = "本方向有可见目标就交换，否则走一格" if model.level.hero_kind=="blue" else "移动一格"
		button.pressed.connect(apply_command.bind({"action": &"move", "direction": entry[1]}))
		legend.add_child(button)


func _build_sidebar(parent: HBoxContainer) -> void:
	var sidebar := _vbox(12 if not model.level.energy_links.is_empty() else 16)
	sidebar.custom_minimum_size.x = 300
	parent.add_child(sidebar)
	var intro := _vbox(6)
	sidebar.add_child(intro)
	intro.add_child(_label("北部英雄  /  %s" % LEVEL_TITLES[maxi(0, current_level_index)], 12, MINT))
	var green := model.level.hero_kind == "green"
	var blue:=model.level.hero_kind=="blue"
	intro.add_child(_label("交换之英雄" if blue else ("拉之英雄" if green else "推之英雄"), 30, TEXT))
	intro.add_child(_label("蓝色小人 · 能走路，不能推拉" if blue else ("绿色小人 · 只能拉，不能推" if green else "红色小人 · 只能推，不能拉"), 16, Board.HERO_BLUE if blue else (Board.HERO_GREEN if green else Board.CORAL)))
	var instructions := _label("可推动紧密排成直线的整列水晶。\n每次前进一格，列末受阻则整列不动。", 14, MUTED)
	if blue:
		instructions.text="按方向键 / WASD：只查看该方向。\n有可见英雄或水晶就与第一个交换；\n没有目标才走一格，不能推拉。"
		if not model.level.energy_links.is_empty():
			instructions.text="按方向：有可见目标就与第一个交换。\n没有目标才走一格，不能推拉。"
	elif green:
		instructions.text = "背离相邻水晶移动，自动拉一枚。\n后面的水晶不跟随，不能推水晶。"
	elif not model.level.bushes.is_empty():
		instructions.text = "整列水晶每次推一格，末端受阻则不动。\n草丛挡通行与视线，不能推动或交换。"
	intro.add_child(instructions)
	if not model.level.energy_links.is_empty():
		var rules := "英雄或水晶压住%s时，能量块消失。\n压力解除后恢复，格内英雄会死亡。" % _plate_name()
		if model.level.energy_links[0]["plates"].size() > 1:
			var count: int = model.level.energy_links[0]["plates"].size()
			var number: String = {3:"三",9:"九"}.get(count,str(count))
			rules = "%s块%s同时受压才开门。\n压力解除后恢复，格内英雄会死亡。" % [number,_plate_name()]
		intro.add_child(_label(rules, 13, _mechanism_tint()))
	var stats := _hbox(12)
	sidebar.add_child(stats)
	moves_label = _stat(stats, "操作" if blue else "步数", "Moves")
	pushes_label = null
	pulls_label = null
	swaps_label=null
	if blue:
		swaps_label=_stat(stats,"交换","Swaps")
	elif green:
		pulls_label = _stat(stats, "拉动", "Pulls")
	else:
		pushes_label = _stat(stats, "推动", "Pushes")
	var goal_card := _panel(Color("262d2d"), Color("5a5541"), 16)
	sidebar.add_child(goal_card)
	var goal := _vbox(5)
	goal_card.add_child(goal)
	goal.add_child(_label("◇  通关目标" if not model.level.is_temporary else "◇  临时目标", 14, _goal_color()))
	var objective_text := "走到%s" % _goal_name() if model.level.objective == "player_on_exit" else "将水晶推至测试落点"
	if model.level.objective == "none":
		objective_text = "自由验证移动与推动"
	var objective_label := _label(objective_text, 18, TEXT)
	objective_label.name = "Objective"
	goal.add_child(objective_label)
	progress_label = _label("", 13, _goal_color())
	progress_label.name = "TargetProgress"
	goal.add_child(progress_label)
	goal.add_child(_label("水晶不需要停在终点", 12, MUTED))
	status_label = _label("", 14, MINT)
	status_label.name = "Status"
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.custom_minimum_size = Vector2(300, 66)
	status_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sidebar.add_child(status_label)
	var actions := _hbox(12)
	sidebar.add_child(actions)
	undo_button = _button("撤销   Z", "Undo")
	undo_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	undo_button.pressed.connect(apply_command.bind({"action": &"undo"}))
	actions.add_child(undo_button)
	restart_button = _button("重开   R", "Restart")
	restart_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	restart_button.pressed.connect(apply_command.bind({"action": &"restart"}))
	actions.add_child(restart_button)


func _build_footer(parent: VBoxContainer) -> void:
	var footer := _vbox(5)
	parent.add_child(footer)
	var controls:="方向键 / WASD  移动     ·     Z / U / Backspace  撤销     ·     R  重开     ·     长按不连走"
	if model.level.hero_kind=="blue":
		controls="方向键 / WASD  有目标交换，否则走一格     ·     Z / U / Backspace  撤销     ·     R  重开     ·     长按不连动"
	footer.add_child(_label(controls,14,TEXT))
	var note := "依据确认的北部关卡网格制作 · 原创 2D 几何图形"
	if model.level.is_temporary:
		note = "临时测试布局"
	footer.add_child(_label(note, 13, MUTED))


func _stat(parent: HBoxContainer, caption: String, node_name: String) -> Label:
	var panel := _panel(Color("172936"), Color("2a414f"), 12)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(panel)
	var column := _vbox(0)
	panel.add_child(column)
	column.add_child(_label(caption, 12, MUTED))
	var number := _label("00", 27, TEXT)
	number.name = node_name
	column.add_child(number)
	return number


func _button(caption: String, node_name: String) -> Button:
	var button := Button.new()
	button.name = node_name
	button.text = caption
	button.focus_mode = Control.FOCUS_NONE
	button.custom_minimum_size.y = 46
	button.add_theme_font_size_override("font_size", 15)
	button.add_theme_color_override("font_color", TEXT)
	button.add_theme_color_override("font_disabled_color", Color("617684"))
	button.add_theme_stylebox_override("normal", _style(Color("213544"), Color("3b5362"), 10, 8))
	button.add_theme_stylebox_override("hover", _style(Color("2e4857"), MINT, 10, 8))
	button.add_theme_stylebox_override("pressed", _style(Color("3b5a65"), MINT, 10, 8))
	button.add_theme_stylebox_override("disabled", _style(Color("142630"), Color("2a3d47"), 10, 8))
	return button


func _show_error(message: String) -> void:
	var label := _label("地图载入失败\n" + message, 20, Board.CORAL)
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(label)


func _label(caption: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = caption
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _vbox(separation: int) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", separation)
	return box


func _hbox(separation: int) -> HBoxContainer:
	var box := HBoxContainer.new()
	box.add_theme_constant_override("separation", separation)
	return box


func _spacer(parent: HBoxContainer) -> void:
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(spacer)


func _panel(color: Color, border: Color, padding: int) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _style(color, border, 14, padding))
	return panel


func _style(color: Color, border: Color, radius: int, padding: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(radius)
	style.content_margin_left = padding
	style.content_margin_right = padding
	style.content_margin_top = padding
	style.content_margin_bottom = padding
	return style
