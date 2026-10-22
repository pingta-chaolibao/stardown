class_name PuzzleLevel
extends RefCounted
## Validated, data-only level definition. Coordinates are zero-based [x, y].

var id: String = ""
var title: String = ""
var is_temporary: bool = true
var source_note: String = ""
var terrain: PackedStringArray = []
var width: int = 0
var height: int = 0
var start: Vector2i = Vector2i.ZERO
var initial_crates: Array[Vector2i] = []
var crystal_colors: PackedStringArray = []
var targets: Array[Vector2i] = []
var exit_cell := Vector2i(-1, -1)
var exit_color: String = "yellow"
var objective: String = "none"
var energy_links: Array[Dictionary] = []
var error: String = ""


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
	var spawn: Variant = _parse_cell(data.get("player"))
	if spawn == null or not level.is_floor(spawn):
		return _invalid("player 必须是地图内可通行的整数坐标。")
	level.start = spawn
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
				if cell == level.start:
					return _invalid("英雄起点不能与箱体重叠。")
				level.initial_crates.append(cell)
			else:
				level.targets.append(cell)
	level.objective = data["objective"]
	if level.objective not in ["none", "all_crates_on_targets", "player_on_exit"]:
		return _invalid("未知 objective；请使用 none、player_on_exit 或基础测试落点规则。")
	if data.has("exit") or level.objective == "player_on_exit":
		var destination: Variant = _parse_cell(data.get("exit"))
		if destination == null or not level.is_floor(destination):
			return _invalid("exit 必须是地图内可通行的整数坐标。")
		level.exit_cell = destination
	var goal_color: Variant = data.get("exit_color", "yellow")
	if goal_color not in ["yellow", "green"]:
		return _invalid("exit_color 仅支持 yellow 或 green。")
	level.exit_color = goal_color
	var colors: Variant = data.get("crystal_colors", [])
	if not colors is Array or (not colors.is_empty() and colors.size() != level.initial_crates.size()):
		return _invalid("crystal_colors 必须为空数组或与水晶数量相同的颜色数组。")
	for i in level.initial_crates.size():
		var variant: Variant = colors[i] if not colors.is_empty() else ("blue" if i % 2 == 0 else "purple")
		if variant not in ["blue", "purple"]:
			return _invalid("水晶颜色仅支持 blue 和 purple。")
		level.crystal_colors.append(variant)
	if level.objective == "all_crates_on_targets":
		if level.initial_crates.is_empty() or level.initial_crates.size() != level.targets.size():
			return _invalid("测试目标要求至少一个箱体，且箱体与落点数量相等。")
	var link_error := level._read_energy_links(data.get("energy_links", []))
	if not link_error.is_empty():
		return _invalid(link_error)
	level.id = data["id"]
	level.title = data["title"]
	level.is_temporary = data["is_temporary"]
	level.source_note = data["source_note"]
	return level


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
		var plate: Variant = _parse_cell(entry.get("plate"))
		if plate == null or not is_floor(plate) or plates.has(plate):
			return "压力板必须是独立且可通行的地图内坐标。"
		plates[plate] = true
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
			if cell == null or not is_floor(cell) or barriers.has(cell):
				return "能量格必须在地板内，且不能重复或由多组机关同时控制。"
			barriers[cell] = true
			cells.append(cell)
		energy_links.append({"id": entry["id"], "plate": plate, "barriers": cells, "pressure_sources": sources})
	for cell in plates:
		if barriers.has(cell):
			return "压力板与能量格不能重叠。"
	return ""


func is_floor(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < width and cell.y < height \
		and terrain[cell.y][cell.x] == "."


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
