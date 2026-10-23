extends SceneTree
const Level=preload("res://scripts/core/level_data.gd")
const State=preload("res://scripts/core/grid_state.gd")
const DIRS={"U":Vector2i.UP,"D":Vector2i.DOWN,"L":Vector2i.LEFT,"R":Vector2i.RIGHT}
const GATES=[Vector2i(8,1),Vector2i(8,5)]
var checks:=0
var failures:=0

func _init() -> void:
	_map()
	_solution()
	_release_and_pull()
	_selection_and_isolation()
	print("NORTH 14 RESULT: 4 cases, %d checks, %d failures" % [checks,failures])
	quit(0 if failures==0 else 1)

func _map() -> void:
	var game:=_game()
	var rows:=["...###...#",".....###.#","####.#....","####....#.","...#.#....",".....###.#","...###...#"]
	_check(game.level.width==10 and game.level.height==7 and game.active_hero_id()=="red" and game.hero_count()==2,"confirmed 10x7 red/green start with red selected")
	for y in 7:
		for x in 10:_check(game.level.is_floor(Vector2i(x,y))==(rows[y][x]=="."),"all 70 terrain cells preserve confirmation")
	_check(not game.level.is_floor(Vector2i(5,0)) and game.level.is_floor(Vector2i(7,0)) and game.level.is_floor(Vector2i(8,0)) and game.level.is_floor(Vector2i(8,2)) and game.level.is_floor(Vector2i(9,4)),"latest marker6 correction is wall;8/9/29/50 remain floor")
	_check(game.hero_position(0)==Vector2i(1,1) and game.hero_position(1)==Vector2i(1,5) and game.heroes()[1]["kind"]=="green","exact red and green identities, no added blue or gray")
	_check(game.crates().size()==1 and game.crate_id(Vector2i(3,1))==0 and game.level.crystal_colors==PackedStringArray(["purple"]) and game.level.bushes.is_empty(),"single purple crystal and no bushes")
	_check(game.level.exit_cells==[Vector2i(6,0),Vector2i(6,6)] and game.level.objective=="all_heroes_on_exits","two distinct hero goals with no fixed assignment")
	_check(game.pressure_progress("yellow_01")==Vector2i(0,1),"single yellow plate initially empty")
	for gate in GATES:_check(game.barrier_is_active(gate) and game.blocks_sight(gate) and not game.is_walkable(gate),"both initial energy cells block sight and movement")
	for cell in [Vector2i(-1,1),Vector2i(10,3),Vector2i(6,-1),Vector2i(6,7)]:_check(not game.is_walkable(cell) and game.blocks_sight(cell),"outside rectangle blocked")

func _solution() -> void:
	var game:=_game()
	var initial:=game.snapshot()
	var solution:=_solution_data()
	var history: Array[Dictionary]=[]
	var actions:=0
	var selections:=0
	for symbol in solution["path"]:
		var before:=game.snapshot()
		var selected:=game.active_hero_id()
		var result: StringName
		if symbol=="C":
			selections+=1
			result=game.switch_hero()
			_check(result==&"switched" and game.snapshot()==before and game.active_hero_id()!=selected,"C changes only selection without world/history/action")
		else:
			history.append(before)
			actions+=1
			result=game.try_move(DIRS[symbol])
			_check(result in [&"moved",&"pushed",&"pulled"] and game.active_hero_id()==selected,"legal selected red/green action %d" % actions)
			if actions==15:_check(result==&"pushed" and game.hero_position(0)==Vector2i(5,3) and game.crate_id(Vector2i(6,3))==0 and game.hero_position(1)==Vector2i(7,3) and game.pulls==2,"red pushes mixed crystal+green line once; inactive green never adds a pull")
			if actions==24:_check(game.hero_position(1)==Vector2i(9,3) and game.pressure_is_active("yellow_01"),"green hero holds plate to open both gates")
			if actions==26:_check(game.hero_position(0)==GATES[0],"red legally walks through upper open gate")
			if actions==29:_check(game.hero_position(0)==Vector2i(6,0) and game.occupied_exits()==1 and not game.is_complete(),"first red goal leaves green able to act")
			if actions==30:_check(result==&"pulled" and game.hero_position(1)==Vector2i(9,4) and game.crate_id(Vector2i(9,3))==0 and game.pressure_is_active("yellow_01"),"green pulls nearest crystal onto plate while leaving, no intermediate gate restoration")
			if actions==32:_check(game.hero_position(1)==GATES[1],"green legally walks through lower open gate")
		_check(game.moves==actions and game.history_size()==actions and game.alive and game.last_mechanism_error.is_empty(),"only actual actions count and all actors stay alive")
		_check(game.is_complete()==(actions==35),"both heroes must reach different goals before victory")
		if actions>=24:
			for gate in GATES:_check(not game.barrier_is_active(gate) and not game.blocks_sight(gate) and game.is_walkable(gate),"both gates remain transparent/walkable under sustained pressure")
	_check(actions==35 and selections==15 and game.pushes==6 and game.pulls==4 and game.swaps==0 and game.hero_position(0)==Vector2i(6,0) and game.hero_position(1)==Vector2i(6,6),"independently found35 actual actions,15 free selections,6push/4pull dual victory")
	_check(solution["moves"]==35 and solution["input_events"]==50 and solution["selection_events"]==15,"solution separates control events and actual actions")
	while not history.is_empty():_check(game.undo() and game.snapshot()==history.pop_back() and game.active_hero_id()=="green","undo each actual action only while preserving selected green")
	_check(game.snapshot()==initial and not game.undo() and game.active_hero_id()=="green","35undos restore initial world, never the15 selections")
	_check(game.restart() and game.active_hero_id()=="red" and game.snapshot()==initial,"restart explicitly restores initial red selection")
	for symbol in solution["path"]:
		if symbol=="C":game.switch_hero()
		else:game.try_move(DIRS[symbol])
	_check(game.restart() and game.snapshot()==initial and game.history_size()==0 and game.active_hero_id()=="red","victory restart restores all actors, both closed gates and empty history")
	print("NORTH 14 SOLUTION: %s;35 actual actions,15 selection events,6 pushes,4 pulls" % solution["path"])

