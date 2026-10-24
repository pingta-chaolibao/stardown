class_name BoardView
extends Control
## Original procedural 2D artwork. This view only reads the grid model.

const State = preload("res://scripts/core/grid_state.gd")
const CORAL := Color("f5787b")
const HERO_GREEN := Color("72ce95")
const HERO_BLUE := Color("78aff0")
const MECHANISM_GREEN := Color("78d799")
const MECHANISM_BLUE := Color("7dbce9")
const MECHANISM_PURPLE := Color("bc9af3")
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
	for edge in level.fence_edges:
		_fence(origin, tile, edge["a"], edge["b"])
	if not level.initial_monsters.is_empty():
		for y in level.height:
			for x in level.width:
				var cell:=Vector2i(x,y)
				if level.is_floor(cell) and model.monster_danger_at(cell):_danger(origin+(Vector2(cell)+Vector2.ONE*0.5)*tile,tile)
	for ray in model.fire_rays():
		for cell in ray["cells"]:_fire_danger(origin+(Vector2(cell)+Vector2.ONE*0.5)*tile,tile,model.monsters()[ray["dragon"]]["facing"])
	for monster in model.monsters():
		if monster["kind"]=="goblin":_goblin(origin+(Vector2(monster["position"])+Vector2.ONE*0.5)*tile,tile,monster["alive"])
		elif monster["kind"]=="fire_dragon":_fire_dragon(origin+(Vector2(monster["position"])+Vector2.ONE*0.5)*tile,tile,monster["alive"],monster["facing"])
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


func _danger(center:Vector2,tile:float) -> void:
	var r:=Rect2(center-Vector2.ONE*tile*0.43,Vector2.ONE*tile*0.86)
	draw_rect(r,Color(0.8,0.25,0.12,0.13));draw_rect(r,Color(0.9,0.42,0.24,0.55),false,1.3)
	# Four marked corners identify a cell, without shading diagonal neighbors.
	for v in [Vector2(-1,-1),Vector2(1,-1),Vector2(-1,1),Vector2(1,1)]:
		var p:Vector2=center+v*tile*0.34
		draw_line(p,p-Vector2(v.x,0)*tile*0.08,Color("c56e4e"),1.5,true)


func _goblin(center:Vector2,tile:float,living:bool) -> void:
	if not living:
		draw_arc(center+Vector2(0,0.22)*tile,tile*0.20,0,TAU,12,Color(0.6,0.4,0.3,0.28),1.2,true)
		return # A non-interactive trace, drawn beneath any new occupant.
	draw_ellipse_shadow(center+Vector2(0,0.29)*tile,Vector2(tile*0.34,tile*0.12))
	var shape:=PackedVector2Array([center+Vector2(-0.30,0.25)*tile,center+Vector2(-0.28,-0.16)*tile,center+Vector2(-0.37,-0.37)*tile,center+Vector2(-0.12,-0.24)*tile,center+Vector2(0.12,-0.24)*tile,center+Vector2(0.37,-0.37)*tile,center+Vector2(0.28,-0.16)*tile,center+Vector2(0.30,0.25)*tile])
	draw_colored_polygon(shape,Color("482e35"));var outline:=shape.duplicate();outline.append(shape[0]);draw_polyline(outline,Color("ce805c"),maxf(1.4,tile*0.027),true)
	for x in [-0.13,0.13]:
		draw_circle(center+Vector2(x,-0.05)*tile,tile*0.064,Color("ffbd74"))
		draw_line(center+Vector2(x,-0.095)*tile,center+Vector2(x,-0.015)*tile,Color("301a23"),maxf(1,tile*0.025),true)
	draw_line(center+Vector2(-0.13,0.14)*tile,center+Vector2(0.13,0.14)*tile,Color("ecb39a"),tile*0.03,true)
	for x in [-0.07,0.07]:draw_line(center+Vector2(x,0.12)*tile,center+Vector2(x,0.19)*tile,Color("ecb39a"),tile*0.025,true)


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


func _energy_block(center: Vector2, tile: float) -> void:
	var green := model.level.mechanism_color == "green"
	var blue := model.level.mechanism_color == "blue"
	var purple := model.level.mechanism_color == "purple"
	_box(Rect2(center - Vector2.ONE * tile * 0.43, Vector2.ONE * tile * 0.86), Color("6b4293") if purple else (Color("376e9b") if blue else (Color("3e845b") if green else Color("ba923c"))), 5)
	_box(Rect2(center - Vector2.ONE * tile * 0.34, Vector2.ONE * tile * 0.68), MECHANISM_PURPLE if purple else (MECHANISM_BLUE if blue else (MECHANISM_GREEN if green else Color("f2ce6d"))), 3)
	for offset in [-0.20, 0.0, 0.20]:
		draw_line(center + Vector2(offset, -0.28) * tile, center + Vector2(offset, 0.28) * tile, Color("f4e8ff") if purple else (Color("e1f5ff") if blue else (Color("dbffe6") if green else Color("fff0b5"))), tile * 0.035, true)


func _mechanism_tint() -> Color:
	if model.level.mechanism_color == "purple":
		return MECHANISM_PURPLE
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
		draw_arc(center,tile*0.23,0,TAU,12,Color(0.65,0.45,0.27,0.28),1.2,true)
		return
	draw_ellipse_shadow(center+Vector2(0,tile*0.28),Vector2(tile*0.36,tile*0.11))
	var points:=PackedVector2Array([center-d*tile*0.30-side*tile*0.17,center-d*tile*0.12-side*tile*0.34,center+d*tile*0.10-side*tile*0.25,center+d*tile*0.34,center+d*tile*0.10+side*tile*0.25,center-d*tile*0.12+side*tile*0.34,center-d*tile*0.30+side*tile*0.17])
	draw_colored_polygon(points,Color("6b3b37"))
	var outline:=points.duplicate();outline.append(points[0])
	draw_polyline(outline,Color("ee965b"),maxf(1.6,tile*0.03),true)
	for sign_y in [-1,1]:draw_circle(center+d*tile*0.05+side*tile*0.12*sign_y,tile*0.042,Color("ffe4a1"))
	# The fixed-facing arrow stays inside the monster cell, above the head.
	draw_line(center-d*tile*0.14,center+d*tile*0.22,Color("fff0b8"),maxf(2,tile*0.035),true)
	draw_line(center+d*tile*0.12-side*tile*0.08,center+d*tile*0.22,Color("fff0b8"),maxf(2,tile*0.035),true)
	draw_line(center+d*tile*0.12+side*tile*0.08,center+d*tile*0.22,Color("fff0b8"),maxf(2,tile*0.035),true)
