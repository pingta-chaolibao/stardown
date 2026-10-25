extends SceneTree
## Godot Movie Maker capture driven exclusively by normal keyboard events.

const KEYS := {"U": KEY_W, "D": KEY_S, "L": KEY_A, "R": KEY_D, "C":KEY_C}
const DIRECTIONS := {"U":Vector2i.UP,"D":Vector2i.DOWN,"L":Vector2i.LEFT,"R":Vector2i.RIGHT}
const STEP_FRAMES := 18
const INITIAL_FRAMES := 60
const VICTORY_FRAMES := 90

var level_number: int = 1
var report_path: String = ""
var game: Control
# Recording telemetry only; never part of GridState or its undo history.
var selection_events: int=0
var dragon_pulls:int=0
var track_dragon_pulls:bool=false


func _init() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--level="):
			level_number = int(argument.trim_prefix("--level="))
		if argument.begins_with("--report="):
			report_path = argument.trim_prefix("--report=")
	call_deferred("_run")


func _run() -> void:
	if level_number<1 or level_number>33 or report_path.is_empty():
		_fail("Pass --level=1 through 33 and an absolute --report path.")
		return
	if DisplayServer.get_name() == "headless" or Engine.get_write_movie_path().is_empty():
		_fail("Recording requires a real renderer and --write-movie.")
		return
	root.size = Vector2i(1280, 820)
	var solution: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://levels/solutions/north_%02d.json" % level_number))
	track_dragon_pulls=solution.has("dragon_pulls")
	game = load("res://scenes/main.tscn").instantiate()
	game.start_in_level = true
	# Choosing the exported startup level happens before the first rendered frame.
	# After initialization, all movement uses only actual press/release events.
	game.level_path = "res://levels/north_%02d.json" % level_number
	root.add_child(game)
	await _frames(INITIAL_FRAMES)
	var initial := _state()
	if initial["level_id"] != solution["level_id"] or initial["moves"] != 0 or initial["completed"]:
		_fail("Initial state is not the selected level's unsolved start.")
		return
	var trace: Array[Dictionary] = []
	var visual_feedback: Array[Dictionary] = []
	print("REPLAY START: chapter 01, level %02d, %s" % [level_number, solution["path"]])
	var previous := initial
	var actual_actions:=0
	for i in solution["path"].length():
		if game.board.feedback.is_busy():
			_fail("Previous visual feedback must finish before the next recorded input.")
			return
		var symbol: String = solution["path"][i]
		var target: Dictionary={}
		if symbol!="C" and game.model.active_kind()=="blue":
			target=game.model.swap_target(DIRECTIONS[symbol])
		var use_swap: bool=target.get("result")==&"target"
		_send_key(KEYS[symbol], true)
		await _frames(1)
		_send_key(KEYS[symbol], false)
		await _frames(1)
		if symbol=="C":selection_events+=1
		else:actual_actions+=1
		var current := _state()
		if track_dragon_pulls and symbol!="C" and game.model.active_kind()=="green" and current["pulls"]==previous["pulls"]+1:
			var moved_dragons:int=0
			for m in current.get("monsters",[]):
				if m["kind"]=="fire_dragon" and m["position"]!=previous["monsters"][m["id"]]["position"]:moved_dragons+=1
			if moved_dragons>1:
				_fail("A green input moved more than one dragon.");return
			dragon_pulls+=moved_dragons
		if track_dragon_pulls:current["dragon_pulls"]=dragon_pulls
		var visual := _visual_sample(i,symbol)
		var world_after_input: Dictionary = game.model.snapshot()
		var selection_after_input: int = game.model.active_hero_index
		var distance: int = absi(current["player"][0] - previous["player"][0]) + absi(current["player"][1] - previous["player"][1])
		var position_valid:=distance==1
		if symbol=="C":
			position_valid=current["selection_events"]==previous["selection_events"]+1 and current["moves"]==previous["moves"] and current["history_size"]==previous["history_size"] and current["crystals"]==previous["crystals"] and current["pressure"]==previous["pressure"] and current["barriers"]==previous["barriers"]
			for identity in current["heroes"].size():
				position_valid=position_valid and current["heroes"][identity]["position"]==previous["heroes"][identity]["position"] and current["heroes"][identity]["alive"]==previous["heroes"][identity]["alive"]
			position_valid=position_valid and current["active_hero_index"]==(previous["active_hero_index"]+1)%current["heroes"].size()
		elif use_swap:
			position_valid=current["player"]==[target["cell"].x,target["cell"].y] and current["swaps"]==previous["swaps"]+1
			if target["kind"]==&"hero":
				position_valid=position_valid and current["heroes"][target["id"]]["position"]==previous["player"]
			elif target["kind"]==&"monster":
				for monster in current["monsters"]:
					if monster["id"]==target["id"]:position_valid=position_valid and monster["position"]==previous["player"]
			else:
				for crystal in current["crystals"]:
					if crystal["id"]==target["id"]:position_valid=position_valid and crystal["position"]==previous["player"]
		else:
			position_valid=position_valid and current["swaps"]==previous["swaps"]
		if not current["alive"] or current["moves"] != actual_actions or not position_valid or current["pushes"] < previous["pushes"] or current["pushes"] > previous["pushes"] + 1 or current["pulls"] < previous["pulls"] or current["pulls"] > previous["pulls"] + 1:
			_fail("Input %d failed: counted movement or uncounted selection did not match." % (i + 1))
			return
		current["event_index"]=i+1
		current["input"] = symbol
		current["action"]="switch" if symbol=="C" else ("swap" if use_swap else "move")
		trace.append(current)
		previous = current
		await _frames(STEP_FRAMES - 2)
		visual["settled_at_step_end"] = not game.board.feedback.is_busy()
		visual["world_unchanged_during_feedback"] = game.model.snapshot()==world_after_input and game.model.active_hero_index==selection_after_input
		if not visual["settled_at_step_end"] or not visual["world_unchanged_during_feedback"]:
			_fail("Visual clock did not settle cleanly or changed gameplay state.")
			return
		visual_feedback.append(visual)
	var final := _state()
	if not final["completed"] or final["moves"] != solution["moves"] or final["pushes"] != solution["pushes"] or final["pulls"] != solution.get("pulls", 0) or final["swaps"]!=solution.get("swaps",0) or selection_events!=solution.get("selection_events",0) or solution["path"].length()!=solution.get("input_events",solution["moves"]):
		_fail("Playback did not finish at the expected victory state.")
		return
	if solution.has("destroyed_crystals") and game.model.crates().size()!=game.model.level.initial_crates.size()-int(solution["destroyed_crystals"]):
		_fail("Final surviving crystal count does not match confirmed destruction route.")
		return
	if track_dragon_pulls and dragon_pulls!=int(solution["dragon_pulls"]):
		_fail("Dragon pull count differs from checked solution.");return
	if solution.has("crystal_pulls") and game.model.pulls-dragon_pulls!=int(solution["crystal_pulls"]):
		_fail("Crystal pull count differs from checked solution.");return
	await _frames(VICTORY_FRAMES)
	var report := {"input_events":solution["path"].length(),"direction_actions":actual_actions,"selection_events":selection_events,"chapter": 1, "level": level_number,
		"game_implementation_commit": OS.get_environment("STARDOWN_RECORDING_COMMIT"),
		"engine": Engine.get_version_info(), "display": DisplayServer.get_name(),
		"capture": "Godot Movie Maker viewport; actual Input.parse_input_event press/release",
		"movie_file": Engine.get_write_movie_path().get_file(),
		"fps": 30, "frames_per_input": STEP_FRAMES,
		"initial_pause_frames": INITIAL_FRAMES, "victory_pause_frames": VICTORY_FRAMES,
		"path": solution["path"], "initial_state": initial, "trace": trace, "final_state": final,
		"visual_feedback":visual_feedback,"visual_feedback_enabled":true,"attack_feedback_requires_target":true}
	DirAccess.make_dir_recursive_absolute(report_path.get_base_dir())
	var file := FileAccess.open(report_path, FileAccess.WRITE)
	if file == null:
		_fail("Cannot write recording evidence.")
		return
	file.store_string(JSON.stringify(report, "  ") + "\n")
	file.close()
	print("REPLAY RESULT: level %02d; %d actual actions, %d uncounted selection events, %d pushes, %d pulls, %d swaps, victory=true" % [level_number, final["moves"],selection_events, final["pushes"], final["pulls"],final["swaps"]])
	quit(0)


