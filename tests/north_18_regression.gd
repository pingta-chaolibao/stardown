extends SceneTree
const Level=preload("res://scripts/core/level_data.gd")
const State=preload("res://scripts/core/grid_state.gd")
const DIRS={"U":Vector2i.UP,"D":Vector2i.DOWN,"L":Vector2i.LEFT,"R":Vector2i.RIGHT}
const GATE=Vector2i(4,2)
var checks:=0
var failures:=0
func _init() -> void:
	_map_and_color();_route();_death_and_blockers();_restart_isolation()
	print("NORTH 18 RESULT: 4 cases, %d checks, %d failures" % [checks,failures]);quit(0 if failures==0 else 1)
func _map_and_color() -> void:
	var game:=_game();var rows=[".......","######.",".....#.","..##.#.","..#..#.","#.####.",".......","#.####."];var floors:=0
	for y in 8:
		for x in 7:
			var cell:=Vector2i(x,y);_check(game.level.is_floor(cell)==(rows[y][x]=="."),"all56 confirmed terrain cells")
			if game.level.is_floor(cell):floors+=1
	_check(floors==34 and game.hero_count()==3 and game.active_hero_id()=="blue","34floor,3heroes,initial blue")
	_check(game.hero_position(0)==Vector2i(0,2) and game.hero_position(1)==Vector2i(1,2) and game.hero_position(2)==Vector2i(2,2),"15red16green17blue; head numbers are not cell IDs")
	_check(game.crates().size()==1 and game.crate_id(Vector2i(0,0))==0 and game.level.crystal_colors==PackedStringArray(["purple_pink"]),"single purple-pink crystal1")
	_check(game.level.exit_color=="blue" and game.level.exit_cells==[Vector2i(4,3),Vector2i(3,4),Vector2i(4,4)],"26/32/33 ordinary blue disc goals")
	_check(game.level.is_floor(Vector2i(3,2)) and not game.level.is_floor(Vector2i(4,1)) and game.barrier_states().size()==1 and game.barrier_is_active(GATE),"18walkable12wall19one energy cell")
	_check(game.try_move(Vector2i.RIGHT)==&"moved" and game.player==Vector2i(3,2),"blue walks onto confirmed18 when no visible target")
	var before:=game.snapshot();_check(game.try_move(Vector2i.RIGHT)==&"energy_blocked" and game.snapshot()==before and game.blocks_sight(GATE),"closed energy blocks movement/sight unchanged")
	game.restart();var data:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://levels/north_18.json"));data["exit_color"]="green";var recolored:=State.new();_check(recolored.load_level(Level.from_dictionary(data)),"recolor fixture validates")
	for symbol in _solution()["path"]:
		var a:StringName=game.switch_hero() if symbol=="C" else game.try_move(DIRS[symbol])
		var b:StringName=recolored.switch_hero() if symbol=="C" else recolored.try_move(DIRS[symbol])
		_check(a==b and game.snapshot()==recolored.snapshot() and game.active_hero_id()==recolored.active_hero_id(),"blue goals change only appearance, no teleport/color assignment")
