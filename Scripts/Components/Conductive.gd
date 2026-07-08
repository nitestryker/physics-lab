class_name Conductive
extends Node
## Component: electricity. Auto-added when the material has
## conductive = true (Steel, Battery) — the flag from the v1.2 material
## table, finally live. The PowerNetwork computes which conductive
## bodies are connected (by touch) to a power source each tick and
## calls set_powered(). While powered: sparks, shocks flesh on contact
## (spasms), and slowly heats touching flammables until they ignite —
## electrical fires are real fires.

var powered: bool = false
var _body: RigidBody2D
var _sparks: CPUParticles2D

func _ready() -> void:
	_body = get_parent() as RigidBody2D
	if _body == null:
		push_warning("Conductive must be a child of a RigidBody2D.")
		return
	add_to_group("conductive_components")
	# Sleeping bodies stop reporting contacts, which would break a
	# resting circuit. Conductive bodies are few; the cost is trivial.
	_body.can_sleep = false

func set_powered(value: bool) -> void:
	if value == powered:
		return
	powered = value
	if powered:
		_make_sparks()
	elif is_instance_valid(_sparks):
		_sparks.emitting = false
		var s := _sparks
		get_tree().create_timer(0.6).timeout.connect(s.queue_free)
		_sparks = null

func _physics_process(delta: float) -> void:
	if not powered or _body == null:
		return
	for other in _body.get_colliding_bodies():
		if not (other is RigidBody2D):
			continue
		var rigid := other as RigidBody2D
		# Shock flesh: spasms.
		if rigid.get_node_or_null(^"Bleeder") != null:
			var jolt := Vector2.RIGHT.rotated(randf() * TAU) * 160.0 * rigid.mass * delta
			rigid.apply_central_impulse(jolt)
		# Electrical fire: heat touching flammables toward ignition.
		var flammable := rigid.get_node_or_null(^"Flammable") as Flammable
		if flammable and not flammable.burning:
			flammable.add_heat(delta * 0.8)

func _make_sparks() -> void:
	_sparks = CPUParticles2D.new()
	_sparks.amount = 10
	_sparks.lifetime = 0.25
	_sparks.local_coords = false
	_sparks.spread = 180.0
	_sparks.gravity = Vector2(0, 300)
	_sparks.initial_velocity_min = 40.0
	_sparks.initial_velocity_max = 120.0
	_sparks.scale_amount_min = 1.0
	_sparks.scale_amount_max = 2.0
	_sparks.color = Color(1.0, 0.9, 0.35)
	_body.add_child(_sparks)
