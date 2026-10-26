class_name GridState
extends RefCounted
## Pure grid rules: no scene, renderer, timers, physics, or input dependencies.

const Level = preload("res://scripts/core/level_data.gd")
const Energy = preload("res://scripts/core/energy_rules.gd")
const Heroes = preload("res://scripts/core/hero_rules.gd")
const Monsters = preload("res://scripts/core/monster_rules.gd")
const Fire = preload("res://scripts/core/fire_rules.gd")
const Swaps = preload("res://scripts/core/swap_rules.gd")
const Protection = preload("res://scripts/core/protection_rules.gd")

var level: Level
var player: Vector2i:
	get:
		return _hero_positions[active_hero_index] if not _hero_positions.is_empty() else Vector2i.ZERO
	set(value):
		if _hero_positions.is_empty():
			_hero_positions.append(value)
		else:
			_hero_positions[active_hero_index] = value
var active_hero_index: int = 0
var _hero_positions: Array[Vector2i] = []
var _hero_alive: Array[bool] = []
var _monster_positions:Array[Vector2i]=[]
var _monster_alive:Array[bool]=[]
var _monster_facings:Array[Vector2i]=[]
var death_reason:String=""
var moves: int = 0
var pushes: int = 0
var pulls: int = 0
var swaps: int = 0
var alive: bool = true
var last_mechanism_error: String = ""
var _crates: Dictionary = {}
var _history: Array[Dictionary] = []
var _pressure: Dictionary = {}
var _barriers: Dictionary = {}
var _initial_state: Dictionary = {}
var _last_attack_phase: Dictionary = {}


func load_level(definition: Level) -> bool:
	if not alive or definition == null or not definition.error.is_empty():
		return false
	var initial_crystals: Dictionary = {}
	for i in definition.initial_crates.size():
		initial_crystals[definition.initial_crates[i]] = i
	var positions: Array[Vector2i] = []
	for hero in definition.hero_definitions:
		positions.append(hero["start"])
	var monster_positions:Array[Vector2i]=definition.initial_monsters.duplicate()
	var monster_life:Array[bool]=[]
	for _m in monster_positions:monster_life.append(true)
	var settled := _settle_world(definition,positions,initial_crystals,monster_positions,monster_life,{},false)
	last_mechanism_error = settled["error"]
	if not last_mechanism_error.is_empty():
		return false
	if not settled["alive"]:
		last_mechanism_error = "英雄不能从能量格或活怪物四向攻击范围内开始。"
		return false
	level = definition
	active_hero_index = definition.initial_active_hero
	_initial_state = {"player": definition.start, "crates": settled["crystals"],
		"moves": 0, "pushes": 0, "pulls": 0, "swaps": 0, "alive": true,
		"pressure": settled["pressure"], "barriers": settled["barriers"]}
	if positions.size() > 1:
		_initial_state.erase("player")
		_initial_state.merge({"hero_positions":positions,"hero_alive":settled["hero_alive"]})
	if not monster_positions.is_empty():
		_initial_state.merge({"monster_positions":monster_positions,"monster_alive":settled["monster_alive"],"death_reason":""})
	if definition.monster_kinds.has("fire_dragon"):
		_initial_state["monster_facings"]=definition.monster_facings.duplicate()
	_restore(_initial_state)
	_history.clear()
	return true


