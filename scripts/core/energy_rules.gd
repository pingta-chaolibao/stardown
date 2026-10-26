class_name EnergyRules
extends RefCounted
## Pure post-action settlement. Callers atomically commit returned occupancy and life.
## Monster life is applied by MonsterRules after shared energy settlement.
const RESTORATION_EFFECTS := {&"hero": &"killed", &"monster": &"killed", &"crystal": &"destroyed"}


static func pressure_matches(cell: Vector2i, sources: Array, hero: Variant, crystals: Dictionary, living_goblins: Array[Vector2i] = []) -> bool:
	var hero_present: bool = cell in hero if hero is Array else hero == cell
	# Goblins are a confirmed global pressure source. The legacy source filter
	# still selects hero/crystal participation without migrating old level JSON.
	return ("hero" in sources and hero_present) or ("crystal" in sources and crystals.has(cell)) or cell in living_goblins


static func monster_clear_states(cells: Array[Vector2i], living: Array[bool]) -> Dictionary:
	var result: Dictionary = {}
	for cell in cells:
		result[cell] = living.has(true) # Zero initial monsters means already clear.
	return result


static func settle(links: Array[Dictionary], hero: Variant, crystals: Dictionary, previous_barriers: Dictionary, other_barriers: Dictionary = {}, living_goblins: Array[Vector2i] = []) -> Dictionary:
	var pressure: Dictionary = {}
	var barriers: Dictionary = {}
	var alive := true
	var remaining := crystals.duplicate()
	var destroyed: Dictionary = {}
	var positions: Array = hero if hero is Array else [hero]
	var hero_alive: Array[bool] = []
	for _cell in positions:
		hero_alive.append(true)
	var all_pressed := true
	for link in links:
		var pressed := true
		for plate: Vector2i in link["plates"]:
			pressed = pressed and pressure_matches(plate, link["pressure_sources"], hero, crystals, living_goblins)
		pressure[link["id"]] = pressed
		all_pressed = all_pressed and pressed
	# Link IDs describe data and local occupancy, never independent doors.
	# Every energy barrier uses the same all-pressure-plates AND result.
	for link in links:
		for cell: Vector2i in link["barriers"]:
			barriers[cell] = not all_pressed
	barriers.merge(other_barriers)
	# All occupancy and pressure are computed before evaluating consequences.
	for cell: Vector2i in barriers:
		if not barriers[cell]:
			continue
		if crystals.has(cell):
			# A disappearance->reappearance edge destroys crystals, never a cold
			# initialization or a barrier that was already active.
			if not previous_barriers.has(cell) or previous_barriers[cell]:
				return {"error": "水晶不能位于已激活的能量格 %s。" % str(cell)}
			destroyed[cell] = remaining[cell]
			remaining.erase(cell)
		if not previous_barriers.get(cell, false):
			for index in positions.size():
				if positions[index] == cell:
					hero_alive[index] = false
					alive = false
	return {"error": "", "pressure": pressure, "barriers": barriers, "alive": alive, "hero_alive":hero_alive, "crystals":remaining, "destroyed_crystals":destroyed}
