extends SceneTree
const Level=preload("res://scripts/core/level_data.gd")
const State=preload("res://scripts/core/grid_state.gd")
const DIRS={"U":Vector2i.UP,"D":Vector2i.DOWN,"L":Vector2i.LEFT,"R":Vector2i.RIGHT}
const GATE=Vector2i(2,3)
var checks:=0
var failures:=0

func _init() -> void:
	_map()
	_solution()
	_blockers_release_and_death()
	_selection_and_isolation()
	print("NORTH 15 RESULT: 4 cases, %d checks, %d failures" % [checks,failures])
	quit(0 if failures==0 else 1)

func _map() -> void:
	var game:=_game()
	var rows:=["####.....##","######.####","..#........",".........#.","..#........","#####..####","######..###"]
	_check(game.level.width==11 and game.level.height==7 and game.hero_count()==2 and game.active_hero_id()=="blue","confirmed11x7 with blue initially selected")
	var floors:=0
	for y in 7:
		for x in 11:
			var cell:=Vector2i(x,y)
			_check(game.level.is_floor(cell)==(rows[y][x]=="."),"all77 confirmed terrain cells")
			if game.level.is_floor(cell):floors+=1
	_check(floors==40 and not game.level.is_floor(Vector2i(2,2)) and not game.level.is_floor(Vector2i(2,4)),"40floor cells; latest25 wall and47 wall preserved")
	for cell in [Vector2i(4,0),Vector2i(8,0),Vector2i(6,1),Vector2i(5,5),Vector2i(6,5),Vector2i(6,6),Vector2i(7,6)]:_check(game.level.is_floor(cell),"confirmed upper and lower narrow corridor floor")
	_check(game.hero_position(0)==Vector2i(4,0) and game.hero_position(1)==Vector2i(3,3) and game.heroes()[1]["kind"]=="green","exact blue/green identities and starts")
	_check(game.crates().size()==2 and game.crate_id(Vector2i(8,0))==0 and game.crate_id(Vector2i(7,6))==1 and game.level.crystal_colors==PackedStringArray(["pink","blue_purple"]),"pink and blue-purple crystal identities")
	_check(game.level.exit_cells==[Vector2i(0,2),Vector2i(0,4)] and game.level.objective=="all_heroes_on_exits" and game.level.bushes.is_empty(),"two distinct unassigned hero goals and no bush/new mechanism")
	_check(game.level.energy_links[0]["plates"]==[Vector2i(4,3),Vector2i(10,3)] and game.pressure_progress("yellow_01")==Vector2i(0,2),"both yellow plates initially empty")
	_check(game.barrier_is_active(GATE) and game.blocks_sight(GATE) and not game.is_walkable(GATE),"initial energy blocks sight and movement")
	for cell in [Vector2i(-1,3),Vector2i(11,3),Vector2i(4,-1),Vector2i(7,7)]:_check(not game.is_walkable(cell) and game.blocks_sight(cell),"outside rectangle blocks sight/movement")

func _solution() -> void:
	var game:=_game()
	var initial:=game.snapshot()
	var data:=_solution_data()
	var history: Array[Dictionary]=[]
	var actions:=0
	var selections:=0
	var hero_exchanges:=0
	var crystal_exchanges: Dictionary={}
	for symbol in data["path"]:
		var before:=game.snapshot()
		var selected:=game.active_hero_id()
		if symbol=="C":
			selections+=1
			_check(game.switch_hero()==&"switched" and game.active_hero_id()!=selected and game.snapshot()==before,"C changes only selection without counted history")
		else:
			history.append(before)
			actions+=1
			var target:=game.swap_target(DIRS[symbol]) if selected=="blue" else {}
			var result:=game.try_move(DIRS[symbol])
			_check(result in [&"moved",&"pulled",&"swapped"] and game.active_hero_id()==selected,"legal blue/green actual action %d" % actions)
			if result==&"swapped":
				if target["kind"]==&"hero":hero_exchanges+=1
				else:crystal_exchanges[target["id"]]=true
			if actions==7:_check(game.hero_position(0)==Vector2i(6,0) and game.hero_position(1)==Vector2i(4,0) and game.swaps==1 and game.pulls==0,"blue chooses nearer green before farther pink and passive green does not pull")
			if actions==12:_check(game.player==Vector2i(8,0) and game.crate_id(Vector2i(6,0))==0 and game.swaps==3,"blue exchanges pink crystal into top corridor")
			if actions==13:_check(game.hero_position(1)==Vector2i(6,2) and game.crate_id(Vector2i(6,1))==0 and game.pulls==1,"green auto-pulls pink down single corridor")
			if actions==45:_check(game.hero_position(1)==Vector2i(4,3) and game.crate_id(Vector2i(10,3))==0 and game.crate_id(Vector2i(5,3))==1 and game.pressure_is_active("yellow_01"),"green plus pink hold both plates and open gate")
			if actions in [52,58]:_check(game.hero_position(0)==GATE and game.is_walkable(GATE),"blue legally walks through open energy")
			if actions==55:_check(game.crate_id(Vector2i(4,3))==1 and game.crate_id(Vector2i(10,3))==0 and game.pressure_is_active("yellow_01"),"green single pull hands near plate to blue-purple crystal atomically")
			if actions==56:_check(game.hero_position(0)==Vector2i(3,3) and game.hero_position(1)==Vector2i(0,3) and game.active_hero_id()=="blue" and game.swaps==7 and game.pulls==11,"blue exchanges green across transparent gate without passive pull or selection theft")
			if actions==57:_check(game.hero_position(1)==Vector2i(0,2) and game.occupied_exits()==1 and not game.is_complete(),"green first goal leaves blue controllable")
		_check(game.moves==actions and game.history_size()==actions and game.alive and game.pushes==0 and game.last_mechanism_error.is_empty(),"only real actions count; no pushing, deaths or unresolved interactions")
		_check(game.is_complete()==(actions==61),"both hero goals needed for final victory")
		if actions>=45:_check(not game.barrier_is_active(GATE) and not game.blocks_sight(GATE),"sustained all-plate pressure leaves energy transparent")
	_check(actions==61 and selections==20 and game.pulls==11 and game.swaps==7 and hero_exchanges==3 and crystal_exchanges.size()==2,"validated61 actions+20free selections,11pull/7swap using both crystals and hero exchanges")
	_check(game.hero_position(0)==Vector2i(0,4) and game.hero_position(1)==Vector2i(0,2) and data["input_events"]==81,"distinct hero goals without fixed assignment and81 input events")
	while not history.is_empty():_check(game.undo() and game.snapshot()==history.pop_back() and game.active_hero_id()=="blue","each undo restores one actual action and retains final blue selection")
	_check(game.snapshot()==initial and not game.undo(),"61undos restore world, never20 selection changes")
	for symbol in data["path"]:
		if symbol=="C":game.switch_hero()
		else:game.try_move(DIRS[symbol])
	_check(game.restart() and game.snapshot()==initial and game.active_hero_id()=="blue" and game.history_size()==0,"victory restart restores both colored crystals, initial blue and closed gate")
	print("NORTH 15 SOLUTION: %s;61 actions,20free selections,11pulls,7swaps" % data["path"])

