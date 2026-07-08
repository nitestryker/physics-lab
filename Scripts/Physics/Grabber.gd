extends Node2D
## Joint-based mouse grabber (see "Mouse Grabbing" technical note).
## NEVER sets a body's position directly. Instead a hidden static anchor
## follows the mouse, and a soft PinJoint2D connects it to the grabbed
## body — so dragging is physical, throwing works by releasing
## mid-swing, and grabbing one ragdoll limb drags the whole assembly.
##
## Right-click removes the object under the cursor (every object must
## be removable — Development Rules).
##
## NOTE: keep this node BELOW ObjectSpawner in the scene tree. Nodes
## lower in the tree receive _unhandled_input first, so the Grabber
## gets first claim on clicks; if it grabs nothing, the Spawner places
## an object instead.

@export_range(0.0, 16.0) var grab_softness: float = 1.5

var _anchor: StaticBody2D
var _joint: PinJoint2D
var _grabbed: RigidBody2D

func _ready() -> void:
	# No collision shape -> the anchor never collides with anything;
	# it exists only as an attachment point for the joint.
	_anchor = StaticBody2D.new()
	add_child(_anchor)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("primary_action"):
		if _try_grab(get_global_mouse_position()):
			get_viewport().set_input_as_handled()
	elif event.is_action_released("primary_action"):
		_release()
	elif event.is_action_pressed("secondary_action"):
		if _try_remove(get_global_mouse_position()):
			get_viewport().set_input_as_handled()

func _physics_process(_delta: float) -> void:
	if _grabbed and not is_instance_valid(_grabbed):
		_release()  # grabbed object broke / was removed
	if _grabbed:
		_anchor.global_position = get_global_mouse_position()

func _try_grab(point: Vector2) -> bool:
	var body := _body_at_point(point)
	if body == null or not body.is_in_group("grabbable"):
		return false
	_grabbed = body
	_anchor.global_position = point
	_joint = PinJoint2D.new()
	_joint.softness = grab_softness
	_joint.add_to_group("joints")
	add_child(_joint)
	_joint.global_position = point
	_joint.node_a = _joint.get_path_to(_anchor)
	_joint.node_b = _joint.get_path_to(_grabbed)
	return true

func _release() -> void:
	if is_instance_valid(_joint):
		_joint.queue_free()
	_joint = null
	_grabbed = null

func _try_remove(point: Vector2) -> bool:
	var body: PhysicsBody2D = _any_body_at_point(point)
	if body == null:
		return false
	# If the body belongs to a composite object (e.g. a ragdoll limb),
	# its scene owner is the composite root — remove the whole thing.
	var target: Node = body
	if body.owner != null and body.owner.has_method("remove"):
		target = body.owner
	if target.has_method("remove"):
		if _grabbed == body:
			_release()
		target.remove()
		return true
	return false

## Any physics body (machines have static parts) - used for removal.
func _any_body_at_point(point: Vector2) -> PhysicsBody2D:
	var params := PhysicsPointQueryParameters2D.new()
	params.position = point
	params.collide_with_bodies = true
	params.collision_mask = 1
	var hits := get_world_2d().direct_space_state.intersect_point(params, 8)
	for hit in hits:
		if hit.collider is PhysicsBody2D:
			return hit.collider
	return null

func _body_at_point(point: Vector2) -> RigidBody2D:
	var params := PhysicsPointQueryParameters2D.new()
	params.position = point
	params.collide_with_bodies = true
	var hits := get_world_2d().direct_space_state.intersect_point(params, 8)
	for hit in hits:
		if hit.collider is RigidBody2D:
			return hit.collider
	return null
