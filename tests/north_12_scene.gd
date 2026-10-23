extends "res://tests/north_02_scene.gd"
## Actual blue direction events, three colored crystals, bushes and pressure handoff.

func _run() -> void:
	root.size=Vector2i(1280,820)
	game=load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await _settle()
	await _click("Level12")
	_check(game.current_level_index==11 and game.model.level.hero_kind=="blue" and game.model.player==Vector2i(1,1),"GUI selects twelfth blue start")
	_check(game.model.level.crystal_colors==PackedStringArray(["orange","purple","pink"]) and game.model.level.bushes.size()==2,"three confirmed colors and exactly two bushes")
	_check(game.progress_label.text.contains("黄板 0 / 3") and game.swaps_label!=null and game.swaps_label.text=="00" and game.find_child("SwapRight",true,false)==null,"three yellow plates and direction-only blue UI")
	var initial: Dictionary=game.model.snapshot()
	await _capture("north_12_initial.png")
	await _click("MoveDown")
	_check(game.model.player==Vector2i(1,2) and game.model.crate_id(Vector2i(1,1))==1 and game.model.swaps==1,"screen direction automatically swaps nearest purple crystal")
	await _click("Undo")
	_check(game.model.snapshot()==initial,"screen undo restores full first exchange")
	await _repeat_check()
	await _click("Restart")
	_check(game.model.snapshot()==initial,"restart clears key-repeat setup")
	var solution: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://levels/solutions/north_12.json"))
	var before_final: Dictionary
	for index in solution["path"].length():
		before_final=game.model.snapshot()
		await _press(_keycode(solution["path"][index]))
		_check(game.model.moves==index+1 and game.model.alive and game.model.pushes==0 and game.model.pulls==0,"actual twelfth direction input %d remains legal and alive" % (index+1))
		_check(game.model.is_complete()==(index==25),"actual victory only on final arrival")
		if index==0:await _capture("north_12_first_swap.png")
		if index==3:
			_check(game.model.crate_id(Vector2i(1,4))==1,"purple crystal holds first pressure plate")
			await _capture("north_12_purple_plate.png")
		if index==14:
			_check(game.model.crate_id(Vector2i(1,4))==0 and game.model.crate_id(Vector2i(3,4))==1,"orange and purple hold two plates")
			await _capture("north_12_two_plates.png")
		if index>=21:_check(game.progress_label.text.contains("黄板 3 / 3") and not game.model.barrier_is_active(Vector2i(6,1)),"all-three-held pressure keeps gate open")
		if index==21:
			_check(game.model.player==Vector2i(5,4) and game.model.is_walkable(Vector2i(6,1)) and not game.model.blocks_sight(Vector2i(6,1)),"hero opens gate collision and sight")
			await _capture("north_12_hero_plate.png")
		if index>=22:_check(game.model.crate_id(Vector2i(1,4))==0 and game.model.crate_id(Vector2i(3,4))==1 and game.model.crate_id(Vector2i(5,4))==2,"all three colored identities keep final plates occupied")
		if index==22:await _capture("north_12_crystal_plate.png")
		if index==24:
			_check(game.model.player==Vector2i(6,1),"actual hero walks through energy cell")
			await _capture("north_12_crossing.png")
	_check(game.model.is_complete() and game.model.player==Vector2i(6,0) and game.model.moves==26 and game.model.swaps==7,"actual 26-input, seven-swap twelfth victory")
	_check(game.moves_label.text=="26" and game.swaps_label.text=="07" and game.status_label.text.contains("已抵达终点"),"visible victory and accurate exchange statistics")
	await _capture("north_12_completed.png")
	await _click("Undo")
	_check(game.model.snapshot()==before_final and not game.model.is_complete(),"victory undo restores full previous state")
	await _click("Restart")
	_check(game.model.snapshot()==initial and game.model.history_size()==0,"victory restart restores actors, bushes and closed gate")
	await _blocker_checks(solution)
	await _release_check(solution)
	await _click("Level11")
	_check(game.model.level.mechanism_color=="green" and game.model.level.void_cells.size()==12 and game.model.crates().size()==9 and game.model.history_size()==0 and game.model.swaps==0,"twelfth identities and history do not leak into eleventh")
	await _click("Level12")
	await _press(KEY_Z)
	_check(game.model.snapshot()==initial and game.model.level.mechanism_color=="yellow" and game.model.level.void_cells.is_empty(),"eleventh green/void skin and history do not leak into twelfth")
	_check_layout(game)
	root.size=Vector2i(960,615)
	await _settle()
	_check_layout(game)
	await _capture("north_12_compact.png")
	print("NORTH 12 SCENE RESULT: %d checks, %d failures; display=%s" % [checks,failures,DisplayServer.get_name()])
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
	_check(game.model.player==Vector2i(2,1) and game.model.swaps==1,"ordinary arrow automatically swaps orange crystal once")
	for echo in [true,false]:
		event.echo=echo
		Input.parse_input_event(event.duplicate())
		await process_frame
		_check(game.model.snapshot()==once,"echo and held duplicates do not repeat automatic exchange")
	await _settle()
	_check(game.model.snapshot()==once,"idle frames do not rescan or swap")
	event.pressed=false
	Input.parse_input_event(event)
	await process_frame
	await _press(KEY_LEFT)
	_check(game.model.player==Vector2i(1,1) and game.model.swaps==2,"fresh opposite direction intentionally exchanges again")

func _blocker_checks(solution: Dictionary) -> void:
	for index in 10:await _press(_keycode(solution["path"][index]))
	await _press(KEY_S)
	var before: Dictionary=game.model.snapshot()
	await _press(KEY_D)
	_check(game.model.player==Vector2i(2,3) and game.model.snapshot()==before and game.status_label.text.contains("草丛"),"actual upper bush blocks movement and exchange")
	await _click("Restart")
	for index in 21:await _press(_keycode(solution["path"][index]))
	await _press(KEY_S)
	before=game.model.snapshot()
	await _press(KEY_A)
	_check(game.model.player==Vector2i(4,5) and game.model.snapshot()==before and game.status_label.text.contains("草丛"),"actual lower bush blocks movement and sight")
	await _click("Restart")
	for index in 9:await _press(_keycode(solution["path"][index]))
	await _press(KEY_D)
	before=game.model.snapshot()
	await _press(KEY_W)
	_check(game.model.player==Vector2i(6,2) and game.model.snapshot()==before and game.status_label.text.contains("能量"),"actual closed energy cell blocks input atomically")
	await _click("Restart")

func _release_check(solution: Dictionary) -> void:
	for index in 22:await _press(_keycode(solution["path"][index]))
	var pressed: Dictionary=game.model.snapshot()
	await _press(KEY_S)
	_check(game.progress_label.text.contains("黄板 2 / 3") and game.model.barrier_is_active(Vector2i(6,1)) and game.model.blocks_sight(Vector2i(6,1)),"actual departure from third plate restores movement and sight blocking")
	await _capture("north_12_released.png")
	await _click("Undo")
	_check(game.model.snapshot()==pressed and game.progress_label.text.contains("黄板 3 / 3"),"one actual undo restores full open-gate state")
	await _click("MoveUp")
	_check(game.model.player==Vector2i(5,2) and game.model.crate_id(Vector2i(5,4))==2 and game.model.alive and not game.model.barrier_is_active(Vector2i(6,1)),"screen direction swaps pink crystal onto plate without intermediate closure")
	await _click("Restart")
