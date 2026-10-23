extends SceneTree
## Confirmed tenth map, passive swaps, pressure handoff and isolated history.
const Level=preload("res://scripts/core/level_data.gd")
const State=preload("res://scripts/core/grid_state.gd")
const DIRS={"U":Vector2i.UP,"D":Vector2i.DOWN,"L":Vector2i.LEFT,"R":Vector2i.RIGHT}
const TERRAIN=[".......#...","...#.......",".......#...","#####.###.#","...#...#...","...........","...#...#..."]
const PLATE=Vector2i(10,6)
const GATE=Vector2i(3,5)
var checks:=0
var failures:=0

func _init() -> void:
	var cases:=[_test_map,_test_solution,_test_blockers,_test_pressure_handoff,_test_switch]
	for test: Callable in cases:
		var before:=failures
		test.call()
		print("%s %s" % ["PASS" if before==failures else "FAIL",test.get_method()])
	print("NORTH 10 RESULT: %d cases, %d checks, %d failures" % [cases.size(),checks,failures])
	quit(0 if failures==0 else 1)

func _test_map() -> void:
	var game:=_game()
	_check(game.level.width==11 and game.level.height==7 and game.level.hero_kind=="blue" and game.player==Vector2i(0,1),"confirmed tenth rectangle and blue hero")
	for y in 7:
		for x in 11:
			_check(game.level.is_floor(Vector2i(x,y))==(TERRAIN[y][x]=="."),"all 77 user-confirmed terrain cells")
	_check(game.is_walkable(Vector2i(3,0)),"user correction: original marker 4 is floor")
	for cell in [Vector2i(-1,1),Vector2i(11,1),Vector2i(1,-1),Vector2i(1,7)]:
		_check(not game.is_walkable(cell) and game.blocks_sight(cell),"outside blocks movement and sight")
	_check(game.crates().size()==1 and game.crate_id(Vector2i(1,1))==0 and game.level.crystal_colors==PackedStringArray(["purple"]),"single purple crystal at marker 13")
	_check(game.level.exit_cell==Vector2i(1,5) and game.level.exit_color=="green" and game.level.objective=="player_on_exit","green destination at marker 57")
	_check(game.level.bushes.is_empty() and game.level.energy_links.size()==1 and game.level.energy_links[0]["plates"]==[PLATE] and game.barrier_states().size()==1,"one plate, one energy cell, no extra mechanics")
	_check(game.barrier_is_active(GATE) and not game.is_walkable(GATE) and game.blocks_sight(GATE),"closed initial gate blocks movement and sight")

func _test_solution() -> void:
	var game:=_game()
	var initial:=game.snapshot()
	var solution:=_solution()
	var history: Array[Dictionary]=[]
	for index in solution["path"].length():
		var direction: Vector2i=DIRS[solution["path"][index]]
		var before:=game.snapshot()
		history.append(before)
		var target:=game.swap_target(direction)
		var result:=game.try_move(direction)
		if target["result"]==&"target":
			_check(result==&"swapped" and game.player==target["cell"] and game.crate_id(before["player"])==target["id"],"direction swaps first visible crystal without an intermediate walk")
		else:
			_check(result==&"moved" and game.player==before["player"]+direction,"no visible target walks one cell")
		_check(game.moves==index+1 and game.alive and game.pushes==0 and game.pulls==0 and game.last_mechanism_error.is_empty(),"actual route remains legal, alive and never pushes or pulls")
		_check(game.is_complete()==(index==solution["moves"]-1),"only final player arrival wins")
		if index==5:_check(game.player==Vector2i(3,0),"actual solution walks across corrected marker 4")
		if index==43:_check(game.player==PLATE and game.pressure_is_active("yellow_01") and not game.blocks_sight(GATE) and game.is_walkable(GATE),"hero press opens movement and sight")
		if index>=44:_check(game.crate_id(PLATE)==0 and game.pressure_is_active("yellow_01") and not game.barrier_is_active(GATE),"swap hands pressure to crystal continuously through victory")
		if index==51:_check(game.player==GATE,"actual hero crosses the open energy cell")
	_check(game.is_complete() and game.moves==54 and game.swaps==5,"54 direction inputs, five automatic swaps, explicit victory")
	_check(game.undo() and game.snapshot()==history.pop_back() and not game.is_complete(),"victory undo restores complete preceding state")
	while not history.is_empty():_check(game.undo() and game.snapshot()==history.pop_back(),"each action reverses all positions, identities, counters and mechanisms")
	_check(game.snapshot()==initial and game.history_size()==0,"full undo returns exact initial state")
	for symbol in solution["path"]:game.try_move(DIRS[symbol])
	_check(game.restart() and game.snapshot()==initial and game.history_size()==0,"victory restart restores initial crystal, gate and counters")
	print("NORTH 10 SOLUTION: %s; 54 actions, 5 swaps, 0 pushes/pulls" % solution["path"])