func try_move(direction: Vector2i) -> StringName:
	if level == null:
		return &"no_level"
	if not alive:
		return &"dead"
	last_mechanism_error = ""
	if absi(direction.x) + absi(direction.y) != 1:
		return &"invalid_direction"
	if is_complete():
		return &"complete"
	if Heroes.can_swap(active_kind()):
		var target := swap_target(direction)
		if target["result"] == &"target":
			return _exchange_target(target)
	var next := player + direction
	if not is_walkable(next):
		if level.bush_at(next) != null:
			return &"bush_blocked"
		return &"energy_blocked" if barrier_is_active(next) else &"wall"
	if _occupied(next) and not Heroes.can_push(active_kind()):
		return &"cannot_push"
	var chain: Array[Vector2i] = []
	var destination := next
	while _occupied(destination):
		chain.append(destination)
		destination += direction
	if not chain.is_empty() and not is_walkable(destination):
		return &"crate_blocked"
	# Validate every moving object's edge before creating any candidate state.
	# Blue's visible-target exchange has already returned above and ignores edges.
	if level.has_fence(player,next): return &"fence_blocked"
	for cell in chain:
		if level.has_fence(cell,cell+direction): return &"fence_blocked"
	var pulling:=pull_target_at(player-direction)
	if not pulling.is_empty() and level.has_fence(player-direction,player):
		return &"fence_blocked"
	var candidate := _crates.duplicate()
	var positions: Array[Vector2i] = _hero_positions.duplicate()
	var monster_positions:Array[Vector2i]=_monster_positions.duplicate()
	for index in range(chain.size() - 1, -1, -1):
		var cell := chain[index]
		if _crates.has(cell):
			var identity: int = _crates[cell]
			candidate.erase(cell)
			candidate[cell + direction] = identity
		elif monster_at(cell)>=0:
			monster_positions[monster_at(cell)]=cell+direction
		else:
			positions[hero_at(cell)] = cell + direction
	var pulled:bool=not pulling.is_empty()
	if pulled:
		var behind:Vector2i=player-direction
		if pulling["kind"]=="crystal":
			candidate.erase(behind)
			candidate[player]=pulling["id"]
		else:
			# A dragon keeps identity/facing; only this adjacent object follows.
			monster_positions[pulling["id"]]=player
	positions[active_hero_index] = next
	var result := _commit(positions, candidate, 0 if chain.is_empty() else 1, 1 if pulled else 0, 0, monster_positions)
	if result != &"committed":
		return result
	if pulled:
		return &"pulled"
	return &"pushed" if not chain.is_empty() else &"moved"


func pull_target_at(cell:Vector2i) -> Dictionary:
	if level==null or not Heroes.can_pull(active_kind()):return {}
	if _crates.has(cell):return {"kind":"crystal","id":_crates[cell]}
	var m:int=monster_at(cell)
	if m>=0 and Heroes.can_pull_target(active_kind(),level.monster_kinds[m]):
		return {"kind":level.monster_kinds[m],"id":m}
	return {}


func switch_hero() -> StringName:
	if level == null:
		return &"no_level"
	if not alive:
		return &"dead"
	if is_complete():
		return &"complete"
	if _hero_positions.size() < 2:
		return &"single_hero"
	# Selection is control state, not an action or an undoable world change.
	active_hero_index = (active_hero_index + 1) % _hero_positions.size()
	last_mechanism_error = ""
	return &"switched"


func _occupied(cell: Vector2i) -> bool:
	return _crates.has(cell) or hero_at(cell) >= 0 or monster_at(cell)>=0


func swap_target(direction: Vector2i) -> Dictionary:
	if level==null:
		return {"result": &"no_level"}
	return Swaps.first_target(player,direction,Rect2i(Vector2i.ZERO,Vector2i(level.width,level.height)),blocks_sight,_swap_occupant)


func _swap_occupant(cell: Vector2i) -> Dictionary:
	var hero := hero_at(cell)
	if hero >= 0:
		return {"kind":&"hero","id":hero}
	if monster_at(cell)>=0:return {"kind":&"monster","id":monster_at(cell)}
	return {"kind": &"crystal", "id":_crates[cell]} if _crates.has(cell) else {}


func _exchange_target(target: Dictionary) -> StringName:
	var plan := Swaps.exchange_plan(player,target)
	var positions: Array[Vector2i] = _hero_positions.duplicate()
	var monster_positions:Array[Vector2i]=_monster_positions.duplicate()
	var candidate := _crates.duplicate()
	if plan["target_kind"] == &"hero":
		positions[plan["target_id"]] = player
	elif plan["target_kind"]==&"monster":
		monster_positions[plan["target_id"]]=player
	else:
		candidate.erase(plan["player"])
		candidate[player] = plan["target_id"]
	positions[active_hero_index] = plan["player"]
	var result := _commit(positions,candidate,0,0,1,monster_positions)
	return &"swapped" if result == &"committed" else result


