extends SceneTree
const Level=preload("res://scripts/core/level_data.gd")
const State=preload("res://scripts/core/grid_state.gd")
const DIRS:={"U":Vector2i.UP,"D":Vector2i.DOWN,"L":Vector2i.LEFT,"R":Vector2i.RIGHT}
var checks:=0
var failures:=0

func _init() -> void:
	var cases:=[_test_map,_test_solution,_test_walk_and_sight,_test_switch]
	for test: Callable in cases:
		var before:=failures
		test.call()
		print("%s %s" % ["PASS" if before==failures else "FAIL",test.get_method()])
	print("NORTH 09 RESULT: %d cases, %d checks, %d failures" % [cases.size(),checks,failures])
	quit(0 if failures==0 else 1)

func _test_map() -> void:
	var game:=_game()
	_check(game.level.width==11 and game.level.height==3 and game.level.hero_kind=="blue" and game.player==Vector2i(1,1),"confirmed blue hero and ninth rectangle")
	for y in 3:
		for x in 11:
			_check(game.level.is_floor(Vector2i(x,y))==(Vector2i(x,y) not in [Vector2i(3,0),Vector2i(3,1),Vector2i(7,1),Vector2i(7,2)]),"all 33 confirmed terrain cells")
	_check(game.crates().size()==2 and game.crate_id(Vector2i(7,0))==0 and game.crate_id(Vector2i(3,2))==1 and game.level.crystal_colors==PackedStringArray(["purple","blue_purple"]),"purple and blue-purple crystals at confirmed coordinates")
	_check(game.level.exit_cell==Vector2i(9,1) and game.level.bushes.is_empty() and game.level.energy_links.is_empty(),"destination and no invented mechanics")

func _test_solution() -> void:
	var game:=_game()
	var initial:=game.snapshot()
	var solution: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://levels/solutions/north_09.json"))
	var history: Array[Dictionary]=[]
	var used:={}
	for index in solution["path"].length():
		var symbol: String=solution["path"][index]
		var direction: Vector2i=DIRS[symbol.to_upper()]
		var before:=game.snapshot()
		history.append(before)
		if symbol==symbol.to_lower():
			var target:=game.swap_target(direction)
			_check(game.try_swap(direction)==&"swapped" and game.player==target["cell"] and game.crate_id(before["player"])==target["id"],"explicit action exchanges exact first visible crystal with hero")
			used[target["id"]]=true
		else:
			_check(game.try_move(direction)==&"moved" and game.player==before["player"]+direction,"ordinary action is exactly one walk, no exchange")
		_check(game.moves==index+1 and game.alive and game.pushes==0 and game.pulls==0 and game.is_complete()==(index==8),"ninth legal operation counters and final-only victory")
	_check(used.size()==2 and game.moves==9 and game.swaps==2 and game.is_complete(),"both crystals participate: seven walks plus two explicit swaps")
	_check(game.undo() and game.snapshot()==history.pop_back() and not game.is_complete(),"victory undo restores full preceding state")
	while not history.is_empty():_check(game.undo() and game.snapshot()==history.pop_back(),"entire history restores each walk and exchange atomically")
	_check(game.snapshot()==initial and game.history_size()==0,"full undo returns exact initial identities and swap counter")
	for symbol in solution["path"]:
		if symbol==symbol.to_lower():game.try_swap(DIRS[symbol.to_upper()])
		else:game.try_move(DIRS[symbol])
	_check(game.restart() and game.snapshot()==initial,"restart after blue victory restores original actors and all counters")
	print("NORTH 09 SOLUTION: %s; 9 actions, 2 swaps, 0 pushes/pulls" % solution["path"])

func _test_walk_and_sight() -> void:
	var game:=_game()
	var before:=game.snapshot()
	_check(game.try_swap(Vector2i.RIGHT)==&"swap_blocked" and game.snapshot()==before and game.history_size()==0,"initial wall blocks sight toward distant crystal")
	game.try_move(Vector2i.DOWN)
	_check(game.try_move(Vector2i.RIGHT)==&"moved" and game.player==Vector2i(2,2) and game.swaps==0,"normal walking toward lower crystal does not auto-swap")
	before=game.snapshot()
	_check(game.try_move(Vector2i.RIGHT)==&"cannot_push" and game.snapshot()==before,"normal blue walk cannot push adjacent lower crystal")
	_check(game.try_move(Vector2i.LEFT)==&"moved" and game.crate_id(Vector2i(3,2))==1 and game.pulls==0,"walking away cannot pull lower crystal")
	_check(game.try_swap(Vector2i.RIGHT)==&"swapped" and game.player==Vector2i(3,2) and game.crate_id(Vector2i(1,2))==1,"only deliberate skill crosses the lower gap")

func _test_switch() -> void:
	var game:=_game()
	var initial:=game.snapshot()
	game.try_move(Vector2i.DOWN)
	game.try_swap(Vector2i.RIGHT)
	_check(game.load_level(Level.from_file("res://levels/north_08.json")) and game.level.hero_kind=="green" and game.swaps==0 and game.history_size()==0,"blue ability history/counter do not leak into eighth")
	_check(game.load_level(Level.from_file("res://levels/north_09.json")) and game.snapshot()==initial and game.history_size()==0,"ninth reload restores independent initial state")

func _game() -> State:
	var definition:=Level.from_file("res://levels/north_09.json")
	_check(definition.error.is_empty(),"ninth confirmed JSON validates: "+definition.error)
	var game:=State.new()
	_check(game.load_level(definition),"ninth initializes")
	return game

func _check(condition: bool,message: String) -> void:
	checks+=1
	if not condition:
		failures+=1
		printerr("FAIL: ",message)
