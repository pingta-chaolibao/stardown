extends SceneTree
## User-confirmed 42-cell green-hero map; static bushes and global three-plate AND.
const Level=preload("res://scripts/core/level_data.gd")
const State=preload("res://scripts/core/grid_state.gd")
const DIRS:={"U":Vector2i.UP,"D":Vector2i.DOWN,"L":Vector2i.LEFT,"R":Vector2i.RIGHT}
const CRYSTALS:=[Vector2i(2,1),Vector2i(1,2),Vector2i(2,2)]
const BUSHES:=[Vector2i(1,3),Vector2i(5,3),Vector2i(3,5)]
const PLATES:=[Vector2i(1,4),Vector2i(3,4),Vector2i(5,4)]
const GATE:=Vector2i(6,1)
var checks:=0
var failures:=0

func _init() -> void:
	var cases:=[_test_map,_test_solution,_test_bush_and_cannot_push,_test_pressure_release,_test_switch]
	for test: Callable in cases:
		var before:=failures
		test.call()
		print("%s %s" % ["PASS" if before==failures else "FAIL",test.get_method()])
	print("NORTH 08 RESULT: %d cases, %d checks, %d failures" % [cases.size(),checks,failures])
	quit(0 if failures==0 else 1)

func _test_map() -> void:
	var game:=_game()
	_check(game.level.width==7 and game.level.height==6 and game.level.hero_kind=="green" and game.player==Vector2i(1,1),"confirmed green hero and 7x6 map")
	for y in 6:
		for x in 7:
			_check(game.level.is_floor(Vector2i(x,y))==(Vector2i(x,y) not in [Vector2i(5,0),Vector2i(5,1)]),"all 42 confirmed terrain cells")
	_check(game.crates().size()==3 and game.level.crystal_colors==PackedStringArray(["purple","purple","purple"]),"exactly three purple crystals")
	for index in 3:
		_check(game.crate_id(CRYSTALS[index])==index,"initial crystal coordinate and identity")
	_check(game.level.bushes.size()==3,"exactly three separate bushes")
	for cell in BUSHES:
		var bush=game.level.bush_at(cell)
		_check(bush!=null and not bush.MOVABLE and not bush.EXCHANGEABLE and game.level.is_floor(cell) and not game.is_walkable(cell) and game.blocks_sight(cell),"confirmed bush is static, nonexchangeable and blocks movement/sight")
	_check(game.level.energy_links.size()==1 and game.level.energy_links[0]["plates"]==PLATES and game.pressure_progress("yellow_01")==Vector2i(0,3),"three correct plates start empty")
	_check(game.barrier_states().size()==1 and game.barrier_is_active(GATE) and not game.is_walkable(GATE) and game.blocks_sight(GATE),"single gate initially blocks movement and sight")
	_check(game.level.exit_cell==Vector2i(6,0) and game.level.exit_color=="green","green destination is a separate cell above energy")
	for cell in [Vector2i(-1,1),Vector2i(7,1),Vector2i(1,-1),Vector2i(1,6)]:
		_check(not game.is_walkable(cell) and game.blocks_sight(cell),"external boundary blocked")

