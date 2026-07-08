class_name ObjectSpawner
extends Node2D
## Spawns physics objects. Two paths:
##  - click in the world -> place the currently selected type at mouse
##  - GameManager.spawn_requested (Developer Panel quick-spawn buttons)
##    -> drop the object at spawn_point
## Every object must be spawnable through this single system
## (Development Rules).

const SCENES := {
	"Box": preload("res://Scenes/Objects/Box.tscn"),
	"Ball": preload("res://Scenes/Objects/Ball.tscn"),
	"Beam": preload("res://Scenes/Objects/Beam.tscn"),
	"Ragdoll": preload("res://Scenes/Characters/Ragdoll.tscn"),
	"Rope": preload("res://Scenes/Joints/Rope.tscn"),
	"Spring": preload("res://Scenes/Joints/Spring.tscn"),
	"Wheel": preload("res://Scenes/Objects/Wheel.tscn"),
	"Motor": preload("res://Scenes/Joints/Motor.tscn"),
	"Car": preload("res://Scenes/Objects/Car.tscn"),
}

## Where quick-spawned objects drop from (a Marker2D in the world).
@export var spawn_point: Node2D

func _ready() -> void:
	GameManager.spawn_requested.connect(_on_spawn_requested)

func _unhandled_input(event: InputEvent) -> void:
	# Only reached if the Grabber didn't consume the click (see Grabber).
	if event.is_action_pressed("primary_action"):
		spawn(GameManager.selected_type, get_global_mouse_position())
		get_viewport().set_input_as_handled()

func _on_spawn_requested(type: String) -> void:
	var pos := spawn_point.global_position if spawn_point else Vector2(640, 100)
	# Small jitter so stacked quick-spawns don't overlap perfectly.
	pos.x += randf_range(-8.0, 8.0)
	spawn(type, pos)

# Returns Node2D, not PhysicsObject: multi-body objects (Ragdoll) have a
# plain Node2D root that only mirrors the PhysicsObject API (remove()).
func spawn(type: String, position_: Vector2) -> Node2D:
	if not SCENES.has(type):
		push_warning("Unknown object type: %s" % type)
		return null
	var obj: Node2D = SCENES[type].instantiate()
	obj.global_position = position_
	get_parent().add_child(obj)
	return obj
