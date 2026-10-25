extends SceneTree
const Level=preload("res://scripts/core/level_data.gd")
const State=preload("res://scripts/core/grid_state.gd")
const Energy=preload("res://scripts/core/energy_rules.gd")
const DIRS={"U":Vector2i.UP,"D":Vector2i.DOWN,"L":Vector2i.LEFT,"R":Vector2i.RIGHT}
const GATE=Vector2i(7,1)
const EMPTY=Vector2i(1,5)
const CRYSTALS=[Vector2i(1,1),Vector2i(3,1),Vector2i(5,1),Vector2i(1,3),Vector2i(3,3),Vector2i(5,3),Vector2i(3,5),Vector2i(5,5),Vector2i(10,1)]
var checks:=0
var failures:=0

func _init() -> void:
	var cases:=[_test_map,_test_solution,_test_gate_and_void,_test_all_nine_plates,_test_cosmetic_data,_test_switch]
	for test: Callable in cases:
		var before:=failures
		test.call()
		print("%s %s" % ["PASS" if before==failures else "FAIL",test.get_method()])
	print("NORTH 11 RESULT: %d cases, %d checks, %d failures" % [cases.size(),checks,failures])
	quit(0 if failures==0 else 1)

func _test_map() -> void:
	var game:=_game()
	_check(game.level.width==11 and game.level.height==7 and game.player==Vector2i(5,0) and game.level.hero_kind=="blue","confirmed eleventh rectangle and blue hero")
	for y in 7:
		for x in 11:
			var floor_cell:=x<=6 or (x==7 and y==1) or (x>=8 and y<=2)
			var void_cell:=x>=8 and y>=3
			_check(game.level.is_floor(Vector2i(x,y))==floor_cell and game.level.is_void(Vector2i(x,y))==void_cell,"all 77 floor/wall/void cells match confirmation")
	for index in CRYSTALS.size():_check(game.crate_id(CRYSTALS[index])==index,"all nine crystal identities at confirmed coordinates")
	_check(game.crates().size()==9 and game.level.crystal_colors[8]=="orange","right platform holds the ninth orange crystal")
	_check(game.level.exit_cell==Vector2i(9,1) and game.level.objective=="player_on_exit" and game.level.mechanism_color=="green","goal and green presentation, no color objective")
	_check(game.level.void_cells.size()==12 and game.level.bushes.is_empty(),"twelve void cells and no bushes")
	var plates: Array=game.level.energy_links[0]["plates"]
	for y in [1,3,5]:
		for x in [1,3,5]:_check(Vector2i(x,y) in plates,"all nine odd-coordinate green plates")
	_check(plates.size()==9 and game.pressure_progress("green_01")==Vector2i(8,9) and not game.pressure_cell_is_active("green_01",EMPTY),"only (1,5) starts unpressed")
	_check(game.barrier_is_active(GATE) and game.blocks_sight(GATE) and not game.is_walkable(GATE),"closed green gate blocks movement and sight")

func _test_solution() -> void:
	var game:=_game()
	var initial:=game.snapshot()
	var history: Array[Dictionary]=[]
	var solution:=_solution()
	for index in solution["path"].length():
		var before:=game.snapshot()
		history.append(before)
		var direction: Vector2i=DIRS[solution["path"][index]]
		var target:=game.swap_target(direction)
		var result:=game.try_move(direction)
		if target["result"]==&"target":
			_check(result==&"swapped" and game.player==target["cell"] and game.crate_id(before["player"])==target["id"],"ordinary direction swaps exact first visible target")
		else:_check(result==&"moved" and game.player==before["player"]+direction,"empty input ray walks only one cell")
		_check(game.moves==index+1 and game.alive and game.pushes==0 and game.pulls==0 and game.last_mechanism_error.is_empty(),"route remains legal and alive without push/pull")
		_check(game.is_complete()==(index==18),"only final player arrival wins")
		if index>=10:_check(game.pressure_progress("green_01")==Vector2i(9,9) and not game.barrier_is_active(GATE) and not game.blocks_sight(GATE) and game.is_walkable(GATE),"all nine plates continuously open movement and sight")
		if index==10:_check(game.player==EMPTY,"hero fills the only empty plate")
		if index==14:_check(game.player==Vector2i(5,1) and game.swap_target(Vector2i.RIGHT).get("id")==8,"open gate reveals the orange crystal as first target")
		if index==15:_check(game.player==Vector2i(10,1) and game.crate_id(Vector2i(5,1))==8,"orange exchange reaches right platform and preserves pressure")
	_check(game.is_complete() and game.moves==19 and game.swaps==5 and game.player==Vector2i(9,1),"nineteen direction inputs and five automatic swaps win")
	_check(game.undo() and game.snapshot()==history.pop_back() and not game.is_complete(),"victory undo restores complete preceding state")
	while not history.is_empty():_check(game.undo() and game.snapshot()==history.pop_back(),"every undo restores all positions, identities, counters and mechanisms")
	_check(game.snapshot()==initial and game.history_size()==0,"full undo returns original eight pressed plates")
	for symbol in solution["path"]:game.try_move(DIRS[symbol])
	_check(game.restart() and game.snapshot()==initial and game.history_size()==0,"victory restart restores nine crystals and closed gate")
	print("NORTH 11 SOLUTION: %s; 19 actions, 5 swaps, 0 pushes/pulls" % solution["path"])

