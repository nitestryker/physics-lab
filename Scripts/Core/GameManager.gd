extends Node
## Autoload singleton. Holds global state and decoupled signals so UI,
## spawner, and world never need direct references to each other.

signal spawn_requested(type: String)
signal selected_changed(type: String)

## The object type placed when the player clicks in the world.
var selected_type: String = "Box":
	set(value):
		selected_type = value
		selected_changed.emit(value)

func request_spawn(type: String) -> void:
	spawn_requested.emit(type)