func _blockers_release_and_death() -> void:
	var game:=_game()
	game.switch_hero()
	var initial:=game.snapshot()
	_check(game.try_move(Vector2i.LEFT)==&"energy_blocked" and game.snapshot()==initial,"initial green cannot pass closed gate")
	_check(game.try_move(Vector2i.UP)==&"moved" and game.player==Vector2i(3,2),"legal approach to corrected25")
	var before:=game.snapshot()
	_check(game.try_move(Vector2i.LEFT)==&"wall" and game.snapshot()==before,"25 wall blocks actual motion atomically")
	game.restart();_advance(game,54);game.switch_hero()
	var held:=game.snapshot()
	_check(game.active_hero_id()=="green" and game.try_move(Vector2i.DOWN)==&"moved" and not game.pressure_is_active("yellow_01") and game.barrier_is_active(GATE),"leaving near plate restores gate while both heroes safe")
	game.switch_hero()
	_check(game.swap_target(Vector2i.RIGHT)["result"]==&"swap_blocked" and game.try_move(Vector2i.RIGHT)==&"moved" and game.player==Vector2i(1,3),"closed gate hides ray target; blue walks just one free cell")
	before=game.snapshot()
	_check(game.try_move(Vector2i.RIGHT)==&"energy_blocked" and game.snapshot()==before,"next blue move is blocked by restored energy")
	_check(game.undo() and game.undo() and game.snapshot()==held and game.active_hero_id()=="blue" and not game.blocks_sight(GATE),"undo skips switches, restores both actual actions and pressure, keeps blue")
	game.restart();_advance(game,52);game.switch_hero()
	var alive:=game.snapshot()
	_check(game.active_hero_id()=="green" and game.hero_position(0)==GATE,"legal prefix places inactive blue inside open energy")
	_check(game.try_move(Vector2i.DOWN)==&"died" and not game.alive and not game.hero_is_alive(0) and game.hero_is_alive(1),"green releases plate and restores energy onto inactive blue, causing death")
	var dead:=game.snapshot()
	_check(game.switch_hero()==&"dead" and game.try_move(Vector2i.LEFT)==&"dead" and not game.restart() and not game.load_level(Level.from_file("res://levels/north_14.json")) and game.snapshot()==dead and game.active_hero_id()=="green","any hero death locks movement,C,restart and level changes")
	_check(game.undo() and game.snapshot()==alive and game.hero_is_alive(0) and game.active_hero_id()=="green" and not game.barrier_is_active(GATE),"one undo revives blue and restores pressure while retaining selected green")

func _selection_and_isolation() -> void:
	var game:=_game()
	var initial:=game.snapshot()
	game.switch_hero()
	_check(game.moves==0 and game.history_size()==0 and not game.undo() and game.active_hero_id()=="green" and game.snapshot()==initial,"free initial C then empty undo retains green")
	game.try_move(Vector2i.UP);game.switch_hero()
	_check(game.undo() and game.snapshot()==initial and game.active_hero_id()=="blue","undo green real movement after C while retaining blue")
	for n in range(1,15):
		_check(game.load_level(Level.from_file("res://levels/north_%02d.json" % n)) and game.moves==0 and game.history_size()==0,"prior level loads without15 history")
		_check(game.load_level(Level.from_file("res://levels/north_15.json")) and game.snapshot()==initial and game.active_hero_id()=="blue","prior state cannot leak into blue/green15")

func _advance(game: State,actions: int) -> void:
	for symbol in _solution_data()["path"]:
		if game.moves>=actions:return
		if symbol=="C":game.switch_hero()
		else:game.try_move(DIRS[symbol])

func _solution_data() -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string("res://levels/solutions/north_15.json"))

func _game() -> State:
	var level:=Level.from_file("res://levels/north_15.json")
	_check(level.error.is_empty(),"confirmed15 JSON validates: "+level.error)
	var game:=State.new()
	_check(game.load_level(level),"15 initializes")
	return game

func _check(condition: bool,message: String) -> void:
	checks+=1
	if not condition:
		failures+=1
		printerr("FAIL: ",message)
