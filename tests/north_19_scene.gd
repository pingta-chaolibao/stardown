extends "res://tests/north_02_scene.gd"
const KEYS={"U":KEY_UP,"D":KEY_DOWN,"L":KEY_LEFT,"R":KEY_RIGHT,"C":KEY_C}
const GATES=[Vector2i(1,3),Vector2i(9,3)]

func _run() -> void:
	root.size=Vector2i(1280,820);game=preload("res://scenes/main.tscn").instantiate();root.add_child(game);await _settle();await _click("Level19")
	_check(game.current_level_index==18 and game.model.active_hero_id()=="green" and game.model.hero_count()==3,"19loads three heroes,green selected")
	_check(game.model.occupied_exits()==2 and not game.model.is_complete() and game.undo_button.disabled,"two starting goal occupants do not win or create history")
	_check(game._goal_name()=="橙色终点" and game._goal_color()==preload("res://scripts/view/board_view.gd").GOAL_ORANGE and game._plate_name()=="蓝板" and game._mechanism_tint()==preload("res://scripts/view/board_view.gd").MECHANISM_BLUE,"orange goal and blue mechanism labels/colors")
	for name in ["Moves","Pushes","Pulls","Swaps"]:_check(game.find_child(name,true,false)!=null,"three abilities visible")
	_check_layout(game);await _capture("north_19_initial.png");await _inspect_solid()
	var initial:Dictionary=game.model.snapshot();await _click("SwitchHero");_check(game.model.active_hero_id()=="blue" and game.model.snapshot()==initial,"mouse selects blue freely");await _capture("north_19_selected_blue.png")
	await _click("SwitchHero");_check(game.model.active_hero_id()=="red" and game.model.snapshot()==initial,"mouse selects red freely");await _capture("north_19_selected_red.png")
	await _press(KEY_Z);_check(game.model.active_hero_id()=="red" and game.model.snapshot()==initial,"emptyundo retains chosen red")
	await _press(KEY_R);_check(game.model.active_hero_id()=="green" and game.model.snapshot()==initial,"restart restores default green")
	await _repeat_keys();await _press(KEY_R);await _click("MoveDown");_check(game.model.player==Vector2i(4,1) and game.model.moves==1,"screen direction matches ordinary green walk");await _press(KEY_R)
	var solution:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://levels/solutions/north_19.json"));var actions:=0;var choices:=0
	for symbol in solution["path"]:
		var before:Dictionary=game.model.snapshot();var selected:String=game.model.active_hero_id();await _press(KEYS[symbol])
		if symbol=="C":choices+=1;_check(game.model.snapshot()==before,"keyboardC creates no world/undo action")
		else:actions+=1;_check(game.model.active_hero_id()==selected,"mixedpush/swap keeps chosen identity")
		_check(game.model.moves==actions and game.model.history_size()==actions and game.model.alive and game.model.crates().size()==1,"actual counts and all identities survive")
		_check(game.model.is_complete()==(actions==63),"allthree goals required throughout actual inputs")
		if symbol!="C":
			if actions==4:await _capture("north_19_first_exchange.png")
			if actions==8:
				await _capture("north_19_multi_hero_push.png");var held:Dictionary=game.model.snapshot();await _choose("green");await _press(KEY_DOWN);_check(game.model.snapshot()==held,"green cannot push blue");await _choose("red")
			if actions==18:
				for gate in GATES:await _inspect_open(gate,"empty blue absent energy")
				await _capture("north_19_all_plates.png")
			if actions==19:
				await _capture("north_19_crystal_handoff.png");var after:Dictionary=game.model.snapshot();await _choose("green");await _press(KEY_Z)
				_check(game.model.snapshot()==before and game.model.active_hero_id()=="green","swapundo restores all occupancy/gates while keeping newly selected green")
				await _choose("blue");await _press(KEY_UP);_check(game.model.snapshot()==after,"same legal swap recomputes handoff atomically")
			if actions==20:await _inspect_solid();await _capture("north_19_restored_energy.png")
			if actions==30:await _capture("north_19_middle_crystal.png")
			if actions==34:await _capture("north_19_hero_handoff.png")
			if actions==36:await _inspect_open(GATES[0],"active red on blue energy");await _capture("north_19_red_energy.png")
			if actions==40:await _capture("north_19_second_crystal_swap.png")
			if actions==49:
				await _inspect_open(GATES[1],"active green on blue energy");await _capture("north_19_green_energy.png")
				var unchanged:Dictionary=game.model.snapshot();await _choose("blue");await _inspect_open(GATES[1],"inactive green on blue energy");await _capture("north_19_inactive_green_energy.png")
				root.size=Vector2i(960,615);await _settle();_check_layout(game);await _inspect_open(GATES[1],"compact inactive green on blue energy");await _capture("north_19_compact_energy_inactive.png")
				await _click("SwitchHero");await _click("SwitchHero");_check(game.model.active_hero_id()=="green" and game.model.snapshot()==unchanged,"compact mouse selection preserves complete world")
				await _inspect_open(GATES[1],"compact active green on blue energy");await _capture("north_19_compact_energy_active.png")
				root.size=Vector2i(1280,820);await _settle();_check(game.model.snapshot()==unchanged,"resize never changes mechanism or history")
			if actions==62:await _capture("north_19_two_goals.png")
	_check(actions==63 and choices==34 and game.model.pushes==13 and game.model.pulls==0 and game.model.swaps==5 and game.model.occupied_exits()==3,"actual63actions34C13push5swap,three-goal victory")
	await _capture("north_19_completed.png");await _press(KEY_Z);_check(not game.model.is_complete() and game.model.moves==62 and game.model.active_hero_id()=="blue","victoryundo keeps blue and retracts actual final direction")
	await _press(KEY_R);_check(game.model.snapshot()==initial and game.model.active_hero_id()=="green","victoryrestart restores start goals/selection")
	await _death_inputs();await _click("Level18");_check(game.current_level_index==17 and game.model.history_size()==0,"old18 independent session")
	await _click("Level19");_check(game.model.snapshot()==initial and game.model.active_hero_id()=="green","no history/selection contamination from18")
	root.size=Vector2i(960,615);await _settle();_check_layout(game);await _capture("north_19_compact_green.png")
	await _click("SwitchHero");_check(game.model.active_hero_id()=="blue" and game.model.snapshot()==initial,"compact mouse blue");_check_layout(game);await _capture("north_19_compact_blue.png")
	await _click("SwitchHero");_check(game.model.active_hero_id()=="red" and game.model.snapshot()==initial,"compact mouse red");_check_layout(game);await _capture("north_19_compact_red.png")
	await _click("SwitchHero");_check(game.model.active_hero_id()=="green" and game.model.moves==0 and game.model.history_size()==0,"full cycle free and no premature victory")
	print("NORTH 19 SCENE RESULT: %d checks, %d failures; display=%s" % [checks,failures,DisplayServer.get_name()]);quit(0 if failures==0 else 1)

