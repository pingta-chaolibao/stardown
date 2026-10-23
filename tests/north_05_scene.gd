extends "res://tests/north_02_scene.gd"
## Real green-role input; the death fixture is never captured as level footage.

const Level = preload("res://scripts/core/level_data.gd")


func _run() -> void:
	root.size = Vector2i(1280, 820)
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await _settle()
	await _click("Level05")
	_check(game.current_level_index == 4 and game.model.level.hero_kind == "green" and game.model.player == Vector2i(1, 1), "GUI selects green fifth level")
	_check(game.pulls_label != null and game.pushes_label == null and game.pulls_label.text == "00", "green UI uses separate pull statistics")
	var initial: Dictionary = game.model.snapshot()
	await _capture("north_05_initial.png")
	await _press(KEY_S)
	await _press(KEY_D)
	var before_pull: Dictionary = game.model.snapshot()
	await _press(KEY_D)
	_check(game.model.snapshot() == before_pull and game.status_label.text.contains("不能推"), "real input cannot push the lower crystal")
	await _press(KEY_A)
	_check(game.model.pulls == 1 and game.model.crate_id(Vector2i(2, 2)) == 0 and game.pulls_label.text == "01", "real key automatically pulls nearest blue crystal")
	await _capture("north_05_first_pull.png")
	await _click("Undo")
	_check(game.model.snapshot() == before_pull and game.pulls_label.text == "00", "GUI undo restores crystal and pull statistic")
	await _click("Restart")
	await _held_key_check()
	await _click("Restart")
	_check(game.model.snapshot() == initial and game.model.history_size() == 0, "restart clears green setup history")
	var solution: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://levels/solutions/north_05.json"))
	var before_final: Dictionary
	for index in solution["path"].length():
		before_final = game.model.snapshot()
		await _press(_keycode(solution["path"][index]))
		_check(game.model.moves == index + 1 and game.model.pushes == 0 and game.model.alive, "real fifth-level legal input %d" % (index + 1))
	_check(game.model.is_complete() and game.model.player == Vector2i(9, 1) and game.model.pulls == 8, "real green victory uses 24 steps and 8 pulls")
	_check(game.moves_label.text == "24" and game.pulls_label.text == "08" and game.status_label.text.contains("已抵达终点"), "visible green victory statistics")
	await _capture("north_05_completed.png")
	await _click("Undo")
	_check(game.model.snapshot() == before_final and not game.model.is_complete(), "green victory undo restores exact preceding state")
	await _click("Restart")
	_check(game.model.snapshot() == initial, "green victory restart restores initial actors and counters")
	await _click("Level04")
	_check(game.model.level.hero_kind == "red" and game.model.pulls == 0 and game.pulls_label == null and game.pushes_label != null and game.model.history_size() == 0, "green role, UI and history do not leak into red fourth level")
	await _press(KEY_D)
	_check(game.model.pushes == 1 and game.model.pulls == 0, "red still pushes normally after leaving green")
	await _click("Level05")
	await _press(KEY_Z)
	_check(game.model.snapshot() == initial and game.undo_button.disabled, "red history cannot be undone inside green level")
	await _green_death_fixture()
	_check_layout(game)
	root.size = Vector2i(960, 615)
	await _settle()
	_check_layout(game)
	await _capture("north_05_compact.png")
	print("NORTH 05 SCENE RESULT: %d checks, %d failures; display=%s" % [checks, failures, DisplayServer.get_name()])
	game.queue_free()
	await process_frame
	quit(0 if failures == 0 else 1)


func _held_key_check() -> void:
	var event := InputEventKey.new()
	event.keycode = KEY_A
	event.physical_keycode = KEY_A
	event.pressed = true
	Input.parse_input_event(event)
	await process_frame
	var first: Dictionary = game.model.snapshot()
	_check(game.model.moves == 1, "green first held key moves once")
	for echo in [true, false]:
		var repeated := event.duplicate() as InputEventKey
		repeated.echo = echo
		Input.parse_input_event(repeated)
		await process_frame
		_check(game.model.snapshot() == first, "green duplicate or echo does not move again")
	event.pressed = false
	Input.parse_input_event(event)
	await process_frame
	await _press(KEY_W)
	_check(game.model.moves == 2, "green deliberate next input works after release")


func _green_death_fixture() -> void:
	var definition := Level.from_dictionary({"schema_version": 1, "id": "green_death_fixture", "title": "Independent green death fixture",
		"is_temporary": true, "source_note": "Tests only; never recorded as fifth-level footage", "hero_kind": "green",
		"terrain": [".....", ".....", "....."], "player": [2, 1], "crates": [[1, 1]], "targets": [], "objective": "none",
		"energy_links": [{"id": "test", "plate": [1, 1], "barriers": [[3, 1]], "pressure_sources": ["hero", "crystal"]}]})
	_check(definition.error.is_empty() and game.model.load_level(definition), "separate green death fixture loads")
	game.apply_command({"action": &"restart"})
	var before: Dictionary = game.model.snapshot()
	await _press(KEY_D)
	_check(not game.model.alive and game.model.pulls == 1 and game.pulls_label.text == "01" and game.status_label.text.contains("英雄已死亡"), "real green pull settles death with visible pull count")
	_check(game.restart_button.disabled and game.find_child("Level05", true, false).disabled and game.find_child("MoveRight", true, false).disabled, "dead green UI only allows undo")
	var dead: Dictionary = game.model.snapshot()
	await _press(KEY_R)
	await _press(KEY_D)
	_check(not game.select_level(0) and game.model.snapshot() == dead, "normal green operations cannot revive hero")
	await _press(KEY_Z)
	_check(game.model.alive and game.model.snapshot() == before and game.pulls_label.text == "00", "actual undo revives green and restores pull/pressure atomically")
	_check(game.select_level(4), "return to real fifth level after independent fixture")
	await _settle()
