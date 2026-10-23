extends SceneTree
## Shared-engine multi-hero behavior, isolated from any campaign map.
const Level=preload("res://scripts/core/level_data.gd")
const State=preload("res://scripts/core/grid_state.gd")
var checks:=0
var failures:=0

func _init() -> void:
	var cases:=[_validation,_mixed_lines,_blue_targets,_selection,_goals,_inactive_death,_green_single_pull]
	for test: Callable in cases:
		var before:=failures
		test.call()
		print("%s %s" % ["PASS" if before==failures else "FAIL",test.get_method()])
	print("MULTI HERO RESULT: %d cases, %d checks, %d failures" % [cases.size(),checks,failures])
	quit(0 if failures==0 else 1)

func _fixture(width: int=9) -> Dictionary:
	return {"schema_version":1,"id":"multi_fixture","title":"Mechanism fixture","source_note":"Independent regression fixture", "is_temporary":true,
		"terrain":[".".repeat(width),".".repeat(width),".".repeat(width)],
		"heroes":[{"id":"red","kind":"red","position":[0,1]},{"id":"blue","kind":"blue","position":[3,1]}],
		"active_hero":"red","crates":[],"targets":[],"objective":"none"}

func _validation() -> void:
	var data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://levels/north_13.json"))
	var level:=Level.from_dictionary(data)
	_check(level.error.is_empty() and level.initial_active_hero==1 and level.hero_definitions.size()==2,"multi data parses stable IDs and selected blue")
	for mutation in ["duplicate_id","overlap","unknown_kind","missing_active","wall","crystal","goal_count","goal_repeat","bush","ambiguous_player"]:
		var bad:=data.duplicate(true)
		match mutation:
			"duplicate_id":bad["heroes"][1]["id"]="red"
			"overlap":bad["heroes"][1]["position"]=[2,2]
			"unknown_kind":bad["heroes"][1]["kind"]="gray"
			"missing_active":bad["active_hero"]="absent"
			"wall":bad["heroes"][0]["position"]=[3,0]
			"crystal":bad["crates"].append([2,2]);bad.erase("crystal_colors")
			"goal_count":bad["exits"].pop_back()
			"goal_repeat":bad["exits"][1]=bad["exits"][0]
			"bush":bad["bushes"]=[[2,2]]
			"ambiguous_player":bad["player"]=[2,4]
		_check(not Level.from_dictionary(bad).error.is_empty(),"reject invalid multi data: "+mutation)
	var legacy:=State.new()
	_check(legacy.load_level(Level.from_file("res://levels/north_01.json")) and legacy.hero_count()==1,"legacy player normalizes to one hero")
	var initial:=legacy.snapshot()
	_check(legacy.switch_hero()==&"single_hero" and legacy.snapshot()==initial and legacy.history_size()==0,"single-hero C has no history or count")

func _mixed_lines() -> void:
	for length in [2,3,4,10]:
		var data:=_fixture(length+3)
		var blue_x: int=1+int(length/2)
		data["heroes"][1]["position"]=[blue_x,1]
		for x in range(1,length+1):
			if x!=blue_x:data["crates"].append([x,1])
		var game:=_game(data)
		var initial:=game.snapshot()
		_check(game.try_move(Vector2i.RIGHT)==&"pushed" and game.hero_position(0)==Vector2i(1,1) and game.hero_position(1)==Vector2i(blue_x+1,1),"red moves mixed line of %d once" % length)
		for index in data["crates"].size():
			var cell: Array=data["crates"][index]
			_check(game.crate_id(Vector2i(cell[0]+1,1))==index,"mixed push retains every crystal identity")
		_check(game.active_hero_id()=="red" and game.pushes==1 and game.swaps==0 and game.moves==1,"pushed blue hero does not exchange or steal selection")
		_check(game.undo() and game.snapshot()==initial,"one undo restores the complete mixed line")
		game.try_move(Vector2i.RIGHT)
		_check(game.restart() and game.snapshot()==initial,"restart restores all mixed objects")
		for obstacle in ["edge","wall","bush","energy"]:
			var blocked:=data.duplicate(true)
			var terminal: int=length+1
			match obstacle:
				"edge":blocked["terrain"]=[".".repeat(terminal),".".repeat(terminal),".".repeat(terminal)]
				"wall":blocked["terrain"][1]=".".repeat(terminal)+"#."
				"bush":blocked["bushes"]=[[terminal,1]]
				"energy":blocked["energy_links"]=[{"id":"gate","plates":[[0,0]],"activation":"all","barriers":[[terminal,1]],"pressure_sources":["hero","crystal"]}]
			var stopped:=_game(blocked)
			var before:=stopped.snapshot()
			_check(stopped.try_move(Vector2i.RIGHT)==&"crate_blocked" and stopped.snapshot()==before and stopped.history_size()==0,"mixed length %d blocked atomically by %s" % [length,obstacle])

