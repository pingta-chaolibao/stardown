extends SceneTree
const Level = preload("res://scripts/core/level_data.gd")
const State = preload("res://scripts/core/grid_state.gd")
const Energy = preload("res://scripts/core/energy_rules.gd")
const DIRS = {"U":Vector2i.UP,"D":Vector2i.DOWN,"L":Vector2i.LEFT,"R":Vector2i.RIGHT}
const GATES = [Vector2i(1,3),Vector2i(9,3)]
const PLATES = [Vector2i(1,5),Vector2i(5,5),Vector2i(9,5)]
var checks := 0
var failures := 0

func _init() -> void:
	_map_and_color();_route_and_undo();_global_and();_death_and_blockers();_isolation()
	print("NORTH 19 RESULT: 5 cases, %d checks, %d failures" % [checks,failures])
	quit(0 if failures==0 else 1)

func _map_and_color() -> void:
	var game:=_game();var rows=["...#...#...","...#...#...","...#...#...","#.###.###.#","...#...#...","...........","...#...#..."];var floors:=0
	for y in 7:
		for x in 11:
			var cell:=Vector2i(x,y);_check(game.level.is_floor(cell)==(rows[y][x]=="."),"all77 confirmed terrain cells")
			if game.level.is_floor(cell):floors+=1
	_check(floors==59 and game.hero_count()==3 and game.active_hero_id()=="green","59floors,three heroes,initial green")
	_check(game.hero_position(0)==Vector2i(5,1) and game.hero_position(1)==Vector2i(4,0) and game.hero_position(2)==Vector2i(6,0),"17red5green7blue confirmed starts")
	_check(game.occupied_exits()==2 and not game.is_complete(),"green/blue start on goals but twoofthree never wins")
	_check(game.level.exit_cells==[Vector2i(4,0),Vector2i(6,0),Vector2i(9,1)] and game.level.exit_color=="orange","three ordinary orange goals, no color assignment")
	_check(game.crates().size()==1 and game.crate_id(Vector2i(1,1))==0 and game.level.crystal_colors==PackedStringArray(["purple"]),"single purple crystal13")
	_check(game.level.mechanism_color=="blue" and game.level.bushes.is_empty() and not game.level.is_floor(Vector2i(3,6)) and not game.level.is_floor(Vector2i(7,6)),"blue mechanisms,70/74 walls not bushes")
	_check(game.pressure_progress("blue_01")==Vector2i(0,3),"three blue plates initially empty")
	for gate in GATES:_check(game.barrier_is_active(gate) and not game.is_walkable(gate) and game.blocks_sight(gate),"both solid blue gates block movement/sight")
	var before:=game.snapshot();_check(game.try_move(Vector2i.UP)==&"wall" and game.snapshot()==before,"top boundary blocks selected green atomically")
	var data:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://levels/north_19.json"));data["exit_color"]="yellow";data["mechanism_color"]="green"
	var recolored:=State.new();_check(recolored.load_level(Level.from_dictionary(data)),"recolor validates")
	for symbol in _solution()["path"]:
		var a:StringName=game.switch_hero() if symbol=="C" else game.try_move(DIRS[symbol])
		var b:StringName=recolored.switch_hero() if symbol=="C" else recolored.try_move(DIRS[symbol])
		_check(a==b and game.snapshot()==recolored.snapshot() and game.active_hero_id()==recolored.active_hero_id(),"orange goals/blue mechanisms affect display only")

func _route_and_undo() -> void:
	var game:=_game();var initial:=game.snapshot();var history:Array[Dictionary]=[];var actions:=0;var choices:=0
	for symbol in _solution()["path"]:
		var before:=game.snapshot();var selected:=game.active_hero_id()
		if symbol=="C":choices+=1;_check(game.switch_hero()==&"switched" and game.snapshot()==before,"free selection creates no action/history")
		else:
			actions+=1;history.append(before)
			_check(game.try_move(DIRS[symbol]) in [&"moved",&"pushed",&"pulled",&"swapped"] and game.active_hero_id()==selected,"legal direction and stable selected identity")
			if actions==4:_check(game.hero_position(2)==Vector2i(5,2) and game.hero_position(0)==Vector2i(5,0),"blue first visible red exchange")
			if actions==8:_check(game.hero_position(0)==Vector2i(5,3) and game.hero_position(1)==Vector2i(5,4) and game.hero_position(2)==Vector2i(5,5),"red pushes green/blue chain,passive green never pulls")
			if actions==18:_check(game.pressure_progress("blue_01")==Vector2i(3,3),"three heroes simultaneously hold all plates")
			if actions==19:_check(game.crate_id(Vector2i(1,5))==0 and game.hero_position(2)==Vector2i(1,1),"blue swaps across open left gate,crystal replaces plate atomically")
			if actions==20:_check(game.barrier_is_active(GATES[0]) and game.barrier_is_active(GATES[1]),"one released plate restores both gates")
			if actions==30:_check(game.crate_id(Vector2i(5,5))==0,"red moves crystal to middle plate")
			if actions==34:_check(game.hero_position(0)==Vector2i(1,1) and game.hero_position(2)==Vector2i(1,5),"blue-red swap through open left gate keeps both pressure and IDs")
			if actions==36:_check(game.hero_position(0)==GATES[0] and not game.blocks_sight(GATES[0]),"red on passable marked left energy")
			if actions==40:_check(game.crate_id(Vector2i(1,5))==0 and game.hero_position(2)==Vector2i(5,5),"blue swaps middle crystal back to left plate")
			if actions==49:_check(game.hero_position(1)==GATES[1] and game.is_walkable(GATES[1]),"green walks through right open energy")
			if actions==62:_check(game.occupied_exits()==2 and not game.is_complete(),"two heroes at goals do not complete three-goal map")
		_check(game.moves==actions and game.history_size()==actions and game.alive and game.crates().size()==1 and game.last_mechanism_error.is_empty(),"actual counts,three living heroes,one crystal,atomic settlement")
		_check(game.is_complete()==(actions==63),"all three different goals required")
	_check(actions==63 and choices==34 and game.pushes==13 and game.swaps==5 and game.pulls==0,"63directions34freeC,13push5swap0pull")
	_check(game.hero_position(0)==Vector2i(4,0) and game.hero_position(1)==Vector2i(9,1) and game.hero_position(2)==Vector2i(6,0) and game.crate_id(Vector2i(1,5))==0,"final distinct goals without fixed color matching")
	while not history.is_empty():_check(game.undo() and game.snapshot()==history.pop_back() and game.active_hero_id()=="blue","undo actual action restores world,keeps current blue")
	_check(game.snapshot()==initial and not game.undo() and game.active_hero_id()=="blue","all63undos skip34C,initial world still not victory")
	_check(game.restart() and game.snapshot()==initial and game.active_hero_id()=="green","restart restores green start selection")

