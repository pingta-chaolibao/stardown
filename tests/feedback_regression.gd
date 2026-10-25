extends SceneTree
const Level = preload("res://scripts/core/level_data.gd")
const State = preload("res://scripts/core/grid_state.gd")
const Events = preload("res://scripts/view/feedback_events.gd")
const Timeline = preload("res://scripts/view/feedback_timeline.gd")
const Cases = preload("res://tests/feedback_cases.gd")
const DIRS = {"U":Vector2i.UP,"D":Vector2i.DOWN,"L":Vector2i.LEFT,"R":Vector2i.RIGHT}
var checks := 0
var failures := 0

func _init() -> void:
	_cases(); _timeline(); _attack_triggers(); _campaign()
	print("FEEDBACK MODEL RESULT: %d checks, %d failures" % [checks,failures])
	quit(0 if failures == 0 else 1)

func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures += 1; printerr("FAIL: "+message)

func _cases() -> void:
	for case in Cases.cases():
		var g := State.new()
		_check(g.load_level(Level.from_dictionary(case["data"])),"sandbox loads: "+case["id"])
		var round := 0
		for symbol in case["path"]:
			var before := Events.capture(g)
			if symbol == "C":
				g.switch_hero(); _check(Events.action(before,g,Vector2i.ZERO).is_empty(),"free selection produces no action/attack events"); continue
			if symbol == "Z":
				g.undo(); _check(Events.action(before,g,Vector2i.ZERO).is_empty(),"Undo never replays old attacks"); continue
			g.try_move(DIRS[symbol])
			var world := g.snapshot()
			var plan := Events.action(before,g,DIRS[symbol])
			_check(g.snapshot() == world,"event planning never changes gameplay")
			if plan.is_empty():
				_check(world == before["world"],"blocked input has no timeline or attack")
				continue
			round += 1
			_check(plan["before"] == before["entities"],"before identities remain immutable")
			for ray in plan["fire"]:
				for cell in ray["cells"]:
					_check(g.level.is_floor(cell) and not g.barrier_is_active(cell) and g.crate_id(cell) < 0,"flame excludes crystal/solid/outside cells")
			if case["id"] == "fire":
				_check(plan["fire"].size() == 1,"one ray per living attacking dragon")
				var expected := Vector2i(3,2) if round == 1 else (Vector2i(5,2) if round == 2 else Vector2i(1,2))
				_check(plan["fire"][0]["cells"][-1] == expected,"pre-death ray stops at this round's first victim,never rescans")
			if case["id"] == "chain": _check(plan["motion"].size() == 4 and plan["contact"],"mixed hero/crystal chain uses one synchronized timeline")
			if case["id"] == "mutual": _check(plan["fire"].size() == 2 and plan["goblin"].size() == 2 and plan["deaths"].size() == 3,"same-step dead attackers retain simultaneous attacks")
			if case["id"] == "destruction":
				_check(plan["fire"].is_empty() and plan["deaths"].size() == 3 and plan["energy"].size() == 3,"energy kills before attack;all3restoration consequences visualized")
				_check(plan["after"]["c:0"]["position"] == Vector2i(4,2) and not g.crates().has(Vector2i(4,2)),"destroyed-crystal ghost has identity/position but no logical occupancy")

func _timeline() -> void:
	var g := State.new(); g.load_level(Level.from_dictionary(Cases.cases()[0]["data"]))
	var before := Events.capture(g); g.try_move(Vector2i.RIGHT)
	var plan := Events.action(before,g,Vector2i.RIGHT); var clock := Timeline.new(); clock.start(plan)
	var world := g.snapshot(); var token := clock.generation
	clock.advance(Timeline.MOVE_SECONDS*0.5)
	_check(clock.is_busy() and clock.position("h:red",Vector2(g.player)).is_equal_approx(Vector2(0.5,1)),"half-duration smooth motion is between cells")
	for key: String in plan["motion"]:
		_check(clock.position(key,Vector2.ZERO).is_equal_approx(plan["motion"][key]["from"]+Vector2(0.5,0)),"whole chain shares exact easing/progress")
	clock.cancel(); _check(not clock.is_busy() and clock.plan.is_empty() and clock.generation > token,"cancel drops snapshots/ghosts and invalidates generation")
	for i in 20: clock.advance(0.1)
	_check(clock.position("h:red",Vector2(g.player)) == Vector2(g.player) and g.snapshot() == world,"canceled clocks cannot rewrite positions or world")
	g = State.new(); g.load_level(Level.from_dictionary(Cases.cases()[2]["data"])); before = Events.capture(g); g.try_move(Vector2i.RIGHT)
	clock.start(Events.action(before,g,Vector2i.RIGHT)); clock.advance(Timeline.SWAP_SECONDS*0.25)
	_check(clock.position("h:blue",Vector2(g.player)) == Vector2(0,1),"swap stays at source before flash midpoint")
	clock.advance(Timeline.SWAP_SECONDS*0.5); _check(clock.position("h:blue",Vector2(g.player)) == Vector2(3,1),"swap appears at destination,never any intermediate cell")
	for i in 100: clock.accent("selection",Vector2.ZERO)
	_check(clock.accents.size() == 6,"effect storage is bounded even under repeat selection")
	clock.cancel(); _check(clock.accents.is_empty(),"cancel clears selection/victory/undo/contact effects")