func _visual_sample(index: int, symbol: String) -> Dictionary:
	var clock = game.board.feedback
	var motions: Array[Dictionary] = []
	for key: String in clock.plan.get("motion",{}):
		var motion: Dictionary = clock.plan["motion"][key]
		var at: Vector2 = clock.position(key,motion["to"])
		motions.append({"key":key,"from":[motion["from"].x,motion["from"].y],"to":[motion["to"].x,motion["to"].y],"displayed":[at.x,at.y]})
	var rays: Array[Dictionary] = []
	for ray in clock.plan.get("fire",[]):
		var cells: Array = []
		for cell in ray["cells"]: cells.append([cell.x,cell.y])
		rays.append({"dragon":ray["dragon"],"from":[ray["from"].x,ray["from"].y],"facing":[ray["facing"].x,ray["facing"].y],"cells":cells,"target":ray["target"]})
	var deaths: Array[String] = []
	for event in clock.plan.get("deaths",[]): deaths.append(event["key"])
	var strikes: Array[Dictionary] = []
	for event in clock.plan.get("goblin",[]):
		strikes.append({"from":[event["from"].x,event["from"].y],"to":[event["to"].x,event["to"].y]})
	var energy: Array[Dictionary] = []
	for event in clock.plan.get("energy",[]):
		energy.append({"cell":[event["cell"].x,event["cell"].y],"active":event["active"]})
	return {"event_index":index+1,"input":symbol,"start_frame":INITIAL_FRAMES+index*STEP_FRAMES,
		"sample_age_seconds":clock.age,"swap":clock.plan.get("swap",false),"motions":motions,
		"locked_fire":rays,"locked_goblin":strikes,"energy_changes":energy,"death_keys":deaths}


