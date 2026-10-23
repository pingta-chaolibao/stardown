extends SceneTree
## Final user correction opens (0,2); every other confirmed cell is preserved.
const Level = preload("res://scripts/core/level_data.gd")
const State = preload("res://scripts/core/grid_state.gd")
const DIRS := {"U":Vector2i.UP,"D":Vector2i.DOWN,"L":Vector2i.LEFT,"R":Vector2i.RIGHT}
const TERRAIN := ["#########...#####","...#............#","...#....#...#...#","#..#....#####...#","#..####.#..####.#","#.......#........","#..##...#...##...","#####...##.######","#####.###..##....","###..............","###...###########"]
const PLATE := Vector2i(12,5)
const GATES := [Vector2i(12,1),Vector2i(15,4)]
var checks := 0
var failures := 0

func _init() -> void:
	var cases := [_test_map,_test_solution,_test_release_and_blocking,_test_switch]
	for test: Callable in cases:
		var before := failures
		test.call()
		print("%s %s" % ["PASS" if before==failures else "FAIL",test.get_method()])
	print("NORTH 07 RESULT: %d cases, %d checks, %d failures" % [cases.size(),checks,failures])
	quit(0 if failures==0 else 1)

func _test_map() -> void:
	var game := _game()
	_check(game.level.width==17 and game.level.height==11 and game.level.hero_kind=="green" and game.player==Vector2i(11,5),"confirmed seventh size and green hero")
	for y in 11:
		for x in 17:
			_check(game.level.is_floor(Vector2i(x,y))==(TERRAIN[y][x]=="."),"all 187 final terrain cells")
	_check(game.level.is_floor(Vector2i(0,2)) and not game.level.is_floor(Vector2i(4,6)) and not game.level.is_floor(Vector2i(6,8)),"only user correction opens (0,2); both explicitly denied openings stay walls")
	_check(game.level.is_floor(Vector2i(5,9)) and game.level.is_floor(Vector2i(5,10)),"original IDs 70 and 129 remain floor")
	_check(game.crates().size()==1 and game.crate_id(Vector2i(9,0))==0 and game.level.crystal_colors==PackedStringArray(["purple"]),"one purple crystal at original marker 6")
	_check(game.level.exit_cell==Vector2i(14,2) and game.level.exit_color=="green" and game.level.bushes.is_empty(),"green goal and no invented obstacles")
	_check(game.level.energy_links.size()==1 and game.level.energy_links[0]["plates"]==[PLATE] and game.barrier_states().size()==2,"one plate controls exactly two barriers")
	_for_gates(game,false,"initial barriers block movement and sight")
	for cell in [Vector2i(-1,2),Vector2i(17,2),Vector2i(5,-1),Vector2i(5,11)]:
		_check(not game.is_walkable(cell) and game.blocks_sight(cell),"outside boundary blocks movement and sight")

func _test_solution() -> void:
	var game := _game()
	var initial := game.snapshot()
	var solution := _solution()
	var history: Array[Dictionary] = []
	var uses_new_floor := false
	for index in solution["path"].length():
		history.append(game.snapshot())
		_check(game.try_move(DIRS[solution["path"][index]]) in [&"moved",&"pulled"],"seventh legal step %d" % (index+1))
		_check(game.alive and game.moves==index+1 and game.pushes==0 and game.last_mechanism_error.is_empty(),"every step remains defined, living and pull-only")
		_check(game.is_complete()==(index==151),"only final hero arrival wins")
		uses_new_floor = uses_new_floor or game.player==Vector2i(0,2)
		if index in [112,113,122,123]:
			_for_gates(game,true,"hero/crystal pressure opens both barriers")
		if index==114:
			_for_gates(game,false,"pulling crystal beyond plate closes both barriers")
		if index>=123:
			_check(game.crate_id(PLATE)==0 and game.pressure_is_active("yellow_01"),"final purple pressure is held throughout return route")
		if index==148:
			_check(game.player==GATES[0] and not game.blocks_sight(GATES[0]),"actual hero crosses energy marker 9 at its corrected base")
	_check(uses_new_floor and game.moves==152 and game.pulls==56 and game.pushes==0 and game.is_complete(),"verified 152 moves / 56 pulls uses the newly confirmed floor")
	_check(game.undo() and game.snapshot()==history.pop_back() and not game.is_complete(),"victory undo restores exact full preceding state")
	while not history.is_empty():
		_check(game.undo() and game.snapshot()==history.pop_back(),"every action reverses all counters, crystal and both barriers")
	_check(game.snapshot()==initial and game.history_size()==0,"full undo returns exact initial state")
	for symbol in solution["path"]:game.try_move(DIRS[symbol])
	_check(game.restart() and game.snapshot()==initial and game.history_size()==0,"victory restart restores entire initial level")
	print("NORTH 07 SOLUTION: %s; 152 moves, 56 pulls, 0 pushes" % solution["path"])

func _test_release_and_blocking() -> void:
	var game := _game()
	var path: String = _solution()["path"]
	for index in 114:game.try_move(DIRS[path[index]])
	var held := game.snapshot()
	_check(game.player==Vector2i(13,5) and game.crate_id(PLATE)==0,"real route reaches first crystal-held pressure")
	_check(game.try_move(Vector2i.RIGHT)==&"pulled" and not game.pressure_is_active("yellow_01"),"automatic pull can release the real plate")
	_for_gates(game,false,"both doors restore movement and sight blocking")
	_check(game.undo() and game.snapshot()==held,"one undo restores pressure, both barriers and pull count")
	game.try_move(Vector2i.RIGHT)
	game.try_move(Vector2i.RIGHT)
	var blocked := game.snapshot()
	var depth := game.history_size()
	_check(game.player==Vector2i(15,5) and game.try_move(Vector2i.UP)==&"energy_blocked" and game.snapshot()==blocked and game.history_size()==depth,"actual lower gate blocks movement without partial state")
	_check(game.try_move(Vector2i.LEFT)==&"cannot_push" and game.snapshot()==blocked and game.history_size()==depth,"green cannot push adjacent crystal while blocked near gate")

func _test_switch() -> void:
	var game := _game()
	var initial := game.snapshot()
	game.try_move(Vector2i.DOWN)
	_check(game.load_level(Level.from_file("res://levels/north_06.json")) and game.barrier_states().size()==1 and game.history_size()==0 and game.pulls==0,"seventh history and extra barrier do not leak into sixth")
	_check(game.load_level(Level.from_file("res://levels/north_07.json")) and game.snapshot()==initial and game.history_size()==0,"seventh reload restores independent initial state")

func _for_gates(game: State, opened: bool, message: String) -> void:
	for gate in GATES:
		_check(game.barrier_is_active(gate)==not opened and game.is_walkable(gate)==opened and game.blocks_sight(gate)==not opened,message)

func _game() -> State:
	var definition := Level.from_file("res://levels/north_07.json")
	_check(definition.error.is_empty(),"seventh final data validates: "+definition.error)
	var game := State.new()
	_check(game.load_level(definition),"seventh initializes")
	return game

func _solution() -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string("res://levels/solutions/north_07.json"))

func _check(condition: bool,message: String) -> void:
	checks+=1
	if not condition:
		failures+=1
		printerr("FAIL: ",message)
