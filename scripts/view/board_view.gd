class_name BoardView
extends Control
## Original procedural 2D artwork. This view only reads the grid model.

signal feedback_finished
const Timeline = preload("res://scripts/view/feedback_timeline.gd")
const Events = preload("res://scripts/view/feedback_events.gd")

const State = preload("res://scripts/core/grid_state.gd")
const CORAL := Color("f5787b")
const HERO_GREEN := Color("72ce95")
const HERO_BLUE := Color("78aff0")
const HERO_PURPLE := Color("bd9bf0")
const MECHANISM_GREEN := Color("78d799")
const MECHANISM_BLUE := Color("7dbce9")
const MECHANISM_PURPLE := Color("bc9af3")
const MECHANISM_RED := Color("ef8b83")
const GOLD := Color("dfbb78")
const GOAL_PURPLE := Color("c4a0f3")
const GOAL_BLUE := Color("85bef5")
const GOAL_ORANGE := Color("efac71")
const MINT := Color("9bc9c1")

var model: State
var facing := Vector2i.DOWN
var blocked: bool = false
var feedback := Timeline.new()
var idle_clock: float = 0.0
var _entity_alpha: float = 1.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)


func _process(delta: float) -> void:
	if not is_visible_in_tree(): return
	idle_clock = fmod(idle_clock+delta,TAU*10.0)
	if feedback.advance(delta): feedback_finished.emit()
	queue_redraw()


func cancel_feedback() -> void:
	feedback.cancel()
	blocked = false
	queue_redraw()


func play_action(before: Dictionary, direction: Vector2i) -> void:
	feedback.start(Events.action(before,model,direction))
	queue_redraw()


func _draw() -> void:
	if model == null or model.level == null:
		return
	var level := model.level
	var tile := minf(72.0, minf((size.x - 32) / level.width, (size.y - 24) / level.height))
	if tile <= 0:
		return
	var extent := Vector2(level.width, level.height) * tile
	var origin := (size - extent) / 2
	_box(Rect2(origin - Vector2(10, 10), extent + Vector2(20, 25)), Color("0c1924"), 16)
	for y in level.height:
		for x in level.width:
			var cell := Vector2i(x, y)
			var rect := Rect2(origin + Vector2(cell) * tile + Vector2(2, 2), Vector2.ONE * (tile - 4))
			if level.is_floor(cell):
				_floor(rect, cell)
			elif not level.is_void(cell):
				_wall(rect)
	for cell in level.targets:
		_target(origin + (Vector2(cell) + Vector2.ONE * 0.5) * tile, tile)
	for link in level.energy_links:
		for plate: Vector2i in link["plates"]:
			var center := origin + (Vector2(plate) + Vector2.ONE * 0.5) * tile
			_pressure_plate(center, tile, model.pressure_cell_is_active(link["id"], plate))
	for bush in level.bushes:
		_bush(origin + (Vector2(bush.cell) + Vector2.ONE * 0.5) * tile, tile)
	for cell: Vector2i in model.barrier_states():
		var center := origin + (Vector2(cell) + Vector2.ONE * 0.5) * tile
		if not model.barrier_is_active(cell): _inactive_energy_floor(center,tile,cell in level.monster_clear_barriers)
		_draw_energy_transition(cell,center,tile)
	for cell in level.exit_cells:
		_exit_marker(origin + (Vector2(cell) + Vector2.ONE * 0.5) * tile, tile)
	for edge in level.fence_edges:
		_fence(origin, tile, edge["a"], edge["b"])
	if not level.initial_monsters.is_empty():
		for y in level.height:
			for x in level.width:
				var cell:=Vector2i(x,y)
				if level.is_floor(cell) and model.monster_danger_at(cell):_danger(origin+(Vector2(cell)+Vector2.ONE*0.5)*tile,tile)
	# During playback use the pre-death locked rays, never a rescan through a victim.
	var rays: Array = feedback.plan.get("sight",model.fire_rays())
	for ray in rays:
		for cell in ray["cells"]:
			_fire_danger(origin+(Vector2(cell)+Vector2.ONE*0.5)*tile,tile,model.monsters()[ray["dragon"]]["facing"])
	var entities: Dictionary = Events.capture(model)["entities"]
	for key: String in feedback.plan.get("after",{}):
		if not entities.has(key): entities[key] = feedback.plan["after"][key]
	# Stable layering: monster ghosts below crystals, heroes above both.
	for role in ["monster","crystal","hero"]:
		for key: String in entities:
			if entities[key]["role"] == role: _draw_entity(key,entities[key],origin,tile)
	_draw_feedback(origin,tile)
	# The footprint stays flat beneath occupants; only its outer dashes sit above
	# them, so a selection ring/shadow cannot hide a passable energy cell.
	for cell: Vector2i in model.barrier_states():
		if not model.barrier_is_active(cell):
			_inactive_energy_border(origin + (Vector2(cell) + Vector2.ONE * 0.5) * tile, tile,cell in level.monster_clear_barriers)


