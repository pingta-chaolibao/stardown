extends "res://tests/north_02_scene.gd"
const KEYS={"U":KEY_UP,"D":KEY_DOWN,"L":KEY_LEFT,"R":KEY_RIGHT,"C":KEY_C}
func _run() -> void:
	root.size=Vector2i(1280,820);game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await _settle();await _click("Level20")
	_check(game.current_level_index==19 and game.model.active_hero_id()=="blue" and game.model.level.fence_edges.size()==2,"virtual card enters real20 with edge fences")
	var initial:Dictionary=game.model.snapshot();_check_layout(game);await _inspect_fences();await _capture("north_20_initial.png")
	await _choose("green");await _click("MoveUp");_check(game.model.snapshot()==initial and game.board.blocked and game.status_label.text.contains("栅栏"),"screen button green step blocked with clear fence hint")
	await _choose("red");await _press(KEY_UP);_check(game.model.snapshot()==initial and game.board.blocked,"real red direction blocked byF2")
	await _press(KEY_R);_check(game.model.active_hero_id()=="blue","restart restores selectedblue")
	await _repeat_keys();await _press(KEY_R)
	var solution:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://levels/solutions/north_20.json"));var actions:=0;var choices:=0
	for symbol in solution["path"]:
		var before:Dictionary=game.model.snapshot();var selected:String=game.model.active_hero_id();await _press(KEYS[symbol])
		if symbol=="C":choices+=1;_check(game.model.snapshot()==before,"actual C free,not a world/undo action")
		else:actions+=1;_check(game.model.active_hero_id()==selected,"selected identity unchanged by passive push/exchange")
		_check(game.model.moves==actions and game.model.history_size()==actions and game.model.alive and game.model.crates().size()==2,"actual legal counts/identities/life")
		_check(game.model.is_complete()==(actions==30),"actual three-goal condition")
		if symbol!="C":
			if actions==3:await _capture("north_20_left_hero_exchange.png")
			if actions==4:
				await _choose("blue");var blocked:Dictionary=game.model.snapshot();await _click("MoveUp")
				_check(game.model.snapshot()==blocked and game.board.blocked,"no visible target:screen blue cannot walk acrossF1")
				await _capture("north_20_blue_blocked.png");await _choose("green")
			if actions==5:await _capture("north_20_first_pull.png")
			if actions==14:
				await _capture("north_20_left_crystal_exchange.png");var after:Dictionary=game.model.snapshot();await _choose("green");await _press(KEY_Z)
				_check(game.model.snapshot()==before and game.model.active_hero_id()=="green","cross-fence exchange Undo restores both endpoints,retains green")
				await _choose("blue");await _click("MoveUp");_check(game.model.snapshot()==after,"screen blue redoes same cross-fence crystal swap legally")
			if actions==19:await _capture("north_20_second_pull.png")
			if actions==23:await _capture("north_20_right_hero_exchange.png")
			if actions==28:await _capture("north_20_right_crystal_exchange.png")
			if actions==29:await _capture("north_20_two_goals.png")
	_check(actions==30 and choices==13 and game.model.pushes==2 and game.model.pulls==2 and game.model.swaps==11 and game.model.occupied_exits()==3,"actual30/13C/2push2pull11swap victory")
	await _capture("north_20_completed.png");await _press(KEY_Z);_check(game.model.moves==29 and not game.model.is_complete() and game.model.active_hero_id()=="red","victoryUndo keepsred and restores passiveblue")
	await _press(KEY_R);_check(game.model.snapshot()==initial and game.model.active_hero_id()=="blue","victoryrestart restores initialworld/fences/blue")
	await _click("BackToLevels");_check(game.menu.visible and game.menu.strip.item_count==20,"20 added to same virtual menu")
	await _click("Level19");_check(game.model.level.fence_edges.is_empty() and game.model.history_size()==0,"19 retains original terrain/no fence leak")
	await _click("Level20");_check(game.model.snapshot()==initial,"return20 has independent history")
	root.size=Vector2i(960,615);await _settle();_check_layout(game);await _inspect_fences();await _capture("north_20_compact_blue.png")
	await _click("SwitchHero");_check(game.model.active_hero_id()=="red" and game.model.snapshot()==initial,"compact red highlighter free");await _capture("north_20_compact_red.png")
	await _click("SwitchHero");_check(game.model.active_hero_id()=="green" and game.model.snapshot()==initial,"compact green highlighter free");await _capture("north_20_compact_green.png")
	print("NORTH 20 SCENE RESULT: %d checks, %d failures; display=%s" % [checks,failures,DisplayServer.get_name()]);quit(0 if failures==0 else 1)
func _choose(id:String) -> void:
	for _i in game.model.hero_count():
		if game.model.active_hero_id()==id:return
		await _press(KEY_C)
func _repeat_keys() -> void:
	var event:=InputEventKey.new();event.keycode=KEY_LEFT;event.physical_keycode=KEY_LEFT;event.pressed=true;Input.parse_input_event(event);await _settle();var once:Dictionary=game.model.snapshot()
	event.echo=true;Input.parse_input_event(event);await _settle();event.echo=false;Input.parse_input_event(event);await _settle()
	_check(game.model.player==Vector2i(1,1) and game.model.moves==1 and game.model.snapshot()==once,"held/echo direction rejected")
	event.pressed=false;Input.parse_input_event(event);await _settle();await _press(KEY_LEFT);await _press(KEY_DOWN)
	_check(game.model.player==Vector2i(0,4) and game.model.swaps==1,"new direction sees first hero through fence,one exchange")
func _inspect_fences() -> void:
	for edge in game.model.level.fence_edges:
		_check(game.model.is_walkable(edge["a"]) and game.model.is_walkable(edge["b"]) and game.model.level.has_fence(edge["a"],edge["b"]),"fence remains edge,not cell blocker")
		if DisplayServer.get_name()!="headless":
			await RenderingServer.frame_post_draw
			var view:Control=game.board;var level=game.model.level
			var tile:float=minf(72.0,minf((view.size.x-32)/level.width,(view.size.y-24)/level.height))
			var origin:Vector2=view.global_position+(view.size-Vector2(level.width,level.height)*tile)*0.5
			var center:Vector2=origin+(Vector2(edge["a"])+Vector2(edge["b"])+Vector2.ONE)*tile*0.5
			var normal:=Vector2(edge["b"]-edge["a"]);var tangent:=Vector2(normal.y,-normal.x);var colored:=0;var picture:=root.get_texture().get_image()
			for step in range(-20,21):
				var point:Vector2=root.get_final_transform()*(center+tangent*tile*step/50.0+normal*tile*0.035)
				var c:=picture.get_pixel(roundi(point.x),roundi(point.y))
				if c.b>0.43 and c.g>0.36 and c.b>c.r*1.05:colored+=1
			_check(colored>=12,"metal rail rendered on shared edge at current scale")
