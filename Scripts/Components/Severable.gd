class_name Severable
extends Node
## Component: realistic dismemberment. Auto-added alongside Bleeder for
## flesh materials. A limb only severs when hit by a rigid object with
## real severing capability — NEVER from falls, walls, or being thrown
## (static geometry is excluded outright).
##
## Cutting power = impact speed x sqrt(impactor mass) x edge factor,
## where the edge factor comes from the impactor's actual shape and
## material: high aspect ratio (a beam edge-on) behaves like a blade,
## a ball never slices, dense steel cuts better than wood, rubber not
## at all. A separate much-higher CRUSH threshold lets blunt-but-massive
## steel at extreme speed sever where wood never could. The spinning
## steel motor blade clears the slash threshold by pure math.

## Below this relative speed, no contact can sever anything.
@export var min_speed: float = 380.0
## Slash: speed * sqrt(mass) * edge_factor must exceed this.
@export var slash_threshold: float = 2200.0
## Crush: speed * sqrt(mass) alone (no edge) must exceed this.
@export var crush_threshold: float = 3800.0

## Sustained contact with a surface moving faster than this (px/s,
## at the contact point) grinds flesh instead of just cutting it.
@export var grind_speed: float = 420.0
## Seconds of sustained grinding contact before the part is destroyed.
@export var grind_endurance: float = 0.9

var _body: RigidBody2D
var _pre_step_velocity: Vector2 = Vector2.ZERO
var _severed: bool = false
var _grind: float = 0.0
var _grind_pulse: float = 0.0
var _ground_up: bool = false

func _ready() -> void:
	_body = get_parent() as RigidBody2D
	if _body == null:
		push_warning("Severable must be a child of a RigidBody2D.")
		return
	_body.body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	if not is_instance_valid(_body):
		return
	_pre_step_velocity = _body.linear_velocity
	if not _ground_up:
		_update_grinding(delta)

## GRINDING: a limb held against a fast-moving surface (a spinning saw's
## rim) is chewed apart — splatter pulses fling blood in the direction
## the surface is moving AT the contact point, which rotates with the
## blade, then the part is destroyed in a final burst.
func _update_grinding(delta: float) -> void:
	var grinding := false
	for other in _body.get_colliding_bodies():
		if not (other is RigidBody2D):
			continue  # ground/conveyors never grind
		if _body.owner != null and other.owner == _body.owner:
			continue
		var rigid := other as RigidBody2D
		var offset := _body.global_position - rigid.global_position
		var surface_velocity := rigid.linear_velocity \
			+ Vector2(-offset.y, offset.x) * rigid.angular_velocity
		var relative := surface_velocity - _pre_step_velocity
		if relative.length() < grind_speed:
			continue
		grinding = true
		_grind += delta
		_grind_pulse += delta
		if _grind_pulse >= 0.12:
			_grind_pulse = 0.0
			# Blood flung along the surface's motion at the contact —
			# the direction changes as the blade turns.
			var contact := _body.global_position - offset.normalized() * 6.0
			EffectsManager.splatter(contact, relative, 0.45, _body, rigid)
		if _grind >= grind_endurance:
			_finish_grinding(relative)
			return
	if not grinding:
		_grind = maxf(0.0, _grind - delta * 0.6)  # brief brushes decay

func _finish_grinding(final_velocity: Vector2) -> void:
	_ground_up = true
	EffectsManager.splatter(_body.global_position, final_velocity, 1.0, _body, null)
	EffectsManager.splatter(_body.global_position, final_velocity.rotated(0.8), 0.7, _body, null)
	if _body is PhysicsObject:
		_body.remove()  # detaches joints, then frees
	else:
		_body.queue_free()

func _on_body_entered(other: Node) -> void:
	if _severed or not is_instance_valid(_body):
		return
	# Realism rule #1: only a moving rigid OBJECT can dismember.
	# Ground, walls, platforms, and falls never can.
	if not (other is RigidBody2D):
		return
	# Never severed by parts of the same body.
	if _body.owner != null and other.owner == _body.owner:
		return
	var impactor := other as RigidBody2D
	# Surface velocity at the contact, not center-of-mass velocity: a
	# blade pinned at its center barely translates, but its rim moves at
	# angular_velocity x radius - that's what cuts.
	var offset := _body.global_position - impactor.global_position
	var point_velocity := impactor.linear_velocity + Vector2(-offset.y, offset.x) * impactor.angular_velocity
	var relative := _pre_step_velocity - point_velocity
	var speed := relative.length()
	if speed < min_speed:
		return
	var power := speed * sqrt(maxf(impactor.mass, 0.05))
	if power * _edge_factor(impactor) >= slash_threshold or power >= crush_threshold:
		_sever(impactor, relative)

## Blade-ness of the impactor: shape aspect ratio x material density.
func _edge_factor(impactor: RigidBody2D) -> float:
	var aspect := 1.0
	for child in impactor.get_children():
		if child is CollisionShape2D and child.shape:
			var s: Shape2D = child.shape
			if s is RectangleShape2D:
				var size := (s as RectangleShape2D).size
				aspect = maxf(size.x, size.y) / maxf(minf(size.x, size.y), 1.0)
			break  # circles keep aspect 1.0: balls never slice
	var hardness := 1.0
	if impactor is PhysicsObject and impactor.object_material:
		hardness = clampf(impactor.object_material.density, 0.4, 2.0)
	return clampf(aspect / 2.5, 1.0, 3.0) * hardness

func _sever(impactor: RigidBody2D, impact_velocity: Vector2) -> void:
	_severed = true
	# Detach: free every joint holding this limb to the body.
	for joint in get_tree().get_nodes_in_group("joints"):
		if joint is Joint2D and is_instance_valid(joint):
			if joint.get_node_or_null(joint.node_a) == _body \
					or joint.get_node_or_null(joint.node_b) == _body:
				joint.queue_free()
	# The cut carries the limb with the blade a little.
	_body.apply_central_impulse(impact_velocity * 0.2 * _body.mass)
	# Arterial spray at the impact, then a few seconds of bleed-out.
	var contact := _body.global_position + (impactor.global_position - _body.global_position).normalized() * 8.0
	EffectsManager.splatter.call_deferred(contact, impact_velocity, 1.0, _body, impactor)
	for i in 8:
		get_tree().create_timer(0.16 * (i + 1)).timeout.connect(_bleed_pulse)

func _bleed_pulse() -> void:
	if not is_instance_valid(_body) or not _body.is_inside_tree():
		return
	var ooze := Vector2(randf_range(-50.0, 50.0), -randf_range(50.0, 110.0))
	EffectsManager.splatter(_body.global_position, ooze, 0.3, _body, null)
