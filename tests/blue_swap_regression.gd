extends SceneTree
## Explicit ability, nearest sight targets, atomic world settlement and role isolation.
const Level=preload("res://scripts/core/level_data.gd")
const State=preload("res://scripts/core/grid_state.gd")
const Swap=preload("res://scripts/core/swap_rules.gd")
const Steps=preload("res://scripts/input/step_input.gd")
var checks:=0
var failures:=0

func _init() -> void:
	var cases:=[_test_four_directions,_test_plain_walk,_test_blockers_and_open_gate,_test_target_classes,_test_death_and_undo,_test_undefined_restoration,_test_victory_and_roles,_test_manual_input]
	for test: Callable in cases:
		var before:=failures
		test.call()
		print("%s %s" % ["PASS" if before==failures else "FAIL",test.get_method()])
	print("BLUE SWAP RESULT: %d cases, %d checks, %d failures" % [cases.size(),checks,failures])
	quit(0 if failures==0 else 1)

func _test_four_directions() -> void:
	for direction in [Vector2i.UP,Vector2i.DOWN,Vector2i.LEFT,Vector2i.RIGHT]:
		var data:=_data()
		data["terrain"]=[".........",".........",".........",".........",".........",".........",".........",".........","........."]
		data["player"]=[4,4]
		var nearest: Vector2i=Vector2i(4,4)+direction*2
		var farther: Vector2i=Vector2i(4,4)+direction*3
		data["crates"]=[_array(nearest),_array(farther)]
		var game:=_game(data)
		var initial:=game.snapshot()
		_check(game.try_swap(direction)==&"swapped" and game.player==nearest and game.crate_id(Vector2i(4,4))==0 and game.crate_id(farther)==1,"cardinal ability swaps first target only across empty space")
		_check(game.moves==1 and game.swaps==1 and game.pulls==0 and game.pushes==0 and game.history_size()==1,"exchange is one action and one atomic undo entry")
		_check(game.undo() and game.snapshot()==initial,"one undo restores hero, both crystal identities and all counters")
		game.try_swap(direction)
		_check(game.restart() and game.snapshot()==initial and game.history_size()==0,"restart restores full pre-exchange state")

func _test_plain_walk() -> void:
	var game:=_game(_data())
	_check(game.try_move(Vector2i.RIGHT)==&"moved" and game.player==Vector2i(2,1) and game.crate_id(Vector2i(4,1))==0 and game.swaps==0,"ordinary walk along sightline never auto-swaps")
	game.try_move(Vector2i.RIGHT)
	var before:=game.snapshot()
	_check(game.try_move(Vector2i.RIGHT)==&"cannot_push" and game.snapshot()==before,"blue cannot push even when there is room behind crystal")
	_check(game.try_move(Vector2i.LEFT)==&"moved" and game.crate_id(Vector2i(4,1))==0 and game.pulls==0,"blue walking away never pulls adjacent rear crystal")
	for direction in [Vector2i.ZERO,Vector2i(1,1),Vector2i(2,0)]:
		before=game.snapshot()
		_check(game.try_swap(direction)==&"invalid_direction" and game.snapshot()==before,"exchange rejects non-cardinal or multi-cell direction")
	game=_game(_data())
	before=game.snapshot()
	_check(game.try_swap(Vector2i.UP)==&"no_target" and game.snapshot()==before and game.history_size()==0,"empty ray to boundary is a no-op")

func _test_blockers_and_open_gate() -> void:
	for blocker in ["wall","bush","energy"]:
		var data:=_data()
		match blocker:
			"wall":data["terrain"][1]="...#....."
			"bush":data["bushes"]=[[3,1]]
			"energy":data["energy_links"]=[_link("a",[8,0],[[3,1]],["hero","crystal"])]
		var game:=_game(data)
		var before:=game.snapshot()
		_check(game.swap_target(Vector2i.RIGHT)["cell"]==Vector2i(3,1),"sight stops at exact blocking cell")
		_check(game.try_swap(Vector2i.RIGHT)==&"swap_blocked" and game.snapshot()==before and game.history_size()==0,"wall/bush/active energy blocks exchange atomically")
	var data:=_data()
	data["crates"].append([8,0])
	data["energy_links"]=[_link("a",[8,0],[[3,1]],["hero","crystal"])]
	var game:=_game(data)
	_check(not game.blocks_sight(Vector2i(3,1)) and game.try_swap(Vector2i.RIGHT)==&"swapped" and game.player==Vector2i(4,1),"inactive energy allows sight and exchange through its cell")

func _test_target_classes() -> void:
	for kind in [&"hero",&"crystal"]:_check(Swap.is_interactable(kind),"heroes and crystals are classified as exchange targets")
	for kind in [&"wall",&"bush",&"plate",&"goal",&"energy",&"decoration"]:_check(not Swap.is_interactable(kind),"static mechanics and decorations are not exchange targets")
	var targets:={Vector2i(5,1):{"kind":&"hero","id":17},Vector2i(7,1):{"kind":&"crystal","id":3},Vector2i(2,1):{"kind":&"goal"}}
	var occupant:=func(cell: Vector2i) -> Dictionary:return targets.get(cell,{})
	var clear:=func(_cell: Vector2i) -> bool:return false
	var first:=Swap.first_target(Vector2i(1,1),Vector2i.RIGHT,Rect2i(0,0,9,3),clear,occupant)
	_check(first["kind"]==&"hero" and first["cell"]==Vector2i(5,1) and first["id"]==17,"nearest hero wins before farther crystal; floor goal is ignored")
	var plan:=Swap.exchange_plan(Vector2i(1,1),first)
	_check(plan["player"]==Vector2i(5,1) and plan["target_cell"]==Vector2i(1,1) and plan["target_kind"]==&"hero" and plan["target_id"]==17,"data-only plan supports hero category without creating a multi-hero level")
	targets[Vector2i(3,1)]={"kind":&"crystal","id":9}
	first=Swap.first_target(Vector2i(1,1),Vector2i.RIGHT,Rect2i(0,0,9,3),clear,occupant)
	_check(first["kind"]==&"crystal" and first["id"]==9,"nearest crystal takes precedence over farther hero")
	_check(Swap.exchange_plan(Vector2i(1,1),{})["result"]==&"invalid_target","invalid exchange plan rejected")

