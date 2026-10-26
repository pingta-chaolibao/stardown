extends Control
## Thin application/controller layer; all gameplay state is owned by GridState.

const Level = preload("res://scripts/core/level_data.gd")
const State = preload("res://scripts/core/grid_state.gd")
const KeySteps = preload("res://scripts/input/step_input.gd")
const Feedback = preload("res://scripts/view/feedback_events.gd")
const Board = preload("res://scripts/view/board_view.gd")
const LevelMenu = preload("res://scripts/view/level_menu.gd")
const UI_FONT = preload("res://assets/fonts/NotoSansCJKsc-Regular.otf")
const TEXT := Color("e3e9e6")
const MUTED := Color("92a8b5")
const GOLD := Color("dfbb78")
const MINT := Color("9bc9c1")
const LEVEL_PATHS := ["res://levels/north_01.json", "res://levels/north_02.json", "res://levels/north_03.json", "res://levels/north_04.json", "res://levels/north_05.json", "res://levels/north_06.json", "res://levels/north_07.json", "res://levels/north_08.json", "res://levels/north_09.json", "res://levels/north_10.json", "res://levels/north_11.json", "res://levels/north_12.json", "res://levels/north_13.json", "res://levels/north_14.json", "res://levels/north_15.json", "res://levels/north_16.json", "res://levels/north_17.json", "res://levels/north_18.json", "res://levels/north_19.json", "res://levels/north_20.json", "res://levels/north_21.json", "res://levels/north_22.json", "res://levels/north_23.json", "res://levels/north_24.json", "res://levels/north_25.json", "res://levels/north_26.json", "res://levels/north_27.json", "res://levels/north_28.json", "res://levels/north_29.json", "res://levels/north_30.json", "res://levels/north_31.json", "res://levels/north_32.json", "res://levels/north_33.json", "res://levels/north_34.json", "res://levels/north_35.json", "res://levels/north_36.json", "res://levels/north_37.json", "res://levels/north_38.json"]
const LEVEL_TITLES := ["第一关", "第二关", "第三关", "第四关", "第五关", "第六关", "第七关", "第八关", "第九关", "第十关", "第十一关", "第十二关", "第十三关", "第十四关", "第十五关", "第十六关", "第十七关", "第十八关", "第十九关", "第二十关", "第二十一关", "第二十二关", "第二十三关", "第二十四关", "第二十五关", "第二十六关", "第二十七关", "第二十八关", "第二十九关", "第三十关", "第三十一关", "第三十二关", "第三十三关", "第三十四关", "第三十五关", "第三十六关", "第三十七关", "第三十八关"]

@export var start_in_level := false
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
var menu: Control


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
	if not level.initial_monsters.is_empty():
		_refresh((("背离相邻火龙可自动拉一只，朝向不变；走到%s。" if model.active_kind()=="green" else "避开箭头火线，用水晶挡火，走到%s。") if level.monster_kinds.has("fire_dragon") else "避开哥布林四向危险格，走到%s。") % _goal_name())
	else:
		_refresh("C 切换英雄，%s名英雄分占不同终点。" % ("三" if model.hero_count()==3 else "两") if model.hero_count()>1 else "按方向：有可见目标就交换，否则走一格。" if model.active_kind()=="blue" else "%s水晶腾出道路，再走到%s。" % ["拉动" if model.active_kind() == "green" else "推动", _goal_name()])

	menu = LevelMenu.new()
	menu.configure(LEVEL_PATHS)
	add_child(menu)
	menu.level_requested.connect(select_level)
	if start_in_level: menu.hide()
	else: ui_root.hide()


func back_to_menu() -> bool:
	if not model.alive:
		_refresh("英雄已死亡，仅可撤销恢复。", Board.CORAL)
		return false
	board.cancel_feedback()
	key_steps.clear()
	ui_root.hide()
	menu.show()
	menu.focus_strip()
	return true


func select_level(index: int) -> bool:
	if not model.alive:
		_refresh("英雄已死亡，仅可撤销恢复。", Board.CORAL)
		return false
	if index < 0 or index >= LEVEL_PATHS.size():
		return false
	board.cancel_feedback()
	var definition := Level.from_file(LEVEL_PATHS[index])
	if not model.load_level(definition):
		return false
	if menu != null:
		menu.strip.freeze()
		menu.hide()
	current_level_index = index
	level_path = LEVEL_PATHS[index]
	key_steps.clear()
	_rebuild_ui()
	_refresh("C 切换英雄，%s名英雄分占不同终点。" % ("三" if model.hero_count()==3 else "两") if model.hero_count()>1 else "已进入%s，走到%s即可完成。" % [model.level.title, _goal_name()])
	return true


