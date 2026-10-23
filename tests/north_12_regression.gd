extends SceneTree
const Level=preload("res://scripts/core/level_data.gd")
const State=preload("res://scripts/core/grid_state.gd")
const DIRS={"U":Vector2i.UP,"D":Vector2i.DOWN,"L":Vector2i.LEFT,"R":Vector2i.RIGHT}
const GATE=Vector2i(6,1)
const PLATES=[Vector2i(1,4),Vector2i(3,4),Vector2i(5,4)]
var checks:=0
var failures:=0

func _init() -> void:
	var cases:=[_test_map,_test_solution,_test_bush_and_gate,_test_handoff_and_release,_test_colors_and_switch]
	for test: Callable in cases:
		var before:=failures
		test.call()
		print("%s %s" % ["PASS" if before==failures else "FAIL",test.get_method()])
	print("NORTH 12 RESULT: %d cases, %d checks, %d failures" % [cases.size(),checks,failures])
	quit(0 if failures==0 else 1)

func _test_map() -> void:
	var game:=_game()
	_check(game.level.width==7 and game.level.height==6 and game.level.hero_kind=="blue" and game.player==Vector2i(1,1),"confirmed twelfth blue rectangle and start")
	for y in 6:
		for x in 7:
			_check(game.level.is_floor(Vector2i(x,y))==(Vector2i(x,y) not in [Vector2i(5,0),Vector2i(5,1)]),"all 42 confirmed terrain cells including complete top/bottom rows")
	for cell in [Vector2i(-1,1),Vector2i(7,1),Vector2i(1,-1),Vector2i(1,6)]:_check(not game.is_walkable(cell) and game.blocks_sight(cell),"outside blocks movement and sight")
	_check(game.crates().size()==3 and game.crate_id(Vector2i(2,1))==0 and game.crate_id(Vector2i(1,2))==1 and game.crate_id(Vector2i(2,2))==2,"all three initial crystal identities")
	_check(game.level.crystal_colors==PackedStringArray(["orange","purple","pink"]),"orange, purple and pink presentation matches confirmation")
	_check(game.level.bushes.size()==2 and game.level.bush_at(Vector2i(3,3))!=null and game.level.bush_at(Vector2i(3,5))!=null,"exact two immovable bushes")
	_check(game.level.energy_links.size()==1 and game.level.energy_links[0]["plates"]==PLATES and game.level.mechanism_color=="yellow" and game.level.void_cells.is_empty(),"three yellow plates and no extra void or mechanisms")
	_check(game.level.exit_cell==Vector2i(6,0) and game.barrier_is_active(GATE) and not game.is_walkable(GATE) and game.blocks_sight(GATE),"top-right goal and initially opaque, impassable yellow gate")

func _test_solution() -> void:
	var game:=_game()
	var initial:=game.snapshot()
	var history: Array[Dictionary]=[]
	var solution:=_solution()
	var used: Dictionary={}
	for index in solution["path"].length():
		var before:=game.snapshot()
		history.append(before)
		var direction: Vector2i=DIRS[solution["path"][index]]
		var target:=game.swap_target(direction)
		var result:=game.try_move(direction)
		if target["result"]==&"target":
			_check(result==&"swapped" and game.player==target["cell"] and game.crate_id(before["player"])==target["id"],"input prioritizes the first visible crystal and exchanges both identities")
			used[target["id"]]=true
		else:_check(result==&"moved" and game.player==before["player"]+direction,"empty input ray walks exactly one cell")
		_check(game.moves==index+1 and game.alive and game.pushes==0 and game.pulls==0 and game.last_mechanism_error.is_empty(),"actual route remains defined, alive and never pushes or pulls")
		_check(game.is_complete()==(index==25),"only final player arrival wins")
		if index>=21:_check(game.pressure_progress("yellow_01")==Vector2i(3,3) and not game.barrier_is_active(GATE) and not game.blocks_sight(GATE) and game.is_walkable(GATE),"all three plates continuously keep movement and sight open")
		if index==21:_check(game.player==Vector2i(5,4),"hero completes three-plate pressure")
		if index>=22:_check(game.crate_id(Vector2i(1,4))==0 and game.crate_id(Vector2i(3,4))==1 and game.crate_id(Vector2i(5,4))==2,"orange/purple/pink identities all hold final plates without color matching")
		if index==24:_check(game.player==GATE,"actual hero walks through open energy cell")
	_check(used.size()==3 and game.moves==26 and game.swaps==7 and game.is_complete(),"all three crystals participate in 26-input, seven-swap victory")
	_check(game.undo() and game.snapshot()==history.pop_back() and not game.is_complete(),"victory undo restores complete preceding state")
	while not history.is_empty():_check(game.undo() and game.snapshot()==history.pop_back(),"every reverse action restores identities, counters, pressure, gate and life")
	_check(game.snapshot()==initial and game.history_size()==0,"full undo restores exact initial state")
	for symbol in solution["path"]:game.try_move(DIRS[symbol])
	_check(game.restart() and game.snapshot()==initial and game.history_size()==0,"victory restart restores initial actors, bushes and closed gate")
	print("NORTH 12 SOLUTION: %s; 26 actions, 7 swaps, 0 pushes/pulls" % solution["path"])

