class_name SwapRules
extends RefCounted
## Bounded cardinal sight and a data-only exchange plan, independent of the world.

static func is_interactable(kind: Variant) -> bool:
	return kind in [&"hero", &"crystal"]

static func first_target(origin: Vector2i, direction: Vector2i, bounds: Rect2i, blocks_sight: Callable, occupant_at: Callable) -> Dictionary:
	if absi(direction.x)+absi(direction.y)!=1:
		return {"result": &"invalid_direction"}
	var cell:=origin+direction
	while bounds.has_point(cell):
		if blocks_sight.call(cell):
			return {"result": &"swap_blocked", "cell":cell}
		var occupant: Dictionary=occupant_at.call(cell)
		if is_interactable(occupant.get("kind")):
			return {"result": &"target", "cell":cell, "kind":occupant["kind"], "id":occupant.get("id",-1)}
		cell+=direction
	return {"result": &"no_target"}

static func exchange_plan(origin: Vector2i, target: Dictionary) -> Dictionary:
	if target.get("result")!=&"target" or not target.get("cell") is Vector2i or not is_interactable(target.get("kind")):
		return {"result": &"invalid_target"}
	return {"result": &"swapped", "player":target["cell"], "target_cell":origin,
		"target_kind":target["kind"], "target_id":target["id"]}
