extends "res://tests/north_02_scene.gd"
const GATE=Vector2i(2,3)

func _run() -> void:
	root.size=Vector2i(1280,820)
	game=load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await _settle()
	await _click("Level15")
	var initial: Dictionary=game.model.snapshot()
	_check(game.current_level_index==14 and game.model.active_hero_id()=="blue" and game.model.hero_position(1)==Vector2i(3,3),"actual15 entry selects blue and confirmed green start")
	_check(game.swaps_label!=null and game.pulls_label!=null and game.pushes_label==null and game.find_child("SelectedHero",true,false).text.contains("蓝色"),"blue/green roster has swap+pull statistics, no push capability label")
	_check(not game.model.level.is_floor(Vector2i(2,2)) and not game.model.level.is_floor(Vector2i(2,4)) and game.progress_label.text.contains("黄板 0 / 2"),"25/47 walls and both plates loaded correctly")
	_check_layout(game)
	await _capture("north_15_initial.png")
	await _press(KEY_RIGHT)
	_check(game.model.player==Vector2i(8,0) and game.model.crate_id(Vector2i(4,0))==0 and game.model.swaps==1,"ordinary arrow swaps first visible pink instead of walking")
	await _click("SwitchHero")
	await _click("Undo")
	_check(game.model.snapshot()==initial and game.model.active_hero_id()=="green" and game.find_child("SelectedHero",true,false).text.contains("绿色"),"screen C then undo reverses blue action while retaining green highlight")
	await _capture("north_15_selected_green.png")
	await _press(KEY_Z)
	_check(game.model.snapshot()==initial and game.model.active_hero_id()=="green","empty undo does not undo selection")
	await _click("MoveUp")
	await _press(KEY_C)
	await _press(KEY_Z)
	_check(game.model.snapshot()==initial and game.model.active_hero_id()=="blue","direction/C/undo reverts green action and keeps blue")
	await _repeat_c()
	await _click("Restart")
	var solution: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://levels/solutions/north_15.json"))
	var actions:=0
	var selections:=0
	var before_final: Dictionary
	for symbol in solution["path"]:
		before_final=game.model.snapshot()
		if symbol=="C":selections+=1
		else:actions+=1
		await _press(KEY_C if symbol=="C" else _keycode(symbol))
		_check(game.model.moves==actions and game.model.history_size()==actions and game.model.alive and game.model.pushes==0 and game.model.last_mechanism_error.is_empty(),"real15 input counts only actual action %d" % actions)
		_check(game.model.is_complete()==(actions==61),"real victory requires both unassigned hero goals")
		if symbol=="C":_check(game.model.snapshot()==before_final,"all20 real C events leave world and history unchanged")
		else:
			if actions==7:
				_check(game.model.hero_position(0)==Vector2i(6,0) and game.model.hero_position(1)==Vector2i(4,0) and game.model.active_hero_id()=="blue" and game.model.pulls==0,"actual blue chooses nearer green before pink and green never auto-pulls when swapped")
				await _capture("north_15_first_hero_exchange.png")
			if actions==13:
				_check(game.model.crate_id(Vector2i(6,1))==0 and game.model.pulls==1,"actual green single-pulls pink into upper narrow corridor")
				await _capture("north_15_pink_pull.png")
			if actions==24:
				_check(game.model.player==Vector2i(9,2) and game.model.crate_id(Vector2i(6,2))==0 and game.model.hero_position(1)==Vector2i(10,2),"nearer visible crystal is chosen before farther green hero")
				await _capture("north_15_nearest_crystal.png")
			if actions==32:
				_check(game.model.player==Vector2i(7,6) and game.model.crate_id(Vector2i(6,6))==1,"blue exchanges bottom blue-purple out of the dead-end")
				await _capture("north_15_lower_crystal.png")
			if actions==45:
				_check(game.model.pressure_is_active("yellow_01") and not game.model.blocks_sight(GATE) and game.progress_label.text.contains("黄板 2 / 2"),"green plus pink open global AND gate")
				await _capture("north_15_all_plates.png")
			if actions==52:
				_check(game.model.hero_position(0)==GATE and game.model.is_walkable(GATE),"actual blue crosses open gate")
				await _capture("north_15_blue_gate.png")
			if actions==55:
				_check(game.model.crate_id(Vector2i(4,3))==1 and game.model.crate_id(Vector2i(10,3))==0 and game.model.pulls==11 and not game.model.barrier_is_active(GATE),"green pulls blue-purple onto near plate continuously")
				await _capture("north_15_crystal_handoff.png")
			if actions==56:
				_check(game.model.hero_position(0)==Vector2i(3,3) and game.model.hero_position(1)==Vector2i(0,3) and game.model.active_hero_id()=="blue" and game.model.swaps==7,"blue exchanges green across transparent energy with stable identity")
				await _capture("north_15_gate_hero_exchange.png")
			if actions==57:
				_check(game.model.occupied_exits()==1 and not game.model.is_complete(),"green first goal does not end blue control")
				await _capture("north_15_first_goal.png")
	_check(game.model.moves==61 and selections==20 and game.model.pulls==11 and game.model.swaps==7 and game.moves_label.text=="61" and game.pulls_label.text=="11" and game.swaps_label.text=="07" and game.status_label.text.contains("双英雄已抵达终点"),"61actual actions,20free selections,11pulls/7swaps and explicit dual victory")
	await _capture("north_15_completed.png")
	await _click("Undo")
	_check(game.model.snapshot()==before_final and game.model.active_hero_id()=="blue" and not game.model.is_complete(),"victory undo restores last actual action and retains blue")
	await _click("Restart")
	_check(game.model.snapshot()==initial and game.model.active_hero_id()=="blue" and game.model.history_size()==0,"victory restart restores both crystal identities and initial blue")
	await _blockers()
	await _death_inputs(solution)
	await _click("Level14")
	_check(game.model.active_hero_id()=="red" and game.model.history_size()==0 and game.pushes_label!=null and game.swaps_label==null and game.pulls_label!=null,"blue/green15 does not leak roster, counters or history into red/green14")
	await _press(KEY_C)
	_check(game.model.moves==0 and game.model.history_size()==0 and game.model.active_hero_id()=="green","previous14 keeps free C")
	await _click("Level15")
	_check(game.model.snapshot()==initial and game.model.active_hero_id()=="blue" and game.swaps_label!=null and game.pushes_label==null,"return15 restores blue/green state and swap/pull UI")
	_check_layout(game)
	root.size=Vector2i(960,615)
	await _settle()
	_check_layout(game)
	await _capture("north_15_compact_blue.png")
	await _click("SwitchHero")
	_check(game.model.active_hero_id()=="green" and game.moves_label.text=="00" and game.model.history_size()==0,"compact physical mouse C selects green without action or history")
	_check_layout(game)
	await _capture("north_15_compact_green.png")
	print("NORTH 15 SCENE RESULT: %d checks, %d failures; display=%s" % [checks,failures,DisplayServer.get_name()])
	game.queue_free()
	await process_frame
	quit(0 if failures==0 else 1)

