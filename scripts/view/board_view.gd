class_name BoardView
extends Control
## Original procedural 2D artwork. This view only reads the grid model.

const State = preload("res://scripts/core/grid_state.gd")
const CORAL := Color("f5787b")
const HERO_GREEN := Color("72ce95")
const HERO_BLUE := Color("78aff0")
const MECHANISM_GREEN := Color("78d799")
const MECHANISM_BLUE := Color("7dbce9")
const GOLD := Color("dfbb78")
const GOAL_PURPLE := Color("c4a0f3")
const GOAL_BLUE := Color("85bef5")
const GOAL_ORANGE := Color("efac71")
const MINT := Color("9bc9c1")

var model: State
var facing := Vector2i.DOWN
var blocked: bool = false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)


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
		if model.barrier_is_active(cell):
			_energy_block(origin + (Vector2(cell) + Vector2.ONE * 0.5) * tile, tile)
		else:
			_inactive_energy_floor(origin + (Vector2(cell) + Vector2.ONE * 0.5) * tile, tile)
	for cell in level.exit_cells:
		_exit_marker(origin + (Vector2(cell) + Vector2.ONE * 0.5) * tile, tile)
	for cell in model.crates():
		_crystal(origin + (Vector2(cell) + Vector2.ONE * 0.5) * tile, tile, level.crystal_colors[model.crate_id(cell)])
	for hero in model.heroes():
		var center:=origin+(Vector2(hero["position"])+Vector2.ONE*0.5)*tile
		_hero(center,tile,hero["kind"],hero["selected"])
		if not hero["alive"]:
			draw_line(center+Vector2(-0.3,-0.3)*tile,center+Vector2(0.3,0.3)*tile,Color("fff0cc"),3,true)
			draw_line(center+Vector2(-0.3,0.3)*tile,center+Vector2(0.3,-0.3)*tile,Color("fff0cc"),3,true)
	# The footprint stays flat beneath occupants; only its outer dashes sit above
	# them, so a selection ring/shadow cannot hide a passable energy cell.
	for cell: Vector2i in model.barrier_states():
		if not model.barrier_is_active(cell):
			_inactive_energy_border(origin + (Vector2(cell) + Vector2.ONE * 0.5) * tile, tile)


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
	_box(Rect2(center - Vector2.ONE * tile * 0.4, Vector2.ONE * tile * 0.8), base, 5)
	draw_arc(center, tile * 0.24, 0, TAU, 32, light, 2, true)
	if pressed:
		draw_circle(center, tile * 0.15, light)


func _energy_block(center: Vector2, tile: float) -> void:
	var green := model.level.mechanism_color == "green"
	var blue := model.level.mechanism_color == "blue"
	_box(Rect2(center - Vector2.ONE * tile * 0.43, Vector2.ONE * tile * 0.86), Color("376e9b") if blue else (Color("3e845b") if green else Color("ba923c")), 5)
	_box(Rect2(center - Vector2.ONE * tile * 0.34, Vector2.ONE * tile * 0.68), MECHANISM_BLUE if blue else (MECHANISM_GREEN if green else Color("f2ce6d")), 3)
	for offset in [-0.20, 0.0, 0.20]:
		draw_line(center + Vector2(offset, -0.28) * tile, center + Vector2(offset, 0.28) * tile, Color("e1f5ff") if blue else (Color("dbffe6") if green else Color("fff0b5")), tile * 0.035, true)


func _mechanism_tint() -> Color:
	if model.level.mechanism_color == "blue":
		return MECHANISM_BLUE
	return MECHANISM_GREEN if model.level.mechanism_color == "green" else GOLD


func _inactive_energy_floor(center: Vector2, tile: float) -> void:
	var tint := _mechanism_tint()
	draw_rect(Rect2(center - Vector2.ONE * tile * 0.38, Vector2.ONE * tile * 0.76), Color(tint, 0.045))
	for offset in [-0.24, -0.12, 0.0, 0.12, 0.24]:
		draw_line(center + Vector2(offset - 0.09, -0.17) * tile, center + Vector2(offset + 0.09, 0.17) * tile, Color(tint, 0.16), 1.0, true)


