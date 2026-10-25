extends SceneTree
const Level=preload("res://scripts/core/level_data.gd")
const State=preload("res://scripts/core/grid_state.gd")
const Events=preload("res://scripts/view/feedback_events.gd")
const Clock=preload("res://scripts/view/feedback_timeline.gd")
const DIRS={"U":Vector2i.UP,"D":Vector2i.DOWN,"L":Vector2i.LEFT,"R":Vector2i.RIGHT}
const TERRAIN=[".......#...",".......#...",".......#...","..#....#...","..##...##.#","..#........","..#........","..#........"]
var checks:=0
var failures:=0
func _init() -> void:
	var level:=Level.from_file("res://levels/north_31.json");var game:=State.new()
	_check(level.error.is_empty() and game.load_level(level),"complete user-confirmed31 loads")
	_check(level.width==11 and level.height==8 and level.terrain==PackedStringArray(TERRAIN),"confirmed11x8,not incomplete old7rows")
	for y in 8:
		for x in 11:
			var cell:=Vector2i(x,y)
			_check(level.is_floor(cell)==(TERRAIN[y][x]==".") and game.blocks_sight(cell)==(TERRAIN[y][x]=="#" or cell==Vector2i(9,4)),"all88 floor/wall/activeenergy sight cells exact")
	var mapping:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://levels/mappings/north_31_markers.json"))
	for n in range(1,78):_check(_cell(mapping["marker_to_runtime_cell"][str(n)])==Vector2i((n-1)%11,(n-1)/11+1),"old1–77 kept with uniformy+1")
	for n in range(78,89):_check(level.is_floor(_cell(mapping["marker_to_runtime_cell"][str(n)]))==(n!=85),"newtop78–88only85blocked")
	_check(game.hero_count()==1 and game.active_kind()=="red" and game.player==Vector2i(0,5),"45red shifted once,not newhero")
	_check(level.initial_crates==[Vector2i(8,6),Vector2i(9,6)] and level.initial_monsters==[Vector2i(7,5),Vector2i(0,7)],"64/65crystal and52/67Goblin exact IDs")
	_check(level.monster_kinds==PackedStringArray(["goblin","goblin"]) and level.exit_cell==Vector2i(9,2) and level.monster_clear_barriers==[Vector2i(9,4)],"21goal and43typedclearblock,all monstersGoblin")
	_check(level.energy_links.is_empty() and level.bushes.is_empty() and level.fence_edges.is_empty(),"no inferred plates,bushes,fences,dragons ornewedge mechanic")
	var initial:=game.snapshot()
	_check(game.switch_hero()==&"single_hero" and game.snapshot()==initial and game.history_size()==0,"singleheroC isfree no-op,noattack")
	_check(game.try_move(Vector2i.LEFT)==&"wall" and game.snapshot()==initial,"outsideboundary remainsblocked")
	for symbol in "UUURRRDRDDDDRRRRRRUUL":_check(game.try_move(DIRS[symbol])==&"moved","legal safe approach toenergy frombelow")
	var gate_before:=Events.capture(game)
	_check(game.player==Vector2i(9,5) and game.try_move(Vector2i.UP)==&"energy_blocked" and game.snapshot()==gate_before["world"],"livingGoblins block43movement,failedinput creates no world change")
	_check(Events.action(gate_before,game,Vector2i.UP).is_empty() and game.restart(),"blocked gate has no attack round;restart restores initial")
	var solution:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://levels/solutions/north_31.json"))
	var proof:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://artifacts/verification/north_31_route.json"))
	var history:Array[Dictionary]=[]
	for i in solution["path"].length():
		var symbol:String=solution["path"][i];var before:=Events.capture(game);history.append(game.snapshot())
		_check(game.try_move(DIRS[symbol]) in [&"moved",&"pushed"] and game.alive and game.moves==i+1 and game.history_size()==i+1,"each actualdirection commitsonelegal living step")
		var expected:Dictionary=proof["trace"][i]
		_check(game.player==_cell(expected["player"]) and game.pushes==expected["pushes"],"independent hero andpush count match")
		for identity in 2:
			_check(game.crate_id(_cell(expected["crystals"][identity]))==identity and game.monsters()[identity]["position"]==_cell(expected["monsters"][identity]) and game.monsters()[identity]["alive"]==expected["monster_alive"][identity],"crystal andGoblin identities/positions/life independentlymatch")
		_check(game.barrier_is_active(Vector2i(9,4))==expected["barrier_active"] and game.blocks_sight(Vector2i(9,4))==expected["barrier_active"] and game.is_walkable(Vector2i(9,4))!=expected["barrier_active"],"clear barrier,movement andsight agree eachstep")
		var plan:=Events.action(before,game,DIRS[symbol]);var clock:=Clock.new();clock.start(plan)
		_check(plan["fire"].is_empty() and plan["goblin"].size()==(2 if i==76 else 0) and plan["deaths"].size()==(2 if i==76 else 0) and plan["energy"].size()==(1 if i==76 else 0),"onlyaction77actual reciprocalGoblin attacks/death andenergy effect")
		_check(clock.duration<0.6 and (clock.duration>0.5 if i==76 else is_equal_approx(clock.duration,0.16)),"noempty attacks,no secondround,longest feedbackfitsinputpace")
		var after:=game.snapshot();clock.advance(1.0)
		_check(game.snapshot()==after and not clock.is_busy() and game.is_complete()==(i==95),"view clockneverchangeslogic,only96isvictory")
		if i==72:_check(game.player==Vector2i(0,0) and game.try_move(Vector2i.UP)==&"wall" and game.snapshot()==after,"new78isinside;aboveitstilloutsideblocked")
		if game.monsters()[0]["position"]==Vector2i(0,2) and game.player==Vector2i(2,2):
			_check(game.try_move(Vector2i.LEFT)==&"crate_blocked" and game.snapshot()==after and game.living_monster_count()==2,"cannotpushGoblinoutofboard;noedge-death rule")
		if i==76:
			_check(game.undo() and game.snapshot()==before["world"] and game.living_monster_count()==2 and game.barrier_is_active(Vector2i(9,4)),"Undo mutualdeathrevivesbothGoblins andrestoresclearenergy atomically")
			_check(game.try_move(DIRS[symbol])==&"pushed" and game.snapshot()==after,"repeatactual77deterministicallyclearsagain")
	_check(game.is_complete() and game.moves==96 and game.pushes==29 and game.living_monster_count()==0 and game.crates().size()==2,"complete96/29livingvictory,twoidentitiespreserved")
	for i in range(history.size()-1,-1,-1):_check(game.undo() and game.snapshot()==history[i] and game.active_kind()=="red","Undo restoresall96worldstepsincludingtopturn,lives,andtypedgate")
	_check(game.snapshot()==initial and not game.undo() and game.restart(),"emptyUndo andfullrestart exact")
	var before_death:=game.snapshot()
	_check(game.try_move(Vector2i.DOWN)==&"died" and game.death_reason=="monster" and game.living_monster_count()==2,"enter67cardinalrange lethal;neither monster prematurelydies")
	var dead:=game.snapshot()
	_check(game.switch_hero()==&"dead" and not game.restart() and not game.load_level(level) and game.try_move(Vector2i.UP)==&"dead" and game.snapshot()==dead,"deathlocksC/restart/load/directions")
	_check(game.undo() and game.snapshot()==before_death and game.alive,"onlyUndo revives")
	_check(game.load_level(Level.from_file("res://levels/north_30.json")) and game.load_level(level) and game.snapshot()==initial,"30/31histories andcleargates isolated")
	print("NORTH31 RESULT: %d checks,%d failures" % [checks,failures]);quit(0 if failures==0 else 1)
func _cell(value:Array) -> Vector2i:return Vector2i(value[0],value[1])
func _check(ok:bool,message:String) -> void:
	checks+=1
	if not ok:failures+=1;printerr("FAIL "+message)
