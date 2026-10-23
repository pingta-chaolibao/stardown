extends "res://tests/north_02_scene.gd"
## Actual keyboard, screen directions, full victory, pressure handoff and layout.

func _run() -> void:
	root.size=Vector2i(1280,820)
	game=load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await _settle()
	await _click("Level10")
	_check(game.current_level_index==9 and game.model.level.hero_kind=="blue" and game.model.player==Vector2i(0,1),"GUI selects tenth blue hero")
	_check(game.model.crates().size()==1 and game.model.crate_id(Vector2i(1,1))==0 and game.model.is_walkable(Vector2i(3,0)),"single purple crystal and corrected marker four floor")
	_check(game.swaps_label!=null and game.pushes_label==null and game.pulls_label==null and game.swaps_label.text=="00","blue action and exchange statistics")
	_check(game.find_child("SwapRight",true,false)==null,"no independent skill mode or movement bypass")
	var initial: Dictionary=game.model.snapshot()
	await _capture("north_10_initial.png")
	await _click("MoveRight")
	_check(game.model.player==Vector2i(1,1) and game.model.crate_id(Vector2i(0,1))==0 and game.model.swaps==1,"screen direction automatically swaps adjacent crystal")
	await _click("Undo")
	_check(game.model.snapshot()==initial,"GUI undo restores initial automatic swap")
	await _repeat_check()
	await _click("Restart")
	_check(game.model.snapshot()==initial and game.model.history_size()==0,"restart clears repeated-input setup")
	var solution: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://levels/solutions/north_10.json"))
	var before_final: Dictionary
	for index in solution["path"].length():
		before_final=game.model.snapshot()
		await _press(_keycode(solution["path"][index]))
		_check(game.model.moves==index+1 and game.model.alive and game.model.pushes==0 and game.model.pulls==0,"actual tenth direction input %d is legal" % (index+1))
		_check(game.model.is_complete()==(index==53),"actual input victory only on final arrival")
		if index==5:
			_check(game.model.player==Vector2i(3,0),"actual keyboard walks through user-corrected marker four")
			await _capture("north_10_corrected_floor.png")
		if index==43:
			_check(game.model.player==Vector2i(10,6) and not game.model.barrier_is_active(Vector2i(3,5)) and not game.model.blocks_sight(Vector2i(3,5)),"real hero press opens energy movement and sight")
			await _capture("north_10_hero_plate.png")
		if index>=44:
			_check(game.model.crate_id(Vector2i(10,6))==0 and not game.model.barrier_is_active(Vector2i(3,5)),"real passive exchange keeps crystal-held plate active")
		if index==44:await _capture("north_10_crystal_plate.png")
		if index==51:
			_check(game.model.player==Vector2i(3,5),"real hero crosses energy cell")
			await _capture("north_10_crossing.png")
	_check(game.model.is_complete() and game.model.player==Vector2i(1,5) and game.model.moves==54 and game.model.swaps==5,"actual 54-direction, five-swap tenth victory")
	_check(game.moves_label.text=="54" and game.swaps_label.text=="05" and game.status_label.text.contains("已抵达终点"),"visible tenth victory and correct statistics")
	await _capture("north_10_completed.png")
	await _click("Undo")
	_check(game.model.snapshot()==before_final and not game.model.is_complete(),"victory undo restores whole previous state")
	await _click("Restart")
	_check(game.model.snapshot()==initial and game.model.history_size()==0,"victory restart restores closed gate and initial purple crystal")
	await _real_pressure_release(solution)
	await _click("Level09")
	_check(game.model.level.id=="north_hero_09" and game.model.barrier_states().is_empty() and game.model.history_size()==0 and game.model.swaps==0,"tenth pressure and history cannot enter ninth")
	await _press(KEY_S)
	_check(game.model.player==Vector2i(1,2) and game.model.swaps==0,"ninth acceptance 13 down to 24 is preserved")
	await _press(KEY_D)
	_check(game.model.player==Vector2i(3,2) and game.model.crate_id(Vector2i(1,2))==1 and game.model.swaps==1,"ninth acceptance 24 right directly exchanges with 26 is preserved")
	await _click("Level10")
	await _press(KEY_Z)
	_check(game.model.snapshot()==initial,"ninth history cannot enter tenth")
	_check_layout(game)
	root.size=Vector2i(960,615)
	await _settle()
	_check_layout(game)
	await _capture("north_10_compact.png")
	print("NORTH 10 SCENE RESULT: %d checks, %d failures; display=%s" % [checks,failures,DisplayServer.get_name()])
	game.queue_free()
	await process_frame
	quit(0 if failures==0 else 1)

func _repeat_check() -> void:
	var event:=InputEventKey.new()
	event.keycode=KEY_RIGHT
	event.physical_keycode=KEY_RIGHT
	event.pressed=true
	Input.parse_input_event(event)
	await process_frame
	var once: Dictionary=game.model.snapshot()
	_check(game.model.swaps==1 and game.model.moves==1,"ordinary arrow key swaps once")
	for echo in [true,false]:
		event.echo=echo
		Input.parse_input_event(event.duplicate())
		await process_frame
		_check(game.model.snapshot()==once,"echo and held duplicate do not repeat input")
	await _settle()
	_check(game.model.snapshot()==once,"idle frames never automatically exchange back")
	event.pressed=false
	Input.parse_input_event(event)
	await process_frame
	await _press(KEY_LEFT)
	_check(game.model.player==Vector2i(0,1) and game.model.swaps==2,"fresh opposite arrow intentionally exchanges again")

func _real_pressure_release(solution: Dictionary) -> void:
	for index in 44:await _press(_keycode(solution["path"][index]))
	var pressed: Dictionary=game.model.snapshot()
	await _press(KEY_A)
	_check(game.model.barrier_is_active(Vector2i(3,5)) and game.model.blocks_sight(Vector2i(3,5)),"real departure from plate restores energy collision and sight")
	await _click("Undo")
	_check(game.model.snapshot()==pressed,"real undo restores pressed plate and open gate atomically")
	await _press(KEY_W)
	_check(game.model.crate_id(Vector2i(10,6))==0 and game.model.alive and not game.model.barrier_is_active(Vector2i(3,5)),"real ordinary up input exchanges onto crystal and keeps pressure continuously")
	await _click("Restart")