func _test_solution() -> void:
	var game:=_game()
	var initial:=game.snapshot()
	var solution:=_solution()
	var history: Array[Dictionary]=[]
	var seen_counts:={0:true}
	var moved:={}
	for index in solution["path"].length():
		var before:=game.snapshot()
		history.append(before)
		_check(game.try_move(DIRS[solution["path"][index]]) in [&"moved",&"pulled"],"legal eighth step %d" % (index+1))
		_check(game.alive and game.moves==index+1 and game.pushes==0 and game.last_mechanism_error.is_empty(),"walkthrough stays living, defined and pull-only")
		_check(game.is_complete()==(index==55),"only final hero arrival wins")
		var count:=game.pressure_progress("yellow_01")
		seen_counts[count.x]=true
		_check(game.barrier_is_active(GATE)==(count.x<3) and game.is_walkable(GATE)==(count.x==3) and game.blocks_sight(GATE)==(count.x<3),"all three plates alone control movement and sight")
		for cell: Vector2i in before["crates"]:
			if game.crate_id(cell)!=before["crates"][cell]:moved[before["crates"][cell]]=true
		if index>=51:
			for plate in PLATES:_check(game.crate_id(plate)>=0,"all crystals keep their final plates occupied")
		if index==54:_check(game.player==GATE,"actual hero crosses opened energy cell")
	_check(seen_counts.size()==4 and moved.size()==3 and game.moves==56 and game.pulls==17 and game.pushes==0 and game.is_complete(),"all crystals participate; 0/1/2/3 plates seen; 56 moves / 17 pulls wins")
	_check(game.undo() and game.snapshot()==history.pop_back() and not game.is_complete(),"victory undo restores exact whole state")
	while not history.is_empty():_check(game.undo() and game.snapshot()==history.pop_back(),"each action reverses all actor/mechanism fields")
	_check(game.snapshot()==initial and game.history_size()==0,"full undo returns to initial state")
	for symbol in solution["path"]:game.try_move(DIRS[symbol])
	_check(game.restart() and game.snapshot()==initial and game.history_size()==0,"victory restart restores three crystals, bushes and closed gate")
	print("NORTH 08 SOLUTION: %s; 56 moves, 17 pulls, 0 pushes" % solution["path"])

func _test_bush_and_cannot_push() -> void:
	var game:=_game()
	var initial:=game.snapshot()
	_check(game.try_move(Vector2i.RIGHT)==&"cannot_push" and game.try_move(Vector2i.DOWN)==&"cannot_push" and game.snapshot()==initial and game.history_size()==0,"green cannot push either initially adjacent crystal")
	for setup in [[7,Vector2i(2,3),Vector2i.LEFT],[9,Vector2i(2,5),Vector2i.RIGHT],[53,Vector2i(6,3),Vector2i.LEFT]]:
		game=_game()
		_prefix(game,setup[0])
		var before:=game.snapshot()
		var depth:=game.history_size()
		_check(game.player==setup[1] and game.try_move(setup[2])==&"bush_blocked" and game.snapshot()==before and game.history_size()==depth,"real route exposes each immutable bush and failed input stays atomic")

func _test_pressure_release() -> void:
	var game:=_game()
	_prefix(game,51)
	var held:=game.snapshot()
	_check(game.player==Vector2i(5,4) and game.pressure_progress("yellow_01")==Vector2i(3,3) and not game.barrier_is_active(GATE),"hero plus two crystals hold all plates")
	_check(game.try_move(Vector2i.DOWN)==&"moved" and game.pressure_progress("yellow_01")==Vector2i(2,3) and game.barrier_is_active(GATE) and game.blocks_sight(GATE),"leaving any real plate restores energy movement/sight blocking")
	_check(game.undo() and game.snapshot()==held,"one undo restores exact hero-held pressure")
	_check(game.try_move(Vector2i.RIGHT)==&"pulled" and game.crate_id(Vector2i(5,4))>=0 and not game.barrier_is_active(GATE) and game.alive,"automatic single pull hands pressure to third crystal without intermediate closure")
	_check(game.undo() and game.snapshot()==held,"handoff undo preserves crystal identity and all mechanism state")

func _test_switch() -> void:
	var game:=_game()
	var initial:=game.snapshot()
	game.try_move(Vector2i.UP)
	_check(game.load_level(Level.from_file("res://levels/north_07.json")) and game.level.bushes.is_empty() and game.barrier_states().size()==2 and game.history_size()==0 and game.pulls==0,"eighth bushes/pressure/history cannot leak into seventh")
	_check(game.load_level(Level.from_file("res://levels/north_08.json")) and game.snapshot()==initial and game.history_size()==0,"returning to eighth restores independent initial state")

func _prefix(game: State,count: int) -> void:
	var path: String=_solution()["path"]
	for index in count:game.try_move(DIRS[path[index]])

func _game() -> State:
	var definition:=Level.from_file("res://levels/north_08.json")
	_check(definition.error.is_empty(),"eighth data validates: "+definition.error)
	var game:=State.new()
	_check(game.load_level(definition),"eighth initializes")
	return game

func _solution() -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string("res://levels/solutions/north_08.json"))

func _check(condition: bool,message: String) -> void:
	checks+=1
	if not condition:
		failures+=1
		printerr("FAIL: ",message)
