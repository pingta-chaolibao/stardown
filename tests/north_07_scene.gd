extends "res://tests/north_05_scene.gd"
## Actual seventh-level keyboard/GUI input; independent death fixture stays off-camera.

func _run() -> void:
	root.size=Vector2i(1280,820)
	game=load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await _settle()
	await _click("Level07")
	_check(game.current_level_index==6 and game.model.level.id=="north_hero_07" and game.model.player==Vector2i(11,5),"GUI selects confirmed seventh level")
	_check(game.model.level.is_floor(Vector2i(0,2)) and game.model.crates().size()==1 and game.model.barrier_states().size()==2,"new floor, one crystal and two barriers are loaded")
	var initial: Dictionary=game.model.snapshot()
	await _capture("north_07_initial.png")
	await _held_key_check()
	await _click("Restart")
	_check(game.model.snapshot()==initial and game.model.history_size()==0,"restart clears deliberate/duplicate input setup")
	var solution: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://levels/solutions/north_07.json"))
	var before_final: Dictionary
	var captured_floor:=false
	for index in solution["path"].length():
		before_final=game.model.snapshot()
		await _press(_keycode(solution["path"][index]))
		_check(game.model.moves==index+1 and game.model.alive and game.model.pushes==0,"actual seventh keyboard step %d" % (index+1))
		if not captured_floor and game.model.player==Vector2i(0,2):
			captured_floor=true
			await _capture("north_07_new_floor.png")
		if index==112:
			_check(game.model.player==Vector2i(12,5),"real hero reaches pressure plate")
			_check_both_gates(true)
			await _capture("north_07_plate_hero.png")
		if index==113:
			_check(game.model.crate_id(Vector2i(12,5))==0,"real pull hands pressure to purple crystal")
			_check_both_gates(true)
			await _capture("north_07_plate_crystal.png")
		if index==114:
			_check_both_gates(false)
			await _capture("north_07_pressure_released.png")
		if index==115:
			var before: Dictionary=game.model.snapshot()
			var depth: int=game.model.history_size()
			await _press(KEY_W)
			_check(game.model.snapshot()==before and game.model.history_size()==depth and game.status_label.text.contains("能量屏障"),"actual lower energy gate rejects movement atomically")
			await _capture("north_07_lower_gate_blocked.png")
		if index==123:
			_check(game.model.crate_id(Vector2i(12,5))==0 and game.model.player==Vector2i(11,5),"real final handoff lets hero leave on west side")
			_check_both_gates(true)
			await _capture("north_07_plate_held.png")
		if index==148:
			_check(game.model.player==Vector2i(12,1),"actual keyboard crosses upper energy base between original markers 27 and 28")
			await _capture("north_07_crossing.png")
	_check(captured_floor and game.model.is_complete() and game.model.moves==152 and game.model.pulls==56,"real seventh victory uses confirmed correction: 152 moves / 56 pulls")
	_check(game.moves_label.text=="152" and game.pulls_label.text=="56" and game.status_label.text.contains("已抵达终点"),"visible seventh victory statistics")
	await _capture("north_07_completed.png")
	await _click("Undo")
	_check(game.model.snapshot()==before_final and not game.model.is_complete(),"GUI victory undo restores exact preceding state")
	await _click("Restart")
	_check(game.model.snapshot()==initial and game.model.history_size()==0,"GUI restart restores all actors and both closed barriers")
	await _click("Level06")
	_check(game.model.crates().size()==7 and game.model.barrier_states().size()==1 and game.model.history_size()==0,"seventh state cannot leak into sixth")
	await _press(KEY_D)
	await _click("Level07")
	await _press(KEY_Z)
	_check(game.model.snapshot()==initial and game.undo_button.disabled,"sixth history cannot enter seventh")
	await _green_death_fixture()
	await _click("Level07")
	_check(game.model.snapshot()==initial,"independent death/undo fixture leaves real seventh state clean")
	_check_layout(game)
	root.size=Vector2i(960,615)
	await _settle()
	_check_layout(game)
	await _capture("north_07_compact.png")
	print("NORTH 07 SCENE RESULT: %d checks, %d failures; display=%s" % [checks,failures,DisplayServer.get_name()])
	game.queue_free()
	await process_frame
	quit(0 if failures==0 else 1)

func _check_both_gates(opened: bool) -> void:
	for gate in [Vector2i(12,1),Vector2i(15,4)]:
		_check(game.model.barrier_is_active(gate)==not opened and game.model.is_walkable(gate)==opened and game.model.blocks_sight(gate)==not opened,"both real energy cells share global movement/sight state")
