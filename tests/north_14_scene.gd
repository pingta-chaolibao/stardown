extends "res://tests/north_02_scene.gd"
const GATES=[Vector2i(8,1),Vector2i(8,5)]

func _run() -> void:
	root.size=Vector2i(1280,820)
	game=load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await _settle()
	await _click("Level14")
	var initial: Dictionary=game.model.snapshot()
	_check(game.current_level_index==13 and game.model.active_hero_id()=="red" and game.model.hero_count()==2 and game.model.hero_position(1)==Vector2i(1,5),"actual level14 entry initially selects red with green at confirmed start")
	_check(game.pulls_label!=null and game.pushes_label!=null and game.swaps_label==null and game.find_child("SelectedHero",true,false).text.contains("红色"),"red/green UI shows push/pull counters and correct red identity")
	_check(not game.model.level.is_floor(Vector2i(5,0)) and game.progress_label.text.contains("黄板 0 / 1"),"latest marker6 wall and one plate correctly loaded")
	_check_layout(game)
	await _capture("north_14_initial.png")
	await _click("SwitchHero")
	_check(game.model.active_hero_id()=="green" and game.find_child("SelectedHero",true,false).text.contains("绿色") and game.model.snapshot()==initial and game.model.history_size()==0 and game.moves_label.text=="00","screen C selects green hue/label without counting or undo history")
	_check_layout(game)
	await _capture("north_14_selected_green.png")
	await _press(KEY_Z)
	_check(game.model.active_hero_id()=="green" and game.model.snapshot()==initial,"empty undo retains green selection")
	await _click("Restart")
	await _click("MoveRight")
	await _click("SwitchHero")
	await _click("Undo")
	_check(game.model.snapshot()==initial and game.model.active_hero_id()=="green" and game.find_child("SelectedHero",true,false).text.contains("绿色"),"screen undo reverts red movement and retains green selection")
	await _click("MoveDown")
	await _press(KEY_C)
	await _press(KEY_Z)
	_check(game.model.snapshot()==initial and game.model.active_hero_id()=="red","keyboard undo reverts green movement without reverting C")
	await _repeat_c()
	await _click("Restart")
	var solution: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://levels/solutions/north_14.json"))
	var actions:=0
	var selections:=0
	var before_final: Dictionary
	for symbol in solution["path"]:
		before_final=game.model.snapshot()
		if symbol=="C":selections+=1
		else:actions+=1
		await _press(KEY_C if symbol=="C" else _keycode(symbol))
		_check(game.model.moves==actions and game.model.history_size()==actions and game.model.alive and game.model.last_mechanism_error.is_empty(),"actual red/green input counts only action %d" % actions)
		_check(game.model.is_complete()==(actions==35),"both different goals required for actual victory")
		if symbol=="C":_check(game.model.snapshot()==before_final,"every actual C leaves the complete world unchanged")
		else:
			if actions==15:
				_check(game.model.hero_position(0)==Vector2i(5,3) and game.model.hero_position(1)==Vector2i(7,3) and game.model.crate_id(Vector2i(6,3))==0 and game.model.pulls==2,"actual red input atomically pushes crystal+green without passive pull")
				await _capture("north_14_mixed_push.png")
			if actions==24:
				_check(game.model.active_hero_id()=="green" and game.model.pressure_is_active("yellow_01") and game.progress_label.text.contains("黄板 1 / 1"),"actual green hero opens both gates by standing on single plate")
				for gate in GATES:_check(not game.model.blocks_sight(gate) and game.model.is_walkable(gate),"both gates simultaneously open movement and sight")
				await _capture("north_14_hero_plate.png")
			if actions==26:
				_check(game.model.hero_position(0)==GATES[0],"actual red crosses upper open gate")
				await _capture("north_14_red_gate.png")
			if actions==29:
				_check(game.model.occupied_exits()==1 and not game.model.is_complete(),"first goal does not finish the other hero")
				await _capture("north_14_first_goal.png")
			if actions==30:
				_check(game.model.active_hero_id()=="green" and game.model.crate_id(Vector2i(9,3))==0 and game.model.pulls==4 and game.model.pressure_is_active("yellow_01"),"actual green single pull hands plate to purple crystal continuously")
				await _capture("north_14_crystal_plate.png")
			if actions==32:
				_check(game.model.hero_position(1)==GATES[1],"actual green crosses lower gate held open by crystal")
				await _capture("north_14_green_gate.png")
	_check(game.model.moves==35 and selections==15 and game.model.pushes==6 and game.model.pulls==4 and game.moves_label.text=="35" and game.pushes_label.text=="06" and game.pulls_label.text=="04" and game.status_label.text.contains("双英雄已抵达终点"),"actual35 actions+15free selections,6 pushes/4 pulls and explicit dual victory")
	await _capture("north_14_completed.png")
	await _click("Undo")
	_check(game.model.snapshot()==before_final and game.model.active_hero_id()=="green" and not game.model.is_complete(),"victory undo restores actual last action and retains green")
	await _click("Restart")
	_check(game.model.snapshot()==initial and game.model.active_hero_id()=="red" and game.model.history_size()==0,"victory restart restores original red selection")
	await _release_inputs(solution)
	await _click("Level13")
	_check(game.model.active_hero_id()=="blue" and game.model.heroes()[1]["kind"]=="blue" and game.model.history_size()==0 and game.swaps_label!=null and game.pulls_label==null,"red/green14 state and UI do not leak into corrected red/blue13")
	await _press(KEY_C)
	_check(game.model.moves==0 and game.model.history_size()==0 and game.model.active_hero_id()=="red","previous13 still has free C")
	await _click("Level14")
	_check(game.model.snapshot()==initial and game.model.active_hero_id()=="red" and game.pulls_label!=null and game.swaps_label==null,"return14 restores red/green roster, counters and history")
	_check_layout(game)
	root.size=Vector2i(960,615)
	await _settle()
	_check_layout(game)
	await _capture("north_14_compact_red.png")
	await _click("SwitchHero")
	_check(game.model.active_hero_id()=="green" and game.model.moves==0 and game.find_child("SelectedHero",true,false).text.contains("绿色"),"compact physical mouse correctly selects green under viewport scaling")
	_check_layout(game)
	await _capture("north_14_compact_green.png")
	print("NORTH 14 SCENE RESULT: %d checks, %d failures; display=%s" % [checks,failures,DisplayServer.get_name()])
	game.queue_free()
	await process_frame
	quit(0 if failures==0 else 1)