func _commit(positions: Array[Vector2i], candidate: Dictionary, pushed: int, pulled: int, swapped: int,monster_positions:Array[Vector2i]) -> StringName:
	var settled := _settle_world(level,positions,candidate,monster_positions,_monster_alive,_barriers)
	last_mechanism_error = settled["error"]
	if not last_mechanism_error.is_empty():
		return &"rule_unresolved"
	# Validate the entire candidate, then record and commit all objects once.
	_history.append(snapshot())
	_hero_positions = positions
	_monster_positions=monster_positions
	_monster_alive.assign(settled.get("monster_alive",[]))
	death_reason=settled.get("death_reason","")
	_crates = settled["crystals"]
	moves += 1
	pushes += pushed
	pulls += pulled
	swaps += swapped
	alive = settled["alive"]
	_hero_alive.assign(settled["hero_alive"])
	_pressure = settled["pressure"]
	_barriers = settled["barriers"]
	_last_attack_phase = settled.get("attack_phase",{}).duplicate(true)
	return &"committed" if alive else &"died"


func _settle_world(definition:Level,positions:Array[Vector2i],crystals:Dictionary,monsters:Array[Vector2i],living:Array[bool],previous:Dictionary,advance:bool=true) -> Dictionary:
	# Only living Goblins are confirmed pressure sources; other monster kinds
	# remain explicitly undefined when they encounter a plate.
	for i in monsters.size():
		if not living[i] or definition.monster_kinds[i]=="goblin":continue
		for link in definition.energy_links:
			if monsters[i] in link["plates"]:return {"error":"怪物压板规则尚未确认；该组合动作未提交。"}
	var settled:=Energy.settle(definition.energy_links,positions,crystals,previous,Energy.monster_clear_states(definition.monster_clear_barriers,living),_pressure_goblins(definition,monsters,living))
	if not settled["error"].is_empty() or monsters.is_empty():return settled
	var danger:=Monsters.settle(definition.monster_kinds,monsters,living,positions,settled["hero_alive"],previous,settled["barriers"],definition.has_fence,{"hero_kinds":_hero_kinds(definition),"facings":definition.monster_facings,"crystals":settled["crystals"],"bounds":Rect2i(Vector2i.ZERO,Vector2i(definition.width,definition.height)),"blocks":func(c:Vector2i)->bool:return not definition.is_floor(c) or definition.bush_at(c)!=null or settled["barriers"].get(c,false),"advance":advance})
	if not danger["error"].is_empty():return danger
	var attack_phase:Dictionary={"monster_alive":danger["attack_monster_alive"].duplicate(),"hero_alive":danger["attack_hero_alive"].duplicate(),"barriers":settled["barriers"].duplicate(),"crystals":settled["crystals"].duplicate()}
	if _hero_kinds(definition).has("yellow"):attack_phase["protected_heroes"]=danger["protected_heroes"].duplicate()
	# Attack deaths release Goblin-held plates in this SAME atomic action.
	# Recompute mechanisms and restoration victims, never another attack round.
	var final_living:Array[bool]=danger["monster_alive"].duplicate()
	var final_energy:=Energy.settle(definition.energy_links,positions,settled["crystals"],settled["barriers"],Energy.monster_clear_states(definition.monster_clear_barriers,final_living),_pressure_goblins(definition,monsters,final_living))
	if not final_energy["error"].is_empty():return final_energy
	for i in monsters.size():
		if final_living[i] and final_energy["barriers"].get(monsters[i],false) and not settled["barriers"].get(monsters[i],false):final_living[i]=false
	for h in positions.size():final_energy["hero_alive"][h]=final_energy["hero_alive"][h] and danger["hero_alive"][h]
	final_energy["alive"]=not final_energy["hero_alive"].has(false)
	# Plates and energy cells cannot overlap, so restoration-killed monsters
	# cannot release another plate. Only update the independent clear condition.
	final_energy["barriers"].merge(Energy.monster_clear_states(definition.monster_clear_barriers,final_living),true)
	final_energy["destroyed_crystals"].merge(settled["destroyed_crystals"])
	final_energy["monster_alive"]=final_living
	final_energy["attack_phase"]=attack_phase
	final_energy["death_reason"]="fire" if not danger.get("fire_heroes",[]).is_empty() else ("monster" if not danger["attacked_heroes"].is_empty() else ("energy" if not final_energy["alive"] else ""))
	return final_energy

