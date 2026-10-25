class_name PuzzleLevel
extends RefCounted
## Validated, data-only level definition. Coordinates are zero-based [x, y].

const Bush = preload("res://scripts/core/bush_obstacle.gd")
const Heroes = preload("res://scripts/core/hero_rules.gd")
const Monsters = preload("res://scripts/core/monster_rules.gd")
const Fences = preload("res://scripts/core/fence_edges.gd")

var id: String = ""
var title: String = ""
var is_temporary: bool = true
var source_note: String = ""
var terrain: PackedStringArray = []
var void_cells: Array[Vector2i] = []
var _void_by_cell: Dictionary = {}
var width: int = 0
var height: int = 0
var start: Vector2i = Vector2i.ZERO
var hero_kind: String = "red"
var hero_definitions: Array[Dictionary] = []
var initial_active_hero: int = 0
var initial_crates: Array[Vector2i] = []
var initial_monsters: Array[Vector2i] = []
var monster_kinds:PackedStringArray=[]
var monster_facings:Array[Vector2i]=[]
var crystal_colors: PackedStringArray = []
var targets: Array[Vector2i] = []
var exit_cell := Vector2i(-1, -1)
var exit_cells: Array[Vector2i] = []
var exit_color: String = "yellow"
var mechanism_color: String = "yellow"
var objective: String = "none"
var energy_links: Array[Dictionary] = []
var monster_clear_barriers: Array[Vector2i] = []
var bushes: Array[Bush] = []
var _bush_by_cell: Dictionary = {}
var error: String = ""
var fence_edges: Array[Dictionary] = []
var _fence_index: Dictionary = {}


static func from_file(path: String) -> PuzzleLevel:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return _invalid("无法读取地图：%s" % path)
	var parser := JSON.new()
	if parser.parse(file.get_as_text()) != OK:
		return _invalid("JSON 第 %d 行：%s" % [parser.get_error_line(), parser.get_error_message()])
	return from_dictionary(parser.data)


