extends SceneTree
const Level=preload("res://scripts/core/level_data.gd")
const State=preload("res://scripts/core/grid_state.gd")
const DIRS={"U":Vector2i.UP,"D":Vector2i.DOWN,"L":Vector2i.LEFT,"R":Vector2i.RIGHT}
var checks:=0
var failures:=0
func _init() -> void:
	_map()
	_route()
	_death_and_undo()
	_previous_and_boundaries()
	print("NORTH 17 RESULT: 4 cases, %d checks, %d failures" % [checks,failures])
	quit(0 if failures==0 else 1)
func _map() -> void:
	var game:=_game();var rows=[".........",".#######.",".#..#..#.",".#.....#.",".#..#..#."];var floors:=0
	for y in 5:
		for x in 9:
			var cell:=Vector2i(x,y)
			_check(game.level.is_floor(cell)==(rows[y][x]=="."),"all45 confirmed terrain cells")
			if game.level.is_floor(cell):floors+=1
	_check(floors==30 and game.hero_count()==3 and game.active_hero_id()=="blue","30floor,3heroes,blue initially selected")
	_check(game.hero_position(0)==Vector2i(0,4) and game.hero_position(1)==Vector2i(2,4) and game.hero_position(2)==Vector2i(8,4),"37green,39blue,45red")
	for i in 4:_check(game.crate_id([Vector2i(0,0),Vector2i(8,0),Vector2i(8,3),Vector2i(6,4)][i])==i,"four initial crystal IDs")
	_check(game.level.exit_cells==[Vector2i(3,0),Vector2i(4,0),Vector2i(2,2)] and game.level.objective=="all_heroes_on_exits","three different hero goals, no color assignment")
	_check(game.level.is_floor(Vector2i(4,3)) and game.blocks_sight(Vector2i(4,2)) and game.blocks_sight(Vector2i(4,4)) and game.blocks_sight(Vector2i(1,4)),"32floor,23/41andhedge38 remain opaque blocked terrain")
	_check(game.try_move(Vector2i.LEFT)==&"wall" and game.history_size()==0,"initial39blue does not exchange through38wall")
	_check(game.barrier_is_active(Vector2i(0,2)) and game.barrier_is_active(Vector2i(8,2)),"both yellow barriers initially active")
func _route() -> void:
	var game:=_game();var initial:=game.snapshot();var history:Array[Dictionary]=[];var actions:=0;var choices:=0
	for symbol in _solution()["path"]:
		var before:=game.snapshot();var selected:=game.active_hero_id()
		if symbol=="C":
			choices+=1
			_check(game.switch_hero()==&"switched" and game.snapshot()==before,"C free selection changes no occupancy/life/history/pressure")
		else:
			actions+=1;history.append(before)
			_check(game.try_move(DIRS[symbol]) in [&"moved",&"pushed",&"pulled",&"swapped"] and game.active_hero_id()==selected,"legal action%d with stable hero identity" % actions)
			if actions==14:_check(game.pressure_progress("yellow_all")==Vector2i(2,2) and not game.blocks_sight(Vector2i(0,2)) and not game.blocks_sight(Vector2i(8,2)),"blue and inner crystal open both movement/sight barriers")
			if actions==20:_check(game.crate_id(Vector2i(0,2))==0 and game.crate_id(Vector2i(8,2))==2 and game.crates().size()==4,"both outer crystals survive while energy absent")
			if actions in [21,53]:
				var after:=game.snapshot();var remain:=2 if actions==21 else 1
				_check(game.crates().size()==remain and game.barrier_is_active(Vector2i(0,2)) and game.barrier_is_active(Vector2i(8,2)),"energy reappearance destroys required crystal IDs atomically ataction%d" % actions)
				_choose(game,"green")
				_check(game.undo() and game.snapshot()==before and game.active_hero_id()=="green","undo destruction restores all crystal IDs/hero/pressure while preserving latest green selection")
				_choose(game,selected)
				_check(game.try_move(DIRS[symbol])==&"moved" and game.snapshot()==after,"repeated confirmed destruction has identical atomic outcome")
			if actions==22 or actions==54:_check(game.pressure_progress("yellow_all")==Vector2i(2,2) and not game.barrier_is_active(Vector2i(0,2)),"blue reopens both after clearing outer crystal obstruction")
		_check(game.moves==actions and game.history_size()==actions and game.alive and game.last_mechanism_error.is_empty(),"only real actions count, all heroes remain alive")
		_check(game.is_complete()==(actions==66),"all three different goals required, never early victory")
	_check(actions==66 and choices==15 and game.pushes==2 and game.pulls==11 and game.swaps==3 and game.crates().size()==1,"66actions15freeC,2push11pull3swap,3crystals destroyed")
	_check(game.hero_position(0)==Vector2i(3,0) and game.hero_position(1)==Vector2i(2,2) and game.hero_position(2)==Vector2i(4,0) and game.crate_id(Vector2i(5,3))==3,"three unique final goals and surviving inner crystal identity")
	_check(game.switch_hero()==&"complete" and game.active_hero_id()=="blue","victory locks selection until undo")
	# Victory locks C, so undo once then change selection to exercise full-history restoration.
	_check(game.undo() and game.snapshot()==history.pop_back(),"victory undo restores last actual move")
	_choose(game,"red")
	while not history.is_empty():_check(game.undo() and game.snapshot()==history.pop_back() and game.active_hero_id()=="red","reverse all actual actions restores destroyed identities and retains current choice")
	_check(game.snapshot()==initial and not game.undo() and game.active_hero_id()=="red","all66undos restore initial world without undoing selection")
	_check(game.restart() and game.snapshot()==initial and game.active_hero_id()=="blue","restart resets three heroes,4crystals and initial blue")