static func _pressure_goblins(definition:Level,positions:Array[Vector2i],living:Array[bool]) -> Array[Vector2i]:
	var cells:Array[Vector2i]=[]
	for i in positions.size():
		if living[i] and definition.monster_kinds[i]=="goblin":cells.append(positions[i])
	return cells

static func _hero_kinds(definition:Level) -> PackedStringArray:
	var kinds:PackedStringArray=[]
	for hero in definition.hero_definitions:kinds.append(hero["kind"])
	return kinds

func protected_heroes() -> Array[bool]:
	return Protection.covered(_hero_kinds(level),_hero_positions,_hero_alive) if level!=null else []

func protection_covers(cell:Vector2i) -> bool:
	return level!=null and Protection.covers_cell(_hero_kinds(level),_hero_positions,_hero_alive,cell)

func attack_phase() -> Dictionary:
	return _last_attack_phase.duplicate(true)


func monster_at(cell:Vector2i) -> int:
	for i in _monster_positions.size():
		if _monster_alive[i] and _monster_positions[i]==cell:return i
	return -1


func monsters() -> Array[Dictionary]:
	var result:Array[Dictionary]=[]
	for i in _monster_positions.size():
		var entry:Dictionary={"id":i,"kind":level.monster_kinds[i],"position":_monster_positions[i],"alive":_monster_alive[i]}
		if level.monster_kinds[i]=="fire_dragon":entry["facing"]=_monster_facings[i]
		result.append(entry)
	return result


func living_monster_count() -> int:
	return _monster_alive.count(true)


func monster_danger_at(cell:Vector2i) -> bool:
	for i in _monster_positions.size():
		if _monster_alive[i] and Monsters.threatens(level.monster_kinds[i],cell,_monster_positions[i]) and not level.has_fence(cell,_monster_positions[i]):return true
	return false


func fire_rays() -> Array[Dictionary]:
	if level==null or not level.monster_kinds.has("fire_dragon"):return []
	return Fire.plan(level.monster_kinds,_monster_positions,_monster_alive,_monster_facings,_hero_positions,_hero_alive,_crates,Rect2i(Vector2i.ZERO,Vector2i(level.width,level.height)),blocks_sight,level.has_fence,protected_heroes())["rays"]


func fire_danger_at(cell:Vector2i) -> bool:
	for ray in fire_rays():
		if cell in ray["cells"]:return true
	return false


func undo() -> bool:
	if _history.is_empty():
		return false
	var previous: Dictionary = _history.pop_back()
	_restore(previous)
	return true


func restart() -> bool:
	if not alive:
		return false
	_history.clear()
	if level == null:
		return true
	active_hero_index = level.initial_active_hero
	_restore(_initial_state)
	return true


func is_complete() -> bool:
	if level == null or not alive:
		return false
	if level.objective == "all_heroes_on_exits":
		return occupied_exits() == _hero_positions.size()
	if level.objective == "player_on_exit":
		return player == level.exit_cell
	if level.objective != "all_crates_on_targets":
		return false
	for target in level.targets:
		if not _crates.has(target):
			return false
	return true


func hero_count() -> int:
	return _hero_positions.size()


func active_kind() -> String:
	return level.hero_definitions[active_hero_index]["kind"] if level != null else ""


func active_hero_id() -> String:
	return level.hero_definitions[active_hero_index]["id"] if level != null else ""


func hero_at(cell: Vector2i) -> int:
	return _hero_positions.find(cell)


func hero_position(index: int) -> Vector2i:
	return _hero_positions[index]


func hero_is_alive(index: int) -> bool:
	return _hero_alive[index]


func heroes() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if level != null:
		for index in _hero_positions.size():
			result.append({"id":level.hero_definitions[index]["id"],"kind":level.hero_definitions[index]["kind"],
				"position":_hero_positions[index],"alive":_hero_alive[index],"selected":index==active_hero_index})
	return result


