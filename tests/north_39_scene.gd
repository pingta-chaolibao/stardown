extends "res://tests/north_02_scene.gd"
func _cell(a:Array)->Vector2i:return Vector2i(a[0],a[1])
func _input(symbol:String)->void:
	if symbol=="C":await _press(KEY_C)
	else:await _press(_keycode(symbol))
func _prefix(sequence:String)->void:
	for k in sequence:await _input(k)
func _run()->void:
	root.size=Vector2i(1280,820);game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await _settle();await _click("Level39")
	_check(game.current_level_index==38 and game.model.level.id=="north_hero_39" and game.LEVEL_TITLES[38]=="第三十九关","real39pooledcardandtitle")
	_check(game.model.hero_count()==2 and game.model.active_kind()=="green" and game.model.level.monster_clear_barriers.is_empty(),"confirmedgreen/redduo")
	_check(game.board._mechanism_tint(false,Vector2i(3,1))==game.board.MECHANISM_BLUE and game.board._mechanism_tint(false,Vector2i(3,3))==game.board.GOLD,"per-cellblue/yellowpalette")
	_check(game.progress_label.text.contains("蓝板") and game.progress_label.text.contains("黄板") and game.progress_label.text.contains("1/1"),"separatepressureprogresslabels")
	var initial:Dictionary=game.model.snapshot();_check_layout(game);await _capture("north_39_initial.png")
	var key:=InputEventKey.new();key.keycode=KEY_W;key.physical_keycode=KEY_W;key.pressed=true;Input.parse_input_event(key);await _settle();var once:Dictionary=game.model.snapshot()
	for echo in [true,false,true]:key.echo=echo;Input.parse_input_event(key);await _settle();_check(game.model.snapshot()==once and game.model.moves==1,"held/echoignored")
	key.pressed=false;Input.parse_input_event(key);await _settle();await _click("Undo");_check(game.model.snapshot()==initial,"screenUndo")
	await _click("SwitchHero");_check(game.model.snapshot()==initial and game.model.active_hero_index==1 and game.model.history_size()==0,"screenCfreeandnoUndosnapshot")
	await _press(KEY_Z);_check(game.model.snapshot()==initial and game.model.active_hero_index==1,"emptyUndokeepscurrentselection")
	await _click("Restart");_check(game.model.snapshot()==initial and game.model.active_hero_index==0,"restartrestoresgreenchoice")
	var proof:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://artifacts/verification/north_39_route.json"))
	var side:Dictionary=proof["fatal_sides"]["energy"];await _prefix(side["prefix"]);var safe:Dictionary=game.model.snapshot();await _input(side["direction"])
	_check(not game.model.alive and not game.model.heroes()[0]["alive"] and game.model.heroes()[1]["alive"] and game.model.death_reason=="energy","actuallegalinactiveGreenblueenergydeath")
	var dead:Dictionary=game.model.snapshot();await _press(KEY_C);await _press(KEY_R);await _click("BackToLevels");_check(game.model.snapshot()==dead and not game.menu.visible,"deathcannotbypassC/restart/menu")
	await _capture("north_39_death_energy.png");await _click("Undo");_check(game.model.snapshot()==safe and game.model.alive and game.model.active_hero_index==1,"onlyUndoreviveswhilekeepingredselected");await _capture("north_39_undo_revived.png");await _click("Restart")
	for color in proof["blocked_energy_sides"]:
		side=proof["blocked_energy_sides"][color];await _prefix(side["prefix"]);var blocked:Dictionary=game.model.snapshot();await _input(side["direction"]);_check(game.model.snapshot()==blocked and game.model.barrier_is_active(_cell(side["cell"])),"bothcoloredsolidbarriersblockwithoutattackadvance")
		await _capture("north_39_blocked_"+color+".png");await _click("Restart")
	var sol:Dictionary=proof["solution"];var history:Array[Dictionary]=[];var final_before:Dictionary={}
	for i in sol["path"].length():
		var symbol:String=sol["path"][i];var before:Dictionary=game.model.snapshot()
		if symbol=="C":
			if i%2==0:await _click("SwitchHero")
			else:await _press(KEY_C)
			_check(game.model.snapshot()==before,"selectiononlynoactions/pressure/attacks")
		else:
			history.append(before);final_before=before
			if i%7==0:await _click({"U":"MoveUp","D":"MoveDown","L":"MoveLeft","R":"MoveRight"}[symbol])
			else:await _press(_keycode(symbol))
		var row:Dictionary=proof["trace"][i]
		_check(game.model.alive and game.model.active_hero_index==int(row["selected"]) and game.model.moves==int(row["actions"]) and game.model.pushes==int(row["pushes"]) and game.model.pulls==int(row["pulls"]),"actualkeys/screen/freeCmatchindependentstate")
		for h in 2:_check(game.model.heroes()[h]["position"]==_cell(row["heroes"][h]) and game.model.heroes()[h]["alive"],"bothheropositionsandidentity")
		_check(game.model.crate_id(_cell(row["crystal"]))==0,"stablecrystalidentity")
		for m in 3:_check(game.model.monsters()[m]["position"]==_cell(row["monsters"][m]) and game.model.monsters()[m]["alive"]==row["monster_alive"][m],"monsteridentities/life")
		_check(game.model.barrier_is_active(Vector2i(3,1))==row["barriers"][0] and game.model.barrier_is_active(Vector2i(3,3))==row["barriers"][1],"blue/yellowindependentcontrollers")
		if symbol!="C" and int(row["actions"]) in [13,17,22,23,29,34,43,55,56,62]:await _capture("north_39_action_%02d.png" % int(row["actions"]))
		if symbol!="C" and int(row["actions"]) in [22,34,56,62]:
			var after:Dictionary=game.model.snapshot();var selected:int=game.model.active_hero_index;await _click("Undo");_check(game.model.snapshot()==before and game.model.active_hero_index==selected and game.board.feedback.plan.is_empty(),"Undoatomicattack/pull/groupsandcancelvisuals")
			await _input(symbol);_check(game.model.snapshot()==after,"redoexact")
	_check(game.model.is_complete() and game.model.occupied_exits()==2 and game.moves_label.text=="73" and game.pushes_label.text=="07" and game.pulls_label.text=="08","73actions7push8pulltwohero victory")
	_check(game.model.crate_id(Vector2i(5,0))==0 and game.model.monsters()[0]["alive"] and game.model.monsters()[2]["alive"] and not game.model.barrier_is_active(Vector2i(3,1)) and not game.model.barrier_is_active(Vector2i(3,3)),"crystalblue/liveGoblinyellowcontinuouslyholdgates")
	await _capture("north_39_completed.png");await _click("Undo");_check(game.model.snapshot()==final_before and not game.model.is_complete() and game.model.active_hero_index==1,"victoryUndo retainsredselection")
	await _click("Restart");root.size=Vector2i(960,615);await _settle();_check_layout(game);await _capture("north_39_compact_green.png");await _click("SwitchHero");_check_layout(game);await _capture("north_39_compact_red.png")
	await _click("BackToLevels");_check(game.menu.strip.item_count==40 and game.menu.strip.pool.size()<=game.menu.strip.capacity_bound(),"40entriesboundedpoolednavigation")
	await _capture("north_39_navigation.png");await _click("Level38");_check(game.model.active_kind()=="blue" and game.model.level.swap_hero_color=="purple" and game.model.level.pressure_colors()==["purple"],"old38purpledefaultsinglecolorunchanged");await _click("Level39");_check(game.model.snapshot()==initial and game.model.active_hero_index==0 and game.model.history_size()==0,"38/39history/selectionisolation")
	print("NORTH39 SCENE RESULT: %d checks,%d failures;display=%s" % [checks,failures,DisplayServer.get_name()]);quit(0 if failures==0 else 1)
