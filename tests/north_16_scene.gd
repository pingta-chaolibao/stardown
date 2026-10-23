extends "res://tests/north_02_scene.gd"
const GATE=Vector2i(7,1)
const MIXED_PREFIX="ULLLLRCURRRRCLLCLLLLLLLL"

func _run() -> void:
	root.size=Vector2i(1280,820)
	game=load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await _settle()
	await _click("Level16")
	var initial: Dictionary=game.model.snapshot()
	_check(game.current_level_index==15 and game.model.active_hero_id()=="blue" and game.model.hero_position(0)==Vector2i(5,1) and game.model.hero_position(1)==Vector2i(5,2),"actual16 entry selects confirmed blue/red starts")
	_check(game.model.level.exit_color=="purple" and game._goal_name()=="紫色终点" and game._goal_color()==game.board.GOAL_PURPLE and not game.model.level.is_floor(Vector2i(10,2)),"purple discs are ordinary goals,33 remains blocked")
	_check(game.pushes_label!=null and game.swaps_label!=null and game.pulls_label==null and game.find_child("SelectedHero",true,false).text.contains("蓝色"),"red/blue roster has pushing/exchange, no pull capability")
	_check_layout(game)
	await _capture("north_16_initial.png")
	await _press(KEY_UP)
	_check(game.model.hero_position(0)==Vector2i(5,2) and game.model.hero_position(1)==Vector2i(5,1) and game.model.swaps==1,"ordinary up input swaps first visible red hero")
	await _click("SwitchHero")
	await _click("Undo")
	_check(game.model.snapshot()==initial and game.model.active_hero_id()=="red" and game.find_child("SelectedHero",true,false).text.contains("红色"),"screen switch then undo rolls back blue action and retains red")
	await _capture("north_16_selected_red.png")
	await _press(KEY_Z)
	_check(game.model.snapshot()==initial and game.model.active_hero_id()=="red","empty undo never undoes selection")
	await _click("SwitchHero")
	await _repeat_c()
	await _click("Restart")
	await _repeat_direction()
	await _click("Restart")
	var solution: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://levels/solutions/north_16.json"))
	var actions:=0
	var selections:=0
	var before_final: Dictionary
	for symbol in solution["path"]:
		before_final=game.model.snapshot()
		if symbol=="C":selections+=1
		else:actions+=1
		await _press(KEY_C if symbol=="C" else _keycode(symbol))
		_check(game.model.moves==actions and game.model.history_size()==actions and game.model.alive and game.model.pushes==0 and game.model.pulls==0 and game.model.last_mechanism_error.is_empty(),"actual16 input counts actual action %d only" % actions)
		_check(game.model.is_complete()==(actions==15),"two different ordinary purple goals required")
		if symbol=="C":_check(game.model.snapshot()==before_final,"every C only changes highlight without history or action")
		else:
			if actions==1:await _capture("north_16_first_hero_exchange.png")
			if actions==5:
				_check(game.model.player==Vector2i(1,1) and game.model.pressure_is_active("yellow_01") and not game.model.blocks_sight(GATE),"blue holds plate to open energy movement/sight")
				await _capture("north_16_blue_plate.png")
			if actions==6:
				_check(game.model.player==Vector2i(10,1) and game.model.crate_id(Vector2i(1,1))==0 and not game.model.barrier_is_active(GATE),"blue exchanges crystal onto plate with continuous pressure")
				await _capture("north_16_crystal_handoff.png")
			if actions==9:
				_check(game.model.hero_position(0)==GATE,"actual red walks through open gate")
				await _capture("north_16_red_gate.png")
			if actions==12:
				_check(game.model.hero_position(0)==Vector2i(10,1) and game.model.hero_position(1)==Vector2i(9,1) and game.model.active_hero_id()=="blue" and game.model.swaps==3,"near red before distant crystal, selected blue identity remains")
				await _capture("north_16_near_hero_exchange.png")
			if actions==13:
				_check(game.model.player==Vector2i(9,0) and game.model.occupied_exits()==1 and not game.model.is_complete(),"blue walks onto upper purple disc and stays there, no teleport")
				await _capture("north_16_first_goal.png")
	_check(actions==15 and selections==3 and game.model.swaps==3 and game.moves_label.text=="15" and game.pushes_label.text=="00" and game.swaps_label.text=="03" and game.status_label.text.contains("双英雄已抵达终点"),"15actual actions+3free switches,3swaps,0push and explicit dual victory")
	await _capture("north_16_completed.png")
	await _click("Undo")
	_check(game.model.snapshot()==before_final and game.model.active_hero_id()=="red" and not game.model.is_complete(),"victory undo restores actual final move and retains red")
	await _click("Restart")
	_check(game.model.snapshot()==initial and game.model.active_hero_id()=="blue" and game.model.history_size()==0,"victory restart restores initial blue and closed gate")
	await _mixed_inputs()
	await _death_inputs(solution)
	await _click("Level15")
	_check(game.model.active_hero_id()=="blue" and game.model.level.exit_color=="green" and game.pulls_label!=null and game.pushes_label==null and game.model.history_size()==0,"purple goals/red roster and history do not leak into blue/green15")
	await _click("Level16")
	_check(game.model.snapshot()==initial and game.model.active_hero_id()=="blue" and game.model.level.exit_color=="purple" and game.pushes_label!=null and game.pulls_label==null,"return16 restores purple/red-blue presentation and history")
	_check_layout(game)
	root.size=Vector2i(960,615)
	await _settle()
	_check_layout(game)
	await _capture("north_16_compact_blue.png")
	await _click("SwitchHero")
	_check(game.model.active_hero_id()=="red" and game.model.moves==0 and game.model.history_size()==0,"compact physical mouse switch is free")
	_check_layout(game)
	await _capture("north_16_compact_red.png")
	print("NORTH 16 SCENE RESULT: %d checks, %d failures; display=%s" % [checks,failures,DisplayServer.get_name()])
	game.queue_free()
	await process_frame
	quit(0 if failures==0 else 1)

