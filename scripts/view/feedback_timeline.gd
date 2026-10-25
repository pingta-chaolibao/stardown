class_name FeedbackTimeline
extends RefCounted
## Bounded, view-only clock. No Tween callbacks can outlive a cancellation.
const MOVE_SECONDS := 0.16
const SWAP_SECONDS := 0.20
const ATTACK_SECONDS := 0.18
const DEATH_SECONDS := 0.22
var plan: Dictionary = {}
var age: float = 0.0
var duration: float = 0.0
var generation: int = 0
var accents: Array[Dictionary] = []

func start(events: Dictionary) -> void:
	cancel()
	plan = events
	if plan.is_empty(): return
	duration = motion_seconds()
	if not plan["energy"].is_empty(): duration = maxf(duration,0.20)
	if not plan["fire"].is_empty() or not plan["goblin"].is_empty(): duration = attack_start()+ATTACK_SECONDS
	if not plan["deaths"].is_empty(): duration = death_start()+DEATH_SECONDS
	if plan["victory"]: accent("victory",Vector2.ZERO,0.55)

func cancel() -> void:
	generation += 1
	plan = {}
	age = 0.0
	duration = 0.0
	accents.clear()

func advance(delta: float) -> bool:
	var was_busy := is_busy()
	age += maxf(delta,0.0)
	for effect in accents: effect["age"] += maxf(delta,0.0)
	accents = accents.filter(func(effect: Dictionary)->bool: return effect["age"] < effect["duration"])
	if not plan.is_empty() and age >= duration:
		plan = {} # Release all snapshots/ghosts, no accumulation across actions.
	return was_busy and not is_busy()

func is_busy() -> bool:
	return not plan.is_empty() and age < duration

func motion_seconds() -> float:
	return SWAP_SECONDS if plan.get("swap",false) else MOVE_SECONDS

func attack_start() -> float:
	return maxf(motion_seconds(),0.20 if not plan.get("energy",[]).is_empty() else 0.0)

func death_start() -> float:
	return attack_start()+0.10 if not plan.get("fire",[]).is_empty() or not plan.get("goblin",[]).is_empty() else attack_start()

func fraction(start: float, length: float) -> float:
	return clampf((age-start)/length,0.0,1.0)

func position(key: String, fallback: Vector2) -> Vector2:
	if not plan.get("motion",{}).has(key): return fallback
	var motion: Dictionary = plan["motion"][key]
	var t := fraction(0.0,motion_seconds())
	if plan["swap"]: return motion["from"] if t < 0.5 else motion["to"]
	return motion["from"].lerp(motion["to"],t*t*(3.0-2.0*t))

func opacity(key: String) -> float:
	var alpha := 1.0
	if plan.get("swap",false) and plan.get("motion",{}).has(key):
		alpha = 0.30+0.70*absf(2.0*fraction(0.0,SWAP_SECONDS)-1.0)
	for death in plan.get("deaths",[]):
		if death["key"] == key: alpha *= 1.0-fraction(death_start(),DEATH_SECONDS)
	return alpha

func accent(kind: String, cell: Vector2, seconds: float = 0.26) -> void:
	if accents.size() >= 6: accents.pop_front()
	accents.append({"kind":kind,"cell":cell,"age":0.0,"duration":seconds})