func _repeat_keys() -> void:
	var initial:Dictionary=game.model.snapshot();var event:=InputEventKey.new();event.keycode=KEY_C;event.physical_keycode=KEY_C;event.pressed=true;Input.parse_input_event(event);await _settle()
	_check(game.model.active_hero_id()=="blue" and game.model.snapshot()==initial,"fresh C changes only selection")
	event.echo=true;Input.parse_input_event(event);await _settle();event.echo=false;Input.parse_input_event(event);await _settle()
	_check(game.model.active_hero_id()=="blue" and game.model.snapshot()==initial,"echo and held C do not switch again")
	event.pressed=false;Input.parse_input_event(event);await _settle();await _press(KEY_C);_check(game.model.active_hero_id()=="red","new released C advances one hero")
	await _press(KEY_R);event=InputEventKey.new();event.keycode=KEY_DOWN;event.physical_keycode=KEY_DOWN;event.pressed=true;Input.parse_input_event(event);await _settle();var once:Dictionary=game.model.snapshot()
	event.echo=true;Input.parse_input_event(event);await _settle();event.echo=false;Input.parse_input_event(event);await _settle()
	_check(game.model.player==Vector2i(4,1) and game.model.moves==1 and game.model.snapshot()==once,"green direction echo/held duplicate blocked")
	event.pressed=false;Input.parse_input_event(event);await _settle();await _press(KEY_DOWN);_check(game.model.player==Vector2i(4,2) and game.model.moves==2,"fresh released direction moves once")