func _blue_targets() -> void:
	var data:=_fixture()
	data["heroes"][0]["position"]=[3,1]
	data["heroes"][1]["position"]=[0,1]
	data["active_hero"]="blue"
	data["crates"]=[[6,1]]
	var game:=_game(data)
	var initial:=game.snapshot()
	_check(game.try_move(Vector2i.RIGHT)==&"swapped" and game.hero_position(0)==Vector2i(0,1) and game.hero_position(1)==Vector2i(3,1) and game.crate_id(Vector2i(6,1))==0,"nearest visible hero takes priority over farther crystal")
	_check(game.active_hero_id()=="blue" and game.swaps==1 and game.pushes==0,"hero exchange retains selected identity and does not fire red ability")
	_check(game.try_move(Vector2i.RIGHT)==&"swapped" and game.hero_position(1)==Vector2i(6,1) and game.crate_id(Vector2i(3,1))==0 and game.hero_position(0)==Vector2i(0,1),"next fresh direction exchanges crystal only")
	_check(game.undo() and game.undo() and game.snapshot()==initial,"hero and crystal exchanges undo atomically")
	for obstacle in ["wall","bush","energy"]:
		var blocked:=data.duplicate(true)
		if obstacle=="wall":blocked["terrain"][1]="..#......"
		elif obstacle=="bush":blocked["bushes"]=[[2,1]]
		else:blocked["energy_links"]=[{"id":"g","plates":[[0,0]],"activation":"all","barriers":[[2,1]],"pressure_sources":["hero","crystal"]}]
		var state:=_game(blocked)
		_check(state.try_move(Vector2i.RIGHT)==&"moved" and state.player==Vector2i(1,1) and state.hero_position(0)==Vector2i(3,1) and state.swaps==0,"sight obstacle hides the hero: "+obstacle)

func _selection() -> void:
	var game:=_game(_fixture())
	var initial:=game.snapshot()
	_check(not initial.has("active_hero") and not initial.has("switches") and not initial.has("player"),"multi undo snapshots contain the world, not selection or selected-player aliases")
	_check(game.switch_hero()==&"switched" and game.active_hero_id()=="blue" and game.snapshot()==initial and game.moves==0 and game.history_size()==0,"C changes selection without count or undo snapshot")
	_check(not game.undo() and game.active_hero_id()=="blue" and game.snapshot()==initial,"empty undo after C retains user selection")
	for index in 6:
		game.switch_hero()
		_check(game.active_hero_id()==("red" if index%2==0 else "blue") and game.snapshot()==initial and game.history_size()==0,"consecutive C cycles stably without world changes or history")
	_check(game.try_move(Vector2i.DOWN)==&"moved" and game.moves==1 and game.history_size()==1,"blue actual move creates one count and one history entry")
	game.switch_hero()
	_check(game.active_hero_id()=="red" and game.moves==1 and game.history_size()==1,"switch after a move leaves action count/history intact")
	_check(game.undo() and game.snapshot()==initial and game.active_hero_id()=="red","undo after switching restores blue movement while keeping current red selection")
	_check(game.try_move(Vector2i.RIGHT)==&"moved","selected red makes the next actual move")
	var red_moved:=game.snapshot()
	game.switch_hero()
	_check(game.try_move(Vector2i.DOWN)==&"moved" and game.moves==2 and game.history_size()==2,"interleaved blue movement is the second actual action")
	game.switch_hero()
	_check(game.undo() and game.snapshot()==red_moved and game.active_hero_id()=="red","undo ignores most recent C and rolls back blue action with red selected")
	game.switch_hero()
	_check(game.undo() and game.snapshot()==initial and game.active_hero_id()=="blue" and game.history_size()==0,"second undo rolls back red action while retaining blue")
	var copy:=game.heroes()
	copy[0]["position"]=Vector2i(8,2)
	var snapshot:=game.snapshot()
	snapshot["hero_positions"][0]=Vector2i(8,2)
	_check(game.snapshot()==initial,"public hero records and snapshots cannot mutate live state")
	game.try_move(Vector2i.DOWN)
	_check(game.restart() and game.snapshot()==initial and game.active_hero_id()=="red" and game.history_size()==0,"restart resets the world and explicit initial selection")