func _danger(center:Vector2,tile:float) -> void:
	var r:=Rect2(center-Vector2.ONE*tile*0.43,Vector2.ONE*tile*0.86)
	draw_rect(r,Color(0.8,0.25,0.12,0.13));draw_rect(r,Color(0.9,0.42,0.24,0.55),false,1.3)
	# Four marked corners identify a cell, without shading diagonal neighbors.
	for v in [Vector2(-1,-1),Vector2(1,-1),Vector2(-1,1),Vector2(1,1)]:
		var p:Vector2=center+v*tile*0.34
		draw_line(p,p-Vector2(v.x,0)*tile*0.08,Color("c56e4e"),1.5,true)


func _goblin(center:Vector2,tile:float,living:bool) -> void:
	if not living:
		_actor_arc(center+Vector2(0,0.22)*tile,tile*0.20,0,TAU,12,Color(0.6,0.4,0.3,0.28),1.2,true)
		return # A non-interactive trace, drawn beneath any new occupant.
	draw_ellipse_shadow(center+Vector2(0,0.29)*tile,Vector2(tile*0.34,tile*0.12))
	var shape:=PackedVector2Array([center+Vector2(-0.30,0.25)*tile,center+Vector2(-0.28,-0.16)*tile,center+Vector2(-0.37,-0.37)*tile,center+Vector2(-0.12,-0.24)*tile,center+Vector2(0.12,-0.24)*tile,center+Vector2(0.37,-0.37)*tile,center+Vector2(0.28,-0.16)*tile,center+Vector2(0.30,0.25)*tile])
	_actor_polygon(shape,Color("482e35"));var outline:=shape.duplicate();outline.append(shape[0]);_actor_polyline(outline,Color("ce805c"),maxf(1.4,tile*0.027),true)
	for x in [-0.13,0.13]:
		_actor_circle(center+Vector2(x,-0.05)*tile,tile*0.064,Color("ffbd74"))
		_actor_line(center+Vector2(x,-0.095)*tile,center+Vector2(x,-0.015)*tile,Color("301a23"),maxf(1,tile*0.025),true)
	_actor_line(center+Vector2(-0.13,0.14)*tile,center+Vector2(0.13,0.14)*tile,Color("ecb39a"),tile*0.03,true)
	for x in [-0.07,0.07]:_actor_line(center+Vector2(x,0.12)*tile,center+Vector2(x,0.19)*tile,Color("ecb39a"),tile*0.025,true)


func _fence(origin: Vector2,tile: float,a: Vector2i,b: Vector2i) -> void:
	var center := origin+(Vector2(a)+Vector2(b)+Vector2.ONE)*tile*0.5
	var normal := Vector2(b-a)
	var tangent := Vector2(normal.y,-normal.x)
	var length := tile*0.43
	draw_line(center-tangent*length,center+tangent*length,Color("07111b"),tile*0.15,true)
	for sign_y in [-1,1]:
		var rail: Vector2 = center+normal*tile*0.035*sign_y
		draw_line(rail-tangent*length,rail+tangent*length,Color("abc4d3"),clampf(tile*0.027,1.4,2.0),true)
	for offset in [-0.41,-0.20,0.0,0.20,0.41]:
		var post: Vector2 = center+tangent*tile*offset
		draw_line(post-normal*tile*0.09,post+normal*tile*0.09,Color("6e94aa"),clampf(tile*0.04,1.8,3.0),true)
		draw_circle(post,tile*0.021,Color("e0c893"))


func _bush(center: Vector2, tile: float) -> void:
	draw_ellipse_shadow(center + Vector2(0, tile * 0.25), Vector2(tile * 0.37, tile * 0.13))
	for offset in [Vector2(-0.20, 0.04), Vector2(0.18, 0.02), Vector2(0, -0.17), Vector2(0, 0.17)]:
		draw_circle(center + offset * tile, tile * 0.24, Color("325c42"))
	for offset in [Vector2(-0.14, -0.02), Vector2(0.15, -0.04), Vector2(0, -0.19)]:
		draw_circle(center + offset * tile, tile * 0.18, Color("568451"))
	for offset in [-0.15, 0.03, 0.20]:
		draw_line(center + Vector2(offset - 0.07, 0.14) * tile, center + Vector2(offset + 0.03, -0.07) * tile, Color("a1b76a"), tile * 0.025, true)


