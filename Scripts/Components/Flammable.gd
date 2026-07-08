class_name Flammable
extends Node
## Component: fire. A burning object damages its own Health over time,
## chars visually, and spreads fire to touching burnable objects.
## PhysicsObject AUTO-ADDS this component when its material has
## burnable = true — flammability is data-driven by material, so Wood
## and Flesh objects burn without any per-scene setup.

signal ignited
signal extinguished

@export var burn_damage_per_second: float = 15.0
## Seconds of contact with a burning body before this one ignites.
@export var ignite_contact_time: float = 0.6
## Burning stops after this long if the object survives (charred).
@export var burn_out_time: float = 8.0
## Start burning immediately (used by the Ember).
@export var auto_ignite: bool = false
## Never chars, never burns out, takes no burn damage (the Ember).
@export var eternal: bool = false

const CHAR_COLOR := Color(0.3, 0.25, 0.22)

var burning: bool = false
var _body: RigidBody2D
var _burn_elapsed: float = 0.0
var _heat: float = 0.0
var _flames: CPUParticles2D

func _ready() -> void:
	_body = get_parent() as RigidBody2D
	if _body == null:
		push_warning("Flammable must be a child of a RigidBody2D.")
		return
	if auto_ignite:
		ignite()

## Called by burning neighbors while touching. Ignites past threshold.
func add_heat(amount: float) -> void:
	if burning:
		return
	_heat += amount
	if _heat >= ignite_contact_time:
		ignite()

func ignite() -> void:
	if burning:
		return
	burning = true
	_burn_elapsed = 0.0
	_make_flames()
	ignited.emit()

func extinguish() -> void:
	if not burning or eternal:
		return
	burning = false
	if is_instance_valid(_flames):
		_flames.emitting = false   # let existing particles fade out
		var f := _flames
		get_tree().create_timer(1.0).timeout.connect(f.queue_free)
	_flames = null
	extinguished.emit()

func _physics_process(delta: float) -> void:
	if not burning or _body == null:
		return
	_burn_elapsed += delta
	if not eternal:
		# Damage-over-time chains into Health -> Breakable -> fragments.
		var health := _body.get_node_or_null(^"Health") as Health
		if health:
			health.take_damage(burn_damage_per_second * delta)
		# Char toward black as it burns.
		_body.modulate = _body.modulate.lerp(CHAR_COLOR, delta * 0.25)
	# Spread: heat up any touching flammable that isn't burning yet.
	# (Requires contact_monitor on the body — PhysicsObject enables it.)
	for other in _body.get_colliding_bodies():
		var f := other.get_node_or_null(^"Flammable") as Flammable
		if f and not f.burning:
			f.add_heat(delta)
	if not eternal and burn_out_time > 0.0 and _burn_elapsed >= burn_out_time:
		extinguish()

func _make_flames() -> void:
	_flames = CPUParticles2D.new()
	_flames.amount = 26
	_flames.lifetime = 0.55
	_flames.local_coords = false     # flames trail behind moving objects
	_flames.direction = Vector2.UP
	_flames.spread = 20.0
	_flames.gravity = Vector2(0, -220)
	_flames.initial_velocity_min = 20.0
	_flames.initial_velocity_max = 60.0
	_flames.scale_amount_min = 2.0
	_flames.scale_amount_max = 4.5
	_flames.color = Color(1.0, 0.55, 0.1, 0.9)
	_flames.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	_flames.emission_sphere_radius = _body_radius()
	_body.add_child(_flames)

func _body_radius() -> float:
	for child in _body.get_children():
		if child is CollisionShape2D and child.shape:
			var s: Shape2D = child.shape
			if s is CircleShape2D:
				return (s as CircleShape2D).radius
			if s is RectangleShape2D:
				return (s as RectangleShape2D).size.length() * 0.3
	return 12.0
