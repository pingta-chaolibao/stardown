extends "res://tests/north_02_scene.gd"
## Actual level-03 inputs; death fixture is separate and never captured as gameplay.

const Level = preload("res://scripts/core/level_data.gd")


func _run() -> void:
	root.size = Vector2i(1280, 820)
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await _settle()
	await _click("Level03")
	_check(game.current_level_index == 2 and game.model.level.id == "north_hero_03", "GUI selects third level")
	_check(game.model.player == Vector2i(0, 1) and game.model.alive and game.model.crate_id(Vector2i(5, 1)) == 0, "third-level initial hero and crystal")
	_check(game.model.barrier_is_active(Vector2i(7, 2)) and game.model.blocks_sight(Vector2i(7, 2)), "third-level initial active barrier")
	var initial: Dictionary = game.model.snapshot()
	await _capture("north_03_initial.png")
	await _press(KEY_D)
	_check(game.model.pressure_is_active("yellow_01") and not game.model.barrier_is_active(Vector2i(7, 2)) and not game.model.blocks_sight(Vector2i(7, 2)), "real hero input presses plate and opens movement/sight")
	await _capture("north_03_plate_pressed.png")
	await _press(KEY_D)
	_check(not game.model.pressure_is_active("yellow_01") and game.model.barrier_is_active(Vector2i(7, 2)), "real release restores energy")
	await _click("Restart")
	_check(game.model.snapshot() == initial and game.model.history_size() == 0, "restart resets pressure and energy")
	var solution: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://levels/solutions/north_03.json"))
	var before_final: Dictionary
	for i in solution["path"].length():
		before_final = game.model.snapshot()
		await _press(_keycode(solution["path"][i]))
		_check(game.model.moves == i + 1 and game.model.alive, "real third-level legal input %d" % (i + 1))
	_check(game.model.is_complete() and game.model.moves == 21 and game.model.pushes == 4 and game.model.player == Vector2i(9, 1), "real third-level victory")
	_check(game.model.crate_id(Vector2i(1, 1)) == 0 and game.model.pressure_is_active("yellow_01") and not game.model.barrier_is_active(Vector2i(7, 2)), "victory keeps crystal pressure and energy open")
	await _capture("north_03_completed.png")
	await _click("Undo")
	_check(game.model.snapshot() == before_final and not game.model.is_complete(), "victory undo restores full preceding mechanism state")
	await _click("Restart")
	_check(game.model.snapshot() == initial, "victory restart returns to initial active energy")
	await _click("Level02")
	_check(game.model.pressure_states().is_empty() and game.model.barrier_states().is_empty() and game.model.moves == 0, "third mechanics do not leak into second level")
	await _press(KEY_D)
	await _click("Level03")
	_check(game.model.snapshot() == initial and game.model.history_size() == 0, "second history does not leak into third level")
	await _check_separate_death_fixture()
	_check_layout(game)
	root.size = Vector2i(960, 615)
	await _settle()
	_check_layout(game)
	await _capture("north_03_compact.png")
	print("NORTH 03 SCENE RESULT: %d checks, %d failures; display=%s" % [checks, failures, DisplayServer.get_name()])
	game.queue_free()
	await process_frame
	quit(0 if failures == 0 else 1)


func _check_separate_death_fixture() -> void:
	var fixture := Level.from_dictionary({"schema_version": 1, "id": "death_fixture", "title": "Independent death fixture",
		"is_temporary": true, "source_note": "Test only, never recorded as the actual third level",
		"terrain": [".....", ".....", "....."], "player": [1, 1], "crates": [[2, 1]], "targets": [], "objective": "none",
		"energy_links": [{"id": "test", "plate": [1, 1], "barriers": [[2, 1]], "pressure_sources": ["hero", "crystal"]}]})
	_check(fixture.error.is_empty() and game.model.load_level(fixture), "separate death fixture initializes")
	game.apply_command({"action": &"restart"})
	var before: Dictionary = game.model.snapshot()
	await _press(KEY_D)
	_check(not game.model.alive and game.model.moves == 1 and game.model.pushes == 1, "actual input triggers restoration death in independent fixture")
	_check(game.status_label.text.contains("英雄已死亡") and game.restart_button.disabled, "death UI only offers undo")
	_check(game.find_child("BackToLevels", true, false).disabled and game.find_child("MoveRight", true, false).disabled, "death disables level switching and movement controls")
	var dead: Dictionary = game.model.snapshot()
	await _press(KEY_R)
	await _press(KEY_D)
	_check(not game.select_level(0) and game.model.snapshot() == dead, "restart, movement and direct selection cannot revive dead hero")
	await _click("Undo")
	_check(game.model.alive and game.model.snapshot() == before and not game.restart_button.disabled, "one GUI undo revives and restores all state")
	_check(game.select_level(2), "restore real third level after independent fixture")
	await _settle()
