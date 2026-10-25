extends SceneTree
const Level=preload("res://scripts/core/level_data.gd")
const State=preload("res://scripts/core/grid_state.gd")
const Events=preload("res://scripts/view/feedback_events.gd")
const Clock=preload("res://scripts/view/feedback_timeline.gd")
const DIRS={"U":Vector2i.UP,"D":Vector2i.DOWN,"L":Vector2i.LEFT,"R":Vector2i.RIGHT}
const TERRAIN=[".......#..",".......#..",".......#..",".......##.",".........."]
var checks:=0
var failures:=0
func _init() -> void:
	var level:=Level.from_file("res://levels/north_32.json");var game:=State.new()
	_check(level.error.is_empty() and game.load_level(level),"confirmed32loads")
	_check(level.width==10 and level.height==5 and level.terrain==PackedStringArray(TERRAIN),"alltopandperimeter10x5exact")
	for n in range(1,51):
		var c:=Vector2i((n-1)%10,(n-1)/10)
		_check(level.is_floor(c)==(n not in [8,18,28,38,39]),"all50numberedcells;29/30floor")
	_check(level.mechanism_color=="red" and level.monster_clear_barriers==[Vector2i(9,3)] and level.energy_links.is_empty(),"40onlytypedglobalclearenergy,redvisual")
	_check(game.player==Vector2i(1,2) and game.active_kind()=="red" and level.initial_crates==[Vector2i(2,2),Vector2i(4,3)],"22red and23/35crystals")
	_check(level.initial_monsters==[Vector2i(4,2),Vector2i(0,4)] and level.monster_kinds==PackedStringArray(["goblin","goblin"]) and level.exit_cell==Vector2i(9,1),"25/41Goblin and20goal")
	_check(level.bushes.is_empty() and level.fence_edges.is_empty() and game.is_walkable(Vector2i(8,2)) and game.is_walkable(Vector2i(9,2)),"noadditionalmechanics;29/30neverenergy")
	var initial:=game.snapshot()
	_check(game.switch_hero()==&"single_hero" and game.snapshot()==initial and game.history_size()==0,"Cfree no-op withoutattacks")
	for s in "DRRDRRRRRR":_check(game.try_move(DIRS[s])==&"moved","safewalktogatebeforeclearing")
	var before:=Events.capture(game)
	_check(game.player==Vector2i(9,4) and game.try_move(Vector2i.UP)==&"energy_blocked" and game.snapshot()==before["world"] and Events.action(before,game,Vector2i.UP).is_empty(),"livingmonsters block40;invalidinputdoesnotadvanceattacks")
	_check(game.restart(),"restartinitial")
	var solution:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://levels/solutions/north_32.json"));var proof:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://artifacts/verification/north_32_route.json"));var history:Array[Dictionary]=[]
	for i in solution["path"].length():
		var s:String=solution["path"][i];before=Events.capture(game);history.append(game.snapshot())
		_check(game.try_move(DIRS[s]) in [&"moved",&"pushed"] and game.alive and game.moves==i+1 and game.history_size()==i+1,"onelegalactualactionperdirection")
		var expected:Dictionary=proof["trace"][i]
		_check(game.player==_cell(expected["player"]) and game.pushes==expected["pushes"],"independenthero/counters")
		for identity in 2:_check(game.crate_id(_cell(expected["crystals"][identity]))==identity and game.monsters()[identity]["position"]==_cell(expected["monsters"][identity]) and game.monsters()[identity]["alive"]==expected["monster_alive"][identity],"eachcrystal/Goblinidentitypositionlife")
		_check(game.barrier_is_active(Vector2i(9,3))==expected["barrier_active"] and game.blocks_sight(Vector2i(9,3))==expected["barrier_active"] and game.is_walkable(Vector2i(9,3))!=expected["barrier_active"],"sight/movement/clearconditioneachaction")
		var plan:=Events.action(before,game,DIRS[s]);var clock:=Clock.new();clock.start(plan)
		_check(plan["fire"].is_empty() and plan["goblin"].size()==(2 if i==31 else 0) and plan["deaths"].size()==(2 if i==31 else 0) and plan["energy"].size()==(1 if i==31 else 0),"only32actualmutualattacks/deaths/cleartransition")
		_check(clock.duration<0.6 and (clock.duration>0.5 if i==31 else is_equal_approx(clock.duration,0.16)),"noemptyattackwait;feedbackfitsnormalinputpace")
		var after:=game.snapshot();clock.advance(1.0)
		_check(game.snapshot()==after and not clock.is_busy() and game.is_complete()==(i==42),"feedbackread-only,only43victory")
		if i==31:
			_check(game.undo() and game.snapshot()==before["world"] and game.living_monster_count()==2 and game.barrier_is_active(Vector2i(9,3)),"Undoatomicallyrevivesbothandrestoresredgate")
			_check(game.try_move(DIRS[s])==&"pushed" and game.snapshot()==after,"repeat32deterministic")
	_check(game.is_complete() and game.moves==43 and game.pushes==12 and game.living_monster_count()==0 and game.crates().size()==2,"43/12livingvictorybothcrystalspreserved")
	for i in range(history.size()-1,-1,-1):_check(game.undo() and game.snapshot()==history[i],"all43undosrestoreworldincludinglife/energy")
	_check(game.snapshot()==initial and not game.undo(),"emptyUndoexact")
	_check(game.try_move(Vector2i.LEFT)==&"moved" and game.try_move(Vector2i.LEFT)==&"wall" and game.moves==1,"boundaryblockednophantomaction")
	_check(game.try_move(Vector2i.DOWN)==&"died" and not game.alive,"enterGoblinrangelethal")
	var dead:=game.snapshot()
	_check(game.switch_hero()==&"dead" and not game.restart() and not game.load_level(level) and game.try_move(Vector2i.UP)==&"dead" and game.snapshot()==dead,"deathonlyUndo,noC/restart/loadbypass")
	_check(game.undo() and game.alive and game.restart() and game.snapshot()==initial,"Undo revives thenrestartinitial")
	_check(game.load_level(Level.from_file("res://levels/north_31.json")) and game.load_level(level) and game.snapshot()==initial,"31/32history/energyisolation")
	print("NORTH32 RESULT: %d checks,%d failures" % [checks,failures]);quit(0 if failures==0 else 1)
func _cell(a:Array)->Vector2i:return Vector2i(a[0],a[1])
func _check(ok:bool,message:String)->void:
	checks+=1
	if not ok:failures+=1;printerr("FAIL "+message)
