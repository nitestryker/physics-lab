class_name Bleeder
extends Node
## Component: blood on hard impacts. When the parent body is thrown
## into something (or something slams into it) above the speed
## threshold, blood sprays from the impact area — an immediate stain on
## whatever was hit, plus droplets flung with the impact that stain
## whatever THEY land on. PhysicsObject AUTO-ADDS this component when
## the material has bleeds = true (Flesh), same pattern as Flammable.

## Relative impact speed (px/s) below which no blood appears.
@export var speed_threshold: float = 240.0
## Impact speed above threshold that counts as maximum severity.
@export var max_severity_speed: float = 650.0

var _body: RigidBody2D
var _cooldown: float = 0.0
## Velocity captured BEFORE the physics solver runs each frame.
## body_entered fires AFTER the solver, when the impact has already
## drained the velocity — measuring there misses almost every hit.
var _pre_step_velocity: Vector2 = Vector2.ZERO

func _ready() -> void:
	_body = get_parent() as RigidBody2D
	if _body == null:
		push_warning("Bleeder must be a child of a RigidBody2D.")
		return
	_body.body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	_cooldown = maxf(0.0, _cooldown - delta)
	if is_instance_valid(_body):
		_pre_step_velocity = _body.linear_velocity

func _on_body_entered(other: Node) -> void:
	if _cooldown > 0.0 or not is_instance_valid(_body):
		return
	# Self-collision guard: parts of the same composite (ragdoll limbs
	# hitting each other while swung around) never draw blood.
	if _body.owner != null and other.owner == _body.owner:
		return
	var relative: Vector2 = _pre_step_velocity
	if other is RigidBody2D:
		relative -= (other as RigidBody2D).linear_velocity
	var speed := relative.length()
	if speed < speed_threshold:
		return
	_cooldown = 0.15  # one splatter per impact, not per contact point
	var severity := (speed - speed_threshold) / (max_severity_speed - speed_threshold)
	# Approximate contact point: on this body's edge, toward the other.
	var direction := Vector2.DOWN
	if other is Node2D:
		direction = ((other as Node2D).global_position - _body.global_position).normalized()
	var contact: Vector2 = _body.global_position + direction * _edge_distance()
	# splatter() spawns bodies — defer out of the physics callback.
	EffectsManager.splatter.call_deferred(contact, relative, severity, _body, other)

func _edge_distance() -> float:
	for child in _body.get_children():
		if child is CollisionShape2D and child.shape:
			var s: Shape2D = child.shape
			if s is CircleShape2D:
				return (s as CircleShape2D).radius
			if s is RectangleShape2D:
				return (s as RectangleShape2D).size.length() * 0.35
	return 10.0
