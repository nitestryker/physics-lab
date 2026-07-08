extends Node
## Autoload singleton. Holds global state and decoupled signals so UI,
## spawner, joint tool, and world never need direct references to each
## other.
##
## TOOL MODES (Milestone 0.6):
##  "drag"  - clicking only grabs; empty clicks do nothing
##  "spawn" - clicking empty space places selected_type
##  "joint" - clicking two bodies connects them with joint_type

signal spawn_requested(type: String)
signal clear_requested
signal tool_changed

var tool_mode: String = "drag"
## Object type placed on click while in spawn mode.
var selected_type: String = ""
## "Pin" | "Spring" | "Rope" while in joint mode.
var joint_type: String = "Pin"

func set_drag() -> void:
	tool_mode = "drag"
	selected_type = ""
	tool_changed.emit()

func set_spawn(type: String) -> void:
	tool_mode = "spawn"
	selected_type = type
	tool_changed.emit()

func set_joint(type: String) -> void:
	tool_mode = "joint"
	joint_type = type
	tool_changed.emit()

func request_spawn(type: String) -> void:
	spawn_requested.emit(type)

func request_clear() -> void:
	clear_requested.emit()