func _pressure_plate(center: Vector2, tile: float, pressed: bool) -> void:
	var green := model.level.mechanism_color == "green"
	var base := (Color("4da66e") if pressed else Color("315a47")) if green else (Color("c7a34d") if pressed else Color("74613c"))
	var light := Color("c6ffd5") if green else Color("ffe6a0")
	if model.level.mechanism_color == "blue":
		base = Color("4c90c1") if pressed else Color("355775")
		light = Color("c8eaff")
	if model.level.mechanism_color == "purple":
		base = Color("9164bf") if pressed else Color("58436f")
		light = Color("e9d4ff")
	_box(Rect2(center - Vector2.ONE * tile * 0.4, Vector2.ONE * tile * 0.8), base, 5)
	draw_arc(center, tile * 0.24, 0, TAU, 32, light, 2, true)
	if pressed:
		draw_circle(center, tile * 0.15, light)


func _energy_block(center: Vector2, tile: float, clear:bool=false) -> void:
	if clear or model.level.mechanism_color == "red":
		_box(Rect2(center - Vector2.ONE * tile * 0.43, Vector2.ONE * tile * 0.86), Color("914e4a"), 5)
		_box(Rect2(center - Vector2.ONE * tile * 0.34, Vector2.ONE * tile * 0.68), MECHANISM_RED, 3)
		for offset in [-0.20, 0.0, 0.20]:
			_actor_line(center + Vector2(offset, -0.28) * tile, center + Vector2(offset, 0.28) * tile, Color("ffe2da"), tile * 0.035, true)
		return
	var green := model.level.mechanism_color == "green"
	var blue := model.level.mechanism_color == "blue"
	var purple := model.level.mechanism_color == "purple"
	_box(Rect2(center - Vector2.ONE * tile * 0.43, Vector2.ONE * tile * 0.86), Color("6b4293") if purple else (Color("376e9b") if blue else (Color("3e845b") if green else Color("ba923c"))), 5)
	_box(Rect2(center - Vector2.ONE * tile * 0.34, Vector2.ONE * tile * 0.68), MECHANISM_PURPLE if purple else (MECHANISM_BLUE if blue else (MECHANISM_GREEN if green else Color("f2ce6d"))), 3)
	for offset in [-0.20, 0.0, 0.20]:
		_actor_line(center + Vector2(offset, -0.28) * tile, center + Vector2(offset, 0.28) * tile, Color("f4e8ff") if purple else (Color("e1f5ff") if blue else (Color("dbffe6") if green else Color("fff0b5"))), tile * 0.035, true)


func _mechanism_tint(clear:bool=false) -> Color:
	if clear:return MECHANISM_RED
	if model.level.mechanism_color == "red":
		return MECHANISM_RED
	if model.level.mechanism_color == "purple":
		return MECHANISM_PURPLE
	if model.level.mechanism_color == "blue":
		return MECHANISM_BLUE
	return MECHANISM_GREEN if model.level.mechanism_color == "green" else GOLD


func _inactive_energy_floor(center: Vector2, tile: float, clear:bool=false) -> void:
	var tint := _mechanism_tint(clear)
	draw_rect(Rect2(center - Vector2.ONE * tile * 0.38, Vector2.ONE * tile * 0.76), Color(tint, 0.045))
	for offset in [-0.24, -0.12, 0.0, 0.12, 0.24]:
		draw_line(center + Vector2(offset - 0.09, -0.17) * tile, center + Vector2(offset + 0.09, 0.17) * tile, Color(tint, 0.16), 1.0, true)


func _inactive_energy_border(center: Vector2, tile: float, clear:bool=false) -> void:
	var tint := _mechanism_tint(clear)
	var corners := PackedVector2Array([
		center + Vector2(-0.43, -0.43) * tile, center + Vector2(0.43, -0.43) * tile,
		center + Vector2(0.43, 0.43) * tile, center + Vector2(-0.43, 0.43) * tile,
	])
	for side in 4:
		var start := corners[side]
		var edge := corners[(side + 1) % 4] - start
		for dash in 5:
			var a := start + edge * ((dash + 0.12) / 5.0)
			var b := start + edge * ((dash + 0.68) / 5.0)
			draw_line(a, b, Color(tint, 0.66), clampf(tile * 0.025, 1.25, 2.0), true)


