extends SceneTree
const NavigationCard = preload("res://scripts/view/level_card.gd")
## Actual keyboard/GUI input, victory replay, and isolated level switching.

var game: Control
var checks: int = 0
var failures: int = 0
var capture_dir: String = ""


func _init() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--capture-dir="):
			capture_dir = argument.trim_prefix("--capture-dir=")
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1280, 820)
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await _settle()
	await _click("Level01")
	var initial_one: Dictionary = game.model.snapshot()
	await _press(KEY_D)
	_check(game.model.moves == 1, "first-level progress before switching")
	var before_invalid: Dictionary = game.model.snapshot()
	_check(not game.select_level(-1) and not game.select_level(19) and game.model.snapshot() == before_invalid, "invalid selection preserves active session")
	await _click("Level02")
	_check(game.current_level_index == 1 and game.model.level.id == "north_hero_02", "GUI enters second level")
	_check(game.model.player == Vector2i(0, 1) and game.model.crates().size() == 10, "GUI second-level initial coordinates")
	_check(game.model.moves == 0 and game.model.history_size() == 0 and game.undo_button.disabled, "first-level history cannot enter second level")
	_check(game.find_child("Objective", true, false).text == "走到绿色终点" and game.model.level.exit_color == "green", "green destination is correctly labeled")
	var initial_two: Dictionary = game.model.snapshot()
	await _press(KEY_Z)
	_check(game.model.snapshot() == initial_two, "empty undo cannot restore first-level state")
	await _press(KEY_D)
	await _press(KEY_R)
	_check(game.model.snapshot() == initial_two and game.current_level_index == 1, "restart keeps active second level and clears history")
	await _capture("north_02_initial.png")
	var solution: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://levels/solutions/north_02.json"))
	var before_final: Dictionary
	for i in solution["path"].length():
		before_final = game.model.snapshot()
		await _press(_keycode(solution["path"][i]))
		_check(game.model.moves == i + 1, "real keyboard solution step %d succeeds" % (i + 1))
	_check(game.model.is_complete() and game.model.player == Vector2i(1, 5), "real inputs reach green exit")
	_check(game.model.pushes == 12 and game.moves_label.text == "27" and game.pushes_label.text == "12", "second-level victory counts")
	_check(game.status_label.text.contains("已抵达终点"), "visible victory state")
	await _capture("north_02_completed.png")
	await _click("Undo")
	_check(game.model.snapshot() == before_final and not game.model.is_complete(), "GUI undo after second-level victory restores full preceding grid")
	await _click("Restart")
	_check(game.model.snapshot() == initial_two and game.model.history_size() == 0, "GUI restart restores all ten crystals")
	await _click("Level01")
	_check(game.current_level_index == 0 and game.model.snapshot() == initial_one, "second-to-first switch restores first initial state")
	_check(game.find_child("Objective", true, false).text == "走到黄色终点", "green goal does not leak into first level")
	await _press(KEY_Z)
	_check(game.model.snapshot() == initial_one, "second-level history cannot leak into first level")
	var first_solution: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://levels/solutions/north_01.json"))
	for symbol in first_solution["path"]:
		await _press(_keycode(symbol))
	_check(game.model.is_complete() and game.model.moves == 12 and game.model.pushes == 4, "first-level GUI regression after switching")
	await _click("Level02")
	_check(game.model.snapshot() == initial_two and not game.model.is_complete(), "first victory does not contaminate second level")
	_check_layout(game)
	root.size = Vector2i(960, 615)
	await _settle()
	_check_layout(game)
	await _capture("north_02_compact.png")
	print("NORTH 02 SCENE RESULT: %d checks, %d failures; display=%s" % [checks, failures, DisplayServer.get_name()])
	game.queue_free()
	await process_frame
	quit(0 if failures == 0 else 1)


func _keycode(symbol: String) -> int:
	return {"U": KEY_W, "D": KEY_S, "L": KEY_A, "R": KEY_D}[symbol]


func _press(code: int) -> void:
	for pressed in [true, false]:
		var event := InputEventKey.new()
		event.keycode = code
		event.physical_keycode = code
		event.pressed = pressed
		Input.parse_input_event(event)
		await process_frame


func _click(node_name: String) -> void:
	if node_name.begins_with("Level"):
		if not game.menu.visible:
			await _click("BackToLevels")
			if not game.menu.visible: return # death locks the actual return button
		game.menu.strip.reveal_index(int(node_name.trim_prefix("Level"))-1)
		await _settle()
	var button := game.find_child(node_name, true, false) as Control
	_check(button != null, "button exists: " + node_name)
	if button == null:
		return
	var point := root.get_final_transform() * button.get_global_rect().get_center()
	var motion := InputEventMouseMotion.new()
	motion.position = point
	motion.global_position = point
	Input.parse_input_event(motion)
	await process_frame
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.position = point
		event.global_position = point
		event.pressed = pressed
		Input.parse_input_event(event)
		await process_frame
	await _settle()


func _capture(filename: String) -> void:
	if capture_dir.is_empty():
		return
	if DisplayServer.get_name() == "headless":
		_check(false, "cannot claim a screenshot from dummy rendering")
		return
	await _settle()
	await RenderingServer.frame_post_draw
	var picture := root.get_texture().get_image()
	_check(picture != null and not picture.is_empty(), "rendered image: " + filename)
	if picture != null and not picture.is_empty():
		DirAccess.make_dir_recursive_absolute(capture_dir)
		_check(picture.save_png(capture_dir.path_join(filename)) == OK, "save rendered image: " + filename)
		print("CAPTURE: ", capture_dir.path_join(filename))


func _check_layout(node: Node) -> void:
	if node is Control and node.is_visible_in_tree() and not node is NavigationCard:
		var rect: Rect2 = node.get_global_rect()
		_check(rect.position.x >= -1 and rect.position.y >= -1 and rect.end.x <= root.get_visible_rect().size.x + 1 and rect.end.y <= root.get_visible_rect().size.y + 1, "visible control fits viewport: %s %s within %s" % [node.get_path(), rect, root.get_visible_rect()])
	for child in node.get_children():
		_check_layout(child)


func _settle() -> void:
	for i in 4:
		await process_frame


func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		printerr("FAIL: ", message)
