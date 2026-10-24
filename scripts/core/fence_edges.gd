class_name FenceEdges
extends RefCounted
## Undirected movement edges. These never occupy cells or obstruct sight.

static func key(a: Vector2i,b: Vector2i) -> Vector4i:
	if a.y>b.y or (a.y==b.y and a.x>b.x):
		return Vector4i(b.x,b.y,a.x,a.y)
	return Vector4i(a.x,a.y,b.x,b.y)

static func read(value: Variant, parse_cell: Callable, is_floor: Callable) -> Dictionary:
	if not value is Array: return {"error":"fences 必须是相邻地板格的边数组。"}
	var edges: Array[Dictionary] = []
	var index: Dictionary = {}
	for entry in value:
		if not entry is Array or entry.size()!=2:
			return {"error":"每条栅栏必须包含两个端点。"}
		var a: Variant = parse_cell.call(entry[0])
		var b: Variant = parse_cell.call(entry[1])
		if a==null or b==null or not is_floor.call(a) or not is_floor.call(b):
			return {"error":"栅栏端点必须是地图内的整数地板坐标。"}
		if absi(a.x-b.x)+absi(a.y-b.y)!=1:
			return {"error":"栅栏仅可位于两个正交相邻格的公共边。"}
		var canonical := key(a,b)
		if index.has(canonical): return {"error":"同一栅栏边不得重复，包括反向重复。"}
		index[canonical]=true
		edges.append({"a":Vector2i(canonical.x,canonical.y),"b":Vector2i(canonical.z,canonical.w)})
	return {"error":"","edges":edges,"index":index}