func _floor(rect: Rect2, cell: Vector2i) -> void:
	var tint := Color("213542") if (cell.x + cell.y) % 2 == 0 else Color("20333f")
	_box(rect, tint, 5)
	draw_line(rect.position + Vector2(5, 0), rect.position + Vector2(rect.size.x - 5, 0), Color("2b4350"), 1)
	if (cell.x * 7 + cell.y * 3) % 5 == 0:
		draw_circle(rect.get_center() + rect.size * Vector2(0.18, 0.18), 1, Color("3c5661"))


func _wall(rect: Rect2) -> void:
	_box(Rect2(rect.position + Vector2(0, 4), rect.size), Color("0a1722"), 5)
	_box(rect, Color("364a59"), 5)
	_box(Rect2(rect.position + Vector2(3, 3), Vector2(rect.size.x - 6, rect.size.y * 0.6)), Color("405766"), 3)
	draw_line(rect.position + Vector2(7, 3), rect.position + Vector2(rect.size.x - 7, 3), Color("5b7280"), 1)
	draw_line(rect.position + Vector2(8, rect.size.y - 9), rect.end - Vector2(8, 9), Color("2c3e4e"), 2)


func _target(center: Vector2, tile: float) -> void:
	var radius := tile * 0.30
	draw_circle(center, radius, Color(0.87, 0.73, 0.47, 0.09))
	draw_arc(center, radius, 0, TAU, 48, Color(GOLD, 0.7), 1.5, true)
	var points := PackedVector2Array([
		center + Vector2(0, -radius * 0.6), center + Vector2(radius * 0.6, 0),
		center + Vector2(0, radius * 0.6), center + Vector2(-radius * 0.6, 0),
	])
	draw_colored_polygon(points, GOLD)
	for sign_x in [-1, 1]:
		for sign_y in [-1, 1]:
			var corner := center + Vector2(sign_x, sign_y) * tile * 0.36
			draw_line(corner, corner - Vector2(sign_x * tile * 0.10, 0), GOLD, 1.5, true)
			draw_line(corner, corner - Vector2(0, sign_y * tile * 0.10), GOLD, 1.5, true)


func _exit_marker(center: Vector2, tile: float) -> void:
	var rect := Rect2(center - Vector2.ONE * tile * 0.4, Vector2.ONE * tile * 0.8)
	if model.level.exit_color == "orange":
		draw_circle(center, tile * 0.36, Color("714a32"))
		draw_arc(center, tile * 0.30, 0, TAU, 48, GOAL_ORANGE, 3, true)
		draw_circle(center, tile * 0.16, Color("ffe0bc"))
		return
	if model.level.exit_color=="red":
		draw_circle(center,tile*0.36,Color("733f4d"))
		draw_arc(center,tile*0.31,0,TAU,48,CORAL,3,true)
		draw_circle(center,tile*0.14,Color("ef9ba2"))
		return
	if model.level.exit_color=="blue":
		draw_circle(center,tile*0.36,Color("36516e"))
		draw_arc(center,tile*0.30,0,TAU,48,GOAL_BLUE,3,true)
		draw_circle(center,tile*0.16,Color("d3eaff"))
		return
	if model.level.exit_color=="purple":
		draw_circle(center,tile*0.36,Color("51406d"))
		draw_arc(center,tile*0.30,0,TAU,48,GOAL_PURPLE,3,true)
		draw_circle(center,tile*0.16,Color("e8d8ff"))
		return
	if model.level.exit_color == "green":
		_box(rect, Color("286447"), 5)
		_box(rect.grow(-tile * 0.05), Color("4ba66e"), 3)
		draw_circle(center, tile * 0.22, Color("c6ffd5"))
		draw_circle(center, tile * 0.12, Color("78dd99"))
		return
	_box(rect, Color("95783d"), 5)
	_box(rect.grow(-tile * 0.05), Color("d8b45f"), 3)
	var points := PackedVector2Array([
		center + Vector2(0, -0.23) * tile, center + Vector2(0.18, 0) * tile,
		center + Vector2(0, 0.23) * tile, center + Vector2(-0.18, 0) * tile,
	])
	draw_colored_polygon(points, Color("fff0b3"))