static func from_dictionary(data: Variant) -> PuzzleLevel:
	if not data is Dictionary:
		return _invalid("地图必须是 JSON 对象。")
	if data.get("schema_version") != 1:
		return _invalid("只支持 schema_version = 1。")
	for field in ["id", "title", "source_note", "objective"]:
		if not data.get(field) is String or data[field].is_empty():
			return _invalid("字段 %s 必须是非空字符串。" % field)
	if not data.get("is_temporary") is bool:
		return _invalid("is_temporary 必须明确为 true 或 false。")
	var rows: Variant = data.get("terrain")
	if not rows is Array or rows.is_empty() or rows.size() > 64:
		return _invalid("terrain 必须包含 1 至 64 行。")
	if not rows[0] is String or rows[0].is_empty() or rows[0].length() > 64:
		return _invalid("地图宽度必须为 1 至 64 格。")
	var level := PuzzleLevel.new()
	level.width = rows[0].length()
	level.height = rows.size()
	for row in rows:
		if not row is String or row.length() != level.width:
			return _invalid("terrain 每行宽度必须相同。")
		for tile in row:
			if tile != "." and tile != "#":
				return _invalid("terrain 仅允许 .（地面）与 #（墙）。")
		level.terrain.append(row)
	# Void is a display annotation on blocked terrain, never an extra floor type.
	var void_entries: Variant = data.get("void_cells", [])
	if not void_entries is Array:
		return _invalid("void_cells 必须是不可通行地形上的坐标数组。")
	for entry in void_entries:
		var cell: Variant = _parse_cell(entry)
		if cell == null or cell.x >= level.width or cell.y >= level.height or level.is_floor(cell) or level._void_by_cell.has(cell):
			return _invalid("界外显示格必须是地图内独立的不可通行坐标。")
		level.void_cells.append(cell)
		level._void_by_cell[cell] = true
	if data.has("heroes"):
		if data.has("player") or data.has("hero_kind"):
			return _invalid("heroes 与旧版 player/hero_kind 不能同时指定。")
		var hero_error := level._read_heroes(data["heroes"], data.get("active_hero"))
		if not hero_error.is_empty():
			return _invalid(hero_error)
	else:
		var kind: Variant = data.get("hero_kind", "red")
		if not Heroes.is_supported(kind):
			return _invalid("hero_kind 只支持 red（推）、green（拉）或 blue（交换）。")
		var spawn: Variant = _parse_cell(data.get("player"))
		if spawn == null or not level.is_floor(spawn):
			return _invalid("player 必须是地图内可通行的整数坐标。")
		level.hero_definitions.append({"id":"hero_01","kind":kind,"start":spawn})
	level.start = level.hero_definitions[level.initial_active_hero]["start"]
	level.hero_kind = level.hero_definitions[level.initial_active_hero]["kind"]
	for field in ["crates", "targets"]:
		var entries: Variant = data.get(field)
		if not entries is Array:
			return _invalid("%s 必须是坐标数组。" % field)
		var seen: Dictionary = {}
		for entry in entries:
			var cell: Variant = _parse_cell(entry)
			if cell == null or not level.is_floor(cell):
				return _invalid("%s 包含无效、越界或墙内坐标。" % field)
			if seen.has(cell):
				return _invalid("%s 不允许重复坐标。" % field)
			seen[cell] = true
			if field == "crates":
				if level.hero_start_at(cell) >= 0:
					return _invalid("英雄起点不能与箱体重叠。")
				level.initial_crates.append(cell)
			else:
				level.targets.append(cell)
	level.objective = data["objective"]
	if level.objective not in ["none", "all_crates_on_targets", "player_on_exit", "all_heroes_on_exits"]:
		return _invalid("未知 objective；支持 none、player_on_exit、all_heroes_on_exits 或基础测试落点规则。")
	if data.has("exit") or level.objective == "player_on_exit":
		var destination: Variant = _parse_cell(data.get("exit"))
		if destination == null or not level.is_floor(destination):
			return _invalid("exit 必须是地图内可通行的整数坐标。")
		level.exit_cell = destination
		level.exit_cells.append(destination)
	if data.has("exits") or level.objective == "all_heroes_on_exits":
		if data.has("exit"):
			return _invalid("exit 与 exits 不能同时指定。")
		var exits: Variant = data.get("exits")
		if not exits is Array or exits.is_empty():
			return _invalid("exits 必须是非空坐标数组。")
		for entry in exits:
			var cell: Variant = _parse_cell(entry)
			if cell == null or not level.is_floor(cell) or cell in level.exit_cells:
				return _invalid("英雄终点必须是独立可走的地图内坐标。")
			level.exit_cells.append(cell)
		if level.objective == "all_heroes_on_exits" and level.exit_cells.size() != level.hero_definitions.size():
			return _invalid("全部英雄目标要求终点数量与英雄数量相等。")
	var goal_color: Variant = data.get("exit_color", "yellow")
	if goal_color not in ["yellow", "green", "red", "purple", "blue", "orange"]:
		return _invalid("exit_color 仅支持 yellow、green、red、purple、blue 或 orange。")
	level.exit_color = goal_color
	var mechanism_tint: Variant = data.get("mechanism_color", "yellow")
	if mechanism_tint not in ["yellow", "green", "blue", "purple"]:
		return _invalid("mechanism_color 仅支持 yellow、green、blue 或 purple，且只影响显示。")
	level.mechanism_color = mechanism_tint
	var colors: Variant = data.get("crystal_colors", [])
	if not colors is Array or (not colors.is_empty() and colors.size() != level.initial_crates.size()):
		return _invalid("crystal_colors 必须为空数组或与水晶数量相同的颜色数组。")
	for i in level.initial_crates.size():
		var variant: Variant = colors[i] if not colors.is_empty() else ("blue" if i % 2 == 0 else "purple")
		if variant not in ["blue", "purple", "blue_purple", "orange", "pink", "purple_pink"]:
			return _invalid("未知水晶显示颜色。")
		level.crystal_colors.append(variant)
	if level.objective == "all_crates_on_targets":
		if level.initial_crates.is_empty() or level.initial_crates.size() != level.targets.size():
			return _invalid("测试目标要求至少一个箱体，且箱体与落点数量相等。")
	var bush_error := level._read_bushes(data.get("bushes", []))
	if not bush_error.is_empty():
		return _invalid(bush_error)
	var link_error := level._read_energy_links(data.get("energy_links", []))
	if not link_error.is_empty():
		return _invalid(link_error)
	var block_error := level._read_energy_blocks(data.get("energy_blocks", []))
	if not block_error.is_empty():
		return _invalid(block_error)
	var fences := Fences.read(data.get("fences", []),_parse_cell,level.is_floor)
	if not fences["error"].is_empty(): return _invalid(fences["error"])
	level.fence_edges.assign(fences["edges"])
	level._fence_index = fences["index"]
	var monster_entries: Variant=data.get("monsters",[])
	if not monster_entries is Array:return _invalid("monsters 必须是坐标数组。")
	for entry in monster_entries:
		if not entry is Dictionary or not Monsters.is_supported(entry.get("kind")):
			return _invalid("每只怪物需明确kind；当前支持goblin（哥布林）和fire_dragon（火龙），未知类型不能套用其行为。")
		var cell:Variant=_parse_cell(entry.get("position"))
		if cell==null or not level.is_floor(cell) or cell in level.initial_monsters or cell in level.initial_crates or level.hero_start_at(cell)>=0 or level.bush_at(cell)!=null:
			return _invalid("怪物必须在独立的地图内整数地板格，不能与英雄、水晶、草丛重叠。")
		level.initial_monsters.append(cell)
		level.monster_kinds.append(entry["kind"])
		var facing:Vector2i=Monsters.parse_facing(entry.get("facing"))
		if entry["kind"]=="fire_dragon" and facing==Vector2i.ZERO:
			return _invalid("火龙必须明确 facing：up/down/left/right，不能省略或使用斜向。")
		if entry["kind"]=="goblin" and entry.has("facing"):
			return _invalid("哥布林没有朝向属性。")
		level.monster_facings.append(facing)
	level.id = data["id"]
	level.title = data["title"]
	level.is_temporary = data["is_temporary"]
	level.source_note = data["source_note"]
	return level


