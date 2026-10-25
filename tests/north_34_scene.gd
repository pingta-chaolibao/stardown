extends "res://tests/north_02_scene.gd"
func _run() -> void:
	root.size=Vector2i(1280,820);game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await _settle();await _click("Level34")
	_check(game.current_level_index==33 and game.LEVEL_PATHS.size()==game.LEVEL_TITLES.size() and game.LEVEL_TITLES[33]=="第三十四关" and game.model.level.id=="north_hero_34","pooled34card andsidebarcorrect")
	_check(game.model.player==Vector2i(1,3) and game.model.active_kind()=="green" and game.model.living_monster_count()==2 and game.board._mechanism_tint()==game.board.MECHANISM_RED,"initialgreen/twofacingdragons/redclearblock")
	var initial:Dictionary=game.model.snapshot();_check_layout(game);await _capture("north_34_initial.png")
	var key:=InputEventKey.new();key.keycode=KEY_W;key.physical_keycode=KEY_W;key.pressed=true
	Input.parse_input_event(key);await _settle();var once:Dictionary=game.model.snapshot()
	for echo in [true,false,true]:key.echo=echo;Input.parse_input_event(key);await _settle();_check(game.model.snapshot()==once and game.model.moves==1,"held/echo ignored")
	key.pressed=false;Input.parse_input_event(key);await _settle();await _click("Undo");_check(game.model.snapshot()==initial,"screenUndo")
	await _press(KEY_C);_check(game.model.snapshot()==initial and game.model.history_size()==0,"singleheroCfree")
	await _click("MoveRight");var near:Dictionary=game.model.snapshot();await _click("MoveRight");_check(game.model.snapshot()==near and game.model.pulls==0,"screeninputgreenneverpushes")
	await _click("Restart")
	for s in "URRR":await _press(_keycode(s))
	var gate:Dictionary=game.model.snapshot();await _click("MoveRight");_check(game.model.snapshot()==gate and game.model.barrier_is_active(Vector2i(5,2)) and game.status_label.text.contains("清怪能量"),"19blockedbeforeclearing")
	await _capture("north_34_gate_blocked.png");await _click("Restart")
	var proof:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://artifacts/verification/north_34_route.json"));var side:Dictionary=proof["fatal_side"]
	for s in side["prefix"]:await _press(_keycode(s))
	var living:Dictionary=game.model.snapshot();await _press(_keycode(side["direction"]));_check(not game.model.alive and game.model.death_reason=="fire","actuallegalsidepathfiredeath")
	var dead:Dictionary=game.model.snapshot();await _press(KEY_C);await _press(KEY_R);await _click("BackToLevels");_check(game.model.snapshot()==dead and not game.menu.visible,"deathcannotbypass")
	await _capture("north_34_death.png");await _click("Undo");_check(game.model.snapshot()==living and game.model.alive,"onlyUndo restoresbeforedeath");await _click("Restart")
	var sol:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://levels/solutions/north_34.json"));var history:Array[Dictionary]=[]
	for i in sol["path"].length():
		var symbol:String=sol["path"][i];var before:Dictionary=game.model.snapshot();history.append(before);await _press(_keycode(symbol));var expected:Dictionary=proof["trace"][i]
		_check(game.model.alive and game.model.moves==i+1 and game.model.player==_cell(expected["player"]) and game.model.pulls==expected["pulls"] and game.model.crate_id(_cell(expected["crystals"][0]))==0,"keyboardgreen/crystal/counters matchindependenttrace")
		for identity in 2:_check(game.model.monsters()[identity]["position"]==_cell(expected["monsters"][identity]) and game.model.monsters()[identity]["alive"]==expected["monster_alive"][identity] and game.model.monsters()[identity]["facing"]==[Vector2i.LEFT,Vector2i.RIGHT][identity],"fixeddragonidentity/facing/life")
		_check(game.model.barrier_is_active(Vector2i(5,2))==expected["barrier_active"] and game.model.is_complete()==(i==32),"energyandvictorytiming")
		if i in [6,12,17,25]:await _capture("north_34_action_%02d.png" % (i+1))
		if i==26:
			var cleared:Dictionary=game.model.snapshot();_check(game.model.living_monster_count()==0 and game.progress_label.text.contains("0 / 2"),"twofireDragonssimultaneouslydead")
			await _capture("north_34_clear_open.png");await _click("Undo");_check(game.model.snapshot()==before and game.model.living_monster_count()==2 and game.model.barrier_is_active(Vector2i(5,2)) and game.board.feedback.plan.is_empty(),"Undo restoresbothdragons/crystal/gateandcancelsfeedback")
			await _capture("north_34_undo_revived.png");await _press(_keycode(symbol));_check(game.model.snapshot()==cleared,"repeat27sameworld")
	_check(game.model.is_complete() and game.moves_label.text=="33" and game.model.pulls==18 and game.model.pushes==0 and game.model.swaps==0,"33actions18pulls livingvictory")
	await _capture("north_34_completed.png");await _click("Undo");_check(game.model.snapshot()==history[-1] and not game.model.is_complete(),"victoryUndo")
	await _click("Restart");root.size=Vector2i(960,615);await _settle();_check_layout(game);await _capture("north_34_compact.png")
	await _click("BackToLevels");_check(game.menu.strip.item_count==34 and game.menu.strip.pool.size()<=game.menu.strip.capacity_bound(),"34realentriesremainpooled")
	await _capture("north_34_navigation.png");await _click("Level33");await _click("Level34");_check(game.model.snapshot()==initial and game.model.history_size()==0,"33/34worldhistoryisolation")
	print("NORTH34 SCENE RESULT: %d checks,%d failures;display=%s" % [checks,failures,DisplayServer.get_name()]);quit(0 if failures==0 else 1)
func _cell(a:Array)->Vector2i:return Vector2i(a[0],a[1])