func _repeat_c() -> void:
	var before: Dictionary=game.model.snapshot()
	var event:=InputEventKey.new()
	event.keycode=KEY_C;event.physical_keycode=KEY_C;event.pressed=true
	Input.parse_input_event(event);await process_frame
	_check(game.model.active_hero_id()=="red" and game.model.snapshot()==before,"fresh C selects red without world action")
	for echo in [true,false]:
		event.echo=echo;Input.parse_input_event(event.duplicate());await process_frame
		_check(game.model.active_hero_id()=="red" and game.model.snapshot()==before,"C echo/held duplicate ignored across view rebuild")
	event.pressed=false;Input.parse_input_event(event);await process_frame
	await _press(KEY_C)
	_check(game.model.active_hero_id()=="blue" and game.model.snapshot()==before and game.model.history_size()==0,"released fresh C cycles normally")

func _repeat_direction() -> void:
	var event:=InputEventKey.new()
	event.keycode=KEY_UP;event.physical_keycode=KEY_UP;event.pressed=true
	Input.parse_input_event(event);await process_frame
	var once: Dictionary=game.model.snapshot()
	_check(game.model.player==Vector2i(5,1) and game.model.swaps==1,"fresh ordinary arrow exchanges once")
	for echo in [true,false]:
		event.echo=echo;Input.parse_input_event(event.duplicate());await process_frame
		_check(game.model.snapshot()==once,"direction echo/held duplicate does not move again")
	await _settle()
	_check(game.model.snapshot()==once,"idle frames never exchange automatically")
	event.pressed=false;Input.parse_input_event(event);await process_frame
	await _press(KEY_UP)
	_check(game.model.player==Vector2i(5,0) and game.model.moves==2 and game.model.swaps==1,"released fresh direction performs the next move")

func _play_inputs(path: String) -> void:
	for symbol in path:await _press(KEY_C if symbol=="C" else _keycode(symbol))

func _mixed_inputs() -> void:
	await _play_inputs(MIXED_PREFIX)
	_check(game.model.moves==21 and game.model.pushes==8 and game.model.swaps==4 and game.model.hero_position(0)==Vector2i(2,1) and game.model.hero_position(1)==Vector2i(0,1) and game.model.crate_id(Vector2i(1,1))==0 and game.model.pressure_is_active("yellow_01"),"legal screen campaign side path pushes crystal+blue together with continuous plate pressure")
	await _capture("north_16_mixed_push.png")
	var before: Dictionary=game.model.snapshot()
	await _click("MoveLeft")
	_check(game.model.snapshot()==before and game.model.history_size()==21,"screen mixed push blocked at boundary is fully atomic")
	await _click("Undo")
	_check(game.model.hero_position(0)==Vector2i(3,1) and game.model.hero_position(1)==Vector2i(1,1) and game.model.crate_id(Vector2i(2,1))==0 and game.model.active_hero_id()=="red" and game.model.pressure_is_active("yellow_01"),"one screen undo restores complete mixed line and pressure while retaining red")
	await _click("Restart")

func _death_inputs(solution: Dictionary) -> void:
	for symbol in solution["path"]:
		if game.model.moves>=9:break
		await _press(KEY_C if symbol=="C" else _keycode(symbol))
	await _play_inputs("CLLCLLLC")
	var alive: Dictionary=game.model.snapshot()
	_check(game.model.active_hero_id()=="blue" and game.model.hero_position(0)==GATE and game.model.player==Vector2i(1,1) and game.model.crate_id(Vector2i(6,1))==0,"legal side path leaves inactive red in open energy and blue holding plate")
	await _press(KEY_DOWN)
	_check(not game.model.alive and not game.model.hero_is_alive(0) and game.model.hero_is_alive(1) and game.status_label.text.contains("只能撤销"),"actual blue departure restores energy and kills inactive red")
	await _capture("north_16_death_inactive_red.png")
	var dead: Dictionary=game.model.snapshot()
	await _press(KEY_C);await _press(KEY_R);await _press(KEY_LEFT);await _click("Level15")
	_check(game.model.snapshot()==dead and game.current_level_index==15 and game.model.active_hero_id()=="blue" and game.find_child("SwitchHero",true,false).disabled and game.restart_button.disabled,"C/R/direction/level cannot bypass inactive red death")
	await _click("Undo")
	_check(game.model.snapshot()==alive and game.model.hero_is_alive(0) and game.model.active_hero_id()=="blue" and not game.model.blocks_sight(GATE),"one actual undo revives red and restores open energy while keeping blue")
	await _capture("north_16_revived_red.png")
	await _click("Restart")