func _repeat_c() -> void:
	var before: Dictionary=game.model.snapshot()
	var event:=InputEventKey.new()
	event.keycode=KEY_C;event.physical_keycode=KEY_C;event.pressed=true
	Input.parse_input_event(event)
	await process_frame
	_check(game.model.active_hero_id()=="green" and game.model.snapshot()==before,"fresh C changes selection only")
	for echo in [true,false]:
		event.echo=echo;Input.parse_input_event(event.duplicate())
		await process_frame
		_check(game.model.active_hero_id()=="green" and game.model.snapshot()==before,"echo and held duplicate cannot repeat C after view rebuild")
	await _settle()
	_check(game.model.active_hero_id()=="green" and game.model.snapshot()==before,"idle frames never auto-exchange or select")
	event.pressed=false;Input.parse_input_event(event)
	await process_frame
	await _press(KEY_C)
	_check(game.model.active_hero_id()=="blue" and game.model.snapshot()==before and game.model.history_size()==0,"release and fresh C cycles freely")

func _blockers() -> void:
	await _click("SwitchHero")
	var before: Dictionary=game.model.snapshot()
	await _press(KEY_LEFT)
	_check(game.model.snapshot()==before and game.model.moves==0 and game.status_label.text.contains("能量"),"closed energy blocks actual green input")
	await _click("MoveUp")
	before=game.model.snapshot()
	await _click("MoveLeft")
	_check(game.model.snapshot()==before and game.model.player==Vector2i(3,2) and game.status_label.text.contains("墙"),"actual screen input respects latest25 blocked correction")
	await _click("Restart")

func _death_inputs(solution: Dictionary) -> void:
	# Legal campaign prefix plus a deliberate side move, never part of formal video.
	for symbol in solution["path"]:
		if game.model.moves>=52:break
		await _press(KEY_C if symbol=="C" else _keycode(symbol))
	await _press(KEY_C)
	var alive: Dictionary=game.model.snapshot()
	_check(game.model.active_hero_id()=="green" and game.model.hero_position(0)==GATE,"legal prefix leaves inactive blue in open energy")
	await _press(KEY_DOWN)
	_check(not game.model.alive and not game.model.hero_is_alive(0) and game.model.hero_is_alive(1) and game.status_label.text.contains("只能撤销"),"actual green plate release restores gate and kills inactive blue")
	await _capture("north_15_death_inactive_blue.png")
	var dead: Dictionary=game.model.snapshot()
	await _press(KEY_C)
	await _press(KEY_R)
	await _press(KEY_LEFT)
	await _click("Level14")
	_check(game.model.snapshot()==dead and game.current_level_index==14 and game.model.active_hero_id()=="green" and game.find_child("SwitchHero",true,false).disabled and game.restart_button.disabled,"C/R/direction/level selection cannot bypass death of another hero")
	await _click("Undo")
	_check(game.model.snapshot()==alive and game.model.hero_is_alive(0) and game.model.active_hero_id()=="green" and not game.model.blocks_sight(GATE),"one actual undo revives blue, opens gate and retains green selection")
	await _capture("north_15_revived_blue.png")
	await _press(KEY_Z)
	_check(game.model.moves==51 and game.model.hero_position(0)==Vector2i(3,3) and game.model.active_hero_id()=="green","next undo reverts blue real move rather than previous C")
	await _click("Restart")
