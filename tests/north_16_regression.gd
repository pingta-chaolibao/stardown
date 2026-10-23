extends SceneTree
const Level=preload("res://scripts/core/level_data.gd")
const State=preload("res://scripts/core/grid_state.gd")
const DIRS={"U":Vector2i.UP,"D":Vector2i.DOWN,"L":Vector2i.LEFT,"R":Vector2i.RIGHT}
const GATE=Vector2i(7,1)
const MIXED_PREFIX="ULLLLRCURRRRCLLCLLLLLLLL"
var checks:=0
var failures:=0

func _init() -> void:
	_map_and_color()
	_solution()
	_push_and_blockers()
	_death_and_isolation()
	print("NORTH 16 RESULT: 4 cases, %d checks, %d failures" % [checks,failures])
	quit(0 if failures==0 else 1)

func _map_and_color() -> void:
	var game:=_game()
	var rows:=["...##.##..#","...........","...##.##..#"]
	var floors:=0
	for y in 3:
		for x in 11:
			var cell:=Vector2i(x,y)
			_check(game.level.is_floor(cell)==(rows[y][x]=="."),"all33 confirmed terrain cells")
			if game.level.is_floor(cell):floors+=1
	_check(game.level.width==11 and game.level.height==3 and floors==23 and not game.level.is_floor(Vector2i(10,2)),"complete3 rows,23 floor and33blocked")
	_check(game.hero_count()==2 and game.hero_position(0)==Vector2i(5,1) and game.hero_position(1)==Vector2i(5,2) and game.active_hero_id()=="blue","confirmed red/blue positions and blue initially selected")
	_check(game.crates().size()==1 and game.crate_id(Vector2i(10,1))==0 and game.level.crystal_colors==PackedStringArray(["purple_pink"]),"single pink-purple crystal at right endpoint")
	_check(game.level.exit_color=="purple" and game.level.exit_cells==[Vector2i(9,0),Vector2i(9,2)] and game.level.objective=="all_heroes_on_exits","purple discs are the two ordinary hero goals")
	_check(game.pressure_progress("yellow_01")==Vector2i(0,1) and game.barrier_is_active(GATE) and game.blocks_sight(GATE) and not game.is_walkable(GATE),"yellow plate initially empty, energy opaque and impassable")
	for cell in [Vector2i(-1,1),Vector2i(11,1),Vector2i(5,-1),Vector2i(5,3)]:_check(not game.is_walkable(cell) and game.blocks_sight(cell),"outside blocks movement and sight")
	var data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://levels/north_16.json"))
	data["exit_color"]="green"
	var recolored:=State.new()
	_check(recolored.load_level(Level.from_dictionary(data)),"goal recolor fixture validates")
	for symbol in _solution_data()["path"]:
		var a: StringName=game.switch_hero() if symbol=="C" else game.try_move(DIRS[symbol])
		var b: StringName=recolored.switch_hero() if symbol=="C" else recolored.try_move(DIRS[symbol])
		_check(a==b and game.snapshot()==recolored.snapshot() and game.active_hero_id()==recolored.active_hero_id(),"purple color does not change any position/action/pressure/win or add teleport")
	data["exit_color"]="portal"
	_check(not Level.from_dictionary(data).error.is_empty(),"unknown goal mode is rejected, no portal mechanism")

func _solution() -> void:
	var game:=_game()
	var initial:=game.snapshot()
	var history: Array[Dictionary]=[]
	var actions:=0
	var selections:=0
	for symbol in _solution_data()["path"]:
		var before:=game.snapshot()
		var selected:=game.active_hero_id()
		if symbol=="C":
			selections+=1
			_check(game.switch_hero()==&"switched" and game.snapshot()==before and game.active_hero_id()!=selected,"C changes only selection, no count/history/occupancy")
		else:
			actions+=1;history.append(before)
			var result:=game.try_move(DIRS[symbol])
			_check(result in [&"moved",&"swapped"] and game.active_hero_id()==selected,"legal actual action %d and stable selection" % actions)
			if actions==1:_check(game.hero_position(0)==Vector2i(5,2) and game.hero_position(1)==Vector2i(5,1) and game.swaps==1,"blue first swaps red, not a global auto-exchange")
			if actions==5:_check(game.player==Vector2i(1,1) and game.pressure_is_active("yellow_01") and not game.blocks_sight(GATE),"blue holds yellow plate to open movement/sight")
			if actions==6:_check(game.player==Vector2i(10,1) and game.crate_id(Vector2i(1,1))==0 and game.pressure_is_active("yellow_01"),"blue swaps pink-purple crystal onto plate continuously")
			if actions==9:_check(game.hero_position(0)==GATE and game.is_walkable(GATE),"red passes open energy while crystal holds plate")
			if actions==12:_check(game.hero_position(0)==Vector2i(10,1) and game.hero_position(1)==Vector2i(9,1) and game.active_hero_id()=="blue" and game.swaps==3,"near red is chosen before distant crystal and selection stays blue")
			if actions==13:_check(game.hero_position(1)==Vector2i(9,0) and game.occupied_exits()==1 and not game.is_complete(),"blue walks onto upper purple disc, no teleport or premature victory")
		_check(game.moves==actions and game.history_size()==actions and game.alive and game.pushes==0 and game.pulls==0 and game.last_mechanism_error.is_empty(),"only actual actions count and legal walkthrough uses no pushing/pulling")
		_check(game.is_complete()==(actions==15),"both distinct hero goals required for victory")
		if actions>=5:_check(not game.barrier_is_active(GATE) and not game.blocks_sight(GATE),"plate handoff preserves open gate to final victory")
	_check(actions==15 and selections==3 and game.swaps==3 and game.hero_position(0)==Vector2i(9,2) and game.hero_position(1)==Vector2i(9,0),"15actual actions+3free selections,3swaps and dual victory")
	while not history.is_empty():_check(game.undo() and game.snapshot()==history.pop_back() and game.active_hero_id()=="red","undo actual world actions only while retaining final red selection")
	_check(game.snapshot()==initial and not game.undo() and game.active_hero_id()=="red","15undos restore initial world, not3C changes")
	_check(game.restart() and game.active_hero_id()=="blue" and game.snapshot()==initial,"restart explicitly restores blue")
	_play(game,_solution_data()["path"])
	_check(game.restart() and game.snapshot()==initial and game.history_size()==0 and game.active_hero_id()=="blue","victory restart restores original actors, plate and gate")
	print("NORTH 16 SOLUTION: %s;15actions,3free selections,3swaps,0pushes" % _solution_data()["path"])