func occupied_exits() -> int:
	var count := 0
	if level != null:
		for index in _hero_positions.size():
			if _hero_alive[index] and _hero_positions[index] in level.exit_cells:
				count += 1
	return count


func crates() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for cell: Vector2i in _crates:
		cells.append(cell)
	return cells


func crate_id(cell: Vector2i) -> int:
	# Identity remains stable across movement, undo, and restart.
	return _crates.get(cell, -1)


func occupied_targets() -> int:
	var count := 0
	if level != null:
		for target in level.targets:
			if _crates.has(target):
				count += 1
	return count


func history_size() -> int:
	return _history.size()


func is_walkable(cell: Vector2i) -> bool:
	if level == null or not level.is_floor(cell) or barrier_is_active(cell):
		return false
	var bush := level.bush_at(cell)
	return bush == null or not bush.BLOCKS_MOVEMENT


func barrier_is_active(cell: Vector2i) -> bool:
	return _barriers.get(cell, false)


func pressure_is_active(id: String) -> bool:
	return _pressure.get(id, false)


func pressure_cell_is_active(id: String, cell: Vector2i) -> bool:
	if level == null:
		return false
	for link in level.energy_links:
		if link["id"] == id and cell in link["plates"]:
			return Energy.pressure_matches(cell, link["pressure_sources"], _hero_positions, _crates, _pressure_goblins(level,_monster_positions,_monster_alive))
	return false


func pressure_progress(id: String) -> Vector2i:
	var count := Vector2i.ZERO
	if level != null:
		for link in level.energy_links:
			if link["id"] == id:
				count.y = link["plates"].size()
				for cell: Vector2i in link["plates"]:
					count.x += 1 if pressure_cell_is_active(id, cell) else 0
	return count


func pressure_states() -> Dictionary:
	return _pressure.duplicate()


func barrier_states() -> Dictionary:
	return _barriers.duplicate()


func blocks_sight(cell: Vector2i) -> bool:
	# Terrain query only: movable sight targets are a caller-level concern.
	if level == null or not level.is_floor(cell) or barrier_is_active(cell):
		return true
	var bush := level.bush_at(cell)
	return bush != null and bush.BLOCKS_SIGHT


func sight_path_is_clear(cells: Array[Vector2i]) -> bool:
	for cell in cells:
		if blocks_sight(cell):
			return false
	return true


func _restore(state: Dictionary) -> void:
	_last_attack_phase.clear()
	# Undo restores the world while retaining the user's current selection.
	if state.has("hero_positions"):
		_hero_positions.assign(state["hero_positions"])
	else:
		_hero_positions.assign([state["player"]])
	_monster_positions.assign(state.get("monster_positions",[]))
	_monster_alive.assign(state.get("monster_alive",[]))
	_monster_facings.assign(state.get("monster_facings",[]))
	death_reason=state.get("death_reason","")
	_crates = state["crates"].duplicate()
	moves = state["moves"]
	pushes = state["pushes"]
	pulls = state["pulls"]
	swaps = state.get("swaps",0)
	alive = state["alive"]
	_hero_alive.assign(state.get("hero_alive",[alive]))
	_pressure = state["pressure"].duplicate()
	_barriers = state["barriers"].duplicate()
	last_mechanism_error = ""


func snapshot() -> Dictionary:
	var result := {"crates":_crates.duplicate(),"moves":moves,"pushes":pushes,"pulls":pulls,"swaps":swaps,
		"alive":alive,"pressure":_pressure.duplicate(),"barriers":_barriers.duplicate()}
	if not _monster_positions.is_empty():
		result.merge({"monster_positions":_monster_positions.duplicate(),"monster_alive":_monster_alive.duplicate(),"death_reason":death_reason})
	if level!=null and level.monster_kinds.has("fire_dragon"):
		result["monster_facings"]=_monster_facings.duplicate()
	# Legacy single-hero snapshots retain their original shape.
	if _hero_positions.size() > 1:
		result.merge({"hero_positions":_hero_positions.duplicate(),"hero_alive":_hero_alive.duplicate()})
	else:
		result["player"] = player
	return result
