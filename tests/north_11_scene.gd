extends "res://tests/north_02_scene.gd"
## Real direction events, nine-plate presentation, orange exchange and void layout.

func _run() -> void:
	root.size=Vector2i(1280,820)
	game=load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await _settle()
	await _click("Level11")
	_check(game.current_level_index==10 and game.model.player==Vector2i(5,0) and game.model.crates().size()==9,"GUI selects confirmed eleventh blue level")
	_check(game.model.level.mechanism_color=="green" and game.model.level.crystal_colors[8]=="orange" and game.model.level.void_cells.size()==12,"green mechanism, orange crystal and twelve void cells")
	_check(game.progress_label.text.contains("绿板 8 / 9") and _has_text(game,"九块绿板同时受压才开门"),"visible instructions and counter describe all nine green plates")
	_check(game.swaps_label!=null and game.swaps_label.text=="00" and game.find_child("SwapRight",true,false)==null,"direction-only blue UI has no separate skill mode")
	var initial: Dictionary=game.model.snapshot()
	await _capture("north_11_initial.png")
	await _click("MoveLeft")
	_check(game.model.player==Vector2i(4,0) and game.model.swaps==0,"screen direction without a visible target walks once")
	await _click("Undo")
	_check(game.model.snapshot()==initial,"GUI undo restores screen-direction action")
	await _repeat_check()
	await _click("Restart")
	_check(game.model.snapshot()==initial,"restart clears direction-input setup")
	await _press(KEY_S)
	await _press(KEY_D)
	var blocked: Dictionary=game.model.snapshot()
	await _press(KEY_D)
	_check(game.model.player==Vector2i(6,1) and game.model.snapshot()==blocked and game.status_label.text.contains("绿板"),"closed green gate blocks movement and hides orange target")
	await _click("Restart")
	var solution: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://levels/solutions/north_11.json"))
	var before_final: Dictionary
	for index in solution["path"].length():
		before_final=game.model.snapshot()
		await _press(_keycode(solution["path"][index]))
		_check(game.model.moves==index+1 and game.model.alive and game.model.pushes==0 and game.model.pulls==0,"actual eleventh direction input %d remains legal and alive" % (index+1))
		_check(game.model.is_complete()==(index==18),"actual player arrival wins only on last input")
		if index>=10:_check(game.progress_label.text.contains("绿板 9 / 9") and not game.model.barrier_is_active(Vector2i(7,1)),"nine pressed plates continuously keep green gate open")
		if index==10:
			_check(game.model.player==Vector2i(1,5) and not game.model.blocks_sight(Vector2i(7,1)) and game.model.is_walkable(Vector2i(7,1)),"hero fills empty ninth plate and opens collision/sight")
			await _capture("north_11_all_plates.png")
		if index==14:
			_check(game.model.player==Vector2i(5,1) and game.model.swap_target(Vector2i.RIGHT).get("id")==8,"open gate reveals orange crystal along this input ray")
			await _capture("north_11_aligned.png")
		if index==15:
			_check(game.model.player==Vector2i(10,1) and game.model.crate_id(Vector2i(5,1))==8 and game.model.swaps==5,"ordinary right input exchanges orange crystal across open gate and keeps pressure")
			await _capture("north_11_orange_exchange.png")
	_check(game.model.is_complete() and game.model.player==Vector2i(9,1) and game.model.moves==19 and game.model.swaps==5,"actual nineteen-input, five-swap eleventh victory")
	_check(game.moves_label.text=="19" and game.swaps_label.text=="05" and game.status_label.text.contains("已抵达终点"),"visible victory and statistics")
	await _capture("north_11_completed.png")
	await _click("Undo")
	_check(game.model.snapshot()==before_final and not game.model.is_complete(),"victory undo restores entire preceding state")
	await _click("Restart")
	_check(game.model.snapshot()==initial and game.model.history_size()==0,"victory restart restores all original plates, identities and closed gate")
	await _pressure_and_void_checks(solution)
	await _click("Level10")
	_check(game.model.level.mechanism_color=="yellow" and game.model.level.void_cells.is_empty() and game.model.swaps==0 and game.model.history_size()==0 and not _has_text(game,"九块绿板"),"green skin, nine-plate labels, void and history do not leak into tenth")
	await _press(KEY_D)
	_check(game.model.player==Vector2i(1,1) and game.model.swaps==1,"tenth retains passive adjacent-crystal exchange")
	await _click("Level11")
	await _press(KEY_Z)
	_check(game.model.snapshot()==initial,"tenth history cannot enter eleventh")
	_check_layout(game)
	root.size=Vector2i(960,615)
	await _settle()
	_check_layout(game)
	await _capture("north_11_compact.png")
	print("NORTH 11 SCENE RESULT: %d checks, %d failures; display=%s" % [checks,failures,DisplayServer.get_name()])
	game.queue_free()
	await process_frame
	quit(0 if failures==0 else 1)

func _repeat_check() -> void:
	var event:=InputEventKey.new()
	event.keycode=KEY_DOWN
	event.physical_keycode=KEY_DOWN
	event.pressed=true
	Input.parse_input_event(event)
	await process_frame
	var once: Dictionary=game.model.snapshot()
	_check(game.model.player==Vector2i(5,1) and game.model.swaps==1,"first ordinary arrow input automatically swaps visible crystal")
	for echo in [true,false]:
		event.echo=echo
		Input.parse_input_event(event.duplicate())
		await process_frame
		_check(game.model.snapshot()==once,"echo and held duplicate do not repeat exchange")
	await _settle()
	_check(game.model.snapshot()==once,"idle frames never rescan directions")
	event.pressed=false
	Input.parse_input_event(event)
	await process_frame
	await _press(KEY_UP)
	_check(game.model.player==Vector2i(5,0) and game.model.swaps==2,"fresh opposite arrow intentionally swaps back once")

func _pressure_and_void_checks(solution: Dictionary) -> void:
	for index in 11:await _press(_keycode(solution["path"][index]))
	var pressed: Dictionary=game.model.snapshot()
	await _press(KEY_S)
	_check(game.progress_label.text.contains("绿板 8 / 9") and game.model.barrier_is_active(Vector2i(7,1)) and game.model.blocks_sight(Vector2i(7,1)),"real departure restores green gate and opaque sight")
	await _capture("north_11_released.png")
	await _click("Undo")
	_check(game.model.snapshot()==pressed and game.progress_label.text.contains("绿板 9 / 9"),"one actual undo restores full pressure and open gate")
	await _click("MoveRight")
	_check(game.model.player==Vector2i(3,5) and game.model.crate_id(Vector2i(1,5))==6 and not game.model.barrier_is_active(Vector2i(7,1)),"screen direction swaps nearest crystal without breaking nine-plate pressure")
	await _click("Restart")
	for index in 16:await _press(_keycode(solution["path"][index]))
	await _press(KEY_S)
	_check(game.model.player==Vector2i(10,2),"right platform includes full lower row")
	var before: Dictionary=game.model.snapshot()
	await _press(KEY_S)
	_check(game.model.snapshot()==before and game.model.level.is_void(Vector2i(10,3)),"screen's omitted lower-right region remains blocked")
	await _capture("north_11_void.png")
	await _click("Restart")

func _has_text(node: Node,value: String) -> bool:
	if node is Label and node.text.contains(value):return true
	for child in node.get_children():
		if _has_text(child,value):return true
	return false
