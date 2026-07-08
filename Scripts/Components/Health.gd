class_name Health
extends Node
## Component: hit points. Emits died when depleted. If the parent
## PhysicsObject has a material, max health scales with its strength.

signal changed(current: float, max_value: float)
signal died

@export var max_health: float = 100.0
## Multiply max_health by the material's strength value.
@export var scale_with_material_strength: bool = true

var current: float

func _ready() -> void:
	var parent := get_parent()
	if scale_with_material_strength and parent is PhysicsObject and parent.object_material:
		max_health *= parent.object_material.strength
	current = max_health

func take_damage(amount: float) -> void:
	if current <= 0.0 or amount <= 0.0:
		return
	current = maxf(0.0, current - amount)
	changed.emit(current, max_health)
	if current == 0.0:
		died.emit()
