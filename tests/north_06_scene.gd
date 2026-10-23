extends "res://tests/north_05_scene.gd"
## Actual sixth-level inputs; reuse the existing independent green-death fixture.


func _run() -> void:
	root.size = Vector2i(1280, 820)
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await _settle()
	await _click("Level06")
	_check(game.current_level_index == 5 and game.model.level.id == "north_hero_06" and game.model.level.hero_kind == "green", "GUI selects confirmed green sixth level")
	_check(game.model.player == Vector2i(0, 1) and game.model.crates().size() == 7 and game.model.barrier_is_active(Vector2i(7, 6)), "sixth actual initial hero, seven crystals and closed gate")
	var initial: Dictionary = game.model.snapshot()
	await _capture("north_06_initial.png")
	await _sixth_repeat_check()
	await _click("Restart")
	_check(game.model.snapshot() == initial and game.model.history_size() == 0, "sixth restart clears repeat-input setup")
	var solution: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://levels/solutions/north_06.json"))
	var before_final: Dictionary
	for index in solution["path"].length():
		before_final = game.model.snapshot()
		await _press(_keycode(solution["path"][index]))
		_check(game.model.moves == index + 1 and game.model.alive and game.model.pushes == 0, "sixth actual keyboard input %d succeeds" % (index + 1))
		if index == 28:
			_check(game.model.player == Vector2i(9, 5) and game.model.pressure_is_active("yellow_01") and not game.model.blocks_sight(Vector2i(7, 6)), "real hero press opens gate and sight")
			await _capture("north_06_hero_plate.png")
			await _actual_close_and_undo()
		if index == 29:
			_check(game.model.crate_id(Vector2i(9, 5)) == 6 and game.model.pressure_is_active("yellow_01") and not game.model.barrier_is_active(Vector2i(7, 6)), "real single pull hands pressure from hero to purple crystal")
			await _capture("north_06_crystal_plate.png")
		if index == 35:
			_check(game.model.player == Vector2i(7, 6) and not game.model.barrier_is_active(Vector2i(7, 6)), "real hero traverses the single open energy cell")
			await _capture("north_06_crossing.png")
	_check(game.model.is_complete() and game.model.player == Vector2i(1, 5) and game.model.moves == 65 and game.model.pulls == 17, "sixth real keyboard victory: 65 moves, 17 pulls, no pushes")
	_check(game.moves_label.text == "65" and game.pulls_label.text == "17" and game.status_label.text.contains("已抵达终点"), "sixth visible victory and pull statistics")
	await _capture("north_06_completed.png")
	await _click("Undo")
	_check(game.model.snapshot() == before_final and not game.model.is_complete(), "sixth GUI victory undo restores full preceding state")
	await _click("Restart")
	_check(game.model.snapshot() == initial and game.model.history_size() == 0, "sixth GUI victory restart restores all seven crystals and active gate")
	await _click("Level05")
	_check(game.model.crates().size() == 2 and game.model.barrier_states().is_empty() and game.model.pressure_states().is_empty() and game.model.history_size() == 0, "sixth mechanisms and history do not leak into fifth")
	await _press(KEY_D)
	await _click("Level06")
	await _press(KEY_Z)
	_check(game.model.snapshot() == initial and game.undo_button.disabled, "fifth history does not enter sixth")
	await _green_death_fixture()
	await _click("Level06")
	_check(game.model.snapshot() == initial, "reused death/undo fixture leaves real sixth state clean")
	_check_layout(game)
	root.size = Vector2i(960, 615)
	await _settle()
	_check_layout(game)
	await _capture("north_06_compact.png")
	print("NORTH 06 SCENE RESULT: %d checks, %d failures; display=%s" % [checks, failures, DisplayServer.get_name()])
	game.queue_free()
	await process_frame
	quit(0 if failures == 0 else 1)


func _actual_close_and_undo() -> void:
	var pressed: Dictionary = game.model.snapshot()
	await _press(KEY_A)
	_check(game.model.barrier_is_active(Vector2i(7, 6)) and game.model.blocks_sight(Vector2i(7, 6)), "actual release restores gate and sight blocking")
	await _press(KEY_S)
	var blocked: Dictionary = game.model.snapshot()
	var depth: int = game.model.history_size()
	await _press(KEY_A)
	_check(game.model.player == Vector2i(8, 6) and game.model.snapshot() == blocked and game.model.history_size() == depth and game.status_label.text.contains("能量屏障"), "actual closed gate blocks hero and directly rear purple crystal atomically")
	await _capture("north_06_gate_blocked.png")
	await _click("Undo")
	await _click("Undo")
	_check(game.model.snapshot() == pressed and not game.model.barrier_is_active(Vector2i(7, 6)), "actual undo restores exact hero-held plate before continuing legal route")


func _sixth_repeat_check() -> void:
	var event := InputEventKey.new()
	event.keycode = KEY_D
	event.physical_keycode = KEY_D
	event.pressed = true
	Input.parse_input_event(event)
	await process_frame
	var once: Dictionary = game.model.snapshot()
	_check(game.model.moves == 1, "sixth first deliberate key advances once")
	for echo in [true, false]:
		var repeated := event.duplicate() as InputEventKey
		repeated.echo = echo
		Input.parse_input_event(repeated)
		await process_frame
		_check(game.model.snapshot() == once, "sixth echo/duplicate does not advance twice")
	event.pressed = false
	Input.parse_input_event(event)
	await process_frame
	await _press(KEY_D)
	_check(game.model.moves == 2, "sixth deliberate input works after release")
