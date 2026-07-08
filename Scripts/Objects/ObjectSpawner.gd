class_name ObjectSpawner
extends Node2D
## Spawns physics objects. Two paths:
##  - click in the world -> place the currently selected type at mouse
##  - GameManager.spawn_requested (Developer Panel quick-spawn buttons)
##    -> drop the object at spawn_point
## Every object must be spawnable through this single system
## (Development Rules).
##
## OVERLAP GUARD: spawning an object inside a platform or another
## object makes the solver eject it violently (or wedge it). Before
## placing anything, the spawner probes a clearance circle at the
## target and nudges upward until the space is free.

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
	"Ember": preload("res://Scenes/Objects/Ember.tscn"),
}

## Approximate clearance radius each object needs to spawn cleanly.
const CLEARANCE := {
	"Box": 34.0, "Ball": 28.0, "Beam": 95.0, "Ragdoll": 90.0,
	"Rope": 20.0, "Spring": 30.0, "Wheel": 30.0, "Motor": 105.0,
	"Car": 95.0, "Ember": 14.0,
}

## Where quick-spawned objects drop from (a Marker2D in the world).
@export var spawn_point: Node2D

func _ready() -> void:
	GameManager.spawn_requested.connect(_on_spawn_requested)
	GameManager.clear_requested.connect(clear_spawned)

func _unhandled_input(event: InputEvent) -> void:
	# Only reached if the Grabber didn't consume the click (see Grabber).
	if event.is_action_pressed("primary_action"):
		if GameManager.selected_type == "":
			return  # Drag mode: missing a grab never spawns anything
		spawn(GameManager.selected_type, get_global_mouse_position())
		get_viewport().set_input_as_handled()

func _on_spawn_requested(type: String) -> void:
	var pos := spawn_point.global_position if spawn_point else Vector2(640, 100)
	# Real jitter so rapid quick-spawns don't interpenetrate each other.
	pos.x += randf_range(-30.0, 30.0)
	spawn(type, pos)

func spawn(type: String, position_: Vector2) -> Node2D:
	if not SCENES.has(type):
		push_warning("Unknown object type: %s" % type)
		return null
	var radius: float = CLEARANCE.get(type, 40.0)
	var clear := _find_clear_position(position_, radius)
	if clear == Vector2.INF:
		return null  # completely blocked (e.g. clicked inside the ground)
	var obj: Node2D = SCENES[type].instantiate()
	obj.global_position = clear
	get_parent().add_child(obj)
	return obj

## Remove every spawned object (and its effects), leaving the default
## environment untouched. Uses the same owner-delegation as right-click
## removal, so composites (ragdolls, ropes, cars) clear as whole units.
func clear_spawned() -> void:
	for body in get_tree().get_nodes_in_group("physics_objects"):
		if not is_instance_valid(body):
			continue
		var target: Node = body
		if body.owner != null and body.owner.has_method("remove"):
			target = body.owner
		if target.has_method("remove"):
			target.remove()
		else:
			target.queue_free()
	EffectsManager.clear_effects()

## Probe a circle at pos; if occupied, step upward looking for space.
## Lets you click ON a platform and get the object placed above it,
## instead of embedded inside it.
func _find_clear_position(pos: Vector2, radius: float) -> Vector2:
	var space := get_world_2d().direct_space_state
	var shape := CircleShape2D.new()
	shape.radius = radius
	var params := PhysicsShapeQueryParameters2D.new()
	params.shape = shape
	params.collision_mask = 1  # world + objects; ignores ash/blood layers
	var step := maxf(radius * 0.6, 20.0)
	for attempt in 10:
		var candidate := pos + Vector2(0, -step * attempt)
		params.transform = Transform2D(0.0, candidate)
		if space.intersect_shape(params, 1).is_empty():
			return candidate
	return Vector2.INF
