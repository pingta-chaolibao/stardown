extends "res://tests/north_02_scene.gd"
## Actual selection-only C events, undo across heroes, pointer controls and dual victory.
const Level=preload("res://scripts/core/level_data.gd")

func _run() -> void:
	root.size=Vector2i(1280,820)
	game=load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await _settle()
	await _click("Level13")
	_check(game.current_level_index==12 and game.model.hero_count()==2 and game.model.active_hero_id()=="blue","screen level entry initially selects blue")
	var initial: Dictionary=game.model.snapshot()
	_check(game.find_child("SelectedHero",true,false).text.contains("蓝色") and game.find_child("SwitchHero",true,false)!=null and game.find_child("Switches",true,false)==null,"visible blue selection, screen switch, no switch action statistic")
	_check(game.find_child("Objective",true,false).text=="两名英雄分占不同终点" and game.progress_label.text.contains("英雄终点 0 / 2"),"dual-hero objective and progress")
	_check_layout(game)
	await _capture("north_13_initial.png")
	await _click("SwitchHero")
	_check(game.model.active_hero_id()=="red" and game.model.moves==0 and game.model.history_size()==0 and game.moves_label.text=="00" and game.find_child("SelectedHero",true,false).text.contains("红色"),"screen switch changes highlight without action count or undo entry")
	_check(game.model.snapshot()==initial and game.undo_button.disabled,"selection leaves complete world unchanged and undo disabled without actual history")
	_check_layout(game)
	await _capture("north_13_selected_red.png")
	await _press(KEY_Z)
	_check(game.model.active_hero_id()=="red" and game.model.snapshot()==initial,"empty keyboard undo does not undo screen selection")
	await _click("SwitchHero")
	await _repeat_c()
	await _click("Restart")
	_check(game.model.snapshot()==initial and game.model.active_hero_id()=="blue","restart explicitly restores blue selection")
	await _selection_undo_inputs(initial)
	var path: String=JSON.parse_string(FileAccess.get_file_as_string("res://levels/solutions/north_13.json"))["path"]
	var before_final: Dictionary
	var actions:=0
	var selection_events:=0
	for index in path.length():
		before_final=game.model.snapshot()
		var symbol: String=path[index]
		if symbol=="C":selection_events+=1
		else:actions+=1
		await _press(KEY_C if symbol=="C" else _keycode(symbol))
		_check(game.model.moves==actions and game.model.history_size()==actions and game.model.alive and game.model.last_mechanism_error.is_empty(),"actual input event %d; counted actions %d" % [index+1,actions])
		_check(game.model.is_complete()==(index==26),"actual dual victory only on final input")
		if symbol=="C":_check(game.model.snapshot()==before_final,"real C leaves world and counts unchanged")
		if index==8:
			_check(game.model.moves==8 and game.model.pressure_progress("yellow_01")==Vector2i(2,2) and not game.model.blocks_sight(Vector2i(5,3)),"actual action8 opens gate with both heroes holding plates")
			await _capture("north_13_both_plates.png")
		if index==10:
			_check(game.model.active_hero_id()=="blue" and game.model.hero_position(0)==Vector2i(5,5) and game.model.hero_position(1)==Vector2i(5,1) and game.model.swaps==1 and game.model.moves==9,"actual action9 exchanges heroes without selection theft")
			await _capture("north_13_hero_exchange.png")
		if index==18:
			_check(game.model.moves==17 and game.model.occupied_exits()==1 and not game.model.is_complete() and not game.find_child("SwitchHero",true,false).disabled,"actual action17 reaches first goal while allowing selection")
			await _capture("north_13_first_goal.png")
	_check(game.model.moves==24 and selection_events==3 and game.model.swaps==2 and game.moves_label.text=="24" and game.swaps_label.text=="02" and game.status_label.text.contains("双英雄已抵达终点"),"24 actual actions and three uncounted C events reach explicit victory")
	await _capture("north_13_completed.png")
	await _click("Undo")
	_check(game.model.snapshot()==before_final and game.model.active_hero_id()=="red" and not game.model.is_complete(),"victory undo restores latest actual action and retains red selection")
	await _click("Restart")
	_check(game.model.snapshot()==initial and game.model.active_hero_id()=="blue" and game.model.history_size()==0,"restart restores world and initial blue selection")
	await _click("MoveDown")
	await _click("MoveRight")
	_check(game.model.player==Vector2i(3,5) and game.model.active_hero_id()=="blue" and game.model.moves==2,"screen directions count only blue actual moves")
	await _click("SwitchHero")
	await _click("MoveUp")
	_check(game.model.hero_position(0)==Vector2i(2,1) and game.model.hero_position(1)==Vector2i(3,5) and game.model.active_hero_id()=="red" and game.model.moves==3,"screen C is uncounted, next red direction is third action")
	await _click("Level12")
	_check(game.model.hero_count()==1 and game.model.history_size()==0 and game.find_child("SwitchHero",true,false)==null,"multi control state does not leak into twelfth level")
	var old: Dictionary=game.model.snapshot()
	await _press(KEY_C)
	_check(game.model.snapshot()==old and game.model.history_size()==0,"single hero C remains a no-op")
	await _click("Level13")
	_check(game.model.snapshot()==initial and game.model.active_hero_id()=="blue","returning to level13 resets selection and history")
	await _inactive_death_input()
	await _click("Level12")
	await _click("Level13")
	_check(game.model.snapshot()==initial and game.model.active_hero_id()=="blue","compact captures use actual campaign start after independent fixture")
	_check_layout(game)
	root.size=Vector2i(960,615)
	await _settle()
	_check_layout(game)
	await _capture("north_13_compact_blue.png")
	await _press(KEY_C)
	await _settle()
	_check_layout(game)
	_check(game.model.moves==0 and game.model.history_size()==0 and game.model.active_hero_id()=="red","compact C only changes highlight")
	await _capture("north_13_compact_red.png")
	print("NORTH 13 SCENE RESULT: %d checks, %d failures; display=%s" % [checks,failures,DisplayServer.get_name()])
	game.queue_free()
	await process_frame
	quit(0 if failures==0 else 1)

