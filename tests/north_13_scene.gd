extends "res://tests/north_02_scene.gd"
## Real keyboard C/UDLR, pointer controls, selected hero appearance, and dual victory.
const Level=preload("res://scripts/core/level_data.gd")

func _run() -> void:
	root.size=Vector2i(1280,820)
	game=load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await _settle()
	await _click("Level13")
	_check(game.current_level_index==12 and game.model.hero_count()==2 and game.model.active_hero_id()=="blue","screen level entry selects both heroes with blue initially active")
	var initial: Dictionary=game.model.snapshot()
	_check(game.find_child("SelectedHero",true,false).text.contains("蓝色") and game.find_child("SwitchHero",true,false)!=null and game.switches_label.text=="00","visible blue selection, switch control and separate switch counter")
	_check(game.find_child("Objective",true,false).text=="两名英雄分占不同终点" and game.progress_label.text.contains("英雄终点 0 / 2"),"explicit dual-hero objective and progress")
	_check_layout(game)
	await _capture("north_13_initial.png")
	await _click("SwitchHero")
	_check(game.model.active_hero_id()=="red" and game.model.moves==1 and game.switches_label.text=="01" and game.find_child("SelectedHero",true,false).text.contains("红色"),"screen C button changes highlighted identity and counts once")
	_check(game.model.hero_position(0)==Vector2i(2,2) and game.model.hero_position(1)==Vector2i(2,4) and game.model.swaps==0,"screen switching does not move heroes or trigger blue exchange")
	_check_layout(game)
	await _capture("north_13_selected_red.png")
	await _click("Undo")
	_check(game.model.snapshot()==initial and game.find_child("SelectedHero",true,false).text.contains("蓝色"),"screen undo restores blue identity and label")
	await _repeat_c()
	await _click("Restart")
	_check(game.model.snapshot()==initial,"restart restores initial blue identity after switching")
	var path: String=JSON.parse_string(FileAccess.get_file_as_string("res://levels/solutions/north_13.json"))["path"]
	var before_final: Dictionary
	for index in path.length():
		before_final=game.model.snapshot()
		var symbol: String=path[index]
		await _press(KEY_C if symbol=="C" else _keycode(symbol))
		_check(game.model.moves==index+1 and game.model.alive and game.model.last_mechanism_error.is_empty(),"actual C/direction operation %d succeeds once" % (index+1))
		_check(game.model.is_complete()==(index==26),"actual dual victory occurs only on final input")
		if index==8:
			_check(game.model.pressure_progress("yellow_01")==Vector2i(2,2) and not game.model.blocks_sight(Vector2i(5,3)),"both real heroes hold plates and open gate sight")
			await _capture("north_13_both_plates.png")
		if index==10:
			_check(game.model.active_hero_id()=="blue" and game.model.hero_position(0)==Vector2i(5,5) and game.model.hero_position(1)==Vector2i(5,1) and game.model.swaps==1,"real blue direction swaps red across gate without selection theft or chains")
			await _capture("north_13_hero_exchange.png")
		if index==18:
			_check(game.model.occupied_exits()==1 and not game.model.is_complete() and not game.find_child("SwitchHero",true,false).disabled,"first hero goal leaves other hero controllable")
			await _capture("north_13_first_goal.png")
	_check(game.model.switches==3 and game.model.swaps==2 and game.switches_label.text=="03" and game.swaps_label.text=="02" and game.status_label.text.contains("双英雄已抵达终点"),"27 operations, three switches, two swaps and explicit visible victory")
	await _capture("north_13_completed.png")
	await _click("Undo")
	_check(game.model.snapshot()==before_final and not game.model.is_complete(),"actual victory undo restores full previous state")
	await _click("Restart")
	_check(game.model.snapshot()==initial and game.model.history_size()==0,"actual restart resets both heroes and selected identity")
	await _click("MoveDown")
	await _click("MoveRight")
	_check(game.model.player==Vector2i(3,5) and game.model.active_hero_id()=="blue" and game.model.moves==2,"screen directional inputs act only on selected blue")
	await _click("SwitchHero")
	await _click("MoveUp")
	_check(game.model.hero_position(0)==Vector2i(2,1) and game.model.hero_position(1)==Vector2i(3,5) and game.model.active_hero_id()=="red","screen direction after C acts only on selected red")
	await _click("Level12")
	_check(game.model.hero_count()==1 and game.model.switches==0 and game.model.history_size()==0 and game.find_child("SwitchHero",true,false)==null,"multi state and switch controls do not leak into old twelfth level")
	var old: Dictionary=game.model.snapshot()
	await _press(KEY_C)
	_check(game.model.snapshot()==old and game.model.history_size()==0,"single hero C stays a no-op via actual keyboard")
	await _click("Level13")
	_check(game.model.snapshot()==initial,"returning level13 resets selection and history")
	await _inactive_death_input()
	await _click("Level12")
	await _click("Level13")
	_check(game.model.snapshot()==initial,"compact captures use actual campaign start after independent death fixture")
	_check_layout(game)
	root.size=Vector2i(960,615)
	await _settle()
	_check_layout(game)
	await _capture("north_13_compact_blue.png")
	await _press(KEY_C)
	await _settle()
	_check_layout(game)
	await _capture("north_13_compact_red.png")
	print("NORTH 13 SCENE RESULT: %d checks, %d failures; display=%s" % [checks,failures,DisplayServer.get_name()])
	game.queue_free()
	await process_frame
	quit(0 if failures==0 else 1)

