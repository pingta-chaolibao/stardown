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

@export_file("*.json") var level_path: String = "res://levels/north_01.json"

var model := State.new()
var key_steps := KeySteps.new()
var board: Board
var moves_label: Label
var pushes_label: Label
var progress_label: Label
var status_label: Label
var undo_button: Button


func _ready() -> void:
	var ui_theme := Theme.new()
	ui_theme.default_font = UI_FONT
	ui_theme.default_font_size = 16
	theme = ui_theme
	resized.connect(queue_redraw)
	get_window().focus_exited.connect(key_steps.clear)
	var level := Level.from_file(level_path)
	if not model.load_level(level):
		_show_error(level.error)
		return
	_build_ui()
	_refresh("推动水晶腾出道路，再走到黄色终点。")


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
			if result in [&"moved", &"pushed", &"wall", &"crate_blocked"]:
				board.facing = direction
			match result:
				&"wall":
					board.blocked = true
					_refresh("前方是墙，换个方向试试。", GOLD)
				&"crate_blocked":
					board.blocked = true
					_refresh("水晶前方被挡住了，无法推动。", GOLD)
				&"pushed":
					_refresh("水晶向前一格。英雄只能推，不能拉。")
				&"moved":
					_refresh("每次按下移动一格；松开后可再次移动。")
				&"complete":
					_refresh("已抵达终点，可撤销或重开。", GOLD)
		&"undo":
			var undone := model.undo()
			_refresh("已撤销最近一步。" if undone else "当前没有可撤销的步骤。")
		&"restart":
			model.restart()
			board.facing = Vector2i.DOWN
			_refresh("已重开%s。" % model.level.title)


func _refresh(message: String, color: Color = MINT) -> void:
	moves_label.text = "%02d" % model.moves
	pushes_label.text = "%02d" % model.pushes
	if model.level.objective == "player_on_exit":
		progress_label.text = "已抵达终点" if model.is_complete() else "玩家抵达即可完成"
	elif model.level.objective == "all_crates_on_targets":
		progress_label.text = "%d / %d 测试落点" % [model.occupied_targets(), model.level.targets.size()]
	else:
		progress_label.text = "未设置胜利判定"
	undo_button.disabled = model.history_size() == 0
	if model.is_complete():
		status_label.text = "已抵达终点！\n可撤销最后一步，或重新开始。"
		if model.level.is_temporary:
			status_label.text = "临时目标已达成！\n这是测试布局。"
		status_label.add_theme_color_override("font_color", GOLD)
	else:
		status_label.text = message
		status_label.add_theme_color_override("font_color", color)
	board.queue_redraw()


func _build_ui() -> void:
	var margin := MarginContainer.new()
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
	var row := _hbox(18)
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
	var caption := "NORTHERN REALM / 01     ·     %d × %d" % [model.level.width, model.level.height]
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
	legend.add_child(_label("● 英雄", 13, Board.CORAL))
	legend.add_child(_label("◆ 水晶", 13, Color("9cc5f5")))
	legend.add_child(_label("◇ 终点", 13, GOLD))
	_spacer(legend)
	for entry in [["←", Vector2i.LEFT, "Left"], ["↑", Vector2i.UP, "Up"], ["↓", Vector2i.DOWN, "Down"], ["→", Vector2i.RIGHT, "Right"]]:
		var button := _button(entry[0], "Move" + entry[2])
		button.custom_minimum_size = Vector2(36, 36)
		button.tooltip_text = "移动一格"
		button.pressed.connect(apply_command.bind({"action": &"move", "direction": entry[1]}))
		legend.add_child(button)


func _build_sidebar(parent: HBoxContainer) -> void:
	var sidebar := _vbox(16)
	sidebar.custom_minimum_size.x = 300
	parent.add_child(sidebar)
	var intro := _vbox(6)
	sidebar.add_child(intro)
	intro.add_child(_label("北部英雄  /  第一关", 12, MINT))
	intro.add_child(_label("推之英雄", 30, TEXT))
	intro.add_child(_label("红色小人 · 只能推，不能拉", 16, Board.CORAL))
	var instructions := _label("走向相邻水晶，将它向前推动一格。\n前方是墙或另一枚水晶时，推动受阻。", 14, MUTED)
	intro.add_child(instructions)
	var stats := _hbox(12)
	sidebar.add_child(stats)
	moves_label = _stat(stats, "步数", "Moves")
	pushes_label = _stat(stats, "推动", "Pushes")
	var goal_card := _panel(Color("262d2d"), Color("5a5541"), 16)
	sidebar.add_child(goal_card)
	var goal := _vbox(5)
	goal_card.add_child(goal)
	goal.add_child(_label("◇  通关目标" if not model.level.is_temporary else "◇  临时目标", 14, GOLD))
	var objective_text := "走到黄色终点" if model.level.objective == "player_on_exit" else "将水晶推至测试落点"
	if model.level.objective == "none":
		objective_text = "自由验证移动与推动"
	goal.add_child(_label(objective_text, 18, TEXT))
	progress_label = _label("", 13, GOLD)
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
	var restart_button := _button("重开   R", "Restart")
	restart_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	restart_button.pressed.connect(apply_command.bind({"action": &"restart"}))
	actions.add_child(restart_button)


func _build_footer(parent: VBoxContainer) -> void:
	var footer := _vbox(5)
	parent.add_child(footer)
	footer.add_child(_label("方向键 / WASD  移动     ·     Z / U / Backspace  撤销     ·     R  重开     ·     长按不连走", 14, TEXT))
	var note := "依据用户确认的北部第一关坐标制作 · 原创 2D 几何图形"
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