func _route() -> void:
	var game:=_game();var initial:=game.snapshot();var history:Array[Dictionary]=[];var actions:=0;var choices:=0
	for symbol in _solution()["path"]:
		var before:=game.snapshot();var selected:=game.active_hero_id()
		if symbol=="C":choices+=1;_check(game.switch_hero()==&"switched" and game.snapshot()==before,"free C creates no world/history action")
		else:
			actions+=1;history.append(before)
			_check(game.try_move(DIRS[symbol]) in [&"moved",&"pushed",&"pulled",&"swapped"] and game.active_hero_id()==selected,"legal actual action with stable selected identity")
			if actions==8:_check(game.hero_position(1)==Vector2i(1,7) and not game.barrier_is_active(GATE),"red pushes both other heroes,green holds plate and opens sight/movement")
			if actions==12:_check(game.barrier_is_active(GATE) and game.blocks_sight(GATE),"green releases plate,energy restores")
			if actions==28:_check(game.hero_position(2)==Vector2i(0,0) and game.crate_id(Vector2i(6,0))==0,"blue swaps distant top crystal by first visible target")
			if actions==52:_check(game.hero_position(0)==Vector2i(5,6) and game.hero_position(1)==Vector2i(3,6) and game.crate_id(Vector2i(4,6))==0,"red pushes mixed crystal/green chain,green does not activate passive pull")
			if actions==61:_check(game.hero_position(2)==Vector2i(1,7) and not game.barrier_is_active(GATE),"blue temporarily holds bottom plate")
			if actions==69:_check(game.hero_position(2)==Vector2i(1,2) and game.crate_id(Vector2i(1,7))==0 and not game.blocks_sight(GATE),"blue swaps crystal onto plate atomically, no intermediate energy return")
			if actions in [71,73,77]:_check(GATE in [game.hero_position(0),game.hero_position(1),game.hero_position(2)] and game.is_walkable(GATE),"selected/inactive heroes occupy passable marked energy")
			if actions==72:_check(game.occupied_exits()==1 and not game.is_complete(),"first ordinary blue goal does not teleport or win early")
			if actions==76:_check(game.occupied_exits()==2 and not game.is_complete(),"twoof3heroes at goals still incomplete")
		_check(game.moves==actions and game.history_size()==actions and game.alive and game.crates().size()==1 and game.last_mechanism_error.is_empty(),"count only actual directions,all heroes/crystal survive")
		_check(game.is_complete()==(actions==78),"three distinct hero goals required")
	_check(actions==78 and choices==61 and game.pushes==26 and game.pulls==8 and game.swaps==10,"78actions61freeC,26push8pull10swap")
	_check(game.hero_position(0)==Vector2i(4,3) and game.hero_position(1)==Vector2i(3,4) and game.hero_position(2)==Vector2i(4,4) and game.crate_id(Vector2i(1,7))==0,"final red pushes blue to last goal,crystal holdsplate")
	while not history.is_empty():_check(game.undo() and game.snapshot()==history.pop_back() and game.active_hero_id()=="red","undo all actual pushes/pulls/exchanges restores identities while keeping final red")
	_check(game.snapshot()==initial and not game.undo() and game.active_hero_id()=="red","78undos restore initial world not61C events")
	_check(game.restart() and game.snapshot()==initial and game.active_hero_id()=="blue","restart restores initial blue")
func _death_and_blockers() -> void:
	var game:=_game();_advance(game,8);var held:=game.snapshot()
	_check(game.try_move(Vector2i.DOWN)==&"crate_blocked" and game.snapshot()==held,"mixed hero push past bottom boundary is atomic")
	_choose(game,"blue");_play(game,"R");_choose(game,"red");_play(game,"UUURRR");_choose(game,"green")
	var before:=game.snapshot();_check(game.hero_position(0)==GATE and game.player==Vector2i(1,7),"legal side path:inactive red on energy,green holding plate")
	_check(game.try_move(Vector2i.UP)==&"died" and not game.hero_is_alive(0) and game.hero_is_alive(1) and game.hero_is_alive(2),"green leaves plate,energy kills inactive red")
	var dead:=game.snapshot();_check(game.switch_hero()==&"dead" and game.try_move(Vector2i.LEFT)==&"dead" and not game.restart() and not game.load_level(Level.from_file("res://levels/north_17.json")) and game.snapshot()==dead,"C/R/level/directions cannot bypass death")
	_check(game.undo() and game.snapshot()==before and game.active_hero_id()=="green" and game.hero_is_alive(0) and not game.blocks_sight(GATE),"oneundo revives red and restores all positions/crystal/pressure while retaining green")
func _restart_isolation() -> void:
	var game:=_game();var initial:=game.snapshot();game.switch_hero();_check(not game.undo() and game.snapshot()==initial and game.active_hero_id()=="red","no-history C is not undoable")
	for n in range(1,18):
		_check(game.load_level(Level.from_file("res://levels/north_%02d.json" % n)) and game.moves==0 and game.history_size()==0,"old1..17 independent history")
		_check(game.load_level(Level.from_file("res://levels/north_18.json")) and game.snapshot()==initial and game.active_hero_id()=="blue","18 reset after previouslevel")
	_play(game,_solution()["path"]);_check(game.restart() and game.snapshot()==initial and game.active_hero_id()=="blue","restart from victory restores all original positions")
func _play(game:State,path:String) -> void:
	for symbol in path:
		if symbol=="C":game.switch_hero()
		else:_check(game.try_move(DIRS[symbol]) in [&"moved",&"pushed",&"pulled",&"swapped"],"legal prefix/side path")
func _advance(game:State,count:int) -> void:
	for symbol in _solution()["path"]:
		if game.moves>=count:return
		_play(game,symbol)
func _choose(game:State,id:String) -> void:
	for _i in game.hero_count():
		if game.active_hero_id()==id:return
		_check(game.switch_hero()==&"switched","free C choose hero")
func _solution() -> Dictionary:return JSON.parse_string(FileAccess.get_file_as_string("res://levels/solutions/north_18.json"))
func _game() -> State:
	var game:=State.new();_check(game.load_level(Level.from_file("res://levels/north_18.json")),"confirmed18 loads");return game
func _check(ok:bool,message:String) -> void:
	checks+=1
	if not ok:failures+=1;push_error("FAIL: "+message)
