extends "res://tests/feedback_scene.gd"
## Actual-input independent mechanism fixture, never campaign victory evidence.
func _run() -> void:
	root.size=Vector2i(1280,820)
	game=load("res://scenes/main.tscn").instantiate();root.add_child(game)
	await _settle()
	var data:Dictionary={"schema_version":1,"id":"clear_input_fixture","title":"独立清怪能量测试","is_temporary":true,"source_note":"独立夹具，非第三十一关通关","terrain":["......","......","......","......"],"player":[0,2],"crates":[],"targets":[],"objective":"none","mechanism_color":"blue","energy_blocks":[{"kind":"all_monsters_defeated","position":[5,1]}],"monsters":[{"kind":"fire_dragon","position":[0,0],"facing":"right"},{"kind":"goblin","position":[2,0]},{"kind":"fire_dragon","position":[4,0],"facing":"left"}]}
	var initial:Dictionary=_fixture_data(data,"独立清怪能量夹具：按方向实际输入；不是正式关卡。")
	_check_layout(game)
	_check(game.model.barrier_is_active(Vector2i(5,1)) and game.progress_label.text.contains("存活怪物 3 / 3"),"clear-type condition and living count displayed independently from pressure")
	await _capture_now("monster_clear_initial.png")
	await _tap(KEY_D)
	_check(game.model.moves==1 and game.model.living_monster_count()==2 and game.model.barrier_is_active(Vector2i(5,1)),"actual key first killsGoblin only;clear gate stays solid")
	_check(game.board.feedback.plan["fire"].size()==2 and game.board.feedback.plan["energy"].is_empty(),"actual target attacks animate without premature clear effect")
	await create_timer(0.23).timeout
	await _capture_now("monster_clear_first_target.png")
	await create_timer(0.45).timeout
	var intermediate:Dictionary=game.model.snapshot()
	await _tap(KEY_S)
	_check(game.model.moves==2 and game.model.living_monster_count()==0 and not game.model.barrier_is_active(Vector2i(5,1)),"lastmonster deaths and gate disappearance immediate in real input")
	_check(game.board.feedback.plan["fire"].size()==2 and game.board.feedback.plan["deaths"].size()==2 and game.board.feedback.plan["energy"].size()==1,"two locked mutual attacks/death and one gate transition")
	var after:Dictionary=game.model.snapshot()
	await create_timer(0.23).timeout;await _capture_now("monster_clear_mutual_and_gate.png")
	await create_timer(0.45).timeout
	_check(game.model.snapshot()==after and not game.board.feedback.is_busy(),"animation never changes logic or triggers a late attack")
	_check(game.progress_label.text.contains("存活怪物 0 / 3") and game.model.is_walkable(Vector2i(5,1)) and not game.model.blocks_sight(Vector2i(5,1)),"open marker state,live count,movement and sight agree")
	await _capture_now("monster_clear_inactive_marker.png")
	await _tap(KEY_Z)
	_check(game.model.snapshot()==intermediate and game.model.barrier_is_active(Vector2i(5,1)) and game.board.feedback.plan.is_empty(),"actualUndo restoreslastpair andclear gate,cancels remnants")
	await _tap(KEY_Z)
	_check(game.model.snapshot()==initial and game.model.living_monster_count()==3,"secondUndo restores complete initial identities")
	await _tap(KEY_D);await create_timer(0.65).timeout;await _tap(KEY_S);await _tap(KEY_R)
	_check(game.model.snapshot()==initial and game.board.feedback.plan.is_empty(),"restart during gate/death animation restores initial gate andmonsters")
	await create_timer(0.65).timeout
	_check(game.model.snapshot()==initial,"no stale visual callbacks change restoredgate")
	root.size=Vector2i(960,615);await _settle();_check_layout(game)
	await _capture_now("monster_clear_compact_active.png")
	await _click("MoveRight");await create_timer(0.65).timeout;await _click("MoveDown");await create_timer(0.65).timeout
	_check(game.model.living_monster_count()==0 and not game.model.barrier_is_active(Vector2i(5,1)),"screen directions use the same final-death clear condition")
	_check_layout(game);await _capture_now("monster_clear_compact_inactive.png")
	data["monsters"]=[]
	_fixture_data(data,"零初始怪物：清怪能量从加载起消失。")
	_check(game.model.living_monster_count()==0 and not game.model.barrier_is_active(Vector2i(5,1)) and game.progress_label.text.contains("0 / 0"),"zero-monster boundary displayed accurately")
	root.size=Vector2i(1280,820);await _settle()
	data["monsters"]=[{"kind":"goblin","position":[2,0]},{"kind":"goblin","position":[3,0]}]
	_fixture_data(data,"哥布林四向相邻：同一步互杀并打开清怪能量。")
	await _tap(KEY_D)
	_check(game.model.living_monster_count()==0 and game.board.feedback.plan["goblin"].size()==2 and game.board.feedback.plan["deaths"].size()==2,"real key displaysboth triggered attacks fromsame-step deadGoblins")
	await create_timer(0.22).timeout;await _capture_now("monster_clear_goblin_mutual.png")
	await _tap(KEY_Z)
	_check(game.model.living_monster_count()==2 and game.model.barrier_is_active(Vector2i(5,1)) and not game.board.feedback.is_busy(),"Undo duringGoblin mutual animationrevivespair/restoresgate/cancelsstrikes")
	data["player"]=[3,2];data["energy_blocks"][0]["position"]=[2,1]
	data["monsters"]=[{"kind":"fire_dragon","position":[2,0],"facing":"down"},{"kind":"goblin","position":[1,0]},{"kind":"goblin","position":[0,0]}]
	_fixture_data(data,"清怪开门发生在攻击之后：不追加火焰，不播放空攻击。")
	await _tap(KEY_A)
	_check(game.model.alive and game.model.living_monster_count()==0 and game.board.feedback.plan["fire"].is_empty() and game.board.feedback.plan["goblin"].size()==3,"actual finalclear doesnot inventlate firethroughformerlyclosedgate")
	await create_timer(0.24).timeout;await _capture_now("monster_clear_no_late_flame.png")
	await create_timer(0.40).timeout
	_check(game.model.alive and game.model.moves==1 and not game.board.feedback.is_busy(),"no delayed damageor extra attack roundafterclear effects")
	print("MONSTER CLEAR ENERGY SCENE RESULT: %d checks,%d failures;independent fixture,notcampaign;display=%s" % [checks,failures,DisplayServer.get_name()])
	quit(0 if failures==0 else 1)