func _test_bush_and_gate() -> void:
	var game:=_game()
	_advance(game,10)
	_check(game.player==Vector2i(2,2),"legal prefix reaches middle-left area")
	_check(game.try_move(Vector2i.DOWN)==&"moved" and game.player==Vector2i(2,3),"approach first bush from its left")
	var before:=game.snapshot()
	_check(game.swap_target(Vector2i.RIGHT).get("cell")==Vector2i(3,3) and game.try_move(Vector2i.RIGHT)==&"bush_blocked" and game.snapshot()==before,"upper bush blocks sight, cannot move or exchange")
	game.restart()
	_advance(game,21)
	_check(game.player==Vector2i(4,4) and game.try_move(Vector2i.DOWN)==&"moved" and game.player==Vector2i(4,5),"legal prefix approaches lower full row")
	before=game.snapshot()
	_check(game.swap_target(Vector2i.LEFT).get("cell")==Vector2i(3,5) and game.try_move(Vector2i.LEFT)==&"bush_blocked" and game.snapshot()==before,"lower bush blocks sight and movement atomically")
	game.restart()
	_advance(game,9)
	_check(game.player==Vector2i(5,2),"legal prefix reaches upper-right approach")
	_check(game.try_move(Vector2i.RIGHT)==&"moved" and game.player==Vector2i(6,2),"adjacent empty floor remains walkable before closed gate")
	before=game.snapshot()
	_check(game.swap_target(Vector2i.UP).get("cell")==GATE and game.try_move(Vector2i.UP)==&"energy_blocked" and game.snapshot()==before,"closed gate stops movement and sight without partial action")

func _test_handoff_and_release() -> void:
	var game:=_game()
	_advance(game,22)
	var pressed:=game.snapshot()
	_check(game.player==Vector2i(5,4) and game.pressure_progress("yellow_01")==Vector2i(3,3),"actual setup uses hero as third occupant")
	_check(game.try_move(Vector2i.LEFT)==&"swapped" and game.pressure_progress("yellow_01")==Vector2i(3,3),"plate-to-plate automatic exchange preserves pressure")
	_check(game.undo() and game.snapshot()==pressed,"one undo restores pressure handoff")
	_check(game.try_move(Vector2i.DOWN)==&"moved" and game.barrier_is_active(GATE) and game.blocks_sight(GATE),"leaving third plate closes gate and sight")
	_check(game.undo() and game.snapshot()==pressed,"undo restores all-three-held open gate")
	_check(game.try_move(Vector2i.UP)==&"swapped" and game.player==Vector2i(5,2) and game.crate_id(Vector2i(5,4))==2 and game.alive and not game.barrier_is_active(GATE),"pink crystal replaces hero continuously and keeps gate open")

func _test_colors_and_switch() -> void:
	var original:=_game()
	var initial:=original.snapshot()
	var data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://levels/north_12.json"))
	data["crystal_colors"]=["purple","purple","purple"]
	var recolored:=State.new()
	_check(recolored.load_level(Level.from_dictionary(data)),"recolored fixture validates")
	for symbol in _solution()["path"]:_check(original.try_move(DIRS[symbol])==recolored.try_move(DIRS[symbol]) and original.snapshot()==recolored.snapshot(),"pink/orange are display only, no color-based pressure or exchange")
	_check(original.load_level(Level.from_file("res://levels/north_11.json")) and original.level.mechanism_color=="green" and original.level.void_cells.size()==12 and original.history_size()==0 and original.swaps==0,"switch to eleventh loads its independent green/void state")
	_check(original.load_level(Level.from_file("res://levels/north_12.json")) and original.snapshot()==initial and original.level.mechanism_color=="yellow" and original.level.void_cells.is_empty(),"return to twelfth restores yellow skin and separate initial state")

func _advance(game: State,count: int) -> void:
	var path: String=_solution()["path"]
	for index in count:game.try_move(DIRS[path[index]])

func _solution() -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string("res://levels/solutions/north_12.json"))

func _game() -> State:
	var level:=Level.from_file("res://levels/north_12.json")
	_check(level.error.is_empty(),"confirmed twelfth JSON validates: "+level.error)
	var game:=State.new()
	_check(game.load_level(level),"twelfth initializes")
	return game

func _check(condition: bool,message: String) -> void:
	checks+=1
	if not condition:
		failures+=1
		printerr("FAIL: ",message)
