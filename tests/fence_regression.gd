extends SceneTree
const Level=preload("res://scripts/core/level_data.gd")
const State=preload("res://scripts/core/grid_state.gd")
const DIRS=[Vector2i.UP,Vector2i.DOWN,Vector2i.LEFT,Vector2i.RIGHT]
var checks:=0
var failures:=0
func _init() -> void:
	_data_validation();_bidirectional_walk();_mixed_chains();_pull_edges();_swap_and_blockers()
	print("FENCE RESULT: 5 cases, %d checks, %d failures" % [checks,failures]);quit(0 if failures==0 else 1)

func _data_validation() -> void:
	var a:=Vector2i(3,3);var b:=Vector2i(3,4);var data:=_data();data["fences"]=[_edge(b,a)]
	var level:=Level.from_dictionary(data)
	_check(level.error.is_empty() and level.fence_edges.size()==1 and level.has_fence(a,b) and level.has_fence(b,a),"edge normalized,undirected and symmetric")
	_check(level.is_floor(a) and level.is_floor(b) and level.fence_edges[0]=={"a":a,"b":b},"fence never consumes endpoint cells")
	for invalid in [null,"edge",{},[[[1,1]]],[[[1,1],[1,1]]],[[[1,1],[2,2]]],[[[1,1],[1,3]]],[[[-1,1],[0,1]]],[[[8,1],[9,1]]],[[[1.5,1],[2,1]]],[[[true,1],[2,1]]],[_edge(a,b),_edge(a,b)],[_edge(a,b),_edge(b,a)]]:
		var bad:=data.duplicate(true);bad["fences"]=invalid
		_check(not Level.from_dictionary(bad).error.is_empty(),"invalid/malformed/nonadjacent/duplicate/reversed edge rejected")
	var wall:=data.duplicate(true);wall["terrain"][4]="...#....."
	_check(not Level.from_dictionary(wall).error.is_empty(),"wall endpoint not a legal floor edge")
	for n in range(1,20):
		var old:=Level.from_file("res://levels/north_%02d.json" % n)
		_check(old.error.is_empty() and old.fence_edges.is_empty() and not old.has_fence(a,b),"old maps omit fences compatibly")

func _bidirectional_walk() -> void:
	var a:=Vector2i(4,4)
	for direction in DIRS:
		var b:Vector2i=a+direction
		for kind in ["red","green","blue"]:
			for reverse in [false,true]:
				var data:=_data(kind,b if reverse else a);data["fences"]=[_edge(a,b)]
				var game:=_game(data);var before:=game.snapshot()
				_check(game.try_move(-direction if reverse else direction)==&"fence_blocked" and game.snapshot()==before and game.moves==0 and game.history_size()==0,"all directions/heroes blocked both ways,blue without target cannot walk")
				_check(game.is_walkable(a) and game.is_walkable(b) and not game.blocks_sight(a) and not game.blocks_sight(b),"edge collision is separate from cell occupancy/sight")

func _mixed_chains() -> void:
	var origin:=Vector2i(4,4)
	for direction in DIRS:
		var data:=_data();data.erase("player");data.erase("hero_kind")
		data["heroes"]=[{"id":"red","kind":"red","position":_cell(origin)},{"id":"green","kind":"green","position":_cell(origin+direction)},{"id":"blue","kind":"blue","position":_cell(origin+direction*3)}];data["active_hero"]="red"
		data["crates"]=[_cell(origin+direction*2)]
		for step in 4:
			var blocked:=data.duplicate(true);blocked["fences"]=[_edge(origin+direction*step,origin+direction*(step+1))]
			var game:=_game(blocked);var before:=game.snapshot()
			_check(game.try_move(direction)==&"fence_blocked" and game.snapshot()==before and game.history_size()==0,"fence at any hero/mixed-chain edge rejects all movement atomically")
		var game:=_game(data);var initial:=game.snapshot()
		_check(game.try_move(direction)==&"pushed" and game.hero_position(0)==origin+direction and game.hero_position(1)==origin+direction*2 and game.crate_id(origin+direction*3)==0 and game.hero_position(2)==origin+direction*4,"unfenced mixed line still pushes one step without passive abilities")
		game.switch_hero();_check(game.undo() and game.snapshot()==initial and game.active_hero_id()=="green","undo mixed movement restores identities and preserves free selection")

