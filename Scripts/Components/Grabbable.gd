class_name Grabbable
extends Node
## Component: marks the parent body as draggable by the mouse Grabber.
## Attach to any PhysicsObject; no configuration required.

func _ready() -> void:
	var parent := get_parent()
	if parent is PhysicsBody2D:
		parent.add_to_group("grabbable")
	else:
		push_warning("Grabbable must be a child of a PhysicsBody2D.")
