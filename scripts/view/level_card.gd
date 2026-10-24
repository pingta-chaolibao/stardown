extends Control
## A pooled, presentation-only card. Input/focus belong to the virtual strip.
const FONT = preload("res://assets/fonts/NotoSansCJKsc-Regular.otf")
const GOLD = Color("dfbb78")
const INK = Color("e3e9e6")
const MINT = Color("8ebbb9")
const ROLES = {"red":Color("f5787b"),"green":Color("72ce95"),"blue":Color("78aff0")}
var bound_index := -1
var entry: Dictionary = {}
var selected := false
var hovered := false
var pressed := false
var keyboard_focus := false
var _styles: Dictionary = {}

func bind(index: int, data: Dictionary) -> void:
	bound_index = index
	entry = data
	name = "Level%02d" % (index + 1)
	tooltip_text = "第%d关 · %s" % [index + 1, data.get("title", "")]
	queue_redraw()

func _box(rect: Rect2, fill: Color, border: Color, width: int = 1) -> void:
	var key := "%s/%s/%d" % [fill.to_html(),border.to_html(),width]
	if not _styles.has(key):
		var cached := StyleBoxFlat.new()
		cached.bg_color=fill;cached.border_color=border
		cached.set_border_width_all(width);cached.set_corner_radius_all(16)
		_styles[key]=cached
	var style: StyleBoxFlat = _styles[key]
	draw_style_box(style, rect)

func _text(value: String, at: Vector2, pixels: int, tint: Color, width: float = -1) -> void:
	draw_string(FONT, at, value, HORIZONTAL_ALIGNMENT_LEFT, width, pixels, tint)

func _draw() -> void:
	if bound_index < 0: return
	var lift := 3.0 if pressed else 0.0
	var rect := Rect2(Vector2(2, 2 + lift), size - Vector2(4, 8))
	_box(Rect2(rect.position + Vector2(0, 5), rect.size), Color("06121b"), Color("06121b"))
	var edge := GOLD if selected else (MINT if hovered else Color("294652"))
	_box(rect, Color("1a303c") if pressed else (Color("172f3a") if hovered else Color("122631")), edge, 2 if selected else 1)
	_text("%02d" % (bound_index + 1), Vector2(21, 55 + lift), 42, GOLD if selected else Color("6f919d"))
	_text("CHAPTER 01", Vector2(119, 34 + lift), 10, MINT)
	_text("北部英雄", Vector2(119, 56 + lift), 16, INK)
	_preview(Rect2(18, 78 + lift, size.x - 36, 126))
	_text(entry.get("title", "关卡"), Vector2(21, 238 + lift), 23, INK, size.x - 40)
	var kinds: Array = entry.get("kinds", [])
	var labels := {"red":"推", "green":"拉", "blue":"换位"}
	var x := 24.0
	for kind in kinds:
		draw_circle(Vector2(x, 258 + lift), 3.5, ROLES.get(kind, MINT))
		_text(labels.get(kind, kind), Vector2(x + 9, 263 + lift), 13, ROLES.get(kind, MINT))
		x += 66
	_text(entry.get("detail", ""), Vector2(21, 285 + lift), 12, MINT)
	draw_line(Vector2(20, size.y - 43), Vector2(size.x - 20, size.y - 43), Color("2a4450"), 1)
	_text("进入关卡", Vector2(21, size.y - 20 + lift), 14, GOLD if selected or hovered else MINT)
	_text("→", Vector2(size.x - 42, size.y - 20 + lift), 20, edge)
	if keyboard_focus and selected:
		draw_line(Vector2(23, 65), Vector2(69, 65), GOLD, 2, true)

func _preview(area: Rect2) -> void:
	_box(area, Color("0c1c27"), Color("243f4d"))
	var data: Dictionary = entry.get("map", {})
	var rows: Array = data.get("terrain", [".....", ".....", "....."])
	var tile := minf(15, minf((area.size.x - 16) / rows[0].length(), (area.size.y - 16) / rows.size()))
	var origin := area.get_center() - Vector2(rows[0].length(), rows.size()) * tile / 2
	for y in rows.size():
		for x in rows[y].length():
			draw_rect(Rect2(origin + Vector2(x,y)*tile + Vector2.ONE, Vector2.ONE*(tile-2)), Color("2b4654") if rows[y][x]=="." else Color("182d3a"))
	for edge in data.get("fences", []):
		var a: Array=edge[0];var b: Array=edge[1]
		var center := origin+(Vector2(a[0],a[1])+Vector2(b[0],b[1])+Vector2.ONE)*tile*0.5
		var normal := Vector2(b[0]-a[0],b[1]-a[1]);var tangent:=Vector2(normal.y,-normal.x)
		draw_line(center-tangent*tile*0.44,center+tangent*tile*0.44,Color("abc4d3"),2,true)
	var goals: Array = data.get("exits", [data["exit"]] if data.has("exit") else [])
	var goal_tint: Color = {"yellow":GOLD,"green":Color("78dd99"),"blue":Color("85bef5"),"purple":Color("c4a0f3"),"orange":Color("efac71"),"red":Color("f5787b")}.get(data.get("exit_color","yellow"),GOLD)
	for c in goals: draw_arc(origin+(Vector2(c[0],c[1])+Vector2.ONE*0.5)*tile,tile*0.30,0,TAU,16,goal_tint,1,true)
	var tint := Color("7dbce9") if data.get("mechanism_color")=="blue" else (Color("78d799") if data.get("mechanism_color")=="green" else GOLD)
	for link in data.get("energy_links", []):
		for c in link.get("plates", [link["plate"]] if link.has("plate") else []):
			draw_circle(origin+(Vector2(c[0],c[1])+Vector2.ONE*0.5)*tile,tile*0.18,tint)
		for c in link["barriers"]:
			draw_rect(Rect2(origin+Vector2(c[0],c[1])*tile+Vector2.ONE*2,Vector2.ONE*(tile-4)),Color(tint,0.65))
	for c in data.get("bushes", []): draw_circle(origin+(Vector2(c[0],c[1])+Vector2.ONE*0.5)*tile,tile*0.3,Color("517345"))
	var crystals: Array = data.get("crates", [])
	var colors: Array = data.get("crystal_colors", [])
	for index in crystals.size():
		var c: Array = crystals[index]
		var center := origin+(Vector2(c[0],c[1])+Vector2.ONE*0.5)*tile
		var variant: String = colors[index] if index<colors.size() else ("blue" if index%2==0 else "purple")
		var crystal_tint: Color = {"blue":Color("77cef1"),"purple":Color("bd9bf0"),"blue_purple":Color("8e9fee"),"orange":Color("ffba74"),"pink":Color("e99cc7"),"purple_pink":Color("c79cdd")}.get(variant,Color("bd9bf0"))
		draw_colored_polygon(PackedVector2Array([center+Vector2(0,-0.35)*tile,center+Vector2(0.28,0)*tile,center+Vector2(0,0.35)*tile,center+Vector2(-0.28,0)*tile]),crystal_tint)
	for h in data.get("heroes", [{"kind":data.get("hero_kind","red"),"position":data.get("player",[1,1])}]):
		var c: Array = h["position"]
		var center := origin+(Vector2(c[0],c[1])+Vector2.ONE*0.5)*tile
		draw_circle(center,tile*0.28,ROLES.get(h["kind"],MINT))
		draw_line(center+Vector2(0,0.1)*tile,center+Vector2(0,0.45)*tile,ROLES.get(h["kind"],MINT),2,true)
