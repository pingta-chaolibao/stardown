extends SceneTree
const Level=preload("res://scripts/core/level_data.gd")
const State=preload("res://scripts/core/grid_state.gd")
const Events=preload("res://scripts/view/feedback_events.gd")
const Timeline=preload("res://scripts/view/feedback_timeline.gd")
var checks:=0
var failures:=0
func _init() -> void:
	_validation()
	_zero_monsters()
	_mixed_first_target_and_last_death()
	_pressure_coexistence()
	_atomic_energy_death()
	_goblin_mutual()
	_no_late_attack()
	print("MONSTER CLEAR ENERGY RESULT: %d checks,%d failures" % [checks,failures])
	quit(0 if failures==0 else 1)
func _base() -> Dictionary:
	return {"schema_version":1,"id":"clear_fixture","title":"独立清怪能量测试","is_temporary":true,"source_note":"独立机制夹具，不是正式关卡或通关演示","terrain":["......","......","......","......"],"player":[0,2],"hero_kind":"red","crates":[],"targets":[],"objective":"none","energy_blocks":[{"kind":"all_monsters_defeated","position":[5,1]}]}
func _game(data:Dictionary) -> State:
	var level:=Level.from_dictionary(data);var game:=State.new()
	_check(level.error.is_empty(),"typed data parses: "+level.error)
	_check(game.load_level(level),"fixture world loads: "+game.last_mechanism_error)
	return game
func _validation() -> void:
	var data:=_base()
	for invalid in [null,{},[{"position":[5,1]}],[{"kind":"pressure","position":[5,1]}],[{"kind":"all_monsters_defeated","position":[6,1]}],[{"kind":"all_monsters_defeated","position":[1.5,1]}],[{"kind":"all_monsters_defeated","position":[5,1]},{"kind":"all_monsters_defeated","position":[5,1]}]]:
		data["energy_blocks"]=invalid
		_check(not Level.from_dictionary(data).error.is_empty(),"invalid,unknown,duplicate or out-of-bounds energy types rejected")
	data=_base();data["terrain"][1]=".....#"
	_check(not Level.from_dictionary(data).error.is_empty(),"new block cannot be in a wall")
	data=_base();data["bushes"]=[[5,1]]
	_check(not Level.from_dictionary(data).error.is_empty(),"new block cannot overlap a bush")
	for cell in [[0,2],[5,1]]:
		data=_base();data["energy_links"]=[{"id":"old","plate":[0,2],"barriers":[[5,1]],"pressure_sources":["hero","crystal"]}]
		data["energy_blocks"][0]["position"]=cell
		_check(not Level.from_dictionary(data).error.is_empty(),"one cell cannot be a pressure plate or two differently controlled barriers")
func _zero_monsters() -> void:
	for tint in ["yellow","blue","green","purple","red"]:
		var data:=_base();data["mechanism_color"]=tint;data["crates"]=[[5,1]]
		var game:=_game(data)
		_check(game.living_monster_count()==0 and not game.barrier_is_active(Vector2i(5,1)),"zero initial monsters already clear,regardless of color")
		_check(game.is_walkable(Vector2i(5,1)) and not game.blocks_sight(Vector2i(5,1)) and game.crate_id(Vector2i(5,1))==0,"absent clear energy permits movement,sight and initial crystal")
		var initial:=game.snapshot()
		_check(game.try_move(Vector2i.RIGHT)==&"moved" and game.undo() and game.snapshot()==initial,"zero-monster state remains complete through movement andUndo")
	var data:=_base();data["monsters"]=[{"kind":"goblin","position":[4,0]}];data["crates"]=[[5,1]]
	var game:=State.new()
	_check(not game.load_level(Level.from_dictionary(data)),"live-monster initial solid energy rejects overlapping crystal")
	data=_base();data["monsters"]=[{"kind":"goblin","position":[4,0]}];data["player"]=[5,1]
	game=State.new();_check(not game.load_level(Level.from_dictionary(data)),"solid clear energy cannot be a living hero spawn")