func _death_and_undo() -> void:
	var game:=_game();_advance(game,15)
	_choose(game,"green");_play(game,"UU");_choose(game,"blue")
	var before:=game.snapshot()
	_check(game.hero_position(0)==Vector2i(0,2) and game.crate_id(Vector2i(8,2))==2,"legal side path:green on open left energy,crystal on right energy")
	_check(game.try_move(Vector2i.UP)==&"died" and not game.hero_is_alive(0) and game.hero_is_alive(1) and game.hero_is_alive(2) and game.crate_id(Vector2i(8,2))==-1,"same restoration kills inactive green and destroys right crystal")
	var dead:=game.snapshot()
	_check(game.switch_hero()==&"dead" and game.try_move(Vector2i.RIGHT)==&"dead" and not game.restart() and not game.load_level(Level.from_file("res://levels/north_16.json")) and game.snapshot()==dead,"cannot bypass any hero death withC/R/load/directions")
	_check(game.undo() and game.snapshot()==before and game.active_hero_id()=="blue" and game.hero_is_alive(0) and game.crate_id(Vector2i(8,2))==2,"one undo revives inactive green and restores destroyed crystal and all pressure")
func _previous_and_boundaries() -> void:
	var game:=_game();var initial:=game.snapshot();game.switch_hero()
	_check(game.active_hero_id()=="red" and not game.undo() and game.snapshot()==initial,"free C with no history has nothing to undo")
	for n in range(1,17):
		_check(game.load_level(Level.from_file("res://levels/north_%02d.json" % n)) and game.moves==0 and game.history_size()==0,"previous1..16 load isolated")
		_check(game.load_level(Level.from_file("res://levels/north_17.json")) and game.snapshot()==initial and game.active_hero_id()=="blue","all three hero states restored without cross-level history")
	for direction in [Vector2i.DOWN,Vector2i.LEFT]:_check(game.try_move(direction)==&"wall" and game.moves==0,"outside and opaque hedge block initial movement")
func _choose(game:State,id:String) -> void:
	for _i in game.hero_count():
		if game.active_hero_id()==id:return
		_check(game.switch_hero()==&"switched","free C selection cycles three stable IDs")
	_check(false,"target hero exists")
func _play(game:State,path:String) -> void:
	for symbol in path:
		if symbol=="C":game.switch_hero()
		else:_check(game.try_move(DIRS[symbol]) in [&"moved",&"pushed",&"pulled",&"swapped"],"legal side/prefix action")
func _advance(game:State,n:int) -> void:
	for symbol in _solution()["path"]:
		if game.moves>=n:return
		_play(game,symbol)
func _solution() -> Dictionary:return JSON.parse_string(FileAccess.get_file_as_string("res://levels/solutions/north_17.json"))
func _game() -> State:
	var game:=State.new();_check(game.load_level(Level.from_file("res://levels/north_17.json")),"17 confirmed map loads");return game
func _check(ok:bool,message:String) -> void:
	checks+=1
	if not ok:failures+=1;push_error("FAIL: "+message)
