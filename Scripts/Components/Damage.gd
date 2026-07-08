class_name Damage
extends Node
## Component: converts collision impacts into damage on THIS object's
## Health. Gentle contacts (below threshold) are free; hard impacts
## scale with relative speed and the other body's mass.

## Impact speed (px/s) below which no damage is taken.
@export var speed_threshold: float = 250.0
## Damage per (px/s over threshold), scaled by impactor mass.
@export var damage_factor: float = 0.05

var _body: RigidBody2D
## Velocity captured BEFORE the physics solver runs each frame —
## body_entered fires after the solver, when the impact has already
## drained the velocity (same fix as Bleeder).
var _pre_step_velocity: Vector2 = Vector2.ZERO

func _ready() -> void:
	_body = get_parent() as RigidBody2D
	if _body == null:
		push_warning("Damage must be a child of a RigidBody2D.")
		return
	_body.body_entered.connect(_on_body_entered)

func _physics_process(_delta: float) -> void:
	if is_instance_valid(_body):
		_pre_step_velocity = _body.linear_velocity

func _on_body_entered(other: Node) -> void:
	if not is_instance_valid(_body):
		return
	var health := _body.get_node_or_null(^"Health") as Health
	if health == null:
		return
	var relative_speed: float = _pre_step_velocity.length()
	var other_mass := 10.0  # static bodies (ground, walls) hit hard
	if other is RigidBody2D:
		relative_speed = (_pre_step_velocity - (other as RigidBody2D).linear_velocity).length()
		other_mass = (other as RigidBody2D).mass
	if relative_speed <= speed_threshold:
		return
	var amount := (relative_speed - speed_threshold) * damage_factor * other_mass
	health.take_damage(amount)
