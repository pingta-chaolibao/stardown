extends SceneTree
const Level=preload("res://scripts/core/level_data.gd")
const State=preload("res://scripts/core/grid_state.gd")
const Events=preload("res://scripts/view/feedback_events.gd")
const Clock=preload("res://scripts/view/feedback_timeline.gd")
const DIRS={"U":Vector2i.UP,"D":Vector2i.DOWN,"L":Vector2i.LEFT,"R":Vector2i.RIGHT}
const TERRAIN=[".....####",".....#...",".........",".....#...",".....####"]
var checks:=0
var failures:=0
func _init() -> void:
	var level:=Level.from_file("res://levels/north_34.json");var g:=State.new()
	_check(level.error.is_empty() and g.load_level(level),"confirmed34loads")
	_check(level.width==9 and level.height==5 and level.terrain==PackedStringArray(TERRAIN),"complete9x5bounds")
	for y in 5:
		for x in 9:
			var c:=Vector2i(x,y);var floor:bool=TERRAIN[y][x]=="."
			_check(level.is_floor(c)==floor and level.is_void(c)!=floor,"45floor/voidcells exact")
	_check(g.player==Vector2i(1,3) and g.active_kind()=="green" and level.initial_crates==[Vector2i(3,3)] and level.exit_cell==Vector2i(7,2),"hero24/crystal26/goal21")
	_check(level.initial_monsters==[Vector2i(0,0),Vector2i(4,0)] and level.monster_kinds==PackedStringArray(["fire_dragon","fire_dragon"]) and level.monster_facings==[Vector2i.LEFT,Vector2i.RIGHT],"1left/5right,neverGoblin")
	_check(level.monster_clear_barriers==[Vector2i(5,2)] and level.mechanism_color=="red" and level.energy_links.is_empty() and level.bushes.is_empty() and level.fence_edges.is_empty(),"onlytypedredclearblock19,nonewmechanism")
	var initial:=g.snapshot();_check(g.switch_hero()==&"single_hero" and g.snapshot()==initial and g.history_size()==0,"Cfree/noattack")
	_check(g.try_move(Vector2i.RIGHT)==&"moved","approachcrystal")
	var before:=Events.capture(g)
	_check(g.try_move(Vector2i.RIGHT)==&"cannot_push" and g.snapshot()==before["world"] and Events.action(before,g,Vector2i.RIGHT).is_empty(),"greenneverpushescrystal,nofailedinputattack")
	_check(g.restart(),"restart")
	for s in "URRR":_check(g.try_move(DIRS[s])==&"moved","safegateapproach")
	before=Events.capture(g)
	_check(g.player==Vector2i(4,2) and g.try_move(Vector2i.RIGHT)==&"energy_blocked" and g.snapshot()==before["world"],"twolivingdragonsblock19")
	_check(g.restart(),"restartaftergate")
	var sol:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://levels/solutions/north_34.json"));var proof:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://artifacts/verification/north_34_route.json"));var history:Array[Dictionary]=[]
	for i in sol["path"].length():
		var symbol:String=sol["path"][i];before=Events.capture(g);history.append(g.snapshot());var expected:Dictionary=proof["trace"][i]
		_check(g.try_move(DIRS[symbol])==(&"pulled" if expected["pulled"]!=null else &"moved") and g.alive and g.moves==i+1 and g.history_size()==i+1,"actualsinglepullorwalk")
		_check(g.player==_cell(expected["player"]) and g.crate_id(_cell(expected["crystals"][0]))==0 and g.pulls==expected["pulls"] and g.pushes==0 and g.swaps==0,"independenthero/crystal/counters")
		for identity in 2:_check(g.monsters()[identity]["position"]==_cell(expected["monsters"][identity]) and g.monsters()[identity]["alive"]==expected["monster_alive"][identity] and g.monsters()[identity]["facing"]==[Vector2i.LEFT,Vector2i.RIGHT][identity],"dragonidentity/life/fixedfacing")
		_check(g.barrier_is_active(Vector2i(5,2))==expected["barrier_active"] and g.blocks_sight(Vector2i(5,2))==expected["barrier_active"] and g.is_walkable(Vector2i(5,2))!=expected["barrier_active"],"clearconditionmovement/sight")
		var plan:=Events.action(before,g,DIRS[symbol]);var clock:=Clock.new();clock.start(plan)
		_check(plan["fire"].size()==(2 if i==26 else 0) and plan["goblin"].is_empty() and plan["deaths"].size()==(2 if i==26 else 0) and plan["energy"].size()==(1 if i==26 else 0),"only27lockedmutualfireanddeaths/opengate,noemptyattack")
		_check(clock.duration<0.6 and (clock.duration>0.5 if i==26 else is_equal_approx(clock.duration,0.16)),"boundedclockwithoutemptyattackwait")
		var after:=g.snapshot();clock.advance(1.0);_check(g.snapshot()==after and not clock.is_busy() and g.is_complete()==(i==32),"feedbackreadonly andonly33victory")
		if i==26:
			_check(g.undo() and g.snapshot()==before["world"] and g.living_monster_count()==2 and g.barrier_is_active(Vector2i(5,2)),"Undo revivesbothdragonsandrestorescrystal/gate/facing")
			_check(g.try_move(DIRS[symbol])==&"pulled" and g.snapshot()==after,"repeat27deterministiccrystalunshielding")
	_check(g.is_complete() and g.moves==33 and g.pulls==18 and g.living_monster_count()==0 and g.crates()==[Vector2i(6,2)],"33livingactions18pulls10dragon8crystal")
	for i in range(history.size()-1,-1,-1):_check(g.undo() and g.snapshot()==history[i],"all33Undoexact")
	_check(g.snapshot()==initial and not g.undo(),"Undoallinitial")
	var side:Dictionary=proof["fatal_side"]
	for s in side["prefix"]:_check(g.try_move(DIRS[s]) in [&"moved",&"pulled"] and g.alive,"legalprefixforactualdeath")
	before=Events.capture(g);_check(g.try_move(DIRS[side["direction"]])==&"died" and not g.alive and g.death_reason=="fire","unshieldedsideinputdies")
	var dead:=g.snapshot();_check(g.switch_hero()==&"dead" and not g.restart() and not g.load_level(level) and g.try_move(Vector2i.UP)==&"dead" and g.snapshot()==dead,"deathonlyUndo,nomenurestartCescape")
	_check(g.undo() and g.snapshot()==before["world"] and g.alive and g.restart() and g.snapshot()==initial,"Undo revivesandrestartinitial")
	_check(g.load_level(Level.from_file("res://levels/north_33.json")) and g.load_level(level) and g.snapshot()==initial,"33/34history/life/energyisolation")
	print("NORTH34 RESULT: %d checks,%d failures" % [checks,failures]);quit(0 if failures==0 else 1)
func _cell(a:Array)->Vector2i:return Vector2i(a[0],a[1])
func _check(ok:bool,message:String)->void:
	checks+=1
	if not ok:failures+=1;printerr("FAIL "+message)