func _crystal(center: Vector2, tile: float, variant: String) -> void:
	var base := Color("77cef1") if variant == "blue" else Color("bd9bf0")
	var dark := Color("35689e") if variant == "blue" else Color("6951a5")
	var light := Color("c6f4ff") if variant == "blue" else Color("e7d7ff")
	if variant=="blue_purple":
		base=Color("8e9fee")
		dark=Color("515fb3")
		light=Color("dbe2ff")
	elif variant=="orange":
		base=Color("ffba74")
		dark=Color("aa6034")
		light=Color("ffe1b7")
	elif variant=="pink":
		base=Color("e99cc7")
		dark=Color("9d527f")
		light=Color("ffdaed")
	elif variant=="purple_pink":
		base=Color("c79cdd")
		dark=Color("83528e")
		light=Color("f7d7f4")
	draw_ellipse_shadow(center + Vector2(0, tile * 0.27), Vector2(tile * 0.29, tile * 0.10))
	var top := center + Vector2(0.02, -0.37) * tile
	var left := center + Vector2(-0.27, -0.08) * tile
	var right := center + Vector2(0.25, -0.11) * tile
	var bottom := center + Vector2(-0.01, 0.31) * tile
	var middle := center + Vector2(0.02, -0.02) * tile
	_actor_polygon(PackedVector2Array([top, right, bottom, left]), base)
	_actor_polygon(PackedVector2Array([top, middle, left]), light)
	_actor_polygon(PackedVector2Array([middle, right, bottom]), dark)
	_actor_polygon(PackedVector2Array([middle, bottom, left]), base.darkened(0.08))
	_actor_line(top, middle, Color(light, 0.9), tile * 0.025, true)
	_actor_line(middle, bottom, Color(light, 0.65), tile * 0.02, true)


func _hero(center: Vector2, tile: float, kind: String, selected: bool) -> void:
	var green := kind == "green"
	var tint := HERO_GREEN if green else CORAL
	var shade := Color("3e9967") if green else Color("d45568")
	if kind=="blue":
		tint=HERO_PURPLE if model.level.swap_hero_color=="purple" else HERO_BLUE
		shade=Color("7652a8") if model.level.swap_hero_color=="purple" else Color("416fae")
	var multi:=model.hero_count()>1
	if multi and not selected:
		tint=tint.darkened(0.35)
		shade=shade.darkened(0.35)
	elif multi:
		var ring:=PackedVector2Array()
		for i in 49:
			var angle:=float(i)/48*TAU
			ring.append(center+Vector2(cos(angle)*0.39,sin(angle)*0.12+0.32)*tile)
		_actor_polyline(ring,Color("f4e2b5"),2.5,true)
	draw_ellipse_shadow(center + Vector2(0, tile * 0.29), Vector2(tile * 0.25, tile * 0.09))
	if blocked and selected:
		_actor_arc(center, tile * 0.41, 0, TAU, 40, Color(GOLD, 0.55), 1.5, true)
	var body := PackedVector2Array([
		center + Vector2(-0.12, -0.05) * tile, center + Vector2(0.12, -0.05) * tile,
		center + Vector2(0.19, 0.24) * tile, center + Vector2(-0.19, 0.24) * tile,
	])
	if multi and selected:
		var outline:=body.duplicate()
		outline.append(body[0])
		_actor_polyline(outline,Color("fff1cb"),3.5,true)
		_actor_arc(center+Vector2(0,-0.21)*tile,tile*0.15,0,TAU,32,Color("fff1cb"),2,true)
	_actor_polygon(body, tint)
	_actor_line(center + Vector2(-0.10, 0.18) * tile, center + Vector2(-0.12, 0.32) * tile, shade, tile * 0.08, true)
	_actor_line(center + Vector2(0.10, 0.18) * tile, center + Vector2(0.12, 0.32) * tile, shade, tile * 0.08, true)
	_actor_line(center + Vector2(-0.13, 0) * tile, center + Vector2(-0.23, 0.12) * tile, tint, tile * 0.075, true)
	_actor_line(center + Vector2(0.13, 0) * tile, center + Vector2(0.23, 0.12) * tile, tint, tile * 0.075, true)
	_actor_circle(center + Vector2(0, -0.21) * tile, tile * 0.13, tint)
	_actor_circle(center + Vector2(0, -0.21) * tile + Vector2(facing if selected else Vector2i.DOWN) * tile * 0.05, tile * 0.025, Color("ffe2c6"))
	_actor_line(center + Vector2(-0.11, 0.04) * tile, center + Vector2(0.11, 0.04) * tile, Color("d8ecff") if kind=="blue" else (Color("c5efbb") if green else Color("ffc3a1")), tile * 0.035, true)


