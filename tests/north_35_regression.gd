extends SceneTree
const Level=preload("res://scripts/core/level_data.gd")
const State=preload("res://scripts/core/grid_state.gd")
const Events=preload("res://scripts/view/feedback_events.gd")
const Clock=preload("res://scripts/view/feedback_timeline.gd")
const DIRS={"U":Vector2i.UP,"D":Vector2i.DOWN,"L":Vector2i.LEFT,"R":Vector2i.RIGHT}
const TERRAIN=["........####","........####","............","........#...","........#...","........####","........####"]
var checks:=0
var failures:=0
func _init()->void:
	var d:=Level.from_file("res://levels/north_35.json");var g:=State.new();_check(d.error.is_empty() and g.load_level(d),"final35loads")
	_check(d.width==12 and d.height==7 and d.terrain==PackedStringArray(TERRAIN),"final12x7supersedesold12x6")
	for y in 7:
		for x in 12:
			var c:=Vector2i(x,y);var f:bool=TERRAIN[y][x]=="."
			_check(d.is_floor(c)==f and d.is_void(c)!=f,"all84floor/voidcells exact")
	var m:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://levels/mappings/north_35_markers.json"))["marker_to_runtime_cell"]
	_check(m.size()==66 and _cell(m["3"])==Vector2i(2,1) and _cell(m["9"])==Vector2i(0,2) and _cell(m["37"])==Vector2i(5,4) and _cell(m["42"])==Vector2i(2,5) and _cell(m["43"])==Vector2i(3,5) and _cell(m["17"])==Vector2i(8,2) and _cell(m["30"])==Vector2i(10,3),"originalentitymarkerspreservedanduniformy+1")
	for x in 8:_check(_cell(m[str(59+x)])==Vector2i(x,0) and d.is_floor(Vector2i(x,0)),"new59through66allfloor")
	for x in 3:_check(_cell(m[str(56+x)])==Vector2i(9+x,4) and _cell(m[str(29+x)])==Vector2i(9+x,3),"56through58remainbelow29through31")
	_check(g.player==Vector2i(2,5) and g.active_kind()=="red" and d.initial_crates==[Vector2i(2,1),Vector2i(3,5)] and d.exit_cell==Vector2i(10,3),"finalhero/crystal/goalcoords")
	_check(d.initial_monsters==[Vector2i(0,2),Vector2i(5,4)] and d.monster_kinds==PackedStringArray(["fire_dragon","goblin"]) and g.monsters()[0]["facing"]==Vector2i.RIGHT and not g.monsters()[1].has("facing"),"dragon9right,Goblin37nondirectional")
	_check(d.monster_clear_barriers==[Vector2i(8,2)] and d.mechanism_color=="red" and d.energy_links.is_empty() and d.bushes.is_empty() and d.fence_edges.is_empty(),"typedredclearenergyonly17,nonewmechanism")
	var initial:=g.snapshot();_check(g.switch_hero()==&"single_hero" and g.snapshot()==initial and g.history_size()==0,"Cfree,noattack/history")
	var sol:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://levels/solutions/north_35.json"));var proof:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://artifacts/verification/north_35_route.json"));var history:Array[Dictionary]=[]
	for s in proof["gate_block_prefix"]:_check(g.try_move(DIRS[s]) in [&"moved",&"pushed"] and g.alive,"legalshieldedgateapproach")
	var before:=Events.capture(g);_check(g.player==Vector2i(7,2) and g.try_move(Vector2i.RIGHT)==&"energy_blocked" and g.snapshot()==before["world"] and Events.action(before,g,Vector2i.RIGHT).is_empty(),"livingmonstersblockgate,noinvalidattackround")
	_check(g.restart(),"restart")
	for i in sol["path"].length():
		var symbol:String=sol["path"][i];before=Events.capture(g);history.append(g.snapshot());var expected:Dictionary=proof["trace"][i]
		_check(g.try_move(DIRS[symbol]) in [&"moved",&"pushed"] and g.alive and g.moves==i+1 and g.history_size()==i+1,"onevalidactionperdirection")
		_check(g.player==_cell(expected["player"]) and g.pushes==expected["pushes"] and g.pulls==0 and g.swaps==0,"independenthero/counters")
		for identity in 2:_check(g.crate_id(_cell(expected["crystals"][identity]))==identity and g.monsters()[identity]["position"]==_cell(expected["monsters"][identity]) and g.monsters()[identity]["alive"]==expected["monster_alive"][identity],"bothcrystal/typedmonsteridentitylife/position")
		_check(g.monsters()[0]["facing"]==Vector2i.RIGHT and g.barrier_is_active(Vector2i(8,2))==expected["barrier_active"] and g.blocks_sight(Vector2i(8,2))==expected["barrier_active"] and g.is_walkable(Vector2i(8,2))!=expected["barrier_active"],"fixedfacing/clearconditionmovementandsight")
		var plan:=Events.action(before,g,DIRS[symbol]);var clock:=Clock.new();clock.start(plan)
		_check(plan["fire"].size()==(1 if i==37 else 0) and plan["goblin"].size()==(1 if i==37 else 0) and plan["deaths"].size()==(2 if i==37 else 0) and plan["energy"].size()==(1 if i==37 else 0),"only38mixedsimultaneousattacks/deaths/opengate")
		_check(clock.duration<0.6 and (clock.duration>0.5 if i==37 else is_equal_approx(clock.duration,0.16)),"noemptyattackwait")
		var after:=g.snapshot();clock.advance(1.0);_check(g.snapshot()==after and not clock.is_busy() and g.is_complete()==(i==49),"feedbackreadonly,only50victory")
		if i==37:
			_check(g.undo() and g.snapshot()==before["world"] and g.living_monster_count()==2 and g.barrier_is_active(Vector2i(8,2)),"Undo revivesdragon/Goblinandrestorescrystals/gate")
			_check(g.try_move(DIRS[symbol])==&"pushed" and g.snapshot()==after,"repeat38deterministic")
	_check(g.is_complete() and g.moves==50 and g.pushes==16 and g.crates().size()==2 and g.living_monster_count()==0,"50actions16pusheslivingvictory")
	for i in range(history.size()-1,-1,-1):_check(g.undo() and g.snapshot()==history[i],"all50Undoexact")
	_check(g.snapshot()==initial and not g.undo(),"allUndo restoresinitial")
	var side:Dictionary=proof["fatal_side"]
	for s in side["prefix"]:_check(g.try_move(DIRS[s]) in [&"moved",&"pushed"] and g.alive,"validdeathprefix")
	before=Events.capture(g);_check(g.try_move(DIRS[side["direction"]])==&"died" and not g.alive and g.death_reason==side["reason"],"enterGoblinrangelethal")
	var dead:=g.snapshot();_check(g.switch_hero()==&"dead" and not g.restart() and not g.load_level(d) and g.try_move(Vector2i.UP)==&"dead" and g.snapshot()==dead,"deathonlyUndo,noC/restart/loadescape")
	_check(g.undo() and g.snapshot()==before["world"] and g.alive and g.restart() and g.snapshot()==initial,"Undo revivesandrestartinitial")
	_check(g.load_level(Level.from_file("res://levels/north_34.json")) and g.load_level(d) and g.snapshot()==initial,"34/35historyisolation")
	print("NORTH35 RESULT: %d checks,%d failures" % [checks,failures]);quit(0 if failures==0 else 1)
func _cell(a:Array)->Vector2i:return Vector2i(a[0],a[1])
func _check(ok:bool,message:String)->void:
	checks+=1
	if not ok:failures+=1;printerr("FAIL "+message)