func _read_heroes(value: Variant, selected: Variant) -> String:
	if not value is Array or value.is_empty():
		return "heroes 必须是非空英雄数组。"
	var ids: Dictionary = {}
	var occupied: Dictionary = {}
	for entry in value:
		if not entry is Dictionary or not entry.get("id") is String or entry["id"].is_empty() or ids.has(entry["id"]):
			return "英雄需要唯一非空 id。"
		if not Heroes.is_supported(entry.get("kind")):
			return "英雄类型只支持 red、green、blue。"
		var cell: Variant = _parse_cell(entry.get("position"))
		if cell == null or not is_floor(cell) or occupied.has(cell):
			return "英雄起点必须是独立可走的地图内坐标。"
		ids[entry["id"]] = hero_definitions.size()
		occupied[cell] = true
		hero_definitions.append({"id":entry["id"],"kind":entry["kind"],"start":cell})
	if not selected is String or not ids.has(selected):
		return "active_hero 必须指定 heroes 中的英雄 id。"
	initial_active_hero = ids[selected]
	return ""


func hero_start_at(cell: Vector2i) -> int:
	for index in hero_definitions.size():
		if hero_definitions[index]["start"] == cell:
			return index
	return -1


func _read_bushes(value: Variant) -> String:
	if not value is Array:
		return "bushes 必须是独立的草丛坐标数组。"
	for entry in value:
		var cell: Variant = _parse_cell(entry)
		if cell == null or not is_floor(cell) or _bush_by_cell.has(cell):
			return "草丛必须是地图内独立的地板坐标。"
		if hero_start_at(cell) >= 0 or cell in initial_crates or cell in exit_cells or cell in targets:
			return "草丛不能与英雄、水晶或目标重叠。"
		var bush := Bush.new(cell)
		bushes.append(bush)
		_bush_by_cell[cell] = bush
	return ""


func bush_at(cell: Vector2i) -> Bush:
	return _bush_by_cell.get(cell)