func draw_ellipse_shadow(center: Vector2, radius: Vector2) -> void:
	var points := PackedVector2Array()
	for i in 32:
		var angle := float(i) / 32 * TAU
		points.append(center + Vector2(cos(angle), sin(angle)) * radius)
	_actor_polygon(points, Color(0.025, 0.07, 0.10, 0.8))


func _box(rect: Rect2, color: Color, radius: int) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(color,color.a*_entity_alpha)
	style.set_corner_radius_all(radius)
	draw_style_box(style, rect)


func _fire_danger(center:Vector2,tile:float,direction:Vector2i) -> void:
	var d:=Vector2(direction)
	var side:=Vector2(-d.y,d.x)
	draw_rect(Rect2(center-Vector2.ONE*tile*0.42,Vector2.ONE*tile*0.84),Color(0.96,0.40,0.13,0.13))
	for offset in [-0.26,0.23]:
		var a:Vector2=center+d*tile*offset
		draw_line(a-d*tile*0.10-side*tile*0.08,a,Color(1.0,0.67,0.32,0.45),1.4,true)
		draw_line(a-d*tile*0.10+side*tile*0.08,a,Color(1.0,0.67,0.32,0.45),1.4,true)


func _fire_dragon(center:Vector2,tile:float,living:bool,direction:Vector2i) -> void:
	var d:=Vector2(direction)
	var side:=Vector2(-d.y,d.x)
	if not living:
		_actor_arc(center,tile*0.23,0,TAU,12,Color(0.65,0.45,0.27,0.28),1.2,true)
		return
	draw_ellipse_shadow(center+Vector2(0,tile*0.28),Vector2(tile*0.36,tile*0.11))
	var points:=PackedVector2Array([center-d*tile*0.30-side*tile*0.17,center-d*tile*0.12-side*tile*0.34,center+d*tile*0.10-side*tile*0.25,center+d*tile*0.34,center+d*tile*0.10+side*tile*0.25,center-d*tile*0.12+side*tile*0.34,center-d*tile*0.30+side*tile*0.17])
	_actor_polygon(points,Color("6b3b37"))
	var outline:=points.duplicate();outline.append(points[0])
	_actor_polyline(outline,Color("ee965b"),maxf(1.6,tile*0.03),true)
	for sign_y in [-1,1]:_actor_circle(center+d*tile*0.05+side*tile*0.12*sign_y,tile*0.042,Color("ffe4a1"))
	# The fixed-facing arrow stays inside the monster cell, above the head.
	_actor_line(center-d*tile*0.14,center+d*tile*0.22,Color("fff0b8"),maxf(2,tile*0.035),true)
	_actor_line(center+d*tile*0.12-side*tile*0.08,center+d*tile*0.22,Color("fff0b8"),maxf(2,tile*0.035),true)
	_actor_line(center+d*tile*0.12+side*tile*0.08,center+d*tile*0.22,Color("fff0b8"),maxf(2,tile*0.035),true)


func _draw_entity(key: String, entity: Dictionary, origin: Vector2, tile: float) -> void:
	var cell := feedback.position(key,Vector2(entity["position"]))
	var center := origin+(cell+Vector2.ONE*0.5)*tile
	var dying := false
	for death in feedback.plan.get("deaths",[]):
		if death["key"] == key: dying = true
	if not entity["alive"] and not dying:
		if entity["role"] == "hero":
			draw_arc(center,tile*0.22,0,TAU,24,Color(0.96,0.55,0.52,0.30),1.3,true)
		else:
			draw_arc(center,tile*0.16,0,TAU,16,Color(0.65,0.45,0.3,0.16),1.0,true)
		return
	_entity_alpha = feedback.opacity(key)
	var scale_factor := Vector2.ONE
	var rotation := 0.0
	if entity["role"] == "crystal":
		var breath := sin(idle_clock*1.8+float(entity["id"])*0.9)
		scale_factor = Vector2.ONE*(1.0+0.022*breath)
		draw_circle(center,tile*(0.33+0.012*breath),Color(0.72,0.78,1.0,(0.025+0.012*breath)*_entity_alpha))
	if dying:
		var fall := feedback.fraction(feedback.death_start(),Timeline.DEATH_SECONDS)
		scale_factor *= Vector2(1.0+0.16*fall,1.0-0.55*fall)
		rotation = fall*0.16
	for accent in feedback.accents:
		if accent["kind"] == "blocked" and entity["role"] == "hero" and Vector2(entity["position"]) == accent["cell"]:
			center += Vector2(facing)*tile*0.045*sin(PI*accent["age"]/accent["duration"])
	if entity["kind"] == "goblin":
		for strike in feedback.plan.get("goblin",[]):
			if strike["from"] == entity["position"]:
				center += Vector2(strike["to"]-strike["from"])*tile*0.055*sin(PI*feedback.fraction(feedback.attack_start(),Timeline.ATTACK_SECONDS))
	draw_set_transform(center,rotation,scale_factor)
	match entity["role"]:
		"hero": _hero(Vector2.ZERO,tile,entity["kind"],entity.get("selected",false))
		"crystal": _crystal(Vector2.ZERO,tile,entity["color"])
		"monster":
			if entity["kind"] == "goblin": _goblin(Vector2.ZERO,tile,true)
			else: _fire_dragon(Vector2.ZERO,tile,true,entity["facing"])
	draw_set_transform(Vector2.ZERO)
	_entity_alpha = 1.0


