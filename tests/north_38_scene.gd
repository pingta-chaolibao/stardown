extends "res://tests/north_02_scene.gd"
func _cell(a:Array)->Vector2i:return Vector2i(a[0],a[1])
func _run()->void:
	root.size=Vector2i(1280,820);game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await _settle();await _click("Level38")
	_check(game.current_level_index==37 and game.model.level.id=="north_hero_38" and game.LEVEL_TITLES[37]=="第三十八关","real38pooledcardandtitle")
	_check(game.model.player==Vector2i(6,7) and game.model.active_kind()=="blue" and game.model.level.swap_hero_color=="purple" and game.model.living_monster_count()==7,"confirmedpurpleexchange/sixGoblinsoneDragon")
	_check(game.model.level.monster_clear_barriers.is_empty() and game.model.pressure_is_active("purple_01") and game.board._mechanism_tint(false)==game.board.MECHANISM_PURPLE,"purplepressureNOTcleargate/initialGoblinpresses")
	_check(game.menu.strip.card_for_index(37)._role_color("blue")==game.board.HERO_PURPLE,"pooledcardpurplehero")
	var initial:Dictionary=game.model.snapshot();_check_layout(game);await _capture("north_38_initial.png")
	var key:=InputEventKey.new();key.keycode=KEY_W;key.physical_keycode=KEY_W;key.pressed=true;Input.parse_input_event(key);await _settle();var once:Dictionary=game.model.snapshot()
	for echo in [true,false,true]:key.echo=echo;Input.parse_input_event(key);await _settle();_check(game.model.snapshot()==once and game.model.moves==1,"held/echoignoredincludingDragonattack")
	key.pressed=false;Input.parse_input_event(key);await _settle();await _click("Undo");_check(game.model.snapshot()==initial,"screenUndorevivesfirstfiretarget")
	await _press(KEY_C);_check(game.model.snapshot()==initial and game.model.history_size()==0,"Cfree/noattackround")
	var proof:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://artifacts/verification/north_38_route.json"))
	for reason in proof["fatal_sides"]:
		var side:Dictionary=proof["fatal_sides"][reason]
		for s in side["prefix"]:await _press(_keycode(s))
		var safe:Dictionary=game.model.snapshot();await _press(_keycode(side["direction"]));_check(not game.model.alive and game.model.death_reason==reason,"actuallegalside"+reason)
		var dead:Dictionary=game.model.snapshot();await _press(KEY_C);await _press(KEY_R);await _click("BackToLevels");_check(game.model.snapshot()==dead and not game.menu.visible,"deathcannotbypassC/restart/menu")
		await _capture("north_38_death_"+reason+".png");await _click("Undo");_check(game.model.snapshot()==safe and game.model.alive,"onlyUndorevives");await _click("Restart")
	var blocked_side:Dictionary=proof["energy_blocked_side"]
	for s in blocked_side["prefix"]:await _press(_keycode(s))
	var blocked:Dictionary=game.model.snapshot();await _press(_keycode(blocked_side["direction"]));_check(game.model.snapshot()==blocked and game.model.barrier_is_active(Vector2i(0,5)),"activepressurebarrierblockswithoutattackround")
	await _capture("north_38_gate_blocked.png");await _click("Restart")
	var sol:Dictionary=proof["solution"];var history:Array[Dictionary]=[]
	for i in sol["path"].length():
		var symbol:String=sol["path"][i];var before:Dictionary=game.model.snapshot();history.append(before)
		if i%6==0:await _click({"U":"MoveUp","D":"MoveDown","L":"MoveLeft","R":"MoveRight"}[symbol])
		else:await _press(_keycode(symbol))
		var row:Dictionary=proof["trace"][i]
		_check(game.model.alive and game.model.player==_cell(row["player"]) and game.model.moves==i+1 and game.model.swaps==int(row["swaps"]),"keyboard/screenmatchesindependentstate")
		for id in 7:_check(game.model.monsters()[id]["position"]==_cell(row["monsters"][id]) and game.model.monsters()[id]["alive"]==row["monster_alive"][id],"sevenstableidentities/life")
		for c:Vector2i in game.model.level.energy_links[0]["barriers"]:_check(game.model.barrier_is_active(c)==row["barrier_active"],"fivebarrierssinglepressurecondition")
		_check(game.model.pressure_is_active("purple_01")==row["pressure_active"] and game.model.monsters()[6]["facing"]==Vector2i.LEFT,"fixedfacing/occupancy")
		if i+1 in [1,3,8,9,23,28,31,32,33]:await _capture("north_38_action_%02d.png" % (i+1))
		if i+1 in [9,31,32]:
			var after:Dictionary=game.model.snapshot();await _click("Undo");_check(game.model.snapshot()==before and game.board.feedback.plan.is_empty(),"Undoallpressure/lives/snapshotandcancelvisuals")
			await _capture("north_38_undo_%02d.png" % (i+1));await _press(_keycode(symbol));_check(game.model.snapshot()==after,"redoatomicpressure/attack")
	_check(game.model.is_complete() and game.moves_label.text=="36" and game.swaps_label.text=="10" and game.model.living_monster_count()==2 and game.model.pressure_is_active("purple_01"),"36/10livingvictorydespitetwolivingmonsters")
	await _capture("north_38_completed.png");await _click("Undo");_check(game.model.snapshot()==history[-1] and not game.model.is_complete(),"victoryUndo")
	await _click("Restart");root.size=Vector2i(960,615);await _settle();_check_layout(game);await _capture("north_38_compact.png")
	await _click("BackToLevels");_check(game.menu.strip.item_count==game.LEVEL_PATHS.size() and game.menu.strip.pool.size()<=game.menu.strip.capacity_bound(),"39entriesboundedvirtualpool")
	await _capture("north_38_navigation.png");await _click("Level37");_check(game.model.active_kind()=="red" and game.model.level.swap_hero_color=="blue","old37untouched");await _click("Level38");_check(game.model.snapshot()==initial and game.model.history_size()==0,"37/38historyisolation")
	print("NORTH38 SCENE RESULT: %d checks,%d failures;display=%s" % [checks,failures,DisplayServer.get_name()]);quit(0 if failures==0 else 1)