func _state() -> Dictionary:
	var crystals: Array[Dictionary] = []
	for identity in game.model.level.initial_crates.size():
		for cell in game.model.crates():
			if game.model.crate_id(cell) == identity:
				crystals.append({"id": identity, "position": [cell.x, cell.y], "color": game.model.level.crystal_colors[identity]})
	var barriers: Array[Dictionary] = []
	for cell: Vector2i in game.model.barrier_states():
		barriers.append({"position": [cell.x, cell.y], "active": game.model.barrier_is_active(cell)})
	var bushes: Array = []
	for bush in game.model.level.bushes:
		bushes.append([bush.cell.x, bush.cell.y])
	var plates: Array[Dictionary] = []
	for link in game.model.level.energy_links:
		for cell: Vector2i in link["plates"]:
			plates.append({"group": link["id"], "position": [cell.x, cell.y], "pressed": game.model.pressure_cell_is_active(link["id"], cell)})
	var result: Dictionary={"level_id": game.model.level.id, "player": [game.model.player.x, game.model.player.y],
		"crystals": crystals, "moves": game.model.moves, "pushes": game.model.pushes, "pulls": game.model.pulls,"swaps":game.model.swaps, "hero_kind": game.model.active_kind(),
		"completed": game.model.is_complete(), "exit": [game.model.level.exit_cell.x, game.model.level.exit_cell.y],
		"exit_color": game.model.level.exit_color, "alive": game.model.alive,
		"pressure": game.model.pressure_states(), "barriers": barriers, "bushes": bushes, "plates": plates}

	if game.model.hero_count()>1:
		var heroes: Array[Dictionary]=[]
		for hero in game.model.heroes():
			heroes.append({"id":hero["id"],"kind":hero["kind"],"position":[hero["position"].x,hero["position"].y],"alive":hero["alive"],"selected":hero["selected"]})
		var exits: Array=[]
		for cell in game.model.level.exit_cells:exits.append([cell.x,cell.y])
		result.erase("exit")
		result.merge({"heroes":heroes,"active_hero_index":game.model.active_hero_index,"active_hero":game.model.active_hero_id(),"selection_events":selection_events,"history_size":game.model.history_size(),"exits":exits,"occupied_exits":game.model.occupied_exits()})
	if not game.model.level.initial_monsters.is_empty():
		var monsters:Array=[]
		for monster in game.model.monsters():
			var entry:Dictionary={"id":monster["id"],"kind":monster["kind"],"position":[monster["position"].x,monster["position"].y],"alive":monster["alive"]}
			if monster.has("facing"):entry["facing"]=[monster["facing"].x,monster["facing"].y]
			monsters.append(entry)
		result["monsters"]=monsters
		result["death_reason"]=game.model.death_reason
	if track_dragon_pulls:result["dragon_pulls"]=dragon_pulls
	if not game.model.level.fence_edges.is_empty():
		var edges:Array=[]
		for edge in game.model.level.fence_edges:edges.append([[edge["a"].x,edge["a"].y],[edge["b"].x,edge["b"].y]])
		result["fences"]=edges
	return result


func _send_key(code: int, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = pressed
	Input.parse_input_event(event)


func _frames(count: int) -> void:
	for i in count:
		await process_frame


func _fail(message: String) -> void:
	printerr("ERROR: recording replay: ", message)
	quit(1)