func _rebuild_ui(preserve_feedback: bool = false) -> void:
	var timeline = board.feedback if preserve_feedback and board != null else null
	var clock: float = board.idle_clock if board != null else 0.0
	var old_facing: Vector2i = board.facing if board != null else Vector2i.DOWN
	if board != null and not preserve_feedback: board.cancel_feedback()
	# Rebuilding selection-dependent labels must not release held keyboard keys.
	if ui_root != null:
		remove_child(ui_root)
		ui_root.queue_free()
	_build_ui()
	if timeline != null: board.feedback = timeline
	board.idle_clock = clock
	board.facing = old_facing


func _has_hero_kind(kind: String) -> bool:
	for hero in model.level.hero_definitions:
		if hero["kind"]==kind:return true
	return false


func _goal_name() -> String:
	if model.level.exit_color=="red":return "红色终点"
	if model.level.exit_color=="purple":return "紫色终点"
	if model.level.exit_color=="blue":return "蓝色终点"
	if model.level.exit_color=="orange":return "橙色终点"
	return "绿色终点" if model.level.exit_color == "green" else "黄色终点"


func _goal_color() -> Color:
	if model.level.exit_color=="red":return Board.CORAL
	if model.level.exit_color=="purple":return Board.GOAL_PURPLE
	if model.level.exit_color=="blue":return Board.GOAL_BLUE
	if model.level.exit_color=="orange":return Board.GOAL_ORANGE
	return Color("78dd99") if model.level.exit_color == "green" else GOLD


func _hero_color_name() -> String:
	if model.active_kind()=="blue" and model.level.swap_hero_color=="purple":return "紫"
	return {"red":"红","green":"绿","blue":"蓝"}[model.active_kind()]

func _hero_tint() -> Color:
	if model.active_kind()=="blue":return Board.HERO_PURPLE if model.level.swap_hero_color=="purple" else Board.HERO_BLUE
	return Board.HERO_GREEN if model.active_kind()=="green" else Board.CORAL


func _plate_name() -> String:
	if model.level.mechanism_color=="red":return "红板"
	if model.level.mechanism_color=="purple":return "紫板"
	if model.level.mechanism_color=="blue":return "蓝板"
	return "绿板" if model.level.mechanism_color=="green" else "黄板"


func _mechanism_tint() -> Color:
	if model.level.mechanism_color=="red":return Board.MECHANISM_RED
	if model.level.mechanism_color=="purple":return Board.MECHANISM_PURPLE
	if model.level.mechanism_color=="blue":return Board.MECHANISM_BLUE
	return Board.MECHANISM_GREEN if model.level.mechanism_color=="green" else GOLD


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("0b1520"))
	for i in 64:
		var point := Vector2(fmod(i * 173.3 + 23, size.x), fmod(i * 97.7 + 41, size.y))
		draw_circle(point, 1.0 if i % 4 else 1.4, Color(0.45, 0.63, 0.68, 0.12))


func _unhandled_key_input(event: InputEvent) -> void:
	if menu != null and menu.visible: return
	if event is InputEventKey and event.keycode==KEY_ESCAPE and event.pressed and not event.echo:
		back_to_menu()
		get_viewport().set_input_as_handled()
		return
	var command := key_steps.command_for_event(event)
	if not command.is_empty() and model.level != null:
		apply_command(command)
		get_viewport().set_input_as_handled()


