extends Node
## Autoload singleton. Holds global state and decoupled signals so UI,
## spawner, and world never need direct references to each other.

signal spawn_requested(type: String)
signal selected_changed(type: String)
signal clear_requested

## The object type placed when the player clicks in the world.
## Empty string = Drag mode: clicking empty space places nothing.
var selected_type: String = "":
	set(value):
		selected_type = value
		selected_changed.emit(value)

func request_spawn(type: String) -> void:
	spawn_requested.emit(type)

func request_clear() -> void:
	clear_requested.emit()