func _mixed_first_target_and_last_death() -> void:
	var data:=_base();data["monsters"]=[{"kind":"fire_dragon","position":[0,0],"facing":"right"},{"kind":"goblin","position":[2,0]},{"kind":"fire_dragon","position":[4,0],"facing":"left"}]
	var game:=_game(data);var initial:=game.snapshot()
	_check(game.living_monster_count()==3 and game.barrier_is_active(Vector2i(5,1)),"all monster kinds count;block starts solid")
	_check(not game.is_walkable(Vector2i(5,1)) and game.blocks_sight(Vector2i(5,1)),"solid clear energy blocks movement and sight")
	var before:=Events.capture(game)
	_check(game.try_move(Vector2i.RIGHT)==&"moved" and game.living_monster_count()==2,"first valid action kills only centralGoblin;dragons do not pierce")
	_check(game.barrier_is_active(Vector2i(5,1)),"deadGoblin alone does not clear living dragons")
	var plan:=Events.action(before,game,Vector2i.RIGHT)
	_check(plan["fire"].size()==2 and plan["energy"].is_empty(),"two real first-target attacks but no premature energy transition")
	for ray in plan["fire"]:_check(ray["target"]=={"kind":"monster","id":1},"both dragons lock the same firstGoblin")
	var intermediate:=game.snapshot();before=Events.capture(game)
	_check(game.try_move(Vector2i.DOWN)==&"moved" and game.living_monster_count()==0,"next valid action mutually kills the lasttwo dragons")
	_check(not game.barrier_is_active(Vector2i(5,1)) and game.is_walkable(Vector2i(5,1)) and not game.blocks_sight(Vector2i(5,1)),"last death opens clear block in same atomic action")
	plan=Events.action(before,game,Vector2i.DOWN)
	_check(plan["fire"].size()==2 and plan["deaths"].size()==2 and plan["energy"].size()==1,"already-killed attackers still animate locked reciprocal attacks and gate transition")
	var clock:=Timeline.new();clock.start(plan);clock.advance(1.0)
	_check(not clock.is_busy() and game.moves==2 and game.history_size()==2,"view clock never adds turns or changes clear state")
	_check(game.undo() and game.snapshot()==intermediate and game.barrier_is_active(Vector2i(5,1)),"oneUndo revives last pair and restores solid clear gate")
	_check(game.undo() and game.snapshot()==initial,"secondUndo restoresGoblin and all initial world identities")
	_check(game.try_move(Vector2i.RIGHT)==&"moved" and game.try_move(Vector2i.DOWN)==&"moved" and game.restart() and game.snapshot()==initial,"repeated clear and restart restores initial monsters/gate")
func _pressure_coexistence() -> void:
	var data:=_base();data["monsters"]=[{"kind":"goblin","position":[4,0]}]
	data["energy_links"]=[{"id":"pressure","plate":[0,2],"barriers":[[3,1]],"pressure_sources":["hero","crystal"]}]
	var game:=_game(data);var initial:=game.snapshot()
	_check(not game.barrier_is_active(Vector2i(3,1)) and game.barrier_is_active(Vector2i(5,1)),"pressure-held opens only old type;liveGoblin keeps new type solid")
	_check(game.try_move(Vector2i.RIGHT)==&"moved" and game.barrier_is_active(Vector2i(3,1)) and game.barrier_is_active(Vector2i(5,1)),"pressure release and monster condition independent")
	_check(game.undo() and game.snapshot()==initial,"Undo restoresboth typed states without cross-contamination")
	data["monsters"]=[];data["player"]=[1,2];game=_game(data)
	_check(game.barrier_is_active(Vector2i(3,1)) and not game.barrier_is_active(Vector2i(5,1)),"all monsters clear opens only new type;unheld pressure remains solid")
func _atomic_energy_death() -> void:
	var data:=_base();data.erase("player");data.erase("hero_kind")
	data["heroes"]=[{"id":"red","kind":"red","position":[0,2]},{"id":"blue","kind":"blue","position":[3,1]}];data["active_hero"]="red"
	data["monsters"]=[{"kind":"fire_dragon","position":[4,0],"facing":"down"}]
	data["energy_links"]=[{"id":"old","plate":[0,2],"barriers":[[3,1],[4,0]],"pressure_sources":["hero","crystal"]}]
	var game:=_game(data);var initial:=game.snapshot();var before:=Events.capture(game)
	_check(game.try_move(Vector2i.RIGHT)==&"died" and not game.alive and game.living_monster_count()==0,"old energy restoration kills inactivehero andlastdragon atomically")
	_check(game.barrier_is_active(Vector2i(3,1)) and game.barrier_is_active(Vector2i(4,0)) and not game.barrier_is_active(Vector2i(5,1)),"new gate opens despite hero death;old type remains restored")
	var plan:=Events.action(before,game,Vector2i.RIGHT)
	_check(plan["fire"].is_empty(),"energy-killeddragon cannot gain a late attack through newly cleared gate")
	var dead:=game.snapshot()
	_check(game.switch_hero()==&"dead" and game.try_move(Vector2i.DOWN)==&"dead" and not game.restart() and not game.load_level(game.level) and game.snapshot()==dead,"C/restart/load/movement cannot bypass death")
	_check(game.undo() and game.snapshot()==initial and game.living_monster_count()==1 and game.barrier_is_active(Vector2i(5,1)),"oneUndo revives all victims,old pressure and clear gate with current selection")