func apply_command(command: Dictionary) -> void:
	if menu != null and menu.visible: return
	if model.level == null:
		return
	# Movement is never queued behind feedback. Release events still reach StepInput.
	# Undo/restart/selection remain responsive and do not invent a world action.
	if command.get("action") == &"move" and board.feedback.is_busy(): return
	var before_visual := Feedback.capture(model)
	var before_selection:=model.active_hero_index
	var pulling:Dictionary=model.pull_target_at(model.player-command.get("direction",Vector2i.ZERO)) if command.get("action")==&"move" else {}
	var before_crystals:=model.crates().size()
	var before_monsters:int=model.monsters().filter(func(m:Dictionary)->bool:return m["alive"]).size()
	board.blocked = false
	match command.get("action"):
		&"move":
			var direction: Vector2i = command.get("direction", Vector2i.ZERO)
			var result := model.try_move(direction)
			if result in [&"moved", &"pushed", &"pulled", &"swapped", &"cannot_push", &"wall", &"crate_blocked", &"energy_blocked", &"bush_blocked", &"fence_blocked", &"died"]:
				board.facing = direction
			match result:
				&"cannot_push":
					board.blocked = true
					_refresh(_hero_color_name()+"色英雄不能推拉；按方向自动交换可见目标。" if model.active_kind()=="blue" else "绿色英雄只能拉，不能推；请绕到水晶前方再背离它移动。", GOLD)
				&"swapped":
					_refresh("已与本次输入方向的第一个可见目标交换。")
				&"pulled":
					_refresh("最近一只火龙跟到英雄原位置，朝向不变；只拉一个。" if pulling.get("kind")=="fire_dragon" else "最近一枚水晶跟到英雄原位置，后面的水晶保持不动。")
				&"bush_blocked":
					board.blocked = true
					_refresh("草丛阻挡通行，无法推动或交换。", GOLD)
				&"wall":
					board.blocked = true
					_refresh("前方是墙，换个方向试试。", GOLD)
				&"fence_blocked":
					board.blocked = true
					_refresh("栅栏阻挡走动和推拉；蓝人仍可交换另一侧可见对象。", MINT)
				&"energy_blocked":
					board.blocked = true
					_refresh("清怪能量阻挡通行：全部怪物死亡后才消失。" if model.player+direction in model.level.monster_clear_barriers else "能量屏障阻挡通行，需要压住全部%s。" % _plate_name(), _mechanism_tint())
				&"rule_unresolved":
					_refresh(model.last_mechanism_error, GOLD)
				&"dead", &"died":
					_refresh("英雄已死亡，仅可撤销恢复。", Board.CORAL)
				&"crate_blocked":
					board.blocked = true
					_refresh("整列对象末端被挡住了，无法推动。", GOLD)
				&"pushed":
					_refresh("整列水晶、怪物与英雄前进一格。" if not model.level.initial_monsters.is_empty() else "相邻英雄和水晶整列前进一格。" if model.hero_count()>1 else "相邻水晶整列前进一格。英雄只能推，不能拉。")
				&"moved":
					_refresh("每次按下移动一格；松开后可再次移动。")
				&"complete":
					_refresh("已抵达终点，可撤销或重开。", GOLD)
		&"switch_hero":
			var result:=model.switch_hero()
			_refresh("已切换操作英雄；不计步，不写撤销历史。" if result==&"switched" else ("任一英雄死亡后，仅可撤销恢复。" if result==&"dead" else "当前无法切换英雄。"))
		&"undo":
			board.cancel_feedback()
			var undone := model.undo()
			_refresh("已撤销最近一步。" if undone else "当前没有可撤销的步骤。")
		&"restart":
			if model.alive: board.cancel_feedback()
			if model.restart():
				board.facing = Vector2i.DOWN
				_refresh("已重开%s。" % model.level.title)
			else:
				_refresh("英雄已死亡，仅可撤销恢复。", Board.CORAL)

	if model.alive and model.crates().size()<before_crystals:
		_refresh("能量再现，摧毁%d枚水晶；可撤销整步恢复。" % (before_crystals-model.crates().size()),GOLD)
	var killed:int=before_monsters-model.monsters().filter(func(m:Dictionary)->bool:return m["alive"]).size()
	if model.alive and killed>0:
		_refresh(("本步%d只怪物死亡；可撤销整步恢复。" if model.level.monster_kinds.has("fire_dragon") or not model.level.monster_clear_barriers.is_empty() else "能量再现，%d只哥布林死亡；可撤销整步恢复。") % killed,GOLD)
	if before_selection!=model.active_hero_index:
		var message:=status_label.text
		_rebuild_ui(true)
		_refresh(message)
		board.feedback.accent("selection",Vector2(model.player))
	if command.get("action") == &"move":
		if model.moves == before_visual["world"]["moves"]+1:
			board.play_action(before_visual,command["direction"])
		elif board.blocked:
			board.feedback.accent("blocked",Vector2(model.player),0.16)
	elif command.get("action") == &"undo" and model.moves < before_visual["world"]["moves"]:
		board.feedback.accent("undo",Vector2(model.player))
	_sync_feedback_controls()


