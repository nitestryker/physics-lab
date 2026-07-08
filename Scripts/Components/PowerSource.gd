class_name PowerSource
extends Node
## Component: marks the parent body as always-live. The PowerNetwork
## floods power from every source through touching conductive bodies.

func _ready() -> void:
	add_to_group("power_sources")