func _test_death_and_undo() -> void:
	var data:=_data()
	data["crates"]=[[3,1],[8,0]]
	data["energy_links"]=[_link("hero_plate",[1,1],[[3,1]],["hero"]),_link("crystal_plate",[8,0],[[7,2]],["crystal"])]
	var game:=_game(data)
	var initial:=game.snapshot()
	_check(game.try_swap(Vector2i.RIGHT)==&"died" and not game.alive and game.player==Vector2i(3,1) and game.crate_id(Vector2i(1,1))==0,"exchange releases configured hero-only pressure and restores barrier on hero")
	_check(game.moves==1 and game.swaps==1 and game.history_size()==1 and game.barrier_is_active(Vector2i(3,1)) and game.barrier_is_active(Vector2i(7,2)),"all global barriers and death settle in the same single exchange action")
	var dead:=game.snapshot()
	_check(game.try_move(Vector2i.LEFT)==&"dead" and game.try_swap(Vector2i.LEFT)==&"dead" and not game.restart() and not game.load_level(Level.from_dictionary(_data())) and game.snapshot()==dead,"dead blue can neither walk, swap, restart nor switch")
	_check(game.undo() and game.alive and game.snapshot()==initial and game.swaps==0,"one undo revives and restores identity, pressure, every barrier and counter")

func _test_undefined_restoration() -> void:
	var data:=_data()
	data["crates"]=[[3,1]]
	data["energy_links"]=[_link("a",[3,1],[[1,1]],["crystal"])]
	var game:=_game(data)
	var before:=game.snapshot()
	_check(game.try_swap(Vector2i.RIGHT)==&"rule_unresolved" and game.snapshot()==before and game.history_size()==0 and game.swaps==0,"unconfirmed crystal restoration commits no part of an exchange")
	_check(not game.last_mechanism_error.is_empty(),"undefined case retains explicit diagnostic, not an invented rule")

func _test_victory_and_roles() -> void:
	var data:=_data()
	data["objective"]="player_on_exit"
	data["exit"]=[4,1]
	var game:=_game(data)
	var initial:=game.snapshot()
	_check(game.try_swap(Vector2i.RIGHT)==&"swapped" and game.is_complete(),"legal swap onto crystal at goal wins")
	var won:=game.snapshot()
	_check(game.try_swap(Vector2i.LEFT)==&"complete" and game.try_move(Vector2i.LEFT)==&"complete" and game.snapshot()==won,"completed world accepts no further movement or exchange")
	_check(game.undo() and game.snapshot()==initial and not game.is_complete(),"victory swap can be atomically undone")
	for kind in ["red","green"]:
		data=_data()
		data["hero_kind"]=kind
		game=_game(data)
		initial=game.snapshot()
		_check(game.try_swap(Vector2i.RIGHT)==&"cannot_swap" and game.snapshot()==initial and game.history_size()==0,"red and green cannot cast blue ability")

func _test_manual_input() -> void:
	for key in [KEY_W,KEY_A,KEY_S,KEY_D,KEY_UP,KEY_LEFT,KEY_DOWN,KEY_RIGHT]:
		var input:=Steps.new()
		var event:=InputEventKey.new()
		event.keycode=key
		event.physical_keycode=key
		event.pressed=true
		_check(input.command_for_event(event,true).get("action")==&"move","plain blue direction stays ordinary walk")
		event.pressed=false
		input.command_for_event(event,true)
		event.pressed=true
		event.shift_pressed=true
		_check(input.command_for_event(event,true).get("action")==&"swap","Shift plus direction explicitly casts exchange")
		for echo in [true,false]:
			event.echo=echo
			_check(input.command_for_event(event,true).is_empty(),"echo or duplicate cannot repeat an exchange")
		event.pressed=false
		input.command_for_event(event,true)
		event.pressed=true
		event.echo=false
		_check(input.command_for_event(event).get("action")==&"move","legacy heroes retain their existing Shift-direction movement")

func _data() -> Dictionary:
	return {"schema_version":1,"id":"blue_swap_fixture","title":"Independent blue swap fixture","is_temporary":true,"source_note":"Tests only; not a reconstructed level or walkthrough","hero_kind":"blue","terrain":[".........",".........","........."],"player":[1,1],"crates":[[4,1]],"targets":[],"objective":"none"}

func _link(id: String,plate: Array,barriers: Array,sources: Array) -> Dictionary:
	return {"id":id,"plate":plate,"barriers":barriers,"pressure_sources":sources}

func _game(data: Dictionary) -> State:
	var definition:=Level.from_dictionary(data)
	_check(definition.error.is_empty(),"blue fixture validates: "+definition.error)
	var game:=State.new()
	_check(game.load_level(definition),"blue fixture initializes")
	return game

func _array(cell: Vector2i) -> Array:return [cell.x,cell.y]

func _check(condition: bool,message: String) -> void:
	checks+=1
	if not condition:
		failures+=1
		printerr("FAIL: ",message)