func _refresh(message: String, color: Color = MINT) -> void:
	moves_label.text = "%02d" % model.moves
	if pushes_label != null:
		pushes_label.text = "%02d" % model.pushes
	if pulls_label != null:
		pulls_label.text = "%02d" % model.pulls
	if swaps_label!=null:
		swaps_label.text="%02d" % model.swaps
	if model.level.objective=="all_heroes_on_exits":
		progress_label.text="英雄终点 %d / %d" % [model.occupied_exits(),model.hero_count()]
	elif model.level.objective == "player_on_exit":
		progress_label.text = "已抵达终点" if model.is_complete() else "玩家抵达即可完成"
	elif model.level.objective == "all_crates_on_targets":
		progress_label.text = "%d / %d 测试落点" % [model.occupied_targets(), model.level.targets.size()]
	else:
		progress_label.text = "未设置胜利判定"
	for link in model.level.energy_links:
		if link["plates"].size() > 1 or model.hero_count()>1:
			var count := model.pressure_progress(link["id"])
			var objective_progress:=progress_label.text if model.hero_count()>1 else ("已抵达终点" if model.is_complete() else "玩家到终点完成")
			progress_label.text = "%s · %s %d / %d" % [objective_progress, _plate_name(), count.x, count.y]
	if not model.level.monster_clear_barriers.is_empty():
		progress_label.text += " · 存活怪物 %d / %d" % [model.living_monster_count(),model.level.initial_monsters.size()]
	undo_button.disabled = model.history_size() == 0
	restart_button.disabled = not model.alive
	for node_name in ["MoveLeft", "MoveRight", "MoveUp", "MoveDown"]:
		var button := find_child(node_name, true, false) as Button
		if button != null:
			button.disabled = not model.alive or board.feedback.is_busy()
	var switch_button:=find_child("SwitchHero",true,false) as Button
	if switch_button!=null:
		switch_button.disabled=not model.alive or model.is_complete()
	var back := find_child("BackToLevels",true,false) as Button
	if back != null: back.disabled = not model.alive
	if not model.alive:
		progress_label.text = "英雄已死亡"
		status_label.text = "英雄被火焰击杀。\n只能撤销恢复。" if model.death_reason=="fire" else ("进入哥布林四向一格范围，英雄死亡。\n只能撤销恢复。" if model.death_reason=="monster" else "英雄已死亡。\n只能撤销到屏障恢复前的状态复活。")
		status_label.add_theme_color_override("font_color", Board.CORAL)
	elif model.is_complete():
		status_label.text = ("三英雄已抵达终点！\n可撤销最后一步，或重新开始。" if model.hero_count()==3 else "双英雄已抵达终点！\n可撤销最后一步，或重新开始。") if model.hero_count()>1 else "已抵达终点！\n可撤销最后一步，或重新开始。"
		if model.level.is_temporary:
			status_label.text = "临时目标已达成！\n这是测试布局。"
		status_label.add_theme_color_override("font_color", _goal_color())
	else:
		status_label.text = message
		status_label.add_theme_color_override("font_color", color)
	board.queue_redraw()


func _sync_feedback_controls() -> void:
	for node_name in ["MoveLeft","MoveRight","MoveUp","MoveDown"]:
		var button := find_child(node_name,true,false) as Button
		if button != null: button.disabled = not model.alive or board.feedback.is_busy()


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
	var row:=_hbox(10)
	row.custom_minimum_size.y=78
	parent.add_child(row)
	var emblem:=_label("✦",52,GOLD)
	emblem.custom_minimum_size.x=58
	row.add_child(emblem)
	var titles:=_vbox(0)
	row.add_child(titles)
	titles.add_child(_label("STARDOWN  /  NORTHERN REALM",12,MINT))
	titles.add_child(_label("沉星之序",34,TEXT))
	_spacer(row)
	var back := _button("←  返回选关", "BackToLevels")
	back.custom_minimum_size = Vector2(152,46)
	back.tooltip_text = "返回主界面，保留浏览位置；英雄死亡时仅可撤销"
	back.pressed.connect(back_to_menu)
	row.add_child(back)


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
	board.feedback_finished.connect(_sync_feedback_controls)
	board.custom_minimum_size = Vector2(560, 350)
	board.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(board)
	var legend := _hbox(8 if model.hero_count()>1 else 12)
	content.add_child(legend)
	var active_name: String=_hero_color_name()
	legend.add_child(_label("● 当前%s人" % active_name if model.hero_count()>1 else "● 英雄", 13, _hero_tint()))
	legend.add_child(_label("◆ 水晶", 13, Color("9cc5f5")))
	legend.add_child(_label("◇ 终点", 13, _goal_color()))
	if not model.level.energy_links.is_empty():
		legend.add_child(_label("▣ 压力板", 13, _mechanism_tint()))
		legend.add_child(_label("▤ 能量块", 13, _mechanism_tint()))
	if not model.level.monster_clear_barriers.is_empty():
		legend.add_child(_label("▤ 清怪能量", 13, Board.MECHANISM_RED))
	if not model.level.bushes.is_empty():
		legend.add_child(_label("♣ 草丛", 13, Color("a1b76a")))
	if model.level.monster_kinds.has("goblin"):legend.add_child(_label("✦ 哥布林 · 四向危险格",13,Color("f0a16b")))
	if model.level.monster_kinds.has("fire_dragon"):legend.add_child(_label("➜ 火龙 · 箭头火线",13,Color("f4af73")))
	_spacer(legend)
	if model.hero_count()>1:
		var switch_button:=_button("切换 C","SwitchHero")
		switch_button.custom_minimum_size=Vector2(66,36)
		switch_button.tooltip_text="循环操作英雄；不计步、不写撤销历史，不移动或发动能力"
		switch_button.pressed.connect(apply_command.bind({"action":&"switch_hero"}))
		legend.add_child(switch_button)
	for entry in [["←", Vector2i.LEFT, "Left"], ["↑", Vector2i.UP, "Up"], ["↓", Vector2i.DOWN, "Down"], ["→", Vector2i.RIGHT, "Right"]]:
		var button := _button(entry[0], "Move" + entry[2])
		button.custom_minimum_size = Vector2(36, 36)
		button.tooltip_text = "本方向有可见目标就交换，否则走一格" if model.active_kind()=="blue" else "移动一格"
		button.pressed.connect(apply_command.bind({"action": &"move", "direction": entry[1]}))
		legend.add_child(button)


