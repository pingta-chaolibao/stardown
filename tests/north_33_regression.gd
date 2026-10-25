extends SceneTree
const Level=preload("res://scripts/core/level_data.gd")
const State=preload("res://scripts/core/grid_state.gd")
const Events=preload("res://scripts/view/feedback_events.gd")
const Clock=preload("res://scripts/view/feedback_timeline.gd")
const DIRS={"U":Vector2i.UP,"D":Vector2i.DOWN,"L":Vector2i.LEFT,"R":Vector2i.RIGHT}
const TERRAIN=["........####","........####","........#...","............","........#...","........####","........####"]
var checks:=0
var failures:=0
func _init() -> void:
	var level:=Level.from_file("res://levels/north_33.json");var game:=State.new()
	_check(level.error.is_empty() and game.load_level(level),"confirmed33loads")
	_check(level.width==12 and level.height==7 and level.terrain==PackedStringArray(TERRAIN),"complete12x7bounds")
	for y in 7:
		for x in 12:
			var cell:=Vector2i(x,y);var is_floor:bool=TERRAIN[y][x]=="."
			_check(level.is_floor(cell)==is_floor and level.is_void(cell)!=is_floor,"all84floor/voidcells exact;rightplatformincluded")
	_check(level.monster_clear_barriers==[Vector2i(8,3)] and level.mechanism_color=="red" and level.energy_links.is_empty(),"typedredclearblock onlygate")
	_check(game.player==Vector2i(2,3) and game.active_kind()=="red" and level.initial_crates==[Vector2i(6,3),Vector2i(4,5)],"hero andtwoordinarycrystals")
	_check(level.initial_monsters==[Vector2i(1,2),Vector2i(4,3),Vector2i(0,6)] and level.monster_kinds==PackedStringArray(["goblin","goblin","goblin"]),"18isGoblin,neverdragon/directionalattack")
	_check(level.exit_cell==Vector2i(10,3) and level.bushes.is_empty() and level.fence_edges.is_empty(),"goal exact,noextraobjects")
	var initial:=game.snapshot()
	_check(game.switch_hero()==&"single_hero" and game.snapshot()==initial and game.history_size()==0,"singleheroCfree,noattack/history")
	for s in "DDDRRRRRUUU":_check(game.try_move(DIRS[s])==&"moved","safegateapproach")
	var before:=Events.capture(game)
	_check(game.player==Vector2i(7,3) and game.try_move(Vector2i.RIGHT)==&"energy_blocked" and game.snapshot()==before["world"] and Events.action(before,game,Vector2i.RIGHT).is_empty(),"threeGoblinsblockgate;failedinputnoattack")
	_check(game.restart(),"restartinitial")
	var solution:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://levels/solutions/north_33.json"));var proof:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://artifacts/verification/north_33_route.json"));var history:Array[Dictionary]=[]
	for i in solution["path"].length():
		var s:String=solution["path"][i];before=Events.capture(game);history.append(game.snapshot())
		_check(game.try_move(DIRS[s]) in [&"moved",&"pushed"] and game.alive and game.moves==i+1 and game.history_size()==i+1,"legalactualdirection")
		var expected:Dictionary=proof["trace"][i]
		_check(game.player==_cell(expected["player"]) and game.pushes==expected["pushes"],"independenthero/counters")
		for identity in 2:_check(game.crate_id(_cell(expected["crystals"][identity]))==identity,"eachcrystalidentity")
		for identity in 3:_check(game.monsters()[identity]["position"]==_cell(expected["monsters"][identity]) and game.monsters()[identity]["alive"]==expected["monster_alive"][identity],"eachGoblinidentitylife/position")
		_check(game.barrier_is_active(Vector2i(8,3))==expected["barrier_active"] and game.blocks_sight(Vector2i(8,3))==expected["barrier_active"] and game.is_walkable(Vector2i(8,3))!=expected["barrier_active"],"globalclearcondition sight/movement")
		var plan:=Events.action(before,game,DIRS[s]);var clock:=Clock.new();clock.start(plan)
		_check(plan["fire"].is_empty() and plan["goblin"].size()==(4 if i==57 else 0) and plan["deaths"].size()==(3 if i==57 else 0) and plan["energy"].size()==(1 if i==57 else 0),"only58fourlockedstrikes,threevictimsandonegate;noemptyattacks")
		_check(clock.duration<0.6 and (clock.duration>0.5 if i==57 else is_equal_approx(clock.duration,0.16)),"feedbackbounded,noemptyattackwait")
		var after:=game.snapshot();clock.advance(1.0)
		_check(game.snapshot()==after and not clock.is_busy() and game.is_complete()==(i==67),"feedbackreadonly,only68victory")
		if i==57:
			_check(game.undo() and game.snapshot()==before["world"] and game.living_monster_count()==3 and game.barrier_is_active(Vector2i(8,3)),"Undoatomicallyrevivesthreeandrestoresgate")
			_check(game.try_move(DIRS[s])==&"pushed" and game.snapshot()==after,"repeat58deterministic")
	_check(game.is_complete() and game.moves==68 and game.pushes==21 and game.living_monster_count()==0 and game.crates().size()==2,"68/21livingvictorybothcrystalspreserved")
	for i in range(history.size()-1,-1,-1):_check(game.undo() and game.snapshot()==history[i],"all68undosrestorefullworld")
	_check(game.snapshot()==initial and not game.undo(),"emptyUndoexact")
	for s in "DDDRRRRR":_check(game.try_move(DIRS[s])==&"moved","boundaryapproach")
	before=Events.capture(game)
	_check(game.try_move(Vector2i.RIGHT)==&"wall" and game.try_move(Vector2i.DOWN)==&"wall" and game.snapshot()==before["world"],"void/right/bottomboundariesblockwithoutaction")
	_check(game.restart() and game.try_move(Vector2i.LEFT)==&"died" and not game.alive,"Goblin18cardinalthreat;notdirectional")
	var dead:=game.snapshot()
	_check(game.switch_hero()==&"dead" and not game.restart() and not game.load_level(level) and game.try_move(Vector2i.UP)==&"dead" and game.snapshot()==dead,"deathonlyUndo,noC/restart/loadbypass")
	_check(game.undo() and game.alive and game.restart() and game.snapshot()==initial,"Undo revives thenrestartinitial")
	_check(game.load_level(Level.from_file("res://levels/north_32.json")) and game.load_level(level) and game.snapshot()==initial,"32/33history/energyisolation")
	print("NORTH33 RESULT: %d checks,%d failures" % [checks,failures]);quit(0 if failures==0 else 1)
func _cell(a:Array)->Vector2i:return Vector2i(a[0],a[1])
func _check(ok:bool,message:String)->void:
	checks+=1
	if not ok:failures+=1;printerr("FAIL "+message)