func _goals() -> void:
	var data:=_fixture()
	data["heroes"][0]["position"]=[1,1]
	data["heroes"][1]["position"]=[2,1]
	data["active_hero"]="blue"
	data["exits"]=[[1,1],[3,1]]
	data["objective"]="all_heroes_on_exits"
	data["crates"]=[[3,1]]
	var game:=_game(data)
	var before:=game.snapshot()
	_check(not game.is_complete() and game.occupied_exits()==1,"crystal on second exit never substitutes for a hero")
	_check(game.try_move(Vector2i.RIGHT)==&"swapped" and game.is_complete() and game.occupied_exits()==2,"second hero arrival wins with different exits")
	_check(game.switch_hero()==&"complete" and game.try_move(Vector2i.DOWN)==&"complete","victory freezes input except undo and restart")
	_check(game.undo() and game.snapshot()==before and not game.is_complete(),"victory undo restores both heroes, crystal and counters")
	data["crates"]=[]
	data["heroes"][0]["position"]=[3,1];data["heroes"][1]["position"]=[1,1]
	_check(_game(data).is_complete(),"hero-to-exit assignment is unrestricted")

func _inactive_death() -> void:
	var data:=_fixture()
	data["heroes"][0]["position"]=[1,1]
	data["heroes"][1]["position"]=[3,1]
	data["energy_links"]=[{"id":"all","plates":[[1,1]],"activation":"all","barriers":[[3,1]],"pressure_sources":["hero","crystal"]}]
	var game:=_game(data)
	var initial:=game.snapshot()
	_check(game.alive and game.pressure_is_active("all") and not game.blocks_sight(Vector2i(3,1)),"inactive hero can stand inside open barrier")
	_check(game.try_move(Vector2i.DOWN)==&"died" and not game.alive and game.hero_is_alive(0) and not game.hero_is_alive(1),"plate release kills inactive hero at restored barrier only")
	var dead:=game.snapshot()
	_check(game.switch_hero()==&"dead" and game.try_move(Vector2i.RIGHT)==&"dead" and not game.restart() and not game.load_level(Level.from_file("res://levels/north_01.json")) and game.snapshot()==dead,"any hero death locks movement, C, restart and level changes")
	_check(game.undo() and game.snapshot()==initial and game.alive and game.hero_is_alive(1),"one undo revives inactive hero and restores selection, pressure and gate together")
	game.switch_hero()
	var switched:=game.snapshot()
	_check(game.pressure_is_active("all") and game.hero_is_alive(1) and not game.barrier_is_active(Vector2i(3,1)),"C does not release inactive red hero pressure or settle death")
	_check(game.try_move(Vector2i.LEFT)==&"swapped" and game.active_hero_id()=="blue" and game.hero_position(0)==Vector2i(3,1) and game.hero_position(1)==Vector2i(1,1) and game.alive and game.pressure_is_active("all"),"hero swap hands plate over atomically, with no intermediate restoration")
	_check(game.undo() and game.snapshot()==switched and game.active_hero_id()=="blue","undo restores the pressure handoff and retains current blue selection")

func _green_single_pull() -> void:
	var data:=_fixture()
	data["heroes"][0]["kind"]="green"
	data["heroes"][0]["position"]=[3,1]
	data["heroes"][1]["position"]=[2,1]
	data["crates"]=[[1,1]]
	var game:=_game(data)
	_check(game.try_move(Vector2i.RIGHT)==&"moved" and game.hero_position(1)==Vector2i(2,1) and game.crate_id(Vector2i(1,1))==0 and game.pulls==0,"green fixture never pulls an adjacent hero or crystal behind that hero")
	data["heroes"][1]["position"]=[7,1];data["crates"]=[[2,1],[1,1]]
	game=_game(data)
	_check(game.try_move(Vector2i.RIGHT)==&"pulled" and game.crate_id(Vector2i(3,1))==0 and game.crate_id(Vector2i(1,1))==1 and game.pulls==1,"multi runtime preserves green nearest-single crystal rule")

func _game(data: Dictionary) -> State:
	var level:=Level.from_dictionary(data)
	_check(level.error.is_empty(),"fixture validates: "+level.error)
	var game:=State.new()
	_check(game.load_level(level),"fixture initializes: "+game.last_mechanism_error)
	return game

func _check(condition: bool,message: String) -> void:
	checks+=1
	if not condition:
		failures+=1
		printerr("FAIL: ",message)
