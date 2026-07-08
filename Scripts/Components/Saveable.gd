class_name Saveable
extends Node
## Component STUB: serialization for the future save system.
## Deliberately minimal for now (see project doc: don't build the save
## system before ~0.3, when we know what state actually matters).
## Runtime saves must be written to user://, never res://.

func capture_state() -> Dictionary:
	var body := get_parent()
	return {
		"scene": body.scene_file_path,
		"position": body.global_position,
		"rotation": body.global_rotation,
		"linear_velocity": body.linear_velocity if body is RigidBody2D else Vector2.ZERO,
	}

func restore_state(state: Dictionary) -> void:
	var body := get_parent()
	body.global_position = state.get("position", body.global_position)
	body.global_rotation = state.get("rotation", body.global_rotation)
	if body is RigidBody2D:
		body.linear_velocity = state.get("linear_velocity", Vector2.ZERO)