func _repeat_c() -> void:
	var initial: Dictionary=game.model.snapshot()
	var event:=InputEventKey.new()
	event.keycode=KEY_C
	event.physical_keycode=KEY_C
	event.pressed=true
	Input.parse_input_event(event)
	await process_frame
	_check(game.model.active_hero_id()=="red" and game.model.snapshot()==initial and game.model.history_size()==0,"fresh C switches once without action history")
	for echo in [true,false]:
		event.echo=echo
		Input.parse_input_event(event.duplicate())
		await process_frame
		_check(game.model.active_hero_id()=="red" and game.model.snapshot()==initial,"held duplicate/echo C cannot cycle again across UI rebuild")
	await _settle()
	_check(game.model.active_hero_id()=="red" and game.model.snapshot()==initial,"idle frames do not switch or activate abilities")
	event.pressed=false
	Input.parse_input_event(event)
	await process_frame
	await _press(KEY_C)
	_check(game.model.active_hero_id()=="blue" and game.model.snapshot()==initial and game.model.history_size()==0,"fresh released C cycles without action count")
	await _press(KEY_Z)
	_check(game.model.active_hero_id()=="blue" and game.model.snapshot()==initial and game.find_child("SelectedHero",true,false).text.contains("蓝色"),"empty undo cannot reverse keyboard C or its highlight")

func _selection_undo_inputs(initial: Dictionary) -> void:
	await _press(KEY_DOWN)
	await _press(KEY_C)
	_check(game.model.active_hero_id()=="red" and game.model.moves==1 and game.model.history_size()==1,"direction then C retains just one actual history entry")
	await _press(KEY_Z)
	_check(game.model.snapshot()==initial and game.model.active_hero_id()=="red" and game.find_child("SelectedHero",true,false).text.contains("红色"),"keyboard undo reverts blue move while retaining selected red and its highlight")
	await _click("MoveUp")
	var red_moved: Dictionary=game.model.snapshot()
	await _click("SwitchHero")
	await _click("MoveDown")
	_check(game.model.moves==2 and game.model.history_size()==2 and game.model.active_hero_id()=="blue","screen C between red and blue moves is not counted")
	await _click("Undo")
	_check(game.model.snapshot()==red_moved and game.model.active_hero_id()=="blue","screen undo reverts latest blue action and keeps blue selected")
	await _press(KEY_Z)
	_check(game.model.snapshot()==initial and game.model.active_hero_id()=="blue" and game.model.moves==0 and game.model.history_size()==0,"next undo reverts red action while keeping blue selection")
	await _press(KEY_C)
	await _click("Restart")
	_check(game.model.snapshot()==initial and game.model.active_hero_id()=="blue","restart resets selection after empty-history switches")

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