func _push_and_blockers() -> void:
	var game:=_game()
	game.switch_hero()
	var before:=game.snapshot()
	_check(game.try_move(Vector2i.DOWN)==&"crate_blocked" and game.snapshot()==before and game.history_size()==0,"red cannot push blue past bottom boundary")
	_check(game.try_move(Vector2i.RIGHT)==&"moved","red approaches initially closed gate")
	before=game.snapshot()
	_check(game.try_move(Vector2i.RIGHT)==&"energy_blocked" and game.snapshot()==before,"closed energy blocks red movement atomically")
	game.restart();game.try_move(Vector2i.UP);game.switch_hero()
	before=game.snapshot()
	_check(game.try_move(Vector2i.UP)==&"pushed" and game.hero_position(0)==Vector2i(5,1) and game.hero_position(1)==Vector2i(5,0) and game.pushes==1 and game.swaps==1,"red pushes inactive blue once; blue does not activate another exchange")
	var pushed:=game.snapshot()
	_check(game.try_move(Vector2i.UP)==&"crate_blocked" and game.snapshot()==pushed,"upper boundary blocks entire hero push")
	_check(game.undo() and game.snapshot()==before and game.active_hero_id()=="red","hero push undo restores both positions and retains red")
	game.restart();_play(game,MIXED_PREFIX)
	_check(game.moves==21 and game.pushes==8 and game.swaps==4 and game.hero_position(0)==Vector2i(2,1) and game.hero_position(1)==Vector2i(0,1) and game.crate_id(Vector2i(1,1))==0 and game.pressure_is_active("yellow_01"),"legal21-action side path ends with red pushing crystal+blue mixed line; plate is handed to crystal")
	before=game.snapshot()
	_check(game.try_move(Vector2i.LEFT)==&"crate_blocked" and game.snapshot()==before,"whole mixed line blocked at left edge without partial movement")
	_check(game.undo() and game.hero_position(0)==Vector2i(3,1) and game.hero_position(1)==Vector2i(1,1) and game.crate_id(Vector2i(2,1))==0 and game.active_hero_id()=="red" and game.pressure_is_active("yellow_01"),"one undo restores full mixed push and original blue pressure")
	game.restart();_advance(game,5)
	var held:=game.snapshot()
	_check(game.try_move(Vector2i.UP)==&"moved" and game.barrier_is_active(GATE) and game.blocks_sight(GATE),"blue leaves plate and energy restores normally")
	_check(game.undo() and game.snapshot()==held,"undo restores blue pressure and transparent gate")

func _death_and_isolation() -> void:
	var game:=_game()
	_advance(game,9)
	_play(game,"CLLCLLLC")
	var held:=game.snapshot()
	_check(game.active_hero_id()=="blue" and game.hero_position(0)==GATE and game.player==Vector2i(1,1) and game.crate_id(Vector2i(6,1))==0,"legal side path leaves inactive red inside open gate")
	_check(game.try_move(Vector2i.DOWN)==&"died" and not game.alive and not game.hero_is_alive(0) and game.hero_is_alive(1),"blue leaves plate, restored energy kills inactive red")
	var dead:=game.snapshot()
	_check(game.switch_hero()==&"dead" and game.try_move(Vector2i.LEFT)==&"dead" and not game.restart() and not game.load_level(Level.from_file("res://levels/north_15.json")) and game.snapshot()==dead,"C/directions/restart/load cannot bypass any hero death")
	_check(game.undo() and game.snapshot()==held and game.active_hero_id()=="blue" and game.hero_is_alive(0) and not game.blocks_sight(GATE),"undo revives red, restores all occupancy/pressure and retains blue selection")
	game.restart();var initial:=game.snapshot();game.switch_hero()
	_check(not game.undo() and game.snapshot()==initial and game.active_hero_id()=="red","empty undo never undoes free initial C")
	for n in range(1,16):
		_check(game.load_level(Level.from_file("res://levels/north_%02d.json" % n)) and game.moves==0 and game.history_size()==0,"prior level independent from16")
		_check(game.load_level(Level.from_file("res://levels/north_16.json")) and game.snapshot()==initial and game.active_hero_id()=="blue","prior data/selection/history cannot leak into16")

func _play(game: State,path: String) -> void:
	for symbol in path:
		if symbol=="C":game.switch_hero()
		else:game.try_move(DIRS[symbol])

func _advance(game: State,actions: int) -> void:
	for symbol in _solution_data()["path"]:
		if game.moves>=actions:return
		_play(game,symbol)

func _solution_data() -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string("res://levels/solutions/north_16.json"))

func _game() -> State:
	var level:=Level.from_file("res://levels/north_16.json")
	_check(level.error.is_empty(),"confirmed16 JSON validates: "+level.error)
	var game:=State.new()
	_check(game.load_level(level),"16 initializes")
	return game

func _check(condition: bool,message: String) -> void:
	checks+=1
	if not condition:
		failures+=1
		printerr("FAIL: ",message)