func _repeat_c() -> void:
	var event:=InputEventKey.new()
	event.keycode=KEY_C
	event.physical_keycode=KEY_C
	event.pressed=true
	Input.parse_input_event(event)
	await process_frame
	var once: Dictionary=game.model.snapshot()
	_check(game.model.active_hero_id()=="red" and game.model.switches==1,"fresh C switches once")
	for echo in [true,false]:
		event.echo=echo
		Input.parse_input_event(event.duplicate())
		await process_frame
		_check(game.model.snapshot()==once,"held duplicate/echo C cannot switch again during UI rebuild")
	await _settle()
	_check(game.model.snapshot()==once,"idle frames cannot switch or trigger swaps")
	event.pressed=false
	Input.parse_input_event(event)
	await process_frame
	await _press(KEY_C)
	_check(game.model.active_hero_id()=="blue" and game.model.switches==2,"release and fresh C cycles normally")
	await _press(KEY_Z)
	_check(game.model.snapshot()==once and game.find_child("SelectedHero",true,false).text.contains("红色"),"keyboard undo restores selected identity and view")

func _inactive_death_input() -> void:
	# Independent fixture uses real input after legal model initialization.
	# It is never part of the campaign walkthrough recording.
	var fixture: Dictionary={"schema_version":1,"id":"death_fixture","title":"独立死亡测试","source_note":"Non-campaign mechanism fixture","is_temporary":true,"terrain":[".......",".......","......."],
		"heroes":[{"id":"red","kind":"red","position":[1,1]},{"id":"blue","kind":"blue","position":[3,1]}],"active_hero":"red","crates":[],"targets":[],"objective":"none",
		"energy_links":[{"id":"gate","plates":[[1,1]],"activation":"all","barriers":[[3,1]],"pressure_sources":["hero","crystal"]}]}
	_check(game.model.load_level(Level.from_dictionary(fixture)),"death fixture initializes with gate open")
	game._rebuild_ui()
	game._refresh("独立测试场景")
	await _settle()
	var before: Dictionary=game.model.snapshot()
	await _press(KEY_DOWN)
	_check(not game.model.alive and game.model.hero_is_alive(0) and not game.model.hero_is_alive(1) and game.status_label.text.contains("只能撤销"),"real red input releases plate and kills inactive blue with visible lock")
	var dead: Dictionary=game.model.snapshot()
	await _press(KEY_C)
	await _press(KEY_R)
	await _press(KEY_RIGHT)
	_check(game.model.snapshot()==dead and game.find_child("SwitchHero",true,false).disabled and game.find_child("Level12",true,false).disabled,"actual C/restart/direction cannot bypass another hero death")
	await _click("Undo")
	_check(game.model.snapshot()==before and game.model.alive and game.model.hero_is_alive(1),"one screen undo revives inactive hero and restores plate, selection and gate")