func _test_gate_and_void() -> void:
	var game:=_game()
	game.try_move(Vector2i.DOWN)
	_check(game.try_move(Vector2i.RIGHT)==&"moved" and game.player==Vector2i(6,1) and game.swap_target(Vector2i.RIGHT).get("cell")==GATE,"closed gate hides orange target while adjacent floor allows a step")
	var before:=game.snapshot()
	_check(game.try_move(Vector2i.RIGHT)==&"energy_blocked" and game.snapshot()==before,"closed gate blocks direction input atomically")
	game.restart()
	_advance(game,11)
	before=game.snapshot()
	_check(game.try_move(Vector2i.DOWN)==&"moved" and game.pressure_progress("green_01")==Vector2i(8,9) and game.barrier_is_active(GATE) and game.blocks_sight(GATE),"leaving any plate restores green gate and sight blocking")
	_check(game.undo() and game.snapshot()==before,"one undo reopens all-nine-held gate")
	_check(game.try_move(Vector2i.RIGHT)==&"swapped" and game.pressure_progress("green_01")==Vector2i(9,9) and game.alive,"hero/crystal plate handoff has no intermediate closure")
	game.restart()
	_advance(game,16)
	_check(game.try_move(Vector2i.DOWN)==&"moved" and game.player==Vector2i(10,2),"right platform includes complete bottom row")
	before=game.snapshot()
	_check(game.level.is_void(Vector2i(10,3)) and game.blocks_sight(Vector2i(10,3)) and game.try_move(Vector2i.DOWN)==&"wall" and game.snapshot()==before,"visually omitted lower-right void remains impassable and opaque")

func _test_all_nine_plates() -> void:
	var game:=_game()
	var plates: Array=game.level.energy_links[0]["plates"]
	for mask in 512:
		var crystals: Dictionary={}
		for index in plates.size():
			if mask & (1<<index):crystals[plates[index]]=index
		var result:=Energy.settle(game.level.energy_links,Vector2i(0,0),crystals,{})
		_check(result["error"].is_empty() and result["barriers"][GATE]==(mask!=511) and result["pressure"]["green_01"]==(mask==511),"all 512 nine-plate occupancy combinations obey global AND")

func _test_cosmetic_data() -> void:
	var data:=_data()
	var original:=_game()
	data["mechanism_color"]="yellow"
	data.erase("void_cells")
	for index in data["crystal_colors"].size():data["crystal_colors"][index]="purple"
	var recolored:=State.new()
	_check(recolored.load_level(Level.from_dictionary(data)) and recolored.snapshot()==original.snapshot(),"presentation-only recoloring and void annotation do not affect initial state")
	for symbol in _solution()["path"]:
		_check(original.try_move(DIRS[symbol])==recolored.try_move(DIRS[symbol]) and original.snapshot()==recolored.snapshot(),"crystal/plate colors never change swap or pressure behavior")
	var old:=Level.from_file("res://levels/north_10.json")
	_check(old.mechanism_color=="yellow" and old.void_cells.is_empty(),"existing maps retain yellow skin and full blocked terrain display")
	for invalid in ["green",[[8,3],[8,3]],[[0,0]],[[11,3]],[[-1,3]],[[8.5,3]]]:
		data=_data()
		data["void_cells"]=invalid
		_check(not Level.from_dictionary(data).error.is_empty(),"invalid void annotation is rejected")
	data=_data()
	data["mechanism_color"]="red"
	_check(Level.from_dictionary(data).error.is_empty(),"red mechanism skin explicitly supported without a color-based rule")
	data["mechanism_color"]="unsupported"
	_check(not Level.from_dictionary(data).error.is_empty(),"unknown mechanism presentation is rejected")
	data=_data()
	data["crystal_colors"][8]="red"
	_check(not Level.from_dictionary(data).error.is_empty(),"unknown crystal presentation is rejected; orange is explicitly supported")

func _test_switch() -> void:
	var game:=_game()
	var initial:=game.snapshot()
	_advance(game,16)
	_check(game.load_level(Level.from_file("res://levels/north_10.json")) and game.level.mechanism_color=="yellow" and game.level.void_cells.is_empty() and game.swaps==0 and game.history_size()==0,"green skin, void annotation and history do not leak into tenth")
	_check(game.load_level(Level.from_file("res://levels/north_11.json")) and game.snapshot()==initial,"eleventh reload restores independent initial state")

func _advance(game: State,count: int) -> void:
	var path: String=_solution()["path"]
	for index in count:game.try_move(DIRS[path[index]])

func _solution() -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string("res://levels/solutions/north_11.json"))

func _data() -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string("res://levels/north_11.json"))

func _game() -> State:
	var level:=Level.from_file("res://levels/north_11.json")
	_check(level.error.is_empty(),"confirmed eleventh JSON validates: "+level.error)
	var game:=State.new()
	_check(game.load_level(level),"eleventh initializes")
	return game

func _check(condition: bool,message: String) -> void:
	checks+=1
	if not condition:
		failures+=1
		printerr("FAIL: ",message)
