extends SceneTree
## Godot Movie Maker capture driven exclusively by normal keyboard events.

const KEYS := {"U": KEY_W, "D": KEY_S, "L": KEY_A, "R": KEY_D}
const DIRECTIONS := {"U":Vector2i.UP,"D":Vector2i.DOWN,"L":Vector2i.LEFT,"R":Vector2i.RIGHT}
const STEP_FRAMES := 18
const INITIAL_FRAMES := 60
const VICTORY_FRAMES := 90

var level_number: int = 1
var report_path: String = ""
var game: Control


func _init() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--level="):
			level_number = int(argument.trim_prefix("--level="))
		if argument.begins_with("--report="):
			report_path = argument.trim_prefix("--report=")
	call_deferred("_run")


func _run() -> void:
	if level_number not in [1, 2, 3, 4, 5, 6, 7, 8, 9] or report_path.is_empty():
		_fail("Pass --level=1 through 9 and an absolute --report path.")
		return
	if DisplayServer.get_name() == "headless" or Engine.get_write_movie_path().is_empty():
		_fail("Recording requires a real renderer and --write-movie.")
		return
	root.size = Vector2i(1280, 820)
	var solution: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://levels/solutions/north_%02d.json" % level_number))
	game = load("res://scenes/main.tscn").instantiate()
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
	print("REPLAY START: chapter 01, level %02d, %s" % [level_number, solution["path"]])
	var previous := initial
	for i in solution["path"].length():
		var symbol: String = solution["path"][i]
		var use_swap:=symbol!=symbol.to_upper()
		var target: Dictionary={}
		if use_swap:
			target=game.model.swap_target(DIRECTIONS[symbol.to_upper()])
			if target.get("result")!=&"target":
				_fail("Ability input %d has no legal first visible target." % (i+1))
				return
			_send_key(KEY_SHIFT,true)
		_send_key(KEYS[symbol.to_upper()], true,use_swap)
		await _frames(1)
		_send_key(KEYS[symbol.to_upper()], false,use_swap)
		if use_swap:_send_key(KEY_SHIFT,false)
		await _frames(1)
		var current := _state()
		var distance: int = absi(current["player"][0] - previous["player"][0]) + absi(current["player"][1] - previous["player"][1])
		var position_valid:=distance==1
		if use_swap:
			position_valid=current["player"]==[target["cell"].x,target["cell"].y] and current["swaps"]==previous["swaps"]+1
			for crystal in current["crystals"]:
				if crystal["id"]==target["id"]:position_valid=position_valid and crystal["position"]==previous["player"]
		else:
			position_valid=position_valid and current["swaps"]==previous["swaps"]
		if not current["alive"] or current["moves"] != i + 1 or not position_valid or current["pushes"] < previous["pushes"] or current["pushes"] > previous["pushes"] + 1 or current["pulls"] < previous["pulls"] or current["pulls"] > previous["pulls"] + 1:
			_fail("Input %d did not make exactly one legal walk or explicit exchange." % (i + 1))
			return
		current["input"] = symbol
		current["action"]="swap" if use_swap else "move"
		trace.append(current)
		previous = current
		await _frames(STEP_FRAMES - 2)
	var final := _state()
	if not final["completed"] or final["moves"] != solution["moves"] or final["pushes"] != solution["pushes"] or final["pulls"] != solution.get("pulls", 0) or final["swaps"]!=solution.get("swaps",0):
		_fail("Playback did not finish at the expected victory state.")
		return
	await _frames(VICTORY_FRAMES)
	var report := {"chapter": 1, "level": level_number,
		"game_implementation_commit": OS.get_environment("STARDOWN_RECORDING_COMMIT"),
		"engine": Engine.get_version_info(), "display": DisplayServer.get_name(),
		"capture": "Godot Movie Maker viewport; actual Input.parse_input_event press/release",
		"movie_file": Engine.get_write_movie_path().get_file(),
		"fps": 30, "frames_per_input": STEP_FRAMES,
		"initial_pause_frames": INITIAL_FRAMES, "victory_pause_frames": VICTORY_FRAMES,
		"path": solution["path"], "initial_state": initial, "trace": trace, "final_state": final}
	DirAccess.make_dir_recursive_absolute(report_path.get_base_dir())
	var file := FileAccess.open(report_path, FileAccess.WRITE)
	if file == null:
		_fail("Cannot write recording evidence.")
		return
	file.store_string(JSON.stringify(report, "  ") + "\n")
	file.close()
	print("REPLAY RESULT: level %02d; %d legal actions, %d pushes, %d pulls, %d swaps, victory=true" % [level_number, final["moves"], final["pushes"], final["pulls"],final["swaps"]])
	quit(0)


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
	return {"level_id": game.model.level.id, "player": [game.model.player.x, game.model.player.y],
		"crystals": crystals, "moves": game.model.moves, "pushes": game.model.pushes, "pulls": game.model.pulls,"swaps":game.model.swaps, "hero_kind": game.model.level.hero_kind,
		"completed": game.model.is_complete(), "exit": [game.model.level.exit_cell.x, game.model.level.exit_cell.y],
		"exit_color": game.model.level.exit_color, "alive": game.model.alive,
		"pressure": game.model.pressure_states(), "barriers": barriers, "bushes": bushes, "plates": plates}


func _send_key(code: int, pressed: bool, shift: bool=false) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = pressed
	event.shift_pressed=shift
	Input.parse_input_event(event)


func _frames(count: int) -> void:
	for i in count:
		await process_frame


func _fail(message: String) -> void:
	printerr("ERROR: recording replay: ", message)
	quit(1)