func _campaign() -> void:
	for number in range(1,32):
		var g := State.new(); _check(g.load_level(Level.from_file("res://levels/north_%02d.json" % number)),"campaign loads")
		var solution: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://levels/solutions/north_%02d.json" % number))
		var attack_actions: Array[int] = []
		var attack_count := 0
		for symbol in solution["path"]:
			var before := Events.capture(g)
			if symbol == "C": g.switch_hero(); continue
			g.try_move(DIRS[symbol]); var world := g.snapshot(); var plan := Events.action(before,g,DIRS[symbol])
			_check(not plan.is_empty() and world == g.snapshot(),"31 confirmed legal paths remain atomic with read-only feedback")
			for ray in plan["fire"]:
				_check(not ray["target"].is_empty(),"campaign fire feedback requires a real target,not an empty sight query")
			if not plan["fire"].is_empty():
				attack_actions.append(g.moves)
				attack_count += plan["fire"].size()
			for death in plan["deaths"]:
				if death["entity"]["role"] == "crystal": _check(g.barrier_is_active(death["entity"]["position"]),"removed-crystal ghosts correspond to restored energy")
		_check(g.is_complete() and g.moves == solution["moves"],"campaign living victory unchanged")
		if number == 29:
			_check(attack_actions == [21,56] and attack_count == 4,"level29 attacks only on its two mutual-hit steps,not the other62actions")

func _attack_triggers() -> void:
	for blocker in ["empty","crystal","wall","bush","energy","goblin_idle","target"]:
		var g := State.new()
		_check(g.load_level(Level.from_dictionary(Cases.attack_room(blocker))),"attack trigger sandbox loads: "+blocker)
		var before := Events.capture(g)
		var sight := g.fire_rays()
		_check(g.try_move(Vector2i.RIGHT) == &"moved","legal safe action: "+blocker)
		var world := g.snapshot()
		var plan := Events.action(before,g,Vector2i.RIGHT)
		var hit: bool = blocker == "target"
		_check(g.snapshot() == world and plan["goblin"].is_empty(),"view queries do not attack or invent idle Goblin strikes")
		_check(plan["fire"].size() == (1 if hit else 0),"only an actual locked target triggers fire: "+blocker)
		_check(plan["sight"].size() == sight.size(),"empty and blocked rays still preserve the existing static danger overlay")
		for i in sight.size():
			_check(plan["sight"][i]["cells"] == sight[i]["cells"] and plan["sight"][i]["target"] == sight[i]["target"],"danger queries remain locked to the common state independently of attack animation")
		var clock := Timeline.new(); clock.start(plan)
		_check(clock.duration > Timeline.MOVE_SECONDS if hit else is_equal_approx(clock.duration,Timeline.MOVE_SECONDS),"no target adds no empty attack delay: "+blocker)
		if hit:
			_check(plan["fire"][0]["target"] == {"kind":"monster","id":1} and not g.monsters()[1]["alive"],"hit animation retains the common-state victim after logical death")
			var once := g.snapshot(); var next_before := Events.capture(g)
			_check(g.try_move(Vector2i.RIGHT) == &"moved","next action remains legal")
			var next := Events.action(next_before,g,Vector2i.RIGHT); clock.start(next)
			_check(next["fire"].is_empty() and is_equal_approx(clock.duration,Timeline.MOVE_SECONDS),"killed target is not an attack on the next step")
			_check(g.undo() and g.snapshot() == once,"undo next move restores previous world")
		else:
			_check(blocker == "goblin_idle" or sight[0]["target"].is_empty(),"empty and blocked sight queries are not attacks")
		var before_undo := Events.capture(g)
		_check(g.undo() and g.snapshot() == before["world"],"Undo restores all life and positions: "+blocker)
		_check(Events.action(before_undo,g,Vector2i.ZERO).is_empty(),"Undo never retriggers the previous attack")
		clock.cancel(); _check(clock.plan.is_empty() and not clock.is_busy(),"Undo cancellation removes pending attacks")
	var d := Cases.attack_room("target")
	d["monsters"][1] = {"kind":"fire_dragon","position":[5,2],"facing":"left"}
	var g := State.new(); _check(g.load_level(Level.from_dictionary(d)),"two-dragon mutual fixture loads")
	var before := Events.capture(g); g.try_move(Vector2i.RIGHT)
	var plan := Events.action(before,g,Vector2i.RIGHT)
	_check(plan["fire"].size() == 2 and plan["deaths"].size() == 2,"both same-step dead dragons retain their triggered attack")
	_check(plan["fire"][0]["target"] == {"kind":"monster","id":1} and plan["fire"][1]["target"] == {"kind":"monster","id":0},"mutual targets stay locked without a second scan")
	_check(g.undo() and g.snapshot() == before["world"],"Undo revives both mutual attackers atomically")
