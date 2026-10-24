extends SceneTree
const Level=preload("res://scripts/core/level_data.gd")
const State=preload("res://scripts/core/grid_state.gd")
const DIRS={"U":Vector2i.UP,"D":Vector2i.DOWN,"L":Vector2i.LEFT,"R":Vector2i.RIGHT}
var checks:=0
var failures:=0
func _init() -> void:
	_map();_route();_isolation()
	print("NORTH 20 RESULT: 3 cases, %d checks, %d failures" % [checks,failures]);quit(0 if failures==0 else 1)
func _map() -> void:
	var game:=_game();var rows=["#.#.#",".....",".....",".....",".###."];var floors:=0
	for y in 5:
		for x in 5:
			var cell:=Vector2i(x,y);_check(game.level.is_floor(cell)==(rows[y][x]=="."),"all25confirmed terrain cells")
			if game.level.is_floor(cell):floors+=1
	_check(floors==19 and game.hero_count()==3 and game.active_hero_id()=="blue","19floors,3heroes,blue selected")
	_check(game.hero_position(0)==Vector2i(4,4) and game.hero_position(1)==Vector2i(0,4) and game.hero_position(2)==Vector2i(2,1),"25red21green8blue confirmed starts")
	_check(game.level.exit_cells==[Vector2i(1,2),Vector2i(2,2),Vector2i(3,2)] and game.occupied_exits()==0,"12/13/14goals requirethree heroes")
	_check(game.crate_id(Vector2i(1,0))==0 and game.crate_id(Vector2i(3,0))==1 and game.level.fence_edges.size()==2 and game.level.energy_links.is_empty(),"two crystals,two edge fences,no pressure or energy")
	for x in [0,4]:
		var a:=Vector2i(x,3);var b:=Vector2i(x,4)
		_check(game.level.has_fence(a,b) and game.level.has_fence(b,a) and game.is_walkable(a) and game.is_walkable(b) and not game.blocks_sight(a),"16↔21/20↔25 are symmetric edges not wall cells")
	_choose(game,"green");var before:=game.snapshot();_check(game.try_move(Vector2i.UP)==&"fence_blocked" and game.snapshot()==before,"green cannot leave21 bywalking acrossF1")
	_choose(game,"red");before=game.snapshot();_check(game.try_move(Vector2i.UP)==&"fence_blocked" and game.snapshot()==before,"red cannot leave25 bywalking acrossF2")
func _route() -> void:
	var game:=_game();var initial:=game.snapshot();var history:Array[Dictionary]=[];var actions:=0;var selections:=0
	for symbol in _solution()["path"]:
		var before:=game.snapshot();var selected:=game.active_hero_id()
		if symbol=="C":selections+=1;_check(game.switch_hero()==&"switched" and game.snapshot()==before,"C selection free,not undoable")
		else:
			actions+=1;history.append(before)
			_check(game.try_move(DIRS[symbol]) in [&"moved",&"pushed",&"pulled",&"swapped"] and game.active_hero_id()==selected,"legal direction and stable identity")
			if actions==3:_check(game.player==Vector2i(0,4) and game.hero_position(1)==Vector2i(0,1),"blue sees throughF1 and frees green")
			if actions==4:
				_choose(game,"blue");var blocked:=game.snapshot();_check(game.try_move(Vector2i.UP)==&"fence_blocked" and game.snapshot()==blocked,"blue without visible object cannot walk acrossF1")
				_choose(game,"green")
			if actions==5:_check(game.crate_id(Vector2i(1,1))==0 and game.hero_position(1)==Vector2i(1,2),"green single-pulls first crystal")
			if actions==14:_check(game.crate_id(Vector2i(0,4))==0 and game.player==Vector2i(0,1),"blue exchanges crystal acrossF1,not a physical push")
			if actions==19:_check(game.crate_id(Vector2i(3,1))==1 and game.hero_position(1)==Vector2i(3,2),"green single-pulls second crystal")
			if actions==23:_check(game.player==Vector2i(4,4) and game.hero_position(0)==Vector2i(4,1),"blue sees throughF2 and frees red")
			if actions==28:_check(game.crate_id(Vector2i(4,4))==1 and game.player==Vector2i(4,2),"blue exchanges second crystal acrossF2")
			if actions==29:_check(game.occupied_exits()==2 and not game.is_complete(),"two goals insufficient")
		_check(game.moves==actions and game.history_size()==actions and game.alive and game.crates().size()==2 and game.level.fence_edges.size()==2,"actual count,life,crystal IDs and immutable fence topology")
		_check(game.is_complete()==(actions==30),"three distinct goals only win at30")
	_check(actions==30 and selections==13 and game.pushes==2 and game.pulls==2 and game.swaps==11,"30actions13C2push2pull11swap")
	_check(game.hero_position(0)==Vector2i(3,2) and game.hero_position(1)==Vector2i(1,2) and game.hero_position(2)==Vector2i(2,2),"red pushes passive blue into final distinct goal without auto exchange")
	while not history.is_empty():_check(game.undo() and game.snapshot()==history.pop_back() and game.active_hero_id()=="red","Undo restores actual move/exchange/pull/push while keeping red")
	_check(game.snapshot()==initial and not game.undo() and game.restart() and game.active_hero_id()=="blue","undo skipsC;restart restores initialblue")
func _isolation() -> void:
	var game:=_game();var initial:=game.snapshot()
	for n in range(1,20):
		_check(game.load_level(Level.from_file("res://levels/north_%02d.json" % n)) and game.history_size()==0 and game.level.fence_edges.is_empty(),"fences/history do not leak to19oldmaps")
		_check(game.load_level(Level.from_file("res://levels/north_20.json")) and game.snapshot()==initial and game.active_hero_id()=="blue" and game.level.fence_edges.size()==2,"20reload restoresstatic edges and initialworld")
func _choose(game:State,id:String) -> void:
	for _i in game.hero_count():
		if game.active_hero_id()==id:return
		_check(game.switch_hero()==&"switched","free selection helper")
func _solution() -> Dictionary:return JSON.parse_string(FileAccess.get_file_as_string("res://levels/solutions/north_20.json"))
func _game() -> State:
	var game:=State.new();_check(game.load_level(Level.from_file("res://levels/north_20.json")),"confirmed20 validates/loads");return game
func _check(ok:bool,message:String) -> void:
	checks+=1
	if not ok:failures+=1;push_error("FAIL: "+message)