func _draw_energy_transition(cell: Vector2i, center: Vector2, tile: float) -> void:
	var active := model.barrier_is_active(cell)
	var clear:bool=cell in model.level.monster_clear_barriers
	var transition: Dictionary = {}
	for event in feedback.plan.get("energy",[]):
		if event["cell"] == cell: transition = event
	if transition.is_empty():
		if active: _energy_block(center,tile,clear)
		return
	var t := feedback.fraction(0.04,0.16)
	var visible := t if active else 1.0-t
	_entity_alpha = visible
	draw_set_transform(center,0.0,Vector2.ONE*(0.72+0.28*visible))
	_energy_block(Vector2.ZERO,tile,clear)
	draw_set_transform(Vector2.ZERO)
	_entity_alpha = 1.0
	var tint := _mechanism_tint(clear)
	draw_arc(center,tile*(0.21+0.27*t),0,TAU,36,Color(tint,0.45*sin(PI*t)),1.5,true)
	for i in 8:
		var angle := TAU*float(i)/8.0
		var point := center+Vector2(cos(angle),sin(angle))*tile*(0.18+0.27*t)
		draw_circle(point,tile*0.024,Color(tint,0.60*(1.0-t)))


func _draw_feedback(origin: Vector2, tile: float) -> void:
	var plan := feedback.plan
	var motion_t := feedback.fraction(0.0,feedback.motion_seconds())
	if plan.get("swap",false) and motion_t < 1.0:
		for motion in plan["motion"].values():
			for cell in [motion["from"],motion["to"]]:
				var center: Vector2 = origin+(cell+Vector2.ONE*0.5)*tile
				var glow := sin(PI*motion_t)
				draw_arc(center,tile*(0.16+0.26*motion_t),0,TAU,36,Color(HERO_BLUE,0.58*glow),2.0,true)
				for i in 6:
					var angle := float(i)*TAU/6.0+motion_t*0.5
					var point := center+Vector2(cos(angle),sin(angle))*tile*(0.10+0.30*motion_t)
					draw_circle(point,tile*0.025,Color("d9efff",0.70*glow))
	if plan.get("contact",false) and motion_t > 0.3 and motion_t < 1.0:
		for key: String in plan["motion"]:
			var motion: Dictionary = plan["motion"][key]
			var point: Vector2 = origin+(feedback.position(key,motion["to"])+Vector2.ONE*0.5)*tile
			for sign_x in [-1,1]: draw_circle(point+Vector2(sign_x*0.21,0.28)*tile,tile*0.023,Color(GOLD,0.42*sin(PI*motion_t)))
	for event in plan.get("plates",[]):
		var t := feedback.fraction(0.06,0.18)
		var center: Vector2 = origin+(Vector2(event["cell"])+Vector2.ONE*0.5)*tile
		draw_arc(center,tile*(0.22+0.17*t),0,TAU,32,Color(_mechanism_tint(),0.38*sin(PI*t)),1.4,true)
	var attack_t := feedback.fraction(feedback.attack_start(),Timeline.ATTACK_SECONDS)
	if attack_t > 0.0 and attack_t < 1.0:
		for ray in plan.get("fire",[]): _draw_flame(ray,attack_t,origin,tile)
		for strike in plan.get("goblin",[]):
			var center: Vector2 = origin+(Vector2(strike["to"])+Vector2.ONE*0.5)*tile
			var direction := Vector2(strike["to"]-strike["from"])
			var side := Vector2(-direction.y,direction.x)
			for offset in [-0.10,0.0,0.10]:
				var at: Vector2 = center+side*tile*offset
				draw_line(at-direction*tile*0.22,at+direction*tile*0.17,Color("f4b389",0.85*sin(PI*attack_t)),tile*0.035,true)
	for death in plan.get("deaths",[]):
		var t := feedback.fraction(feedback.death_start(),Timeline.DEATH_SECONDS)
		if t <= 0.0 or t >= 1.0: continue
		var center: Vector2 = origin+(Vector2(death["entity"]["position"])+Vector2.ONE*0.5)*tile
		var tint := _mechanism_tint() if death["energy"] else (Color("d6b3f7") if death["entity"]["role"] == "crystal" else Color("f0b78e"))
		for i in 8:
			var angle := float(i)*TAU/8.0+0.21
			var point := center+Vector2(cos(angle),sin(angle))*tile*(0.07+0.33*t)
			var shard := PackedVector2Array([point+Vector2(0,-0.035)*tile,point+Vector2(0.025,0.02)*tile,point+Vector2(-0.025,0.02)*tile])
			draw_colored_polygon(shard,Color(tint,0.70*(1.0-t)))
	for effect in feedback.accents:
		var t: float = effect["age"]/effect["duration"]
		if effect["kind"] == "victory":
			for cell in model.level.exit_cells:
				var center := origin+(Vector2(cell)+Vector2.ONE*0.5)*tile
				draw_arc(center,tile*(0.27+0.19*t),0,TAU,36,Color(MINT,0.48*sin(PI*t)),1.8,true)
			continue
		var center: Vector2 = origin+(effect["cell"]+Vector2.ONE*0.5)*tile
		var tint := HERO_BLUE if effect["kind"] == "undo" else GOLD
		draw_arc(center,tile*(0.27+0.17*t),0,TAU,36,Color(tint,0.55*sin(PI*t)),1.6,true)


