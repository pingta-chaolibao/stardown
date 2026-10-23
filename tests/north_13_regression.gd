extends SceneTree
const Level=preload("res://scripts/core/level_data.gd")
const State=preload("res://scripts/core/grid_state.gd")
const DIRS={"U":Vector2i.UP,"D":Vector2i.DOWN,"L":Vector2i.LEFT,"R":Vector2i.RIGHT}
const GATE=Vector2i(5,3)
var checks:=0
var failures:=0

func _init() -> void:
	_map()
	_solution()
	_boundaries_and_isolation()
	print("NORTH 13 RESULT: 3 cases, %d checks, %d failures" % [checks,failures])
	quit(0 if failures==0 else 1)

func _map() -> void:
	var game:=_game()
	var rows:=["...#...",".#.....",".#.#...","#####.#",".#.#...",".#.....","...#..."]
	_check(game.level.width==7 and game.level.height==7 and game.hero_count()==2 and game.active_hero_id()=="blue","confirmed rectangle and initially selected blue")
	for y in 7:
		for x in 7:_check(game.level.is_floor(Vector2i(x,y))==(rows[y][x]=="."),"all 49 terrain cells")
	_check(game.hero_position(0)==Vector2i(2,2) and game.hero_position(1)==Vector2i(2,4) and game.active_kind()=="blue","both stable hero identities at confirmed starts")
	_check(game.crates().size()==2 and game.crate_id(Vector2i(0,1))==0 and game.crate_id(Vector2i(0,4))==1 and game.level.crystal_colors==PackedStringArray(["blue_purple","purple_pink"]),"both crystals and display colors")
	_check(game.level.exit_cells==[Vector2i(0,2),Vector2i(0,5)] and game.level.exit_color=="red" and game.level.objective=="all_heroes_on_exits","both red circular goals with hero objective")
	_check(game.level.energy_links[0]["plates"]==[Vector2i(5,1),Vector2i(5,5)] and game.pressure_progress("yellow_01")==Vector2i(0,2) and game.barrier_is_active(GATE) and game.blocks_sight(GATE),"two global plates and initially solid, opaque gate")

func _solution() -> void:
	var game:=_game()
	var initial:=game.snapshot()
	var solution: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://levels/solutions/north_13.json"))
	var history: Array[Dictionary]=[]
	for index in solution["path"].length():
		var symbol: String=solution["path"][index]
		history.append(game.snapshot())
		var selected:=game.active_hero_id()
		var result:=game.switch_hero() if symbol=="C" else game.try_move(DIRS[symbol])
		_check(result in [&"moved",&"swapped",&"switched"] and game.moves==index+1 and game.alive and game.last_mechanism_error.is_empty(),"legal Godot route operation %d" % (index+1))
		_check((game.active_hero_id()!=selected)==(symbol=="C"),"only explicit C changes selected identity")
		_check(game.is_complete()==(index==26),"dual victory only at final operation")
		if symbol=="C":
			_check(game.snapshot()["hero_positions"]==history[-1]["hero_positions"] and game.snapshot()["crates"]==history[-1]["crates"] and game.barrier_states()==history[-1]["barriers"],"C leaves positions, crystals and energy untouched")
		if index in [8,9,10]:_check(game.pressure_progress("yellow_01")==Vector2i(2,2) and not game.barrier_is_active(GATE) and not game.blocks_sight(GATE) and game.is_walkable(GATE),"inactive hero plus selected hero hold both plates")
		if index==10:_check(game.hero_position(0)==Vector2i(5,5) and game.hero_position(1)==Vector2i(5,1) and game.swaps==1 and game.active_hero_id()=="blue","blue exchanges red across open gate once with stable selection")
		if index==11:_check(game.barrier_is_active(GATE) and game.blocks_sight(GATE) and game.alive,"leaving either plate restores gate with both heroes safely outside")
		if index==18:_check(game.hero_position(1)==Vector2i(0,2) and game.occupied_exits()==1 and not game.is_complete(),"blue reaches first exit without ending game")
	_check(game.hero_position(0)==Vector2i(0,5) and game.hero_position(1)==Vector2i(0,2) and game.moves==27 and game.switches==3 and game.swaps==2 and game.pushes==0 and game.pulls==0,"constructed 27-operation victory, not an optimality or all-crystals claim")
	_check(game.crate_id(Vector2i(0,0))==0 and game.crate_id(Vector2i(0,4))==1,"only upper crystal is used; lower crystal remains unchanged legally")
	while not history.is_empty():_check(game.undo() and game.snapshot()==history.pop_back(),"each undo restores all heroes, selection, life, objects and mechanism state")
	_check(game.snapshot()==initial and game.history_size()==0,"entire route undo returns exact initial state")
	for symbol in solution["path"]:
		if symbol=="C":game.switch_hero()
		else:game.try_move(DIRS[symbol])
	_check(game.restart() and game.snapshot()==initial and game.history_size()==0,"victory restart returns initial blue selection and both actors")
	print("NORTH 13 SOLUTION: %s; 24 directions + 3 C, 2 swaps" % solution["path"])

func _boundaries_and_isolation() -> void:
	var game:=_game()
	var initial:=game.snapshot()
	_check(game.try_move(Vector2i.LEFT)==&"wall" and game.snapshot()==initial and game.history_size()==0,"confirmed wall left of blue blocks without history")
	_check(game.try_move(Vector2i.UP)==&"wall" and game.snapshot()==initial,"central full wall row blocks initial blue")
	game.switch_hero()
	_check(game.try_move(Vector2i.RIGHT)==&"wall" and game.moves==1 and game.switches==1,"red wall does not undo or count extra switch")
	_check(game.undo() and game.snapshot()==initial,"wall does not contaminate undoable selection")
	for number in range(1,13):
		game.switch_hero()
		_check(game.load_level(Level.from_file("res://levels/north_%02d.json" % number)) and game.hero_count()==1 and game.switches==0 and game.history_size()==0 and game.moves==0,"multi history and selection cannot leak into old level %d" % number)
		_check(game.load_level(Level.from_file("res://levels/north_13.json")) and game.snapshot()==initial,"old level %d cannot leak into thirteenth" % number)

func _game() -> State:
	var level:=Level.from_file("res://levels/north_13.json")
	_check(level.error.is_empty(),"confirmed thirteenth JSON validates: "+level.error)
	var game:=State.new()
	_check(game.load_level(level),"thirteenth initializes")
	return game

func _check(condition: bool,message: String) -> void:
	checks+=1
	if not condition:
		failures+=1
		printerr("FAIL: ",message)