func _global_and() -> void:
	var game:=_game()
	for mask in 8:
		var positions:Array=[Vector2i(5,1),Vector2i(4,0),Vector2i(6,0)]
		for index in 3:
			if mask & (1<<index):positions[index]=PLATES[index]
		var result:=Energy.settle(game.level.energy_links,positions,{Vector2i(1,1):0},{})
		_check(result["error"].is_empty() and result["pressure"]["blue_01"]==(mask==7) and result["alive"],"all8three-plate occupancy combinations")
		for gate in GATES:_check(result["barriers"][gate]==(mask!=7),"global AND synchronizes both blue gates")

func _death_and_blockers() -> void:
	var game:=_game();_advance(game,8);_choose(game,"green");var blocked:=game.snapshot()
	_check(game.try_move(Vector2i.DOWN)==&"cannot_push" and game.snapshot()==blocked,"green cannot push adjacent blue hero")
	game.restart();_advance(game,36);_choose(game,"green");var before:=game.snapshot()
	_check(game.hero_position(0)==GATES[0] and game.player==Vector2i(9,5),"legal side path:inactive red on energy,green on right plate")
	_check(game.try_move(Vector2i.UP)==&"died" and not game.hero_is_alive(0) and game.hero_is_alive(1) and game.hero_is_alive(2),"release right plate restores both gates,kills inactive red")
	var dead:=game.snapshot();_check(game.switch_hero()==&"dead" and game.try_move(Vector2i.RIGHT)==&"dead" and not game.restart() and not game.load_level(Level.from_file("res://levels/north_18.json")) and game.snapshot()==dead,"C/R/directions/level cannot bypass any-hero death")
	_check(game.undo() and game.snapshot()==before and game.active_hero_id()=="green" and game.hero_is_alive(0),"oneundo restores red life,all occupancy/pressure,keeps green")
	for gate in GATES:_check(game.is_walkable(gate) and not game.blocks_sight(gate),"undo restores both open movement and sight")
	_choose(game,"red");_play(game,"D");_check(game.player==Vector2i(1,4),"red leaves energy legally")

func _isolation() -> void:
	var game:=_game();var initial:=game.snapshot();game.switch_hero()
	_check(game.active_hero_id()=="blue" and not game.undo() and game.snapshot()==initial,"no-history C not undoable")
	for n in range(1,19):
		_check(game.load_level(Level.from_file("res://levels/north_%02d.json" % n)) and game.moves==0 and game.history_size()==0,"old18 reset independent history")
		_check(game.load_level(Level.from_file("res://levels/north_19.json")) and game.snapshot()==initial and game.active_hero_id()=="green","19 restores two initial goal occupants without victory")
	_play(game,_solution()["path"]);_check(game.restart() and game.snapshot()==initial and game.active_hero_id()=="green","restart from victory restores all initial positions")

func _advance(game:State,count:int) -> void:
	for symbol in _solution()["path"]:
		if game.moves>=count:return
		_play(game,symbol)
func _play(game:State,path:String) -> void:
	for symbol in path:
		if symbol=="C":game.switch_hero()
		else:_check(game.try_move(DIRS[symbol]) in [&"moved",&"pushed",&"pulled",&"swapped"],"legal route/side-path prefix")
func _choose(game:State,id:String) -> void:
	for _i in game.hero_count():
		if game.active_hero_id()==id:return
		_check(game.switch_hero()==&"switched","free hero selection")
func _solution() -> Dictionary:return JSON.parse_string(FileAccess.get_file_as_string("res://levels/solutions/north_19.json"))
func _game() -> State:
	var game:=State.new();_check(game.load_level(Level.from_file("res://levels/north_19.json")),"confirmed19 loads");return game
func _check(ok:bool,message:String) -> void:
	checks+=1
	if not ok:failures+=1;push_error("FAIL: "+message)
