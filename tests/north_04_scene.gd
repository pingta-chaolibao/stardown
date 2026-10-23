extends "res://tests/north_02_scene.gd"
## Real input and viewport checks for the confirmed fourth level.


func _run() -> void:
	root.size = Vector2i(1280, 820)
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await _settle()
	await _click("Level04")
	_check(game.current_level_index == 3 and game.model.level.id == "north_hero_04", "GUI enters fourth level")
	_check(game.model.player == Vector2i(1, 1) and game.model.crates().size() == 3 and game.model.level.bushes.size() == 2, "fourth initial actor and bush counts")
	_check(game.model.pressure_progress("yellow_01") == Vector2i(0, 3) and game.model.barrier_is_active(Vector2i(6, 1)), "initial three-plate group is closed")
	var initial: Dictionary = game.model.snapshot()
	await _capture("north_04_initial.png")
	await _check_repeated_key()
	await _click("Restart")
	_check(game.model.snapshot() == initial and game.model.history_size() == 0, "GUI restart resets fourth before walkthrough")
	var solution: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://levels/solutions/north_04.json"))
	var before_final: Dictionary
	var captured_held := false
	var crossed_gate := false
	for index in solution["path"].length():
		before_final = game.model.snapshot()
		await _press(_keycode(solution["path"][index]))
		_check(game.model.moves == index + 1 and game.model.alive, "actual fourth-level input %d is legal" % (index + 1))
		if game.model.player == Vector2i(6, 1):
			crossed_gate = true
			_check(game.model.pressure_progress("yellow_01") == Vector2i(3, 3) and not game.model.barrier_is_active(Vector2i(6, 1)), "real hero crosses gate only with all three plates held")
		if not captured_held and game.model.crate_id(Vector2i(1, 4)) >= 0 and game.model.crate_id(Vector2i(3, 4)) >= 0 and game.model.crate_id(Vector2i(5, 4)) >= 0:
			captured_held = true
			_check(game.progress_label.text.contains("黄板 3 / 3"), "visible pressure counter confirms full group")
			await _capture("north_04_all_plates.png")
	_check(captured_held and crossed_gate and game.model.is_complete() and game.model.player == Vector2i(6, 0), "all three crystal-held plates, gate traversal and actual victory")
	_check(game.model.moves == 34 and game.model.pushes == 13 and game.moves_label.text == "34" and game.pushes_label.text == "13", "actual fourth-level victory counts")
	_check(game.status_label.text.contains("已抵达终点"), "fourth visible victory prompt")
	await _capture("north_04_completed.png")
	await _click("Undo")
	_check(game.model.snapshot() == before_final and not game.model.is_complete() and game.model.alive, "GUI undo after victory restores exact open-gate state")
	await _click("Restart")
	_check(game.model.snapshot() == initial and game.model.history_size() == 0 and game.model.barrier_is_active(Vector2i(6, 1)), "GUI restart resets all three crystals and pressure")
	for symbol in "URRDD":
		await _press(_keycode(symbol))
	var before_bush: Dictionary = game.model.snapshot()
	await _press(KEY_S)
	_check(game.model.snapshot() == before_bush and game.status_label.text.contains("草丛"), "real hero input is blocked with a bush-specific prompt")
	await _click("Level03")
	_check(game.model.level.bushes.is_empty() and game.model.pressure_progress("yellow_01") == Vector2i(0, 1) and game.model.history_size() == 0, "fourth group and bushes do not leak into third")
	await _press(KEY_D)
	await _click("Level04")
	_check(game.model.snapshot() == initial and game.model.history_size() == 0 and game.undo_button.disabled, "third history does not enter fourth")
	_check_layout(game)
	root.size = Vector2i(960, 615)
	await _settle()
	_check_layout(game)
	await _capture("north_04_compact.png")
	print("NORTH 04 SCENE RESULT: %d checks, %d failures; display=%s" % [checks, failures, DisplayServer.get_name()])
	game.queue_free()
	await process_frame
	quit(0 if failures == 0 else 1)


func _check_repeated_key() -> void:
	var event := InputEventKey.new()
	event.keycode = KEY_D
	event.physical_keycode = KEY_D
	event.pressed = true
	Input.parse_input_event(event)
	await process_frame
	var first: Dictionary = game.model.snapshot()
	_check(game.model.moves == 1, "first key-down makes one move")
	for echo in [true, false, true]:
		var repeated := event.duplicate() as InputEventKey
		repeated.echo = echo
		Input.parse_input_event(repeated)
		await process_frame
		_check(game.model.snapshot() == first, "held or echoed key cannot cause repeated steps")
	event.pressed = false
	Input.parse_input_event(event)
	await process_frame
	await _press(KEY_D)
	_check(game.model.moves == 2, "release allows next deliberate press")