func _release_and_pull() -> void:
	var game:=_game()
	_advance(game,24)
	var held:=game.snapshot()
	_check(game.active_hero_id()=="green" and game.crate_id(Vector2i(8,2))==0,"legal prefix reaches green-only pressure before handoff")
	_check(game.try_move(Vector2i.DOWN)==&"moved" and not game.pressure_is_active("yellow_01"),"leaving plate before crystal handoff releases pressure")
	for gate in GATES:_check(game.barrier_is_active(gate) and game.blocks_sight(gate) and not game.is_walkable(gate),"one released plate simultaneously restores both movement/sight blockers")
	_check(game.undo() and game.snapshot()==held and game.active_hero_id()=="green","one undo restores both open gates and current green selection")
	game.restart()
	_advance(game,29)
	game.switch_hero()
	var before:=game.snapshot()
	_check(game.active_hero_id()=="green" and game.try_move(Vector2i.UP)==&"cannot_push" and game.snapshot()==before,"green facing adjacent crystal cannot push, no partial action")
	_check(game.try_move(Vector2i.DOWN)==&"pulled" and game.crate_id(Vector2i(9,3))==0 and game.pulls==4,"same green automatic single pull performs legal pressure handoff")
	for gate in GATES:_check(not game.barrier_is_active(gate) and not game.blocks_sight(gate),"crystal continuously keeps both gates open")

func _selection_and_isolation() -> void:
	var game:=_game()
	var initial:=game.snapshot()
	game.switch_hero();game.switch_hero();game.switch_hero()
	_check(game.moves==0 and game.history_size()==0 and not game.undo() and game.active_hero_id()=="green" and game.snapshot()==initial,"repeated free switches create no history and empty undo retains green")
	game.restart()
	game.try_move(Vector2i.RIGHT)
	game.switch_hero()
	_check(game.undo() and game.snapshot()==initial and game.active_hero_id()=="green","switch then undo rolls back red action and retains selected green")
	for n in range(1,14):
		_check(game.load_level(Level.from_file("res://levels/north_%02d.json" % n)) and game.moves==0 and game.history_size()==0,"load prior level without14 history")
		_check(game.load_level(Level.from_file("res://levels/north_14.json")) and game.snapshot()==initial and game.active_hero_id()=="red","prior level cannot leak state or selection into14")

func _advance(game: State,actions: int) -> void:
	for symbol in _solution_data()["path"]:
		if game.moves>=actions:return
		if symbol=="C":game.switch_hero()
		else:game.try_move(DIRS[symbol])

func _solution_data() -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string("res://levels/solutions/north_14.json"))

func _game() -> State:
	var level:=Level.from_file("res://levels/north_14.json")
	_check(level.error.is_empty(),"confirmed14 JSON validates: "+level.error)
	var game:=State.new()
	_check(game.load_level(level),"14 initializes")
	return game

func _check(condition: bool,message: String) -> void:
	checks+=1
	if not condition:
		failures+=1
		printerr("FAIL: ",message)
