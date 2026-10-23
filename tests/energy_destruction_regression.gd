extends SceneTree
const Energy=preload("res://scripts/core/energy_rules.gd")
const Level=preload("res://scripts/core/level_data.gd")
const State=preload("res://scripts/core/grid_state.gd")
var checks:=0
var failures:=0
func _init() -> void:
	_pure_edges()
	_atomic_world()
	_multiple_groups()
	print("ENERGY DESTRUCTION RESULT: 3 cases, %d checks, %d failures" % [checks,failures])
	quit(0 if failures==0 else 1)
func _pure_edges() -> void:
	var links: Array[Dictionary]=[{"id":"all","plates":[Vector2i(0,1)],"barriers":[Vector2i(1,1),Vector2i(2,1)],"pressure_sources":["hero","crystal"]}]
	var crystals={Vector2i(1,1):7,Vector2i(2,1):12,Vector2i(4,2):20}
	var before:=crystals.duplicate()
	var open_before={Vector2i(1,1):false,Vector2i(2,1):false}
	var held:=Energy.settle(links,Vector2i(0,1),crystals,open_before)
	_check(held["error"].is_empty() and held["crystals"]==before and held["destroyed_crystals"].is_empty(),"energy stays absent while pressure held, crystals survive")
	var restored:=Energy.settle(links,Vector2i(0,2),crystals,open_before)
	_check(restored["error"].is_empty() and restored["crystals"]=={Vector2i(4,2):20} and restored["destroyed_crystals"]=={Vector2i(1,1):7,Vector2i(2,1):12},"two restoring barriers destroy both crystals preserving survivor identity")
	_check(crystals==before and open_before=={Vector2i(1,1):false,Vector2i(2,1):false},"pure settlement never mutates caller dictionaries")
	_check(restored["barriers"]=={Vector2i(1,1):true,Vector2i(2,1):true} and not restored["pressure"]["all"],"pressure and both restored barriers computed together")
	for previous in [{},{Vector2i(1,1):true,Vector2i(2,1):true}]:
		var invalid:=Energy.settle(links,Vector2i(0,2),crystals,previous)
		_check(not invalid["error"].is_empty() and crystals==before,"cold/already-active energy never arbitrarily destroys crystals")
	_check(Energy.RESTORATION_EFFECTS[&"hero"]==&"killed" and Energy.RESTORATION_EFFECTS[&"crystal"]==&"destroyed", "shared entity semantics for implemented heroes/crystals")
	_check(Energy.RESTORATION_EFFECTS[&"monster"]==&"killed", "future monster semantic declared; no monster gameplay instantiated")
func _atomic_world() -> void:
	var game:=State.new();var level:=Level.from_dictionary(_data())
	_check(level.error.is_empty() and game.load_level(level),"independent3-hero/3-gate destruction fixture loads open")
	var initial:=game.snapshot()
	_check(game.try_move(Vector2i.DOWN)==&"died" and game.crates().size()==1 and game.crate_id(Vector2i(4,2))==2,"one release destroys two crystals and kills inactive blue atomically")
	_check(not game.hero_is_alive(1) and game.hero_is_alive(0) and game.hero_is_alive(2) and not game.alive and game.moves==1 and game.history_size()==1,"one history entry includes all life/occupancy consequences")
	for gate in [Vector2i(1,1),Vector2i(2,1),Vector2i(3,1)]:_check(game.barrier_is_active(gate) and game.blocks_sight(gate) and not game.is_walkable(gate),"all energy returns movement and sight blocking")
	var dead:=game.snapshot()
	_check(game.switch_hero()==&"dead" and game.try_move(Vector2i.RIGHT)==&"dead" and not game.restart() and not game.load_level(level) and game.snapshot()==dead,"death locks C/movement/restart/load")
	_check(game.undo() and game.snapshot()==initial and game.active_hero_id()=="red","one undo restores destroyed IDs, all heroes/life, pressure and history with current selection")
	_check(game.try_move(Vector2i.DOWN)==&"died" and game.undo() and game.snapshot()==initial,"repeat destruction/undo deterministic, no lost crystal identities")
	game.switch_hero();game.switch_hero()
	_check(game.active_hero_id()=="green" and game.restart() and game.active_hero_id()=="red" and game.snapshot()==initial,"restart restores all initial crystals and default selection")
func _multiple_groups() -> void:
	var data:=_data();data["heroes"][1]["position"]=[3,0]
	data["energy_links"]=[{"id":"a","plate":[0,1],"barriers":[[1,1]],"pressure_sources":["hero","crystal"]},{"id":"b","plate":[4,0],"barriers":[[2,1]],"pressure_sources":["hero","crystal"]}]
	var game:=State.new();_check(game.load_level(Level.from_dictionary(data)),"separate link IDs with both plates occupied open globally")
	var initial:=game.snapshot()
	_check(game.try_move(Vector2i.DOWN)==&"moved" and game.crates().size()==1 and not game.pressure_is_active("a") and game.pressure_is_active("b"),"releasing one of two groups restores both and destroys crystals in both")
	_check(game.barrier_is_active(Vector2i(1,1)) and game.barrier_is_active(Vector2i(2,1)) and game.undo() and game.snapshot()==initial,"global two-gate destruction and all pressure undo atomically")
func _data() -> Dictionary:
	return {"schema_version":1,"is_temporary":true,"source_note":"独立结算测试夹具，不是正式关卡", "id":"destruction_fixture","title":"独立机关测试","terrain":[".....",".....","....."],"heroes":[{"id":"red","kind":"red","position":[0,1]},{"id":"blue","kind":"blue","position":[3,1]},{"id":"green","kind":"green","position":[4,0]}],"active_hero":"red","crates":[[1,1],[2,1],[4,2]],"targets":[],"objective":"none","energy_links":[{"id":"all","plate":[0,1],"barriers":[[1,1],[2,1],[3,1]],"pressure_sources":["hero","crystal"]}]}
func _check(ok: bool,message: String) -> void:
	checks+=1
	if not ok:failures+=1;push_error("FAIL: "+message)