func _death_inputs() -> void:
	await _press(KEY_R)
	for symbol in JSON.parse_string(FileAccess.get_file_as_string("res://levels/solutions/north_19.json"))["path"]:
		if game.model.moves>=36:break
		await _press(KEYS[symbol])
	await _choose("green");var before:Dictionary=game.model.snapshot();await _press(KEY_UP)
	_check(not game.model.alive and not game.model.hero_is_alive(0) and game.model.hero_is_alive(1) and game.model.hero_is_alive(2),"legal release kills inactive red only")
	await _capture("north_19_death_inactive_red.png");var dead:Dictionary=game.model.snapshot();await _press(KEY_C);await _press(KEY_R);await _press(KEY_LEFT);await _click("Level18")
	_check(game.model.snapshot()==dead and game.current_level_index==18,"any-hero death blocksC/R/directions/level")
	await _press(KEY_Z);_check(game.model.snapshot()==before and game.model.active_hero_id()=="green" and game.model.hero_is_alive(0),"oneundo revives red,restores both gates/threeplates,retains green")
	await _capture("north_19_revived_red.png");await _press(KEY_R)

func _choose(id:String) -> void:
	var before:Dictionary=game.model.snapshot()
	for _i in game.model.hero_count():
		if game.model.active_hero_id()==id:break
		await _press(KEY_C)
	_check(game.model.active_hero_id()==id and game.model.snapshot()==before,"selection never changes world")

func _center_tile(cell:Vector2i) -> Vector3:
	var view:Control=game.board;var level=game.model.level
	var tile:float=minf(72.0,minf((view.size.x-32)/level.width,(view.size.y-24)/level.height))
	var origin:Vector2=view.global_position+(view.size-Vector2(level.width,level.height)*tile)/2
	var center:Vector2=root.get_final_transform()*(origin+(Vector2(cell)+Vector2.ONE*0.5)*tile)
	return Vector3(center.x,center.y,tile*root.get_final_transform().get_scale().x)

func _inspect_solid() -> void:
	for cell in GATES:
		_check(game.model.barrier_is_active(cell) and game.model.blocks_sight(cell) and not game.model.is_walkable(cell),"both solid blue energies block movement/sight")
		if DisplayServer.get_name()!="headless":
			await RenderingServer.frame_post_draw
			var image:=root.get_texture().get_image();var p:=_center_tile(cell);var c:=image.get_pixel(int(p.x-p.z*0.12),int(p.y))
			_check(c.b>c.r*1.25 and c.b>0.70,"solid energy uses actual blue skin")

func _inspect_open(cell:Vector2i,label:String) -> void:
	var before:Dictionary=game.model.snapshot();game.board.queue_redraw();await _settle()
	_check(game.model.is_walkable(cell) and not game.model.blocks_sight(cell) and not game.model.barrier_is_active(cell),label+" remains passable/transparent")
	if DisplayServer.get_name()!="headless":
		await RenderingServer.frame_post_draw
		var image:=root.get_texture().get_image();var p:=_center_tile(cell);var colored:=0;var gaps:=0;var transitions:=0;var previous_blue:=false;var first:=true
		for x in range(int(p.x-p.z*0.40),int(p.x+p.z*0.40)):
			var c:=image.get_pixel(x,roundi(p.y-p.z*0.43))
			var blue:=c.b>c.r*1.25 and c.b>c.g*1.05 and c.b>0.35
			if blue:colored+=1
			else:gaps+=1
			if not first and blue!=previous_blue:transitions+=1
			previous_blue=blue;first=false
		# At compact scale the 5 antialiased dash gaps have fewer pixels. Check
		# alternating segments as well as scale-relative coverage, not 8 fixed gaps.
		_check(colored>=8 and gaps>=maxi(4,int(p.z*0.10)) and transitions>=6,label+" has distinct blue dash segments and clear gaps")
		if label=="empty blue absent energy":
			var c:=image.get_pixel(int(p.x),int(p.y));_check(maxf(c.r,maxf(c.g,c.b))<0.46,"absent blue energy stays flat/dim")
	_check(game.model.snapshot()==before,label+" repaint preserves occupancy/life/pressure/history")