func _repeat_c() -> void:
	var before: Dictionary=game.model.snapshot()
	var event:=InputEventKey.new()
	event.keycode=KEY_C;event.physical_keycode=KEY_C;event.pressed=true
	Input.parse_input_event(event)
	await process_frame
	_check(game.model.active_hero_id()=="green" and game.model.snapshot()==before,"fresh C selects green without action")
	for echo in [true,false]:
		event.echo=echo
		Input.parse_input_event(event.duplicate())
		await process_frame
		_check(game.model.active_hero_id()=="green" and game.model.snapshot()==before,"C echo/held duplicate cannot cycle after view rebuild")
	event.pressed=false;Input.parse_input_event(event)
	await process_frame
	await _press(KEY_C)
	_check(game.model.active_hero_id()=="red" and game.model.snapshot()==before and game.model.history_size()==0,"released fresh C cycles normally with no history")

func _release_inputs(solution: Dictionary) -> void:
	for symbol in solution["path"]:
		if game.model.moves>=24:break
		await _press(KEY_C if symbol=="C" else _keycode(symbol))
	var held: Dictionary=game.model.snapshot()
	await _press(KEY_DOWN)
	for gate in GATES:_check(game.model.barrier_is_active(gate) and game.model.blocks_sight(gate) and not game.model.is_walkable(gate),"actual departure releases both gates together")
	await _capture("north_14_released.png")
	await _click("Undo")
	_check(game.model.snapshot()==held and game.model.active_hero_id()=="green","screen undo restores both gates open and retains green")
	await _press(KEY_C)
	await _press(KEY_Z)
	_check(game.model.moves==23 and game.model.active_hero_id()=="red" and not game.model.pressure_is_active("yellow_01"),"C then undo rolls back green plate arrival while keeping red selected")
	await _click("Restart")