func _draw_flame(ray: Dictionary, t: float, origin: Vector2, tile: float) -> void:
	var direction := Vector2(ray["facing"])
	var side := Vector2(-direction.y,direction.x)
	var start := origin+(Vector2(ray["from"])+Vector2.ONE*0.5+direction*0.32)*tile
	var end := start+direction*tile*0.07
	if not ray["cells"].is_empty():
		end = origin+(Vector2(ray["cells"][-1])+Vector2.ONE*0.5)*tile
		if ray["target"].is_empty(): end += direction*tile*0.35
	var reach := clampf(t*2.8,0.0,1.0)
	var tip := start.lerp(end,reach)
	var glow := sin(PI*t)
	draw_line(start,tip,Color(0.96,0.32,0.12,0.40*glow),tile*0.18,true)
	draw_line(start,tip,Color(1.0,0.78,0.37,0.80*glow),tile*0.065,true)
	var count := maxi(1,int(start.distance_to(tip)/(tile*0.18)))
	for i in count:
		var f := float(i+1)/float(count+1)
		var center := start.lerp(tip,f)
		var width := tile*0.07*(0.6+0.4*sin(f*19.0-t*14.0))
		var tongue := PackedVector2Array([center-direction*tile*0.10-side*width,center+direction*minf(tile*0.13,center.distance_to(tip)),center-direction*tile*0.10+side*width])
		draw_colored_polygon(tongue,Color(1.0,0.57,0.20,0.60*glow))


func _actor_polygon(points: PackedVector2Array, tint: Color) -> void:
	draw_colored_polygon(points,Color(tint,tint.a*_entity_alpha))
func _actor_line(a: Vector2, b: Vector2, tint: Color, width: float = -1.0, antialias: bool = false) -> void:
	draw_line(a,b,Color(tint,tint.a*_entity_alpha),width,antialias)
func _actor_circle(center: Vector2, radius: float, tint: Color) -> void:
	draw_circle(center,radius,Color(tint,tint.a*_entity_alpha))
func _actor_arc(center: Vector2, radius: float, a: float, b: float, count: int, tint: Color, width: float = 1.0, antialias: bool = false) -> void:
	draw_arc(center,radius,a,b,count,Color(tint,tint.a*_entity_alpha),width,antialias)
func _actor_polyline(points: PackedVector2Array, tint: Color, width: float = -1.0, antialias: bool = false) -> void:
	draw_polyline(points,Color(tint,tint.a*_entity_alpha),width,antialias)
