extends "res://tests/north_02_scene.gd"
## Existing controller, actual Shift-key exchange, mouse ability buttons and isolated fixtures.
const Level=preload("res://scripts/core/level_data.gd")

func _run() -> void:
	root.size=Vector2i(1280,820)
	game=load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await _settle()
	await _click("Level09")
	_check(game.current_level_index==8 and game.model.level.hero_kind=="blue" and game.model.player==Vector2i(1,1),"GUI selects blue ninth hero")
	_check(game.swaps_label!=null and game.pushes_label==null and game.pulls_label==null and game.swaps_label.text=="00","blue UI displays separate exchange statistics")
	var initial: Dictionary=game.model.snapshot()
	await _capture("north_09_initial.png")
	await _press(KEY_D)
	_check(game.model.player==Vector2i(2,1) and game.model.swaps==0,"ordinary blue keyboard input walks one cell without swapping")
	await _click("Restart")
	await _press(KEY_S)
	await _press(KEY_D)
	var adjacent: Dictionary=game.model.snapshot()
	await _press(KEY_D)
	_check(game.model.snapshot()==adjacent and game.status_label.text.contains("不能推拉"),"normal blue keyboard cannot push lower adjacent crystal")
	await _click("Restart")
	await _press(KEY_S)
	var before_swap: Dictionary=game.model.snapshot()
	await _click("SwapRight")
	_check(game.model.player==Vector2i(3,2) and game.model.crate_id(Vector2i(1,2))==1 and game.model.swaps==1 and game.swaps_label.text=="01","real ability button exchanges first visible lower crystal")
	await _click("Undo")
	_check(game.model.snapshot()==before_swap and game.swaps_label.text=="00","GUI undo restores complete exchange and counter")
	await _click("Restart")
	await _repeat_swap_check()
	await _click("Restart")
	_check(game.model.snapshot()==initial and game.model.history_size()==0,"restart clears all manual-input setup")
	var solution: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://levels/solutions/north_09.json"))
	var before_final: Dictionary
	for index in solution["path"].length():
		before_final=game.model.snapshot()
		await _action(solution["path"][index])
		_check(game.model.moves==index+1 and game.model.alive and game.model.pushes==0 and game.model.pulls==0,"ninth legal actual action %d" % (index+1))
		if index==1:
			_check(game.model.player==Vector2i(3,2) and game.model.swaps==1,"actual Shift-right crosses lower gap with exactly one exchange")
			await _capture("north_09_first_swap.png")
		if index==5:
			_check(game.model.player==Vector2i(7,0) and game.model.crate_id(Vector2i(4,0))==0 and game.model.swaps==2,"actual Shift-right exchanges far upper purple crystal")
			await _capture("north_09_second_swap.png")
	_check(game.model.is_complete() and game.model.player==Vector2i(9,1) and game.model.moves==9 and game.model.swaps==2,"blue keyboard victory uses seven walks and two deliberate exchanges")
	_check(game.moves_label.text=="09" and game.swaps_label.text=="02" and game.status_label.text.contains("已抵达终点"),"visible blue action/exchange victory statistics")
	await _capture("north_09_completed.png")
	await _click("Undo")
	_check(game.model.snapshot()==before_final and not game.model.is_complete(),"blue GUI victory undo restores preceding whole state")
	await _click("Restart")
	_check(game.model.snapshot()==initial and game.model.history_size()==0,"blue victory restart restores original crystal identities and zero exchanges")
	await _click("Level08")
	_check(game.model.level.hero_kind=="green" and game.swaps_label==null and game.pulls_label!=null and game.model.swaps==0 and game.model.history_size()==0,"blue counter, ability UI and history do not leak into green")
	await _press(KEY_W)
	_check(game.model.pulls==1 and game.model.swaps==0,"green still auto-pulls normally after blue")
	await _click("Level09")
	await _press(KEY_Z)
	_check(game.model.snapshot()==initial,"green history cannot enter blue level")
	await _blue_death_fixture()
	await _click("Level09")
	_check(game.model.snapshot()==initial,"independent death/undo fixture leaves actual ninth clean")
	_check_layout(game)
	root.size=Vector2i(960,615)
	await _settle()
	_check_layout(game)
	await _capture("north_09_compact.png")
	print("NORTH 09 SCENE RESULT: %d checks, %d failures; display=%s" % [checks,failures,DisplayServer.get_name()])
	game.queue_free()
	await process_frame
	quit(0 if failures==0 else 1)

