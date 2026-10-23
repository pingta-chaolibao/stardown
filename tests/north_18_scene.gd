extends "res://tests/north_02_scene.gd"
const KEYS={"U":KEY_UP,"D":KEY_DOWN,"L":KEY_LEFT,"R":KEY_RIGHT,"C":KEY_C}
func _run() -> void:
	root.size=Vector2i(1280,820);game=preload("res://scenes/main.tscn").instantiate();root.add_child(game);await _settle();await _click("Level18")
	_check(game.current_level_index==17 and game.model.active_hero_id()=="blue" and game.model.hero_count()==3,"18 loads three confirmed heroes,blue initially selected")
	_check(game.model.level.exit_color=="blue" and game._goal_name()=="蓝色终点" and game._goal_color()==preload("res://scripts/view/board_view.gd").GOAL_BLUE,"ordinary blue disc goals, no teleport")
	for name in ["Moves","Pushes","Pulls","Swaps"]:_check(game.find_child(name,true,false)!=null,"all three abilities shown")
	_check_layout(game);await _capture("north_18_initial.png")
	var initial:Dictionary=game.model.snapshot();await _click("SwitchHero");_check(game.model.active_hero_id()=="red" and game.model.snapshot()==initial,"screen C selects red for free");await _capture("north_18_selected_red.png")
	await _click("SwitchHero");_check(game.model.active_hero_id()=="green" and game.model.snapshot()==initial,"screen C selects green for free");await _capture("north_18_selected_green.png")
	await _press(KEY_Z);_check(game.model.active_hero_id()=="green" and game.model.snapshot()==initial,"empty undo preserves chosen green")
	await _press(KEY_R);_check(game.model.active_hero_id()=="blue" and game.model.snapshot()==initial,"restart restores default blue")
	await _repeat_keys();await _press(KEY_R)
	var solution:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://levels/solutions/north_18.json"));var actions:=0;var choices:=0
	for symbol in solution["path"]:
		var before:Dictionary=game.model.snapshot();var selected:String=game.model.active_hero_id();await _press(KEYS[symbol])
		if symbol=="C":choices+=1;_check(game.model.snapshot()==before,"actual C creates no world/history action")
		else:
			actions+=1;_check(game.model.active_hero_id()==selected,"push/exchange keeps selected identity")
		_check(game.model.moves==actions and game.model.history_size()==actions and game.model.alive and game.model.crates().size()==1,"actual counts/life/crystal identity remain legal")
		_check(game.model.is_complete()==(actions==78),"require all3hero goals, not earlier")
		if symbol!="C":
			if actions==5:await _capture("north_18_first_hero_exchange.png")
			if actions==8:
				await _capture("north_18_multi_hero_push.png");var held:Dictionary=game.model.snapshot();await _press(KEY_DOWN);_check(game.model.snapshot()==held,"real red mixed-chain boundary block atomic")
			if actions==28:await _capture("north_18_top_crystal.png")
			if actions==52:await _capture("north_18_mixed_push.png")
			if actions==61:await _capture("north_18_blue_plate.png")
			if actions==69:
				await _capture("north_18_crystal_handoff.png");var after:Dictionary=game.model.snapshot();await _choose("green");await _press(KEY_Z)
				_check(game.model.snapshot()==before and game.model.active_hero_id()=="green","handoff undo restores world,retains new green selection")
				await _choose("blue");await _press(KEY_UP);_check(game.model.snapshot()==after,"repeated legal handoff preserves gate transparency")
			if actions==71:
				await _capture("north_18_green_energy.png")
				var unchanged:Dictionary=game.model.snapshot();root.size=Vector2i(960,615);await _settle();_check_layout(game)
				await _capture("north_18_compact_energy_inactive.png")
				await _choose("green");_check(game.model.snapshot()==unchanged and game.model.player==Vector2i(4,2),"compact active/inactive energy overlay keeps all world state")
				await _capture("north_18_compact_energy_active.png")
				await _choose("red");root.size=Vector2i(1280,820);await _settle()
				_check(game.model.snapshot()==unchanged and game.model.active_hero_id()=="red","viewport/selection changes leave canonical route intact")
			if actions==72:await _capture("north_18_first_goal.png")
			if actions==76:await _capture("north_18_two_goals.png")
			if actions==77:await _capture("north_18_red_energy.png")
	_check(actions==78 and choices==61 and game.model.pushes==26 and game.model.pulls==8 and game.model.swaps==10 and game.model.occupied_exits()==3,"78actions61C26push8pull10swap three-hero victory")
	await _capture("north_18_completed.png");await _press(KEY_Z);_check(not game.model.is_complete() and game.model.moves==77 and game.model.active_hero_id()=="red","victory undo keeps selected red")
	await _press(KEY_R);_check(game.model.snapshot()==initial and game.model.active_hero_id()=="blue","victory restart resets all four identities")
	await _death_inputs()
	await _click("Level17");_check(game.current_level_index==16 and game.model.crates().size()==4 and game.model.history_size()==0,"previous17 remains independent")
	await _click("Level18");_check(game.model.snapshot()==initial and game.model.active_hero_id()=="blue","backto18 no history/selection contamination")
	root.size=Vector2i(960,615);await _settle();_check_layout(game);await _capture("north_18_compact_blue.png")
	await _click("SwitchHero");_check(game.model.active_hero_id()=="red" and game.model.snapshot()==initial,"compact real mouse selects red");_check_layout(game);await _capture("north_18_compact_red.png")
	await _click("SwitchHero");_check(game.model.active_hero_id()=="green" and game.model.snapshot()==initial,"compact real mouse selects green");_check_layout(game);await _capture("north_18_compact_green.png")
	await _click("SwitchHero");_check(game.model.active_hero_id()=="blue" and game.model.moves==0 and game.model.history_size()==0,"full3hero cycle free")
	print("NORTH 18 SCENE RESULT: %d checks, %d failures; display=%s" % [checks,failures,DisplayServer.get_name()]);quit(0 if failures==0 else 1)
