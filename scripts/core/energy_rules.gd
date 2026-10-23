class_name EnergyRules
extends RefCounted
## Pure post-action settlement. Callers commit only a fully defined result.


static func pressure_matches(cell: Vector2i, sources: Array, hero: Vector2i, crystals: Dictionary) -> bool:
	return ("hero" in sources and hero == cell) or ("crystal" in sources and crystals.has(cell))


static func settle(links: Array[Dictionary], hero: Vector2i, crystals: Dictionary, previous_barriers: Dictionary) -> Dictionary:
	var pressure: Dictionary = {}
	var barriers: Dictionary = {}
	var alive := true
	var all_pressed := true
	for link in links:
		var pressed := true
		for plate: Vector2i in link["plates"]:
			pressed = pressed and pressure_matches(plate, link["pressure_sources"], hero, crystals)
		pressure[link["id"]] = pressed
		all_pressed = all_pressed and pressed
	# Link IDs describe data and local occupancy, never independent doors.
	# Every energy barrier uses the same all-pressure-plates AND result.
	for link in links:
		for cell: Vector2i in link["barriers"]:
			barriers[cell] = not all_pressed
	# All occupancy and pressure are computed before evaluating consequences.
	for cell: Vector2i in barriers:
		if not barriers[cell]:
			continue
		if crystals.has(cell):
			return {"error": "能量屏障恢复格 %s 有水晶：该行为尚未确认，动作未提交。" % str(cell)}
		if not previous_barriers.get(cell, false) and hero == cell:
			alive = false
	return {"error": "", "pressure": pressure, "barriers": barriers, "alive": alive}
