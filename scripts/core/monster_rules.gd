class_name MonsterRules
extends RefCounted
## Goblin is the only implemented kind; unknown kinds never inherit behavior.
## Dead identities remain for Undo, but are absent from collision/targets/threats.
static func is_supported(kind:Variant) -> bool:
 return kind=="goblin"
static func display_name(kind:String) -> String:
 return "哥布林" if kind=="goblin" else "未支持的怪物"
static func is_stationary(kind:String) -> bool:
 return kind=="goblin"
static func threatens(kind:String,a:Vector2i,b:Vector2i) -> bool:
 match kind:
  "goblin":return absi(a.x-b.x)+absi(a.y-b.y)==1
 return false # Input validation rejects unsupported kinds before simulation.

static func settle(kinds:PackedStringArray,positions:Array[Vector2i],living:Array[bool],heroes:Array[Vector2i],hero_alive:Array[bool],previous:Dictionary,barriers:Dictionary,has_fence:Callable) -> Dictionary:
 if kinds.size()!=positions.size():return {"error":"怪物类型与位置数量不一致。"}
 for kind in kinds:
  if not is_supported(kind):return {"error":"未支持的怪物类型：%s；需先定义其行为。" % kind}
 var survivors:Array[bool]=living.duplicate();var lives:Array[bool]=hero_alive.duplicate();var attacked:Array[int]=[]
 for i in positions.size():
  if not survivors[i] or not barriers.get(positions[i],false):continue
  if not previous.has(positions[i]) or previous[positions[i]]:
   return {"error":"怪物不能位于已激活的能量格。"}
  survivors[i]=false
 # Energy consequences precede attacks: a killed monster never attacks this step.
 for h in heroes.size():
  if not lives[h]:continue
  for m in positions.size():
   if not survivors[m] or not threatens(kinds[m],heroes[h],positions[m]):continue
   if has_fence.call(heroes[h],positions[m]):return {"error":"哥布林隔栅栏攻击尚未确认；该组合动作未提交。"}
   lives[h]=false;attacked.append(h);break
 return {"error":"","monster_alive":survivors,"hero_alive":lives,"alive":not lives.has(false),"attacked_heroes":attacked}
