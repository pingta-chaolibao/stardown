extends "res://tests/north_02_scene.gd"
func _cell(a:Array)->Vector2i:return Vector2i(a[0],a[1])
func _run()->void:
	root.size=Vector2i(1280,820);game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await _settle();await _click("Level37")
	_check(game.current_level_index==36 and game.model.level.id=="north_hero_37" and game.LEVEL_TITLES[36]=="第三十七关","real37pooledcardandtitle")
	_check(game.model.player==Vector2i(4,0) and game.model.active_kind()=="red" and game.model.living_monster_count()==4 and game.model.level.width==12 and game.model.level.height==7,"confirmed12x7fourmonsterstart")
	var initial:Dictionary=game.model.snapshot();_check_layout(game);await _capture("north_37_initial.png")
	var key:=InputEventKey.new();key.keycode=KEY_A;key.physical_keycode=KEY_A;key.pressed=true;Input.parse_input_event(key);await _settle();var once:Dictionary=game.model.snapshot()
	for echo in [true,false,true]:key.echo=echo;Input.parse_input_event(key);await _settle();_check(game.model.snapshot()==once and game.model.moves==1,"held/echoignored")
	key.pressed=false;Input.parse_input_event(key);await _settle();await _click("Undo");_check(game.model.snapshot()==initial,"screenUndo")
	await _press(KEY_C);_check(game.model.snapshot()==initial and game.model.history_size()==0,"singleheroCfree")
	var proof:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://artifacts/verification/north_37_route.json"))
	for reason in proof["fatal_sides"]:
		var side:Dictionary=proof["fatal_sides"][reason]
		for s in side["prefix"]:await _press(_keycode(s))
		var safe:Dictionary=game.model.snapshot();await _press(_keycode(side["direction"]));_check(not game.model.alive and game.model.death_reason==reason,"actuallegalside"+reason)
		var dead:Dictionary=game.model.snapshot();await _press(KEY_C);await _press(KEY_R);await _click("BackToLevels");_check(game.model.snapshot()==dead and not game.menu.visible,"deadcannotbypassC/restart/menu")
		await _capture("north_37_death_"+reason+".png");await _click("Undo");_check(game.model.snapshot()==safe and game.model.alive,"onlyUndorevives");await _click("Restart")
	for s in proof["gate_block_prefix"]:await _press(_keycode(s))
	var gate:Dictionary=game.model.snapshot();await _click("MoveRight");_check(game.model.snapshot()==gate and game.model.barrier_is_active(Vector2i(8,3)) and game.status_label.text.contains("清怪能量"),"live-monstergateblockdoesnotadvanceattack")
	await _capture("north_37_gate_blocked.png");await _click("Restart")
	var sol:Dictionary=proof["solution"];var history:Array[Dictionary]=[]
	for i in sol["path"].length():
		var symbol:String=sol["path"][i];var before:Dictionary=game.model.snapshot();history.append(before)
		if i%7==0:await _click({"U":"MoveUp","D":"MoveDown","L":"MoveLeft","R":"MoveRight"}[symbol])
		else:await _press(_keycode(symbol))
		var row:Dictionary=proof["trace"][i]
		_check(game.model.alive and game.model.player==_cell(row["player"]) and game.model.moves==i+1 and game.model.pushes==int(row["pushes"]),"keyboard/screenmatchesindependentstate")
		for id in 2:_check(game.model.crate_id(_cell(row["crystals"][id]))==id,"crystalidentity")
		for id in 4:_check(game.model.monsters()[id]["position"]==_cell(row["monsters"][id]) and game.model.monsters()[id]["alive"]==row["monster_alive"][id],"monsteridentity/life")
		_check(game.model.monsters()[0]["facing"]==Vector2i.RIGHT and game.model.barrier_is_active(Vector2i(8,3))==row["barrier_active"],"fixedfacing/typedgate")
		if i+1 in [5,6,7,21,24,29,41]:await _capture("north_37_action_%02d.png" % (i+1))
		if i==29:
			var cleared:Dictionary=game.model.snapshot();_check(game.model.living_monster_count()==0 and not game.model.barrier_is_active(Vector2i(8,3)),"30mutualdeathclearsgate")
			await _capture("north_37_clear_open.png");await _click("Undo");_check(game.model.snapshot()==before and game.model.living_monster_count()==2 and game.model.barrier_is_active(Vector2i(8,3)) and game.board.feedback.plan.is_empty(),"Undo30restoreslastpairandclearcondition/cancelsvisuals")
			await _capture("north_37_undo_revived.png");await _press(_keycode(symbol));_check(game.model.snapshot()==cleared,"redo30deterministic")
	_check(game.model.is_complete() and game.moves_label.text=="43" and game.pushes_label.text=="10" and game.model.crates().size()==2,"43/10livingvictory")
	await _capture("north_37_completed.png");await _click("Undo");_check(game.model.snapshot()==history[-1] and not game.model.is_complete(),"victoryUndo")
	await _click("Restart");root.size=Vector2i(960,615);await _settle();_check_layout(game);await _capture("north_37_compact.png")
	await _click("BackToLevels");_check(game.menu.strip.item_count==39 and game.menu.strip.pool.size()<=game.menu.strip.capacity_bound(),"39realentriesboundedpool")
	await _capture("north_37_navigation.png");await _click("Level36");_check(game.model.active_kind()=="blue" and game.model.level.swap_hero_color=="purple","old36purplekept");await _click("Level37");_check(game.model.snapshot()==initial and game.model.history_size()==0,"36/37historyisolation")
	print("NORTH37 SCENE RESULT: %d checks,%d failures;display=%s" % [checks,failures,DisplayServer.get_name()]);quit(0 if failures==0 else 1)
