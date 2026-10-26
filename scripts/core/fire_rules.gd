class_name FireRules
extends RefCounted
## Pure directional query. One target per dragon, sampled once per action.
## Rendering may query rays; querying never attacks or changes the world.

static func plan(kinds:PackedStringArray,positions:Array[Vector2i],living:Array[bool],facings:Array[Vector2i],heroes:Array[Vector2i],hero_alive:Array[bool],crystals:Dictionary,bounds:Rect2i,blocks:Callable,has_fence:Callable,protected_heroes:Array[bool]=[]) -> Dictionary:
	var rays:Array[Dictionary]=[]
	var error:String=""
	for i in positions.size():
		if kinds[i]!="fire_dragon" or not living[i]:continue
		var cells:Array[Vector2i]=[]
		var target:Dictionary={}
		var shielded_hero:int=-1
		var previous:Vector2i=positions[i]
		var cell:Vector2i=previous+facings[i]
		while bounds.has_point(cell) and not blocks.call(cell) and not crystals.has(cell):
			if has_fence.call(previous,cell):
				error="火焰跨栅栏规则尚未确认；该组合动作未提交。"
				break
			cells.append(cell)
			var hero:int=heroes.find(cell)
			if hero>=0 and hero_alive[hero]:
				if not protected_heroes.is_empty() and protected_heroes[hero]:shielded_hero=hero
				else:target={"kind":"hero","id":hero}
				break
			for m in positions.size():
				if m!=i and living[m] and positions[m]==cell:
					target={"kind":"monster","id":m}
					break
			if not target.is_empty():break
			previous=cell
			cell+=facings[i]
		var ray:Dictionary={"dragon":i,"cells":cells,"target":target}
		if shielded_hero>=0:ray["shielded_hero"]=shielded_hero
		rays.append(ray)
	return {"error":error,"rays":rays}