func _build_sidebar(parent: HBoxContainer) -> void:
	var has_energy := not model.level.energy_links.is_empty() or not model.level.monster_clear_barriers.is_empty()
	var compact_rules:=not model.level.initial_monsters.is_empty() and has_energy
	var sidebar := _vbox(8 if model.hero_count()>2 or compact_rules else (12 if has_energy else 16))
	sidebar.custom_minimum_size.x = 300
	parent.add_child(sidebar)
	var intro := _vbox(4 if model.hero_count()>2 or compact_rules else 6)
	sidebar.add_child(intro)
	intro.add_child(_label("北部英雄  /  %s" % LEVEL_TITLES[maxi(0, current_level_index)], 12, MINT))
	var multi:=model.hero_count()>1
	var green_party:=multi and _has_hero_kind("green")
	var blue_party:=multi and _has_hero_kind("blue")
	var green := model.active_kind() == "green"
	var blue:=model.active_kind()=="blue"
	intro.add_child(_label(("三英雄协作" if model.hero_count()==3 else "双英雄协作") if multi else ("交换之英雄" if blue else ("拉之英雄" if green else "推之英雄")), 30, TEXT))
	var selected_label:=_label(("当前操作：%s色英雄" % _hero_color_name()) if multi else ((_hero_color_name()+"色小人 · 能走路，不能推拉") if blue else ("绿色小人 · 只能拉，不能推" if green else "红色小人 · 只能推，不能拉")), 16, _hero_tint())
	selected_label.name="SelectedHero"
	intro.add_child(selected_label)
	var instructions := _label("可推动紧密排成直线的整列水晶。\n每次前进一格，列末受阻则整列不动。", 14, MUTED)
	if blue:
		instructions.text="按方向键 / WASD：只查看该方向。\n有可见英雄或水晶就与第一个交换；\n没有目标才走一格，不能推拉。"
		if not model.level.energy_links.is_empty():
			instructions.text="按方向：有可见目标就与第一个交换。\n没有目标才走一格，不能推拉。"
	elif green:
		instructions.text = "背离相邻水晶移动，自动拉一枚。\n后面的水晶不跟随，不能推水晶。"
	elif not model.level.bushes.is_empty():
		instructions.text = "整列水晶每次推一格，末端受阻则不动。\n草丛挡通行与视线，不能推动或交换。"
	if multi:
		instructions.text="红人：混合整列推。C 切换不计步。\n绿人：背离相邻水晶，只自动拉一枚。" if green_party else "蓝人：方向首个可见对象交换，否则走。\n红人：混合整列推。C 切换，不计步。"
		if blue_party and green_party:
			instructions.text="蓝人：首个可见目标交换，否则走一步。\n绿人：背离相邻晶单拉；C 切换不计步。"
		if _has_hero_kind("red") and blue_party and green_party:
			instructions.text="红：混合整列推；绿：自动单晶拉。\n蓝：方向首目标交换，否则走一步。\nC 免费选择，撤销保留当前选择。"
	if not model.level.initial_monsters.is_empty():
		instructions.text="哥布林静止；四向一格杀英雄与怪物。\n斜角安全，进入范围后只能撤销。\n"+("蓝人可与首个可见活哥布林交换。" if blue else ("绿人仍只自动拉一枚水晶。" if green else "红人可隔着水晶推动哥布林。"))
	if model.level.monster_kinds.has("fire_dragon"):
		instructions.text="火龙不转向；每次有效行动只击杀首目标。\n水晶、墙与实体屏障挡火，水晶不烧毁。\n红推、蓝换不改朝向；哥布林四向危险。"
	if green and model.level.monster_kinds.has("fire_dragon"):
		instructions.text="背离相邻水晶或火龙，自动只拉一个。\n火龙不转向；每步火焰只击杀首目标。\n不能推、不能链拉；死亡仅能撤销。"
	if model.level.monster_kinds.has("goblin") and not model.level.energy_links.is_empty() and not model.level.monster_clear_barriers.is_empty():
		instructions.text="%s人沿方向与首个可见对象交换。\n活哥布林可压板；四向相邻有危险。" % _hero_color_name() if blue else "活哥布林和英雄、水晶都能压板。\n哥布林四向一格危险；死亡仅可撤销。"
	if model.level.swap_hero_color=="purple":instructions.text=instructions.text.replace("蓝","紫")
	intro.add_child(instructions)
	if not model.level.fence_edges.is_empty():
		intro.add_child(_label("栅栏挡走动和推拉。\n蓝人视线与交换不受栅栏阻挡。", 13, MINT))
	var combined_energy:bool=not model.level.energy_links.is_empty() and not model.level.monster_clear_barriers.is_empty()
	if combined_energy:
		intro.add_child(_label("全部%s同时受压：黄能量消失。\n全部怪物死亡：红屏障消失。\n再现杀英雄/怪物、毁晶；撤销恢复。" % _plate_name(),13,MUTED))
	elif not model.level.energy_links.is_empty():
		var rules := "英雄或水晶压住%s时，能量块消失。\n再现：格内英雄死亡、水晶摧毁。" % _plate_name()
		if model.level.energy_links[0]["plates"].size() > 1:
			var count: int = model.level.energy_links[0]["plates"].size()
			var number: String = {2:"两",3:"三",9:"九"}.get(count,str(count))
			rules = "%s块%s同时受压才开门。\n再现：格内英雄死亡、水晶摧毁。" % [number,_plate_name()]
		intro.add_child(_label(rules, 13, _mechanism_tint()))
	elif not model.level.monster_clear_barriers.is_empty():
		intro.add_child(_label("清怪能量：所有类型的怪物全部死亡才消失。\n存在时挡移动和视线；撤销复活时同步恢复。",13,_mechanism_tint()))
	var stats := _hbox(6 if multi else 12)
	sidebar.add_child(stats)
	moves_label = _stat(stats, "操作" if multi or blue else "步数", "Moves")
	pushes_label = null
	pulls_label = null
	swaps_label=null
	if multi:
		if _has_hero_kind("red"):pushes_label=_stat(stats,"推动","Pushes")
		if blue_party:swaps_label=_stat(stats,"交换","Swaps")
		if green_party:pulls_label=_stat(stats,"拉动","Pulls")
	elif blue:
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
	if multi:
		objective_text="三名英雄分占不同终点" if model.hero_count()==3 else "两名英雄分占不同终点"
	if model.level.objective == "none":
		objective_text = "自由验证移动与推动"
	var objective_label := _label(objective_text, 18, TEXT)
	objective_label.name = "Objective"
	goal.add_child(objective_label)
	progress_label = _label("", 13, _goal_color())
	progress_label.name = "TargetProgress"
	goal.add_child(progress_label)
	goal.add_child(_label("不限定英雄对应；水晶不计入" if multi else "水晶不需要停在终点", 12, MUTED))
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
	if model.active_kind()=="blue":
		controls="方向键 / WASD  有目标交换，否则走一格     ·     Z / U / Backspace  撤销     ·     R  重开     ·     长按不连动"
	if model.hero_count()>1:
		controls="方向键 / WASD  操作高亮英雄     ·     C  切换     ·     Z / U / Backspace  撤销     ·     R  重开     ·     长按不连动"
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