func _action(symbol: String) -> void:
	var skill:=symbol==symbol.to_lower()
	if skill:
		var modifier:=InputEventKey.new()
		modifier.keycode=KEY_SHIFT
		modifier.physical_keycode=KEY_SHIFT
		modifier.pressed=true
		Input.parse_input_event(modifier)
	for pressed in [true,false]:
		var event:=InputEventKey.new()
		event.keycode=_keycode(symbol.to_upper())
		event.physical_keycode=event.keycode
		event.pressed=pressed
		event.shift_pressed=skill
		Input.parse_input_event(event)
		await process_frame
	if skill:
		var modifier:=InputEventKey.new()
		modifier.keycode=KEY_SHIFT
		modifier.physical_keycode=KEY_SHIFT
		modifier.pressed=false
		Input.parse_input_event(modifier)
		await process_frame

func _repeat_swap_check() -> void:
	await _press(KEY_S)
	var event:=InputEventKey.new()
	event.keycode=KEY_D
	event.physical_keycode=KEY_D
	event.pressed=true
	event.shift_pressed=true
	Input.parse_input_event(event)
	await process_frame
	var once: Dictionary=game.model.snapshot()
	_check(game.model.swaps==1 and game.model.moves==2,"first deliberate skill press exchanges once")
	for echo in [true,false]:
		event.echo=echo
		Input.parse_input_event(event.duplicate())
		await process_frame
		_check(game.model.snapshot()==once,"held/echo skill cannot repeat exchange")
	event.pressed=false
	Input.parse_input_event(event)
	await process_frame
	await _press(KEY_D)
	_check(game.model.player==Vector2i(4,2) and game.model.swaps==1,"plain direction after skill release remains one-cell walk")

func _blue_death_fixture() -> void:
	var definition:=Level.from_dictionary({"schema_version":1,"id":"blue_death_fixture","title":"Independent blue death fixture","is_temporary":true,"source_note":"Tests only; never filmed as ninth level","hero_kind":"blue","terrain":[".....",".....","....."],"player":[1,1],"crates":[[3,1]],"targets":[],"objective":"none","energy_links":[{"id":"a","plate":[1,1],"barriers":[[3,1]],"pressure_sources":["hero"]}]})
	_check(definition.error.is_empty() and game.model.load_level(definition),"independent blue mechanism fixture loads")
	game.apply_command({"action":&"restart"})
	var initial: Dictionary=game.model.snapshot()
	await _action("r")
	_check(not game.model.alive and game.model.swaps==1 and game.swaps_label.text=="01" and game.status_label.text.contains("死亡"),"real skill input settles restoration death and shows exchange statistic")
	_check(game.restart_button.disabled and game.find_child("SwapRight",true,false).disabled and game.find_child("MoveRight",true,false).disabled and game.find_child("Level09",true,false).disabled,"dead blue UI leaves only undo available")
	var dead: Dictionary=game.model.snapshot()
	await _press(KEY_R)
	await _press(KEY_A)
	await _action("l")
	_check(not game.select_level(0) and game.model.snapshot()==dead,"walk/skill/restart/switch cannot revive blue")
	await _press(KEY_Z)
	_check(game.model.alive and game.model.snapshot()==initial and game.model.swaps==0,"one actual undo revives blue and restores full pre-skill state")
	_check(game.select_level(0),"leave independent fixture before selecting real ninth level")
	await _settle()