func _inactive_energy_border(center: Vector2, tile: float) -> void:
	var tint := _mechanism_tint()
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
	draw_colored_polygon(PackedVector2Array([top, right, bottom, left]), base)
	draw_colored_polygon(PackedVector2Array([top, middle, left]), light)
	draw_colored_polygon(PackedVector2Array([middle, right, bottom]), dark)
	draw_colored_polygon(PackedVector2Array([middle, bottom, left]), base.darkened(0.08))
	draw_line(top, middle, Color(light, 0.9), tile * 0.025, true)
	draw_line(middle, bottom, Color(light, 0.65), tile * 0.02, true)


func _hero(center: Vector2, tile: float, kind: String, selected: bool) -> void:
	var green := kind == "green"
	var tint := HERO_GREEN if green else CORAL
	var shade := Color("3e9967") if green else Color("d45568")
	if kind=="blue":
		tint=HERO_BLUE
		shade=Color("416fae")
	var multi:=model.hero_count()>1
	if multi and not selected:
		tint=tint.darkened(0.35)
		shade=shade.darkened(0.35)
	elif multi:
		var ring:=PackedVector2Array()
		for i in 49:
			var angle:=float(i)/48*TAU
			ring.append(center+Vector2(cos(angle)*0.39,sin(angle)*0.12+0.32)*tile)
		draw_polyline(ring,Color("f4e2b5"),2.5,true)
	draw_ellipse_shadow(center + Vector2(0, tile * 0.29), Vector2(tile * 0.25, tile * 0.09))
	if blocked and selected:
		draw_arc(center, tile * 0.41, 0, TAU, 40, Color(GOLD, 0.55), 1.5, true)
	var body := PackedVector2Array([
		center + Vector2(-0.12, -0.05) * tile, center + Vector2(0.12, -0.05) * tile,
		center + Vector2(0.19, 0.24) * tile, center + Vector2(-0.19, 0.24) * tile,
	])
	if multi and selected:
		var outline:=body.duplicate()
		outline.append(body[0])
		draw_polyline(outline,Color("fff1cb"),3.5,true)
		draw_arc(center+Vector2(0,-0.21)*tile,tile*0.15,0,TAU,32,Color("fff1cb"),2,true)
	draw_colored_polygon(body, tint)
	draw_line(center + Vector2(-0.10, 0.18) * tile, center + Vector2(-0.12, 0.32) * tile, shade, tile * 0.08, true)
	draw_line(center + Vector2(0.10, 0.18) * tile, center + Vector2(0.12, 0.32) * tile, shade, tile * 0.08, true)
	draw_line(center + Vector2(-0.13, 0) * tile, center + Vector2(-0.23, 0.12) * tile, tint, tile * 0.075, true)
	draw_line(center + Vector2(0.13, 0) * tile, center + Vector2(0.23, 0.12) * tile, tint, tile * 0.075, true)
	draw_circle(center + Vector2(0, -0.21) * tile, tile * 0.13, tint)
	draw_circle(center + Vector2(0, -0.21) * tile + Vector2(facing if selected else Vector2i.DOWN) * tile * 0.05, tile * 0.025, Color("ffe2c6"))
	draw_line(center + Vector2(-0.11, 0.04) * tile, center + Vector2(0.11, 0.04) * tile, Color("d8ecff") if kind=="blue" else (Color("c5efbb") if green else Color("ffc3a1")), tile * 0.035, true)


func draw_ellipse_shadow(center: Vector2, radius: Vector2) -> void:
	var points := PackedVector2Array()
	for i in 32:
		var angle := float(i) / 32 * TAU
		points.append(center + Vector2(cos(angle), sin(angle)) * radius)
	draw_colored_polygon(points, Color(0.025, 0.07, 0.10, 0.8))


func _box(rect: Rect2, color: Color, radius: int) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(radius)
	draw_style_box(style, rect)
