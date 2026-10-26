class_name ProtectionRules
extends RefCounted
## Yellow protection is a property of the common attack snapshot, not selection.

static func covered(kinds:PackedStringArray,positions:Array[Vector2i],living:Array[bool]) -> Array[bool]:
	var result:Array[bool]=[]
	for _cell in positions:result.append(false)
	if kinds.is_empty():return result # Compatible pure-rule callers with no yellow kind.
	assert(kinds.size()==positions.size() and living.size()==positions.size())
	for source in positions.size():
		if kinds[source]!="yellow" or not living[source]:continue
		for target in positions.size():
			if living[target] and absi(positions[source].x-positions[target].x)+absi(positions[source].y-positions[target].y)<=1:
				result[target]=true
	return result

static func covers_cell(kinds:PackedStringArray,positions:Array[Vector2i],living:Array[bool],cell:Vector2i) -> bool:
	for source in positions.size():
		if kinds[source]=="yellow" and living[source] and absi(positions[source].x-cell.x)+absi(positions[source].y-cell.y)<=1:return true
	return false
