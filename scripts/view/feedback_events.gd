class_name FeedbackEvents
extends RefCounted
## Read-only adapter: immutable before/after identities -> presentation events.
## No gameplay mutation, timer, damage or collision is performed here.
const Fire = preload("res://scripts/core/fire_rules.gd")
const Monsters = preload("res://scripts/core/monster_rules.gd")

static func capture(model: RefCounted) -> Dictionary:
	var entities: Dictionary = {}
	for hero in model.heroes():
		var entry: Dictionary = hero.duplicate(true)
		entry["role"] = "hero"
		entities["h:" + str(hero["id"])] = entry
	for cell in model.crates():
		var identity: int = model.crate_id(cell)
		entities["c:" + str(identity)] = {"id":identity,"role":"crystal","kind":"crystal","position":cell,"alive":true,"color":model.level.crystal_colors[identity]}
	for monster in model.monsters():
		var entry: Dictionary = monster.duplicate(true)
		entry["role"] = "monster"
		entities["m:" + str(monster["id"])] = entry
	var plates: Dictionary = {}
	for link in model.level.energy_links:
		for cell: Vector2i in link["plates"]:
			plates[cell] = model.pressure_cell_is_active(link["id"],cell)
	return {"entities":entities,"barriers":model.barrier_states(),"plates":plates,
		"world":model.snapshot(),"complete":model.is_complete(),"active":"h:"+model.active_hero_id(),"player":model.player,"kind":model.active_kind()}

static func action(before: Dictionary, model: RefCounted, direction: Vector2i) -> Dictionary:
	var after := capture(model)
	if after["world"]["moves"] != before["world"]["moves"] + 1:
		return {} # Failed input/selection/undo never creates an attack round.
	var plan: Dictionary = {"before":before["entities"],"after":after["entities"].duplicate(true),
		"motion":{},"energy":[],"plates":[],"deaths":[],"sight":[],"fire":[],"goblin":[],
		"swap":after["world"]["swaps"]>before["world"]["swaps"],
		"contact":after["world"]["pushes"]>before["world"]["pushes"] or after["world"]["pulls"]>before["world"]["pulls"],
		"victory":after["complete"] and not before["complete"]}
	for cell: Vector2i in after["barriers"]:
		if before["barriers"].get(cell) != after["barriers"][cell]:
			plan["energy"].append({"cell":cell,"active":after["barriers"][cell]})
	for cell: Vector2i in after["plates"]:
		if before["plates"].get(cell) != after["plates"][cell]:
			plan["plates"].append({"cell":cell,"pressed":after["plates"][cell]})
	for key: String in before["entities"]:
		var old: Dictionary = before["entities"][key]
		if not old["alive"]:
			continue
		if not plan["after"].has(key):
			# A removed crystal may have moved before restoration destroyed it.
			var ghost := old.duplicate(true)
			ghost["alive"] = false
			ghost["position"] = _removed_crystal_destination(key,before,after,direction)
			plan["after"][key] = ghost
		var current: Dictionary = plan["after"][key]
		if old["position"] != current["position"]:
			plan["motion"][key] = {"from":Vector2(old["position"]),"to":Vector2(current["position"])}
		if not current["alive"]:
			plan["deaths"].append({"key":key,"entity":current.duplicate(true),"energy":_restored_at(current["position"],before,after)})
	_sample_attacks(plan,before,after,model)
	return plan

static func _restored_at(cell: Vector2i, before: Dictionary, after: Dictionary) -> bool:
	return after["barriers"].get(cell,false) and not before["barriers"].get(cell,true)

static func _removed_crystal_destination(key: String, before: Dictionary, after: Dictionary, direction: Vector2i) -> Vector2i:
	var cell: Vector2i = before["entities"][key]["position"]
	if after["world"]["swaps"] > before["world"]["swaps"]:
		return before["player"] # The sole absent exchange target was destroyed.
	if before["kind"] == "green" and after["world"]["pulls"] > before["world"]["pulls"] and cell == before["player"]-direction:
		return before["player"]
	if after["world"]["pushes"] > before["world"]["pushes"]:
		var occupied: Dictionary = {}
		for entry in before["entities"].values():
			if entry["alive"]: occupied[entry["position"]] = true
		var cursor: Vector2i = before["player"]+direction
		while occupied.has(cursor):
			if cursor == cell: return cell+direction
			cursor += direction
	return cell

static func _sample_attacks(plan: Dictionary, before: Dictionary, after: Dictionary, model: RefCounted) -> void:
	# Reuse the exact pure ray query on the common post-move/post-energy state,
	# with pre-attack life. Same-step dead attackers still have their one attack.
	var hero_positions: Array[Vector2i] = []
	var hero_lives: Array[bool] = []
	for hero in model.heroes():
		var key: String = "h:"+str(hero["id"])
		hero_positions.append(hero["position"])
		hero_lives.append(before["entities"][key]["alive"] and not _restored_at(hero["position"],before,after))
	var monster_positions: Array[Vector2i] = []
	var monster_lives: Array[bool] = []
	var facings: Array[Vector2i] = []
	for monster in model.monsters():
		monster_positions.append(monster["position"])
		monster_lives.append(before["entities"]["m:"+str(monster["id"])]["alive"] and not _restored_at(monster["position"],before,after))
		facings.append(monster.get("facing",Vector2i.ZERO))
	var crystals: Dictionary = {}
	for cell in model.crates(): crystals[cell] = model.crate_id(cell)
	var rays := Fire.plan(model.level.monster_kinds,monster_positions,monster_lives,facings,hero_positions,hero_lives,crystals,
		Rect2i(Vector2i.ZERO,Vector2i(model.level.width,model.level.height)),model.blocks_sight,model.level.has_fence)
	for ray in rays["rays"]:
		var event: Dictionary = ray.duplicate(true)
		event["from"] = monster_positions[ray["dragon"]]
		event["facing"] = facings[ray["dragon"]]
		# Preserve every locked sight ray for the existing danger overlay.
		# Only an actual target contributes an attack or its waiting stage.
		plan["sight"].append(event)
		if ray["target"].is_empty(): continue
		plan["fire"].append(event)
	for i in monster_positions.size():
		if not monster_lives[i] or model.level.monster_kinds[i] != "goblin": continue
		for h in hero_positions.size():
			if hero_lives[h] and Monsters.threatens("goblin",monster_positions[i],hero_positions[h]):
				plan["goblin"].append({"from":monster_positions[i],"to":hero_positions[h]})
		for m in monster_positions.size():
			if monster_lives[m] and model.level.monster_kinds[m] == "fire_dragon" and Monsters.threatens("goblin",monster_positions[i],monster_positions[m]):
				plan["goblin"].append({"from":monster_positions[i],"to":monster_positions[m]})