func _read_energy_links(value: Variant) -> String:
	if not value is Array:
		return "energy_links 必须是数组。"
	var ids: Dictionary = {}
	var plates: Dictionary = {}
	var barriers: Dictionary = {}
	for entry in value:
		if not entry is Dictionary or not entry.get("id") is String or entry["id"].is_empty():
			return "每组能量机关需要非空 id。"
		if ids.has(entry["id"]):
			return "能量机关 id 不得重复。"
		ids[entry["id"]] = true
		if entry.has("plate") and entry.has("plates"):
			return "plate 与 plates 不能同时指定。"
		var plate_entries: Variant = entry.get("plates", [entry["plate"]] if entry.has("plate") else [])
		if not plate_entries is Array or plate_entries.is_empty():
			return "每组机关需要至少一块压力板。"
		if entry.get("activation", "all" if entry.has("plate") else "") != "all":
			return "多压力板必须明确指定 activation = all。"
		var group_plates: Array[Vector2i] = []
		for item in plate_entries:
			var plate: Variant = _parse_cell(item)
			if plate == null or not is_floor(plate) or plates.has(plate) or bush_at(plate) != null:
				return "压力板必须是独立且可通行的地图内坐标。"
			plates[plate] = true
			group_plates.append(plate)
		var source_list: Variant = entry.get("pressure_sources")
		if not source_list is Array or source_list.is_empty():
			return "pressure_sources 必须显式指定 hero、crystal 或两者。"
		var sources: Array = []
		for source in source_list:
			if source not in ["hero", "crystal"] or source in sources:
				return "压力来源无效或重复。"
			sources.append(source)
		var entries: Variant = entry.get("barriers")
		if not entries is Array or entries.is_empty():
			return "每块压力板需要明确关联至少一个能量格。"
		var cells: Array[Vector2i] = []
		for item in entries:
			var cell: Variant = _parse_cell(item)
			if cell == null or not is_floor(cell) or barriers.has(cell) or bush_at(cell) != null:
				return "能量格必须在地板内，且不能重复或由多组机关同时控制。"
			barriers[cell] = true
			cells.append(cell)
		var link := {"id": entry["id"], "plates": group_plates, "activation": "all", "barriers": cells, "pressure_sources": sources}
		if entry.has("plate"):
			link["plate"] = group_plates[0]
		energy_links.append(link)
	for cell in plates:
		if barriers.has(cell):
			return "压力板与能量格不能重叠。"
	return ""


func _read_energy_blocks(value: Variant) -> String:
	if not value is Array:
		return "energy_blocks 必须是明确类型的能量块数组。"
	var occupied: Dictionary = {}
	for link in energy_links:
		for cell in link["plates"]: occupied[cell] = true
		for cell in link["barriers"]: occupied[cell] = true
	for entry in value:
		if not entry is Dictionary or entry.get("kind") != "all_monsters_defeated":
			return "energy_blocks 需明确 kind=all_monsters_defeated；未知条件不能套用压板规则。"
		var cell: Variant = _parse_cell(entry.get("position"))
		if cell == null or not is_floor(cell) or bush_at(cell) != null or occupied.has(cell):
			return "清怪能量块必须在独立地板格，不能与草丛、压力板或其他能量块重叠。"
		occupied[cell] = true
		monster_clear_barriers.append(cell)
	return ""


func is_floor(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < width and cell.y < height \
		and terrain[cell.y][cell.x] == "."


func is_void(cell: Vector2i) -> bool:
	return _void_by_cell.has(cell)


func has_fence(a: Vector2i,b: Vector2i) -> bool:
	return _fence_index.has(Fences.key(a,b))


static func _parse_cell(value: Variant) -> Variant:
	if not value is Array or value.size() != 2:
		return null
	for component in value:
		if typeof(component) not in [TYPE_INT, TYPE_FLOAT]:
			return null
		if not is_finite(float(component)) or float(component) != floor(float(component)):
			return null
		if component < 0 or component > 63:
			return null
	return Vector2i(int(value[0]), int(value[1]))


static func _invalid(message: String) -> PuzzleLevel:
	var level := PuzzleLevel.new()
	level.error = message
	return level
