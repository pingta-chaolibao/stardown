extends SceneTree
const NavigationCard = preload("res://scripts/view/level_card.gd")
## Exercises the real scene, keyboard dispatch, GUI mouse clicks, and screenshots.

const Level = preload("res://scripts/core/level_data.gd")

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
	await _click("Level01")
	_check(game.model.level != null and game.board != null, "main scene loads confirmed map and board")
	_check(game.model.level.id == "north_hero_01" and not game.model.level.is_temporary, "default scene uses user-confirmed first level")
	_check(game.model.player == Vector2i(1, 1), "initial hero position")
	_check(game.model.crate_id(Vector2i(3, 2)) == 0 and game.model.crate_id(Vector2i(7, 0)) == 1, "initial blue and purple coordinates")
	_check(game.undo_button.disabled, "undo begins disabled")
	_check(game.moves_label.text == "00" and game.pushes_label.text == "00", "initial UI counters")
	_check_labels(game)
	await _capture("01_initial.png")
	await _key(KEY_D)
	_check(game.model.player == Vector2i(2, 1) and game.model.moves == 1, "keyboard routes one movement")
	for i in 8:
		await _key(KEY_D, true, true)
		await _key(KEY_D)
	_check(game.model.moves == 1, "scene rejects repeated echo and held key")
	await _key(KEY_D, false)
	await _press(KEY_D)
	_check(game.model.player == Vector2i(2, 1) and game.model.moves == 1 and game.board.blocked, "fresh press into confirmed wall is blocked")
	await _press(KEY_R)
	for key in [KEY_S, KEY_D, KEY_D]:
		await _press(key)
	_check(game.model.player == Vector2i(3, 2) and game.model.crate_id(Vector2i(4, 2)) == 0, "keyboard pushes blue through lower opening")
	_check(game.moves_label.text == "03" and game.pushes_label.text == "01" and not game.undo_button.disabled, "UI follows successful push")
	await _capture("02_pushed.png")
	await _press(KEY_Z)
	_check(game.model.player == Vector2i(2, 2) and game.model.crate_id(Vector2i(3, 2)) == 0, "keyboard undo restores blue push")
	await _press(KEY_R)
	_check(game.model.moves == 0 and game.undo_button.disabled, "keyboard restart resets state and UI")
	await _click("MoveRight")
	_check(game.model.player == Vector2i(2, 1) and game.model.moves == 1, "actual GUI move click works")
	await _click("Undo")
	_check(game.model.moves == 0, "actual GUI undo click works")
	await _click("MoveRight")
	await _click("Restart")
	_check(game.model.moves == 0 and game.model.player == Vector2i(1, 1), "actual GUI restart click works")
	for key in [KEY_S, KEY_D, KEY_D, KEY_D, KEY_W, KEY_W, KEY_D, KEY_D, KEY_D, KEY_D, KEY_S]:
		await _press(key)
	_check(not game.model.is_complete() and game.model.player == Vector2i(8, 1), "passing both crystals does not win before yellow exit")
	_check(game.model.crate_id(Vector2i(5, 2)) == 0 and game.model.crate_id(Vector2i(9, 0)) == 1, "both colored crystals moved through actual scene")
	await _press(KEY_D)
	_check(game.model.is_complete() and game.model.player == Vector2i(9, 1), "player enters confirmed yellow exit")
	_check(game.status_label.text.contains("已抵达终点") and not game.status_label.text.contains("临时"), "confirmed completion UI")
	_check(game.moves_label.text == "12" and game.pushes_label.text == "04", "completion UI counters")
	await _capture("03_completed.png")
	await _click("Undo")
	_check(not game.model.is_complete() and game.model.player == Vector2i(8, 1) and not game.status_label.text.contains("已抵达"), "undo after victory returns before exit and clears victory UI")
	await _click("Restart")
	_check(game.model.moves == 0 and game.model.history_size() == 0 and game.model.player == Vector2i(1, 1), "restart clears completed session")
	_check(game.model.crate_id(Vector2i(3, 2)) == 0 and game.model.crate_id(Vector2i(7, 0)) == 1, "restart restores both colored crystals")
	await _capture("04_restarted.png")
	_check_layout(game)
	await _check_chain_scene()
	root.size = Vector2i(960, 615)
	await _settle()
	_check_layout(game)
	await _capture("05_compact.png")
	print("SCENE RESULT: %d checks, %d failures; display=%s" % [checks, failures, DisplayServer.get_name()])
	game.queue_free()
	await process_frame
	quit(0 if failures == 0 else 1)


