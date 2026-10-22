extends SceneTree
## Exercises the real scene, keyboard dispatch, GUI mouse clicks, and screenshots.

var checks: int = 0
var failures: int = 0
var game: Control
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
	_check(game.model.level != null and game.board != null, "main scene loads map and board")
	_check(game.model.player == Vector2i(2, 4), "initial hero position")
	_check(game.undo_button.disabled, "undo begins disabled")
	_check(game.moves_label.text == "00" and game.pushes_label.text == "00", "initial UI counters")
	await _capture("01_initial.png")
	await _key(KEY_D)
	_check(game.model.player == Vector2i(3, 4) and game.model.moves == 1, "keyboard routes one movement")
	await _key(KEY_D, true, true)
	await _key(KEY_D)
	_check(game.model.moves == 1, "scene rejects echo and repeated held key")
	await _key(KEY_D, false)
	await _key(KEY_D)
	_check(game.model.crates().size() == 2 and Vector2i(5, 4) in game.model.crates() and game.model.pushes == 1, "fresh press pushes one of two crystals")
	_check(game.moves_label.text == "02" and game.pushes_label.text == "01" and not game.undo_button.disabled, "UI follows successful push")
	await _key(KEY_D, false)
	await _capture("02_pushed.png")
	await _key(KEY_Z)
	await _key(KEY_Z, false)
	_check(game.model.player == Vector2i(3, 4) and Vector2i(4, 4) in game.model.crates(), "keyboard undo restores push")
	await _key(KEY_R)
	await _key(KEY_R, false)
	_check(game.model.moves == 0 and game.undo_button.disabled, "keyboard restart resets state and UI")
	await _click("MoveRight")
	_check(game.model.player == Vector2i(3, 4) and game.model.moves == 1, "actual GUI move click works")
	await _click("Undo")
	_check(game.model.moves == 0, "actual GUI undo click works")
	await _click("MoveRight")
	await _click("Restart")
	_check(game.model.moves == 0 and game.model.player == Vector2i(2, 4), "actual GUI restart click works")
	for key in [KEY_D, KEY_D, KEY_D, KEY_D, KEY_D, KEY_S, KEY_D, KEY_W, KEY_W]:
		await _key(key)
		await _key(key, false)
	_check(not game.model.is_complete() and game.model.level.exit_cell in game.model.crates(), "a crystal on exit does not complete the scene")
	await _key(KEY_W)
	await _key(KEY_W, false)
	_check(game.model.is_complete(), "scene completes documented temporary solution")
	_check(game.status_label.text.contains("临时目标已达成") and game.status_label.text.contains("非原关"), "completion UI clearly distinguishes temporary objective")
	_check(game.moves_label.text == "10" and game.pushes_label.text == "07", "completion UI counters")
	await _capture("03_temporary_goal.png")
	await _click("Undo")
	_check(not game.model.is_complete() and not game.status_label.text.contains("已达成"), "UI exits completed state after undo")
	await _click("Restart")
	_check(game.model.moves == 0 and game.model.history_size() == 0, "restart clears full completed session")
	await _capture("04_restarted.png")
	_check_layout(game)
	print("SCENE RESULT: %d checks, %d failures; display=%s" % [checks, failures, DisplayServer.get_name()])
	game.queue_free()
	await process_frame
	quit(0 if failures == 0 else 1)


func _key(key: int, pressed: bool = true, echo: bool = false) -> void:
	var event := InputEventKey.new()
	event.keycode = key
	event.physical_keycode = key
	event.pressed = pressed
	event.echo = echo
	Input.parse_input_event(event)
	await process_frame


func _click(node_name: String) -> void:
	var button := game.find_child(node_name, true, false) as Button
	_check(button != null, "button exists: " + node_name)
	if button == null:
		return
	var position := button.get_global_rect().get_center()
	var motion := InputEventMouseMotion.new()
	motion.position = position
	motion.global_position = position
	Input.parse_input_event(motion)
	await process_frame
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.position = position
		event.global_position = position
		event.pressed = pressed
		Input.parse_input_event(event)
		await process_frame
	await _settle()


func _capture(filename: String) -> void:
	if capture_dir.is_empty():
		return
	if DisplayServer.get_name() == "headless":
		_check(false, "capture requested but headless uses a dummy renderer")
		return
	await _settle()
	await RenderingServer.frame_post_draw
	var picture := root.get_texture().get_image()
	_check(picture != null and not picture.is_empty(), "renderer returns image: " + filename)
	if picture == null or picture.is_empty():
		return
	DirAccess.make_dir_recursive_absolute(capture_dir)
	_check(picture.save_png(capture_dir.path_join(filename)) == OK, "save rendered image: " + filename)
	print("CAPTURE: ", capture_dir.path_join(filename))


func _check_layout(node: Node) -> void:
	if node is Control and node.is_visible_in_tree():
		var rect: Rect2 = node.get_global_rect()
		_check(rect.position.x >= -1 and rect.position.y >= -1 and rect.end.x <= 1281 and rect.end.y <= 821, "control fits viewport: " + str(node.get_path()))
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
