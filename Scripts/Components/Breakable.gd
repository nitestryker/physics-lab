class_name Breakable
extends Node
## Component: removes the object when its sibling Health dies.
## TODO (later milestone): spawn fragment scenes with inherited velocity
## instead of simply freeing the object.

func _ready() -> void:
	var health := get_parent().get_node_or_null(^"Health") as Health
	if health == null:
		push_warning("Breakable requires a sibling Health component.")
		return
	health.died.connect(_on_died)

func _on_died() -> void:
	var parent := get_parent()
	if parent is PhysicsObject:
		parent.remove()
	else:
		parent.queue_free()