func _check_chain_scene() -> void:
	var original = game.model.level
	for count in [2, 3, 4]:
		var row := ".".repeat(count + 4)
		var crystals: Array = []
		for i in count:
			crystals.append([i + 2, 1])
		var level := Level.from_dictionary({"schema_version": 1, "id": "chain_scene_fixture",
			"title": "Input regression fixture", "is_temporary": true, "source_note": "Tests only",
			"terrain": [row, row, row], "player": [1, 1], "crates": crystals,
			"targets": [], "objective": "none"})
		_check(level.error.is_empty() and game.model.load_level(level), "scene line fixture loads")
		game.apply_command({"action": &"restart"})
		var initial: Dictionary = game.model.snapshot()
		await _key(KEY_D)
		await _key(KEY_D, true, true)
		await _key(KEY_D)
		await _key(KEY_D, false)
		_check(game.model.player == Vector2i(2, 1) and game.model.moves == 1 and game.model.pushes == 1, "real keyboard advances %d-crystal line only once" % count)
		for i in count:
			_check(game.model.crate_id(Vector2i(i + 3, 1)) == i, "scene push preserves every crystal position and identity")
		_check(game.moves_label.text == "01" and game.pushes_label.text == "01", "scene counts whole line as one push action")
		await _click("Undo")
		_check(game.model.snapshot() == initial and game.model.history_size() == 0, "GUI undo restores entire line in one action")
		await _press(KEY_D)
		await _click("Restart")
		_check(game.model.snapshot() == initial and game.undo_button.disabled, "GUI restart restores entire line")
	_check(game.model.load_level(original), "restore unchanged first level after input fixtures")
	game.apply_command({"action": &"restart"})
	await _settle()


func _press(code: int) -> void:
	await _settle() # A deliberate next press waits for the prior visual action.
	await _key(code)
	await _key(code, false)
	await _settle()


func _check_labels(node: Node) -> void:
	if node is Label:
		_check(not node.text.contains("临时") and not node.text.contains("待核实") and not node.text.contains("自编"), "current level UI contains no temporary-map notice")
	for child in node.get_children():
		_check_labels(child)

func _key(key: int, pressed: bool = true, echo: bool = false) -> void:
	var event := InputEventKey.new()
	event.keycode = key
	event.physical_keycode = key
	event.pressed = pressed
	event.echo = echo
	Input.parse_input_event(event)
	await process_frame
	if not pressed: await _settle()


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
	if node is Control and node.is_visible_in_tree() and not node is NavigationCard:
		var rect: Rect2 = node.get_global_rect()
		_check(rect.position.x >= -1 and rect.position.y >= -1 and rect.end.x <= root.get_visible_rect().size.x + 1 and rect.end.y <= root.get_visible_rect().size.y + 1, "control fits viewport: " + str(node.get_path()))
	for child in node.get_children():
		_check_layout(child)


func _settle() -> void:
	for i in 4:
		await process_frame
	var deadline := Time.get_ticks_msec()+2000
	while game != null and is_instance_valid(game.board) and game.board.feedback.is_busy():
		await process_frame
		if Time.get_ticks_msec()>deadline:
			_check(false,"view feedback clock settles within 2 seconds")
			break


func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		printerr("FAIL: ", message)
