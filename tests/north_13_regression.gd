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
	var actions:=0
	var selections:=0
	for index in solution["path"].length():
		var symbol: String=solution["path"][index]
		var before:=game.snapshot()
		var selected:=game.active_hero_id()
		if symbol=="C":selections+=1
		else:
			history.append(before)
			actions+=1
		var result:=game.switch_hero() if symbol=="C" else game.try_move(DIRS[symbol])
		_check(result in [&"moved",&"swapped",&"switched"] and game.moves==actions and game.history_size()==actions and game.alive and game.last_mechanism_error.is_empty(),"legal Godot input event %d, counted actions %d" % [index+1,actions])
		_check((game.active_hero_id()!=selected)==(symbol=="C"),"only explicit C changes selected identity")
		_check(game.is_complete()==(index==26),"dual victory only at final input")
		if symbol=="C":_check(game.snapshot()==before,"C leaves entire world snapshot, counters and undo history unchanged")
		if index in [8,9,10]:_check(game.pressure_progress("yellow_01")==Vector2i(2,2) and not game.barrier_is_active(GATE) and not game.blocks_sight(GATE) and game.is_walkable(GATE),"both heroes keep the open gate, including during uncounted C")
		if index==10:_check(game.hero_position(0)==Vector2i(5,5) and game.hero_position(1)==Vector2i(5,1) and game.swaps==1 and game.active_hero_id()=="blue" and game.moves==9,"counted action9 exchanges heroes across open gate with stable selection")
		if index==11:_check(game.barrier_is_active(GATE) and game.blocks_sight(GATE) and game.alive,"leaving either plate restores gate with both heroes safely outside")
		if index==18:_check(game.hero_position(1)==Vector2i(0,2) and game.occupied_exits()==1 and not game.is_complete() and game.moves==17,"counted action17 reaches first exit without ending game")
	_check(game.hero_position(0)==Vector2i(0,5) and game.hero_position(1)==Vector2i(0,2) and game.moves==24 and selections==3 and game.swaps==2 and game.pushes==0 and game.pulls==0,"validated 24 actual actions and3 uncounted selection events, not optimality claim")
	_check(solution["moves"]==24 and solution["directions"]==24 and solution["input_events"]==27 and solution["selection_events"]==3,"solution separates actual actions from input and selection event totals")
	_check(game.crate_id(Vector2i(0,0))==0 and game.crate_id(Vector2i(0,4))==1,"only upper crystal moves legally")
	while not history.is_empty():_check(game.undo() and game.snapshot()==history.pop_back() and game.active_hero_id()=="red","each undo restores one actual action while preserving final user-selected red")
	_check(game.snapshot()==initial and game.history_size()==0 and game.active_hero_id()=="red","24 undos restore initial world but do not undo user selection")
	_check(not game.undo() and game.active_hero_id()=="red","no remaining history cannot revert C")
	_check(game.restart() and game.active_hero_id()=="blue" and game.snapshot()==initial,"explicit restart restores initial blue before replay")
	for symbol in solution["path"]:
		if symbol=="C":game.switch_hero()
		else:game.try_move(DIRS[symbol])
	_check(game.restart() and game.snapshot()==initial and game.active_hero_id()=="blue" and game.history_size()==0,"victory restart restores blue selection and both actors")
	print("NORTH 13 SOLUTION: %s; 24 counted actions + 3 uncounted C, 2 swaps" % solution["path"])

func _boundaries_and_isolation() -> void:
	var game:=_game()
	var initial:=game.snapshot()
	_check(game.try_move(Vector2i.LEFT)==&"wall" and game.snapshot()==initial and game.history_size()==0,"confirmed wall left of blue blocks without history")
	_check(game.try_move(Vector2i.UP)==&"wall" and game.snapshot()==initial,"central full wall row blocks initial blue")
	game.switch_hero()
	_check(game.try_move(Vector2i.RIGHT)==&"wall" and game.moves==0 and game.history_size()==0,"red wall and preceding C do not count or write history")
	_check(not game.undo() and game.snapshot()==initial and game.active_hero_id()=="red","blocked movement and C never create undoable selection")
	for number in range(1,13):
		game.switch_hero()
		_check(game.load_level(Level.from_file("res://levels/north_%02d.json" % number)) and game.hero_count()==1 and game.history_size()==0 and game.moves==0,"multi history and selection cannot leak into old level %d" % number)
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
