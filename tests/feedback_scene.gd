extends "res://tests/north_02_scene.gd"
const Cases = preload("res://tests/feedback_cases.gd")
const Definition = preload("res://scripts/core/level_data.gd")
const Feedback = preload("res://scripts/view/feedback_events.gd")

func _run() -> void:
	root.size = Vector2i(1280,820)
	game = load("res://scenes/main.tscn").instantiate(); game.start_in_level = true; root.add_child(game)
	await _settle()
	var initial := _fixture(0)
	await _capture_now("feedback_breath_initial.png")
	await create_timer(0.7).timeout
	_check(game.model.snapshot() == initial,"idle breathing cannot move/change any logical entity")
	await _capture_now("feedback_breath_later.png")
	await _tap(KEY_D)
	var after: Dictionary = game.model.snapshot()
	var clock = game.board.feedback
	_check(game.model.moves == 1 and clock.is_busy() and clock.plan["motion"].size() == 4,"actual key commits mixed chain once then animates")
	await _tap(KEY_D)
	_check(game.model.snapshot() == after,"fresh movement during animation is ignored,not queued")
	await create_timer(0.02).timeout
	var display: Vector2 = clock.position("h:red",Vector2(game.model.player))
	_check(display.x > 0.0 and display.x < 1.0,"real clock renders smooth intermediate position")
	await _capture_now("feedback_move_mid.png")
	await _tap(KEY_Z)
	_check(game.model.snapshot() == initial and not clock.is_busy() and clock.plan.is_empty(),"Undo during motion atomically restores whole chain and cancels feedback")
	await create_timer(0.55).timeout
	_check(game.model.snapshot() == initial,"no stale callbacks or queued input after Undo")
	await _tap(KEY_D); await _tap(KEY_R)
	_check(game.model.snapshot() == initial and not game.board.feedback.is_busy(),"restart interrupts and restores initial positions/selection")
	_fixture(2)
	await _tap(KEY_D)
	clock = game.board.feedback; after = game.model.snapshot()
	var generation: int = clock.generation
	await _capture_now("feedback_swap_flash.png")
	await _tap(KEY_C)
	_check(game.model.active_hero_id() == "red" and game.model.snapshot() == after and game.board.feedback == clock and clock.generation == generation,"free C changes highlight during swap without replaying or resetting timeline")
	await _tap(KEY_Z)
	_check(game.model.moves == 0 and game.model.active_hero_id() == "red" and game.model.hero_position(0) == Vector2i(0,1) and clock.plan.is_empty(),"Undo after mid-animation C retains current selection")
	await _capture_now("feedback_selection_undo.png")
	for _i in 6:
		_fixture(0); await _tap(KEY_D); var abandoned = game.board.feedback
		await _tap(KEY_ESCAPE)
		_check(game.menu.visible and abandoned.plan.is_empty(),"return cancels pending motion before hiding board")
		await _click("Level01")
		_check(game.model.moves == 0 and game.board.feedback.plan.is_empty(),"re-enter cannot inherit previous ghosts/timers")
	for item in [[3,KEY_W,0.10,"feedback_energy_open.png"],[4,KEY_D,0.23,"feedback_fire_first_target.png"],[5,KEY_D,0.22,"feedback_goblin_attack.png"],[6,KEY_D,0.23,"feedback_mutual_death.png"],[7,KEY_A,0.28,"feedback_energy_destruction.png"]]:
		_fixture(item[0]); await _tap(item[1]); await create_timer(item[2]).timeout
		await _capture_now(item[3])
		if not game.model.alive:
			var dead: Dictionary = game.model.snapshot()
			await _tap(KEY_C); await _tap(KEY_R); await _tap(KEY_ESCAPE)
			_check(not game.menu.visible and game.model.snapshot() == dead,"animated death cannot be bypassed by C/restart/menu")
		await _tap(KEY_Z)
		_check(game.model.alive and game.model.moves == 0 and game.board.feedback.plan.is_empty(),"Undo cancels all attacks/ghosts and restores life")
	_fixture(8); await _tap(KEY_W)
	_check(game.model.moves == 0 and game.board.feedback.plan.is_empty() and not game.board.feedback.accents.is_empty(),"blocked input gives only bounded local feedback,not a round")
	await _settle(); await _tap(KEY_D); await create_timer(0.17).timeout
	_check(game.model.is_complete(),"victory logic remains immediate and atomic")
	await _capture_now("feedback_victory.png")
	await _tap(KEY_Z); _check(not game.model.is_complete() and game.model.moves == 0,"Undo clears victory and pending celebration")
	root.size = Vector2i(960,615); await _settle(); _fixture(7); await _settle()
	_check_layout(game); await _capture_now("feedback_compact_initial.png")
	await _tap(KEY_A); await create_timer(0.27).timeout; await _capture_now("feedback_compact_death.png")
	await _tap(KEY_Z); _check_layout(game)
	print("FEEDBACK SCENE RESULT: %d checks, %d failures;display=%s" % [checks,failures,DisplayServer.get_name()])
	quit(0 if failures == 0 else 1)

func _fixture(index: int) -> Dictionary:
	if not game.model.alive: _check(game.model.undo(),"fixture preparation legally undoes prior death")
	game.board.cancel_feedback()
	_check(game.model.load_level(Definition.from_dictionary(Cases.cases()[index]["data"])),"explicit temporary feedback sandbox loads")
	game.menu.hide(); game.ui_root.show(); game._rebuild_ui()
	game._refresh(Cases.cases()[index]["caption"])
	return game.model.snapshot()

func _tap(code: int) -> void:
	for down in [true,false]:
		var event := InputEventKey.new(); event.keycode = code; event.physical_keycode = code; event.pressed = down
		Input.parse_input_event(event); await process_frame

func _capture_now(filename: String) -> void:
	if capture_dir.is_empty(): return
	_check(DisplayServer.get_name() != "headless","mid-animation screenshots require actual rendering")
	await RenderingServer.frame_post_draw
	var picture := root.get_texture().get_image()
	DirAccess.make_dir_recursive_absolute(capture_dir)
	_check(picture != null and not picture.is_empty() and picture.save_png(capture_dir.path_join(filename)) == OK,"actual feedback frame saved: "+filename)