func _goblin_mutual() -> void:
	var data:=_base();data["monsters"]=[{"kind":"goblin","position":[2,0]},{"kind":"goblin","position":[3,0]}]
	var game:=_game(data);var initial:=game.snapshot();var before:=Events.capture(game)
	_check(game.try_move(Vector2i.RIGHT)==&"moved" and game.living_monster_count()==0 and not game.barrier_is_active(Vector2i(5,1)),"cardinalGoblins mutuallydie on same valid action andclear gate")
	var plan:=Events.action(before,game,Vector2i.RIGHT)
	_check(plan["goblin"].size()==2 and plan["deaths"].size()==2 and plan["fire"].is_empty(),"bothsame-step deadGoblins animate theiractual reciprocal attacks")
	_check(game.undo() and game.snapshot()==initial,"oneUndo revivespair andrestores gate")
	data["player"]=[2,2];game=_game(data);initial=game.snapshot();before=Events.capture(game)
	_check(game.try_move(Vector2i.UP)==&"died" and game.living_monster_count()==0 and not game.alive,"enteringadjacency stilldies evenwhile bothGoblins mutuallydie")
	plan=Events.action(before,game,Vector2i.UP)
	_check(plan["goblin"].size()==3 and plan["deaths"].size()==3,"hero attack plusboth mutual attacks sampledfrom onecommon state")
	_check(game.undo() and game.snapshot()==initial and game.alive,"Undo atomicallyrevives hero,pair,andgate")
	data=_base();data["monsters"]=[{"kind":"goblin","position":[1,0]},{"kind":"goblin","position":[2,1]}];game=_game(data);before=Events.capture(game)
	_check(game.try_move(Vector2i.DOWN)==&"moved" and game.living_monster_count()==2 and game.barrier_is_active(Vector2i(5,1)),"diagonalGoblins nevermutuallyattack")
	plan=Events.action(before,game,Vector2i.DOWN);_check(plan["goblin"].is_empty(),"no-targetGoblin turn addsnoattack animation")
	data=_base();data["monsters"]=[{"kind":"goblin","position":[2,0]},{"kind":"goblin","position":[3,0]}];data["fences"]=[[[2,0],[3,0]]];game=_game(data);initial=game.snapshot()
	_check(game.try_move(Vector2i.RIGHT)==&"rule_unresolved" and game.snapshot()==initial and game.history_size()==0,"undefinedGoblin fence interaction stillguarded atomically")
func _no_late_attack() -> void:
	var data:=_base();data["player"]=[3,2];data["energy_blocks"][0]["position"]=[2,1]
	data["monsters"]=[{"kind":"fire_dragon","position":[2,0],"facing":"down"},{"kind":"goblin","position":[1,0]},{"kind":"goblin","position":[0,0]}]
	var game:=_game(data);var initial:=game.snapshot();var before:=Events.capture(game)
	_check(game.try_move(Vector2i.LEFT)==&"moved" and game.alive and game.living_monster_count()==0 and not game.barrier_is_active(Vector2i(2,1)),"Goblins killoneanother anddragon whilehero safelymoves behindclosedclear gate")
	var plan:=Events.action(before,game,Vector2i.LEFT)
	_check(plan["fire"].is_empty() and plan["sight"].size()==1 and plan["sight"][0]["cells"].is_empty() and plan["sight"][0]["target"].is_empty(),"openinggate afterall deaths cannot inventlateflame orattack animation")
	_check(plan["goblin"].size()==3 and plan["deaths"].size()==3 and plan["energy"].size()==1,"allactualGoblin attacks/deaths andgateeffect retained")
	_check(game.undo() and game.snapshot()==initial and game.barrier_is_active(Vector2i(2,1)),"Undo restoreslocked barrierandallthree monsters")
func _check(ok:bool,message:String) -> void:
	checks+=1
	if not ok:failures+=1;push_error("FAIL: "+message)