func _test_blockers() -> void:
	var game:=_game()
	var initial:=game.snapshot()
	_check(game.try_move(Vector2i.LEFT)==&"wall" and game.snapshot()==initial and game.history_size()==0,"initial boundary is a no-op")
	_check(game.try_move(Vector2i.RIGHT)==&"swapped" and game.player==Vector2i(1,1) and game.crate_id(Vector2i(0,1))==0,"adjacent initial crystal swaps without pushing")
	_check(game.try_move(Vector2i.RIGHT)==&"moved" and game.player==Vector2i(2,1),"empty input ray falls back to walking")
	var before:=game.snapshot()
	_check(game.try_move(Vector2i.RIGHT)==&"wall" and game.snapshot()==before,"wall blocks fallback movement atomically")
	game.restart()
	_advance(game,30)
	_check(game.player==Vector2i(5,5) and game.try_move(Vector2i.LEFT)==&"moved" and game.player==Vector2i(4,5),"legal prefix reaches closed gate from the right")
	before=game.snapshot()
	_check(game.swap_target(Vector2i.LEFT).get("cell")==GATE and game.try_move(Vector2i.LEFT)==&"energy_blocked" and game.snapshot()==before,"closed gate blocks sight and movement without counting a step")

func _test_pressure_handoff() -> void:
	var game:=_game()
	_advance(game,44)
	var pressed:=game.snapshot()
	_check(game.player==PLATE and game.crate_id(Vector2i(10,5))==0 and not game.barrier_is_active(GATE),"actual map setup has hero holding pressure")
	_check(game.try_move(Vector2i.LEFT)==&"moved" and game.barrier_is_active(GATE) and game.blocks_sight(GATE) and not game.is_walkable(GATE),"leaving plate restores both collision and sight")
	_check(game.undo() and game.snapshot()==pressed,"one undo restores plate and open gate")
	_check(game.try_move(Vector2i.UP)==&"swapped" and game.crate_id(PLATE)==0 and game.player==Vector2i(10,5) and game.alive and not game.barrier_is_active(GATE),"passive swap hands hero pressure to crystal without intermediate closure")
	var handoff:=game.snapshot()
	_check(game.try_move(Vector2i.DOWN)==&"swapped" and game.player==PLATE and game.crate_id(Vector2i(10,5))==0 and not game.barrier_is_active(GATE),"reverse direction intentionally exchanges again and hero keeps pressure")
	_check(game.try_move(Vector2i.LEFT)==&"moved" and game.barrier_is_active(GATE),"removing final occupant closes energy after exchange")
	_check(game.undo() and game.undo() and game.snapshot()==handoff,"two undos restore exact crystal-held gate state")

func _test_switch() -> void:
	var game:=_game()
	var initial:=game.snapshot()
	_advance(game,45)
	_check(game.load_level(Level.from_file("res://levels/north_09.json")) and game.level.hero_kind=="blue" and game.barrier_states().is_empty() and game.pressure_states().is_empty() and game.swaps==0 and game.history_size()==0,"tenth mechanisms and history do not leak into ninth")
	_check(game.load_level(Level.from_file("res://levels/north_10.json")) and game.snapshot()==initial and game.history_size()==0,"tenth reload restores independent closed-gate start")

func _advance(game: State,count: int) -> void:
	var path: String=_solution()["path"]
	for index in count:game.try_move(DIRS[path[index]])

func _solution() -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string("res://levels/solutions/north_10.json"))

func _game() -> State:
	var definition:=Level.from_file("res://levels/north_10.json")
	_check(definition.error.is_empty(),"tenth confirmed JSON validates: "+definition.error)
	var game:=State.new()
	_check(game.load_level(definition),"tenth initializes")
	return game

func _check(condition: bool,message: String) -> void:
	checks+=1
	if not condition:
		failures+=1
		printerr("FAIL: ",message)
