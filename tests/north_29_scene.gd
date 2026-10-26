extends "res://tests/north_02_scene.gd"
const Map = preload("res://tests/north_29_regression.gd")

func _run() -> void:
	root.size = Vector2i(1280,820)
	game = load("res://scenes/main.tscn").instantiate(); root.add_child(game)
	await _settle(); await _click("Level29")
	_check(game.current_level_index == 28 and game.model.level.id == "north_hero_29" and game.model.active_kind() == "green","pooled29card enters correct green level")
	_check(game.model.player == Vector2i(0,7) and game.model.crates() == [Vector2i(7,7)] and game.model.monsters().size() == 4,"71hero/78crystal/fourdragon positions loaded")
	_check(game.model.level.width == 10 and game.model.level.height == 9 and not game.model.level.is_floor(Vector2i(3,7)) and game.model.level.bushes.is_empty(),"74fixedwall,no inferred grass or extra passage")
	var initial: Dictionary = game.model.snapshot()
	_check_layout(game); await _capture("north_29_initial.png")
	await _press(KEY_C); _check(game.model.snapshot() == initial,"single-green C cannot advance attack or history")
	var event := InputEventKey.new(); event.keycode = KEY_D; event.physical_keycode = KEY_D; event.pressed = true
	Input.parse_input_event(event); await _settle(); var once: Dictionary = game.model.snapshot()
	for echo in [true,false,true]:
		event.echo = echo; Input.parse_input_event(event); await _settle()
		_check(game.model.snapshot() == once and game.model.moves == 1,"held/echo input cannot repeat action or fire")
	event.pressed = false; Input.parse_input_event(event); await _settle()
	await _press(KEY_D); _check(game.model.moves == 2 and game.model.player == Vector2i(2,7),"release then fresh key moves once")
	await _click("Restart")
	for symbol in "URRRRRR": await _press(_keycode(symbol))
	_check(not game.model.alive and game.model.player == Vector2i(6,6) and game.status_label.text.contains("火焰"),"real side route enters87upwardray and dies")
	await _capture("north_29_shortcut_death.png")
	var dead: Dictionary = game.model.snapshot()
	await _press(KEY_C); await _press(KEY_R); await _click("BackToLevels")
	_check(game.model.snapshot() == dead and not game.menu.visible,"death locked against C/restart/menu")
	await _click("Undo"); _check(game.model.alive and game.model.player == Vector2i(5,6),"screenUndo revives with exact prior position")
	await _click("Restart")
	for symbol in "RRDRRR": await _press(_keycode(symbol))
	var before_pull: Dictionary = game.model.snapshot()
	await _click("MoveLeft")
	_check(game.model.pulls == 1 and game.model.monsters()[3]["position"] == Vector2i(5,8) and game.model.monsters()[3]["facing"] == Vector2i.UP,"screen input pulls87left without rotating")
	await _click("Undo"); _check(game.model.snapshot() == before_pull,"screenUndo restores pulled dragon and all counters")
	await _click("Restart"); _check(game.model.snapshot() == initial,"restart restores complete confirmed initial state")
	var solution: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://levels/solutions/north_29.json"))
	var proof: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://artifacts/verification/north_29_route.json"))
	var history: Array[Dictionary] = []; var dragon_pulls := 0; var crystal_pulls := 0
	for i in solution["path"].length():
		history.append(game.model.snapshot()); await _press(_keycode(solution["path"][i])); var expected: Dictionary = proof["trace"][i]
		_check(game.model.alive and game.model.moves == i+1 and game.model.player == _cell(expected["hero"]) and game.model.crate_id(_cell(expected["crystal"])) == 0 and game.model.pulls == expected["pulls"],"actual input agrees with independent29route %02d" % (i+1))
		for monster in game.model.monsters():
			var identity: int = monster["id"]
			_check(monster["alive"] == expected["monster_alive"][identity] and monster["position"] == _cell(expected["monsters"][identity]) and monster["facing"] == Map.FACINGS[identity],"fourdragon life/identity/facing matches common-state proof")
		if expected["pulled"] is String: crystal_pulls += 1
		elif expected["pulled"] != null: dragon_pulls += 1
		if i+1 in [9,20,21,42,55,56]: await _capture("north_29_action_%02d.png" % (i+1))
		if i+1 == 21: _check(not game.model.monsters()[2]["alive"] and not game.model.monsters()[3]["alive"] and game.model.monsters()[0]["alive"] and game.model.monsters()[1]["alive"],"first mutual pair dies exactly together at21")
		if i+1 == 56: _check(game.model.fire_rays().is_empty(),"second mutual pair at56 removes all further attacks")
	_check(game.model.is_complete() and game.moves_label.text == "64" and game.pulls_label.text == "23" and dragon_pulls == 13 and crystal_pulls == 10 and game.status_label.text.contains("已抵达终点"),"actual64action/23pull living victory with preserved crystal")
	await _capture("north_29_completed.png")
	await _click("Undo"); _check(game.model.snapshot() == history[-1] and not game.model.is_complete(),"victoryUndo exact prior full state")
	await _click("Restart"); _check(game.model.snapshot() == initial,"restart revives all4dragons after mutual kills")
	root.size = Vector2i(960,615); await _settle(); _check_layout(game); await _capture("north_29_compact.png")
	await _click("BackToLevels")
	_check(game.menu.strip.item_count == game.LEVEL_PATHS.size() and game.menu.strip.item_count == 38 and game.menu.strip.pool.size() <= game.menu.strip.capacity_bound(),"37reallevels stay viewport-pooled")
	await _capture("north_29_navigation.png")
	await _click("Level28"); _check(game.model.player == Vector2i(0,0) and game.model.monsters().size() == 4 and game.model.crates() == [Vector2i(1,1)],"prior28unchanged")
	await _click("Level29"); _check(game.model.snapshot() == initial,"29history cannot leak across navigation")
	print("NORTH29 SCENE RESULT: %d checks, %d failures;display=%s" % [checks,failures,DisplayServer.get_name()])
	quit(0 if failures == 0 else 1)

func _cell(a: Array) -> Vector2i: return Vector2i(a[0],a[1])
