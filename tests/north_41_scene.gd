extends "res://tests/north_02_scene.gd"
func _cell(a:Array)->Vector2i:return Vector2i(int(a[0]),int(a[1]))
func _input(s:String)->void:
	if s=="C":await _press(KEY_C)
	else:await _press(_keycode(s))
func _run()->void:
	root.size=Vector2i(1280,820);game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await _settle();await _click("Level41")
	_check(game.LEVEL_PATHS.size()==41 and game.current_level_index==40 and game.LEVEL_TITLES[40]=="第四十一关" and game.model.level.id=="north_hero_41","real41pooledentry/title")
	_check(game.model.active_hero_id()=="purple" and game._hero_color_name()=="紫" and game._hero_tint()==game.board.HERO_PURPLE,"purple highlight and naming")
	var initial:Dictionary=game.model.snapshot();_check_layout(game);await _capture("north_41_initial.png")
	await _click("SwitchHero");_check(game.model.active_kind()=="yellow" and game._hero_tint()==game.board.HERO_YELLOW and game.model.snapshot()==initial,"screenC selectsyellow,hue kept,free")
	await _click("Undo");_check(game.model.snapshot()==initial and game.model.active_hero_index==1,"emptyUndo retainsselectedyellow")
	await _press(KEY_C);_check(game.model.snapshot()==initial and game.model.active_hero_index==0,"keyboardC matches screen")
	var proof:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://artifacts/verification/north_41_route.json"));var final_before:Dictionary={}
	for row in proof["trace"]:
		var s:String=row["input"];var before:Dictionary=game.model.snapshot();var n:int=row["event_index"]
		if s=="C":
			if n%2==0:await _click("SwitchHero")
			else:await _press(KEY_C)
			_check(game.model.snapshot()==before,"Cselection does not consume action/history/attacks")
		else:
			final_before=before
			if n%4==0:await _click({"U":"MoveUp","D":"MoveDown","L":"MoveLeft","R":"MoveRight"}[s])
			else:await _press(_keycode(s))
		_check(game.model.alive and game.model.active_hero_index==int(row["selected"]) and game.model.moves==int(row["actions"]) and game.model.swaps==int(row["swaps"]),"actual keyboard/screen agrees with independent counters")
		for h in 2:_check(game.model.heroes()[h]["position"]==_cell(row["heroes"][h]) and game.model.hero_is_alive(h),"both identities/positions and hue remain")
		_check(game.model.protected_heroes()==row["protected_heroes"] and game.model.living_monster_count()==5 and game.model.crates().is_empty(),"actual protection/monster lives")
		_check(game.model.is_complete()==row["completed"],"onlytwoheroesgoalwin")
		if n in [7,10,16,19,24]:await _capture("north_41_event_%02d.png"%n)
		if n==16:
			var after:Dictionary=game.model.snapshot();await _click("Undo");_check(game.model.snapshot()==before and game.board.feedback.plan.is_empty(),"realUndo cancels exchange effects")
			await _press(_keycode(s));_check(game.model.snapshot()==after,"redone hero exchange exact")
	_check(game.model.is_complete() and game.model.moves==25 and game.model.swaps==1 and game.model.occupied_exits()==2,"25directionsoneexchangebothgoals")
	await _capture("north_41_completed.png");await _click("Undo");_check(game.model.snapshot()==final_before and not game.model.is_complete() and game.model.active_hero_index==1,"victoryUndo retainsyellow")
	await _click("Restart");root.size=Vector2i(960,615);await _settle();_check_layout(game);await _capture("north_41_compact_purple.png");await _click("SwitchHero");_check_layout(game);await _capture("north_41_compact_yellow.png")
	await _click("BackToLevels");_check(game.menu.strip.item_count==41 and game.menu.strip.pool.size()<=game.menu.strip.capacity_bound(),"41catalogboundedpool")
	await _capture("north_41_navigation.png");await _click("Level40");_check(game.model.hero_count()==1 and game.model.active_kind()=="yellow","old40 remains solo yellow")
	await _click("Level41");_check(game.model.snapshot()==initial and game.model.active_hero_index==0,"reenter clearsoldhistoryandselection")
	for s in "CUURCDDR":await _input(s)
	_check(game.model.active_kind()=="blue" and game.model.player==Vector2i(1,2) and game.model.protected_heroes()==[true,true],"reachable adjacent shield after hero exchange")
	var safe:Dictionary=game.model.snapshot();await _click("MoveRight");_check(not game.model.alive and not game.model.hero_is_alive(0) and game.model.hero_is_alive(1),"twoawaypurple dies to Goblin,yellow survives")
	var dead:Dictionary=game.model.snapshot();await _press(KEY_C);await _press(KEY_R);await _click("BackToLevels");_check(game.model.snapshot()==dead and not game.menu.visible,"actualdeathlock noC/restart/menubypass")
	root.size=Vector2i(1280,820);await _settle();await _capture("north_41_death_side.png")
	await _click("Undo");_check(game.model.snapshot()==safe and game.model.alive and game.board.feedback.plan.is_empty(),"Undo restoresbothhero positions/protection,clearsdeathghost")
	await _click("SwitchHero");await _click("Undo");_check(game.model.active_kind()=="yellow" and game.model.player==Vector2i(1,2),"switchthenUndo actualexchange retainsyellowselection")
	await _capture("north_41_undo_side.png")
	print("NORTH41 SCENE RESULT: %d checks,%d failures;display=%s"%[checks,failures,DisplayServer.get_name()]);quit(0 if failures==0 else 1)