func _choose(id:String) -> void:
	for _i in game.model.hero_count():
		if game.model.active_hero_id()==id:return
		await _press(KEY_C)
	_check(false,"requested hero exists")
func _repeat_keys() -> void:
	var initial:Dictionary=game.model.snapshot();var c:=InputEventKey.new();c.keycode=KEY_C;c.physical_keycode=KEY_C;c.pressed=true;Input.parse_input_event(c);await _settle()
	_check(game.model.active_hero_id()=="red" and game.model.snapshot()==initial,"fresh C chooses red, no count")
	c.echo=true;Input.parse_input_event(c);await _settle();c.echo=false;Input.parse_input_event(c);await _settle();_check(game.model.active_hero_id()=="red" and game.model.snapshot()==initial,"C echo/held duplicates ignored across UI rebuild")
	c.pressed=false;Input.parse_input_event(c);await _settle();await _press(KEY_C);_check(game.model.active_hero_id()=="green" and game.model.snapshot()==initial,"fresh released C chooses green")
	await _press(KEY_R);var left:=InputEventKey.new();left.keycode=KEY_LEFT;left.physical_keycode=KEY_LEFT;left.pressed=true;Input.parse_input_event(left);await _settle();var once:Dictionary=game.model.snapshot()
	left.echo=true;Input.parse_input_event(left);await _settle();left.echo=false;Input.parse_input_event(left);await _settle();_check(game.model.player==Vector2i(1,2) and game.model.moves==1 and game.model.snapshot()==once,"blue single fresh left exchange, no repeat")
	left.pressed=false;Input.parse_input_event(left);await _settle();await _press(KEY_LEFT);_check(game.model.player==Vector2i(0,2) and game.model.moves==2 and game.model.swaps==2,"released new left exchanges next visible hero")
func _death_inputs() -> void:
	await _press(KEY_R);var solution:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://levels/solutions/north_18.json"))
	for symbol in solution["path"]:
		if game.model.moves>=8:break
		await _press(KEYS[symbol])
	await _choose("blue");await _press(KEY_RIGHT);await _choose("red")
	for symbol in "UUURRR":await _press(KEYS[symbol])
	await _choose("green");var before:Dictionary=game.model.snapshot();await _press(KEY_UP)
	_check(not game.model.alive and not game.model.hero_is_alive(0) and game.model.hero_is_alive(1) and game.model.hero_is_alive(2),"legal side path kills inactive red when green releases plate")
	await _capture("north_18_death_inactive_red.png");var dead:Dictionary=game.model.snapshot();await _press(KEY_C);await _press(KEY_R);await _press(KEY_LEFT);await _click("Level17")
	_check(game.model.snapshot()==dead and game.current_level_index==17,"death blocksC/R/directions/level")
	await _press(KEY_Z);_check(game.model.snapshot()==before and game.model.active_hero_id()=="green" and game.model.hero_is_alive(0),"oneundo revives red and restores pressure,retains green")
	await _capture("north_18_revived_red.png");await _press(KEY_R)
