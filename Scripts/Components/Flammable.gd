class_name Flammable
extends Node
## Component: fire. A burning object damages its own Health over time,
## chars from its natural color toward black, and spreads fire to
## touching burnable objects. When fully charred it burns up: a puff of
## ash, a short fade-out, and removal. PhysicsObject AUTO-ADDS this
## component when its material has burnable = true — flammability is
## data-driven by material, so Wood and Flesh burn with no per-scene
## setup.

signal ignited
signal extinguished
signal burned_up

@export var burn_damage_per_second: float = 15.0
## Seconds of contact with a burning body before this one ignites.
@export var ignite_contact_time: float = 0.6
## Time from ignition to fully charred; at the end the object burns up.
@export var burn_out_time: float = 8.0
## Start burning immediately (used by the Ember).
@export var auto_ignite: bool = false
## Never chars, never burns up, takes no burn damage (the Ember).
@export var eternal: bool = false

const CHAR_COLOR := Color(0.28, 0.23, 0.2)

var burning: bool = false
var _body: RigidBody2D
var _burn_elapsed: float = 0.0
var _heat: float = 0.0
var _flames: CPUParticles2D
var _consumed: bool = false

func _ready() -> void:
	_body = get_parent() as RigidBody2D
	if _body == null:
		push_warning("Flammable must be a child of a RigidBody2D.")
		return
	if auto_ignite:
		ignite()

## Called by burning neighbors while touching. Ignites past threshold.
func add_heat(amount: float) -> void:
	if burning or _consumed:
		return
	_heat += amount
	if _heat >= ignite_contact_time:
		ignite()

## 0 = untouched, 1 = fully charred. Used by Rope to tint burning spans.
func char_progress() -> float:
	if _consumed:
		return 1.0
	if not burning or eternal:
		return 0.0
	return clampf(_burn_elapsed / burn_out_time, 0.0, 1.0)

## Restore a saved burn: ignite and fast-forward to the saved elapsed
## time. The deterministic char recolors correctly on the next tick.
func resume_burn(elapsed: float) -> void:
	ignite()
	_burn_elapsed = clampf(elapsed, 0.0, burn_out_time)

func ignite() -> void:
	if burning or _consumed:
		return
	burning = true
	_burn_elapsed = 0.0
	_make_flames()
	ignited.emit()

## Kept for future systems (water, extinguishers). Charring remains.
func extinguish() -> void:
	if not burning or eternal:
		return
	burning = false
	_stop_flames()
	extinguished.emit()

func _physics_process(delta: float) -> void:
	if not burning or _body == null or _consumed:
		return
	_burn_elapsed += delta
	if not eternal:
		# Deterministic char: fully dark exactly when burn_out_time ends.
		var progress: float = clampf(_burn_elapsed / burn_out_time, 0.0, 1.0)
		_body.modulate = Color.WHITE.lerp(CHAR_COLOR, progress)
		# Damage-over-time chains into Health -> Breakable -> fragments.
		var health := _body.get_node_or_null(^"Health") as Health
		if health:
			health.take_damage(burn_damage_per_second * delta)
		if progress >= 1.0:
			_burn_up()
			return
	# Spread: heat up any touching flammable that isn't burning yet.
	# (Requires contact_monitor on the body — PhysicsObject enables it.)
	for other in _body.get_colliding_bodies():
		var f := other.get_node_or_null(^"Flammable") as Flammable
		if f and not f.burning:
			f.add_heat(delta)

## Fully charred: the object turns into persistent physical ash flecks
## that stay in the scene, get pushed by objects, and blow in the wind
## of things passing by (see EffectsManager).
func _burn_up() -> void:
	if _consumed:
		return
	_consumed = true
	burning = false
	set_physics_process(false)
	_stop_flames()
	EffectsManager.spawn_ash_burst(_body.global_position, _body_radius(), _body.get_parent())
	burned_up.emit()
	_remove_body()

func _remove_body() -> void:
	if not is_instance_valid(_body):
		return
	_detach_joints(_body)
	if _body.has_method("remove"):
		_body.remove()  # frees just this body — a ragdoll can lose one limb
	else:
		_body.queue_free()

## Free any joints connected to this body BEFORE freeing it, so nothing
## in the world references a dead node (ragdoll limbs, grabber joint,
## car wheels — all register their joints in the "joints" group).
func _detach_joints(body: Node) -> void:
	for joint in get_tree().get_nodes_in_group("joints"):
		if joint is Joint2D and is_instance_valid(joint):
			if joint.get_node_or_null(joint.node_a) == body \
					or joint.get_node_or_null(joint.node_b) == body:
				joint.queue_free()

func _stop_flames() -> void:
	if is_instance_valid(_flames):
		_flames.emitting = false  # let existing particles fade naturally
		var f := _flames
		get_tree().create_timer(1.0).timeout.connect(f.queue_free)
	_flames = null

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