func _pull_edges() -> void:
	var origin:=Vector2i(4,4)
	for direction in DIRS:
		var data:=_data("green",origin);data["crates"]=[_cell(origin-direction),_cell(origin-direction*2)]
		data["fences"]=[_edge(origin-direction,origin)]
		var game:=_game(data);var initial:=game.snapshot()
		_check(game.try_move(direction)==&"fence_blocked" and game.snapshot()==initial and game.history_size()==0,"blocked automatic pull also blocks hero,not a partial walk")
		data["fences"]=[_edge(origin,origin+direction)];game=_game(data);initial=game.snapshot()
		_check(game.try_move(direction)==&"fence_blocked" and game.snapshot()==initial,"blocked hero step never drags crystal across or records history")
		data["fences"]=[_edge(origin-direction*2,origin-direction)];game=_game(data);initial=game.snapshot()
		_check(game.try_move(direction)==&"pulled" and game.player==origin+direction and game.crate_id(origin)==0 and game.crate_id(origin-direction*2)==1,"only nearest crystal pulls; fence behind it is not crossed")
		_check(game.undo() and game.snapshot()==initial,"pull undo restores both crystal IDs and edges remain immutable")

func _swap_and_blockers() -> void:
	var origin:=Vector2i(3,1);var target:=Vector2i(3,5);var edge:=_edge(origin,origin+Vector2i.DOWN)
	for kind in ["crystal","hero"]:
		var data:=_data("blue",origin);data["fences"]=[edge]
		if kind=="crystal":data["crates"]=[_cell(target)]
		else:
			data.erase("player");data.erase("hero_kind");data["heroes"]=[{"id":"blue","kind":"blue","position":_cell(origin)},{"id":"green","kind":"green","position":_cell(target)}];data["active_hero"]="blue";data["crates"]=[[3,6]]
		var game:=_game(data);var initial:=game.snapshot()
		_check(game.swap_target(Vector2i.DOWN).get("cell")==target and game.try_move(Vector2i.DOWN)==&"swapped" and game.player==target and game.swaps==1,"blue swaps first visible hero/crystal across fence")
		_check(game.undo() and game.snapshot()==initial,"cross-fence exchange undo is atomic")
		for blocker in ["wall","bush","energy"]:
			var blocked:=data.duplicate(true)
			if blocker=="wall":blocked["terrain"][3]="...#....."
			elif blocker=="bush":blocked["bushes"]=[[3,3]]
			else:blocked["energy_links"]=[{"id":"test","plate":[7,7],"barriers":[[3,3]],"pressure_sources":["hero","crystal"]}]
			game=_game(blocked);initial=game.snapshot()
			_check(game.swap_target(Vector2i.DOWN).get("result")==&"swap_blocked" and game.try_move(Vector2i.DOWN)==&"fence_blocked" and game.snapshot()==initial,"walls,bushes,active energy still stop sight; no illegal fallback walking")
	var nearest:=_data("blue",origin);nearest["crates"]=[[3,2],[3,5]];nearest["fences"]=[edge];nearest["bushes"]=[[3,3]]
	var game:=_game(nearest)
	_check(game.try_move(Vector2i.DOWN)==&"swapped" and game.player==Vector2i(3,2) and game.crate_id(origin)==0 and game.crate_id(Vector2i(3,5))==1,"first target before opaque blocker wins,never skips to farther crystal")

func _data(kind:String="red",origin:Vector2i=Vector2i(4,4)) -> Dictionary:
	return {"schema_version":1,"id":"fence_fixture","title":"Fence regression","is_temporary":true,"source_note":"Independent tests only","terrain":[".........",".........",".........",".........",".........",".........",".........",".........","........."],"player":_cell(origin),"hero_kind":kind,"crates":[],"targets":[],"objective":"none"}
func _game(data:Dictionary) -> State:
	var game:=State.new();var level:=Level.from_dictionary(data);_check(level.error.is_empty() and game.load_level(level),"fence fixture validates and loads");return game
func _cell(c:Vector2i) -> Array:return [c.x,c.y]
func _edge(a:Vector2i,b:Vector2i) -> Array:return [_cell(a),_cell(b)]
func _check(ok:bool,message:String) -> void:
	checks+=1
	if not ok:failures+=1;push_error("FAIL: "+message)
