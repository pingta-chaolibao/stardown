class_name MonsterRules
extends RefCounted
## Explicit type dispatch. Dead identities remain for Undo, not collision/attacks.
const Fire=preload("res://scripts/core/fire_rules.gd")

static func is_supported(kind:Variant) -> bool:
	return kind in ["goblin","fire_dragon"]
static func display_name(kind:String) -> String:
	return {"goblin":"哥布林","fire_dragon":"火龙"}.get(kind,"未支持的怪物")
static func is_stationary(kind:String) -> bool:
	return is_supported(kind)
static func parse_facing(value:Variant) -> Vector2i:
	return {"up":Vector2i.UP,"down":Vector2i.DOWN,"left":Vector2i.LEFT,"right":Vector2i.RIGHT}.get(value,Vector2i.ZERO) if value is String else Vector2i.ZERO
static func threatens(kind:String,a:Vector2i,b:Vector2i) -> bool:
	return kind=="goblin" and absi(a.x-b.x)+absi(a.y-b.y)==1
static func can_attack_monster(kind:String,target_kind:String) -> bool:
	return kind=="goblin" and target_kind in ["goblin","fire_dragon"]

static func settle(kinds:PackedStringArray,positions:Array[Vector2i],living:Array[bool],heroes:Array[Vector2i],hero_alive:Array[bool],previous:Dictionary,barriers:Dictionary,has_fence:Callable,fire_context:Dictionary={}) -> Dictionary:
	if kinds.size()!=positions.size():return {"error":"怪物类型与位置数量不一致。"}
	for kind in kinds:
		if not is_supported(kind):return {"error":"未支持的怪物类型：%s；需先定义其行为。" % kind}
	var survivors:Array[bool]=living.duplicate()
	var lives:Array[bool]=hero_alive.duplicate()
	var attacked:Array[int]=[]
	var fire_heroes:Array[int]=[]
	for i in positions.size():
		if not survivors[i] or not barriers.get(positions[i],false):continue
		if not previous.has(positions[i]) or previous[positions[i]]:
			return {"error":"怪物不能位于已激活的能量格。"}
		survivors[i]=false
	# Energy restoration resolves first. All attack targets then use this common
	# post-movement/post-mechanism state, before ANY attack deaths are applied.
	var attack_monster_alive:Array[bool]=survivors.duplicate()
	var attack_hero_alive:Array[bool]=lives.duplicate()
	var fire_targets:Array[Dictionary]=[]
	var goblin_monster_victims:Array[int]=[]
	if kinds.has("fire_dragon") and fire_context.get("advance",true):
		if fire_context.is_empty():return {"error":"火龙结算缺少朝向或阻挡查询。"}
		var plan:=Fire.plan(kinds,positions,survivors,fire_context["facings"],heroes,lives,fire_context["crystals"],fire_context["bounds"],fire_context["blocks"],has_fence)
		if not plan["error"].is_empty():return plan
		for ray in plan["rays"]:
			if not ray["target"].is_empty():fire_targets.append(ray["target"])
	if fire_context.get("advance",true):
		# Both target categories are confirmed. Sample all of them before any
		# death applies, including mutual Goblins; never infer future kinds.
		for m in positions.size():
			if not survivors[m] or kinds[m]!="goblin":continue
			for target in positions.size():
				if target!=m and survivors[target] and can_attack_monster(kinds[m],kinds[target]) and threatens(kinds[m],positions[m],positions[target]):
					if has_fence.call(positions[m],positions[target]):return {"error":"哥布林隔栅栏攻击尚未确认；该组合动作未提交。"}
					goblin_monster_victims.append(target)
	for h in heroes.size():
		if not lives[h]:continue
		for m in positions.size():
			if not survivors[m] or not threatens(kinds[m],heroes[h],positions[m]):continue
			if has_fence.call(heroes[h],positions[m]):return {"error":"哥布林隔栅栏攻击尚未确认；该组合动作未提交。"}
			attacked.append(h);break
	# Apply once. A same-step victim's sampled attack is not canceled; a dead
	# monster is absent from NEXT step's sample. Never rescan after a fire kill.
	for target in fire_targets:
		if target["kind"]=="hero":
			lives[target["id"]]=false
			fire_heroes.append(target["id"])
		else:survivors[target["id"]]=false
	for victim in goblin_monster_victims:survivors[victim]=false
	for h in attacked:lives[h]=false
	return {"error":"","monster_alive":survivors,"hero_alive":lives,"alive":not lives.has(false),"attacked_heroes":attacked,"fire_heroes":fire_heroes,"attack_monster_alive":attack_monster_alive,"attack_hero_alive":attack_hero_alive}
