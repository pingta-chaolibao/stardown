class_name BoardView
extends Control
## Original procedural 2D artwork. This view only reads the grid model.

const State = preload("res://scripts/core/grid_state.gd")
const CORAL := Color("f5787b")
const HERO_GREEN := Color("72ce95")
const GOLD := Color("dfbb78")
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
			else:
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
	if level.exit_cell != Vector2i(-1, -1):
		_exit_marker(origin + (Vector2(level.exit_cell) + Vector2.ONE * 0.5) * tile, tile)
	for cell in model.crates():
		_crystal(origin + (Vector2(cell) + Vector2.ONE * 0.5) * tile, tile, level.crystal_colors[model.crate_id(cell)])
	_hero(origin + (Vector2(model.player) + Vector2.ONE * 0.5) * tile, tile)
	if not model.alive:
		var center := origin + (Vector2(model.player) + Vector2.ONE * 0.5) * tile
		draw_line(center + Vector2(-0.3, -0.3) * tile, center + Vector2(0.3, 0.3) * tile, Color("fff0cc"), 3, true)
		draw_line(center + Vector2(-0.3, 0.3) * tile, center + Vector2(0.3, -0.3) * tile, Color("fff0cc"), 3, true)


func _bush(center: Vector2, tile: float) -> void:
	draw_ellipse_shadow(center + Vector2(0, tile * 0.25), Vector2(tile * 0.37, tile * 0.13))
	for offset in [Vector2(-0.20, 0.04), Vector2(0.18, 0.02), Vector2(0, -0.17), Vector2(0, 0.17)]:
		draw_circle(center + offset * tile, tile * 0.24, Color("325c42"))
	for offset in [Vector2(-0.14, -0.02), Vector2(0.15, -0.04), Vector2(0, -0.19)]:
		draw_circle(center + offset * tile, tile * 0.18, Color("568451"))
	for offset in [-0.15, 0.03, 0.20]:
		draw_line(center + Vector2(offset - 0.07, 0.14) * tile, center + Vector2(offset + 0.03, -0.07) * tile, Color("a1b76a"), tile * 0.025, true)


func _pressure_plate(center: Vector2, tile: float, pressed: bool) -> void:
	_box(Rect2(center - Vector2.ONE * tile * 0.4, Vector2.ONE * tile * 0.8), Color("c7a34d") if pressed else Color("74613c"), 5)
	draw_arc(center, tile * 0.24, 0, TAU, 32, Color("ffe6a0"), 2, true)
	if pressed:
		draw_circle(center, tile * 0.15, Color("ffe6a0"))


func _energy_block(center: Vector2, tile: float) -> void:
	_box(Rect2(center - Vector2.ONE * tile * 0.43, Vector2.ONE * tile * 0.86), Color("ba923c"), 5)
	_box(Rect2(center - Vector2.ONE * tile * 0.34, Vector2.ONE * tile * 0.68), Color("f2ce6d"), 3)
	for offset in [-0.20, 0.0, 0.20]:
		draw_line(center + Vector2(offset, -0.28) * tile, center + Vector2(offset, 0.28) * tile, Color("fff0b5"), tile * 0.035, true)


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


func _hero(center: Vector2, tile: float) -> void:
	var green := model.level.hero_kind == "green"
	var tint := HERO_GREEN if green else CORAL
	var shade := Color("3e9967") if green else Color("d45568")
	draw_ellipse_shadow(center + Vector2(0, tile * 0.29), Vector2(tile * 0.25, tile * 0.09))
	if blocked:
		draw_arc(center, tile * 0.41, 0, TAU, 40, Color(GOLD, 0.55), 1.5, true)
	var body := PackedVector2Array([
		center + Vector2(-0.12, -0.05) * tile, center + Vector2(0.12, -0.05) * tile,
		center + Vector2(0.19, 0.24) * tile, center + Vector2(-0.19, 0.24) * tile,
	])
	draw_colored_polygon(body, tint)
	draw_line(center + Vector2(-0.10, 0.18) * tile, center + Vector2(-0.12, 0.32) * tile, shade, tile * 0.08, true)
	draw_line(center + Vector2(0.10, 0.18) * tile, center + Vector2(0.12, 0.32) * tile, shade, tile * 0.08, true)
	draw_line(center + Vector2(-0.13, 0) * tile, center + Vector2(-0.23, 0.12) * tile, tint, tile * 0.075, true)
	draw_line(center + Vector2(0.13, 0) * tile, center + Vector2(0.23, 0.12) * tile, tint, tile * 0.075, true)
	draw_circle(center + Vector2(0, -0.21) * tile, tile * 0.13, tint)
	draw_circle(center + Vector2(0, -0.21) * tile + Vector2(facing) * tile * 0.05, tile * 0.025, Color("ffe2c6"))
	draw_line(center + Vector2(-0.11, 0.04) * tile, center + Vector2(0.11, 0.04) * tile, Color("c5efbb") if green else Color("ffc3a1"), tile * 0.035, true)


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
