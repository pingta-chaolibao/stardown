class_name BushObstacle
extends RefCounted
## A distinct static object, not a wall or a movable crystal.

const MOVABLE := false
const EXCHANGEABLE := false
const BLOCKS_MOVEMENT := true
const BLOCKS_SIGHT := true

var cell: Vector2i


func _init(position: Vector2i) -> void:
	cell = position
