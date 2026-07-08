extends Node2D
## Player joint tool (Milestone 0.6): in joint mode, click one body,
## then a second, and they're connected with the selected joint type at
## the exact points clicked. Endpoints can be spawned objects OR the
## environment (pin a beam to a wall). Right-click or clicking empty
## space cancels a pending first selection.
##
## Tree position: keep this node BELOW the Grabber so it receives
## _unhandled_input first while joint mode is active.

const ROPE_LINK := preload("res://Scripts/Physics/RopeLink.gd")

## Pending first selection.
var _body_a: PhysicsBody2D = null
var _local_a: Vector2 = Vector2.ZERO

## Metadata for drawing created pins/springs (joints are invisible).
## Each: {type, joint, body_a, local_a, body_b, local_b}
var _links: Array[Dictionary] = []

func _ready() -> void:
	add_to_group("joint_tool")

## Save support: live link records (type, body_a, local_a, body_b, local_b).
func serialize_links() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for link in _links:
		if is_instance_valid(link.joint) and is_instance_valid(link.body_a) and is_instance_valid(link.body_b):
			out.append(link)
	return out

func _unhandled_input(event: InputEvent) -> void:
	if GameManager.tool_mode != "joint":
		_body_a = null
		return
	if event.is_action_pressed("primary_action"):
		_handle_click(get_global_mouse_position())
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("secondary_action") and _body_a != null:
		_body_a = null
		get_viewport().set_input_as_handled()

func _handle_click(point: Vector2) -> void:
	var body := _body_at_point(point)
	if _body_a == null:
		if body != null:
			_body_a = body
			_local_a = body.to_local(point)
		return
	if body == null or body == _body_a or not is_instance_valid(_body_a):
		_body_a = null  # cancel
		return
	create_link(GameManager.joint_type, _body_a, _body_a.to_global(_local_a), body, point)
	_body_a = null

## Creates a joint of the given type between two bodies at the given
## global points. Used by both player clicks and SaveManager loading.
func create_link(joint_type: String, body_a: PhysicsBody2D, pa: Vector2, body_b: PhysicsBody2D, pb: Vector2) -> void:
	match joint_type:
		"Pin":
			var pin := PinJoint2D.new()
			add_child(pin)
			pin.global_position = pb
			pin.node_a = pin.get_path_to(body_a)
			pin.node_b = pin.get_path_to(body_b)
			pin.add_to_group("joints")
			_links.append({"type": "Pin", "joint": pin,
				"body_a": body_a, "local_a": body_a.to_local(pb),
				"body_b": body_b, "local_b": body_b.to_local(pb)})
		"Spring":
			var spring := DampedSpringJoint2D.new()
			add_child(spring)
			spring.global_position = pa
			# DampedSpringJoint2D extends along its local +Y axis.
			spring.global_rotation = (pb - pa).angle() - PI / 2.0
			var dist := maxf(pa.distance_to(pb), 8.0)
			spring.length = dist
			spring.rest_length = dist * 0.9
			spring.stiffness = 24.0
			spring.damping = 1.0
			spring.node_a = spring.get_path_to(body_a)
			spring.node_b = spring.get_path_to(body_b)
			spring.add_to_group("joints")
			_links.append({"type": "Spring", "joint": spring,
				"body_a": body_a, "local_a": body_a.to_local(pa),
				"body_b": body_b, "local_b": body_b.to_local(pb)})
		"Rope":
			var link: RopeLink = ROPE_LINK.new()
			get_parent().add_child(link)
			link.build(body_a, pa, body_b, pb)
			# RopeLink draws itself and registers its own joints.

func _body_at_point(point: Vector2) -> PhysicsBody2D:
	var params := PhysicsPointQueryParameters2D.new()
	params.position = point
	params.collide_with_bodies = true
	params.collision_mask = 1  # objects + environment; never ash/blood
	var hits := get_world_2d().direct_space_state.intersect_point(params, 8)
	for hit in hits:
		if hit.collider is PhysicsBody2D:
			return hit.collider
	return null

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	# Pending selection: highlight + rubber band to the mouse.
	if GameManager.tool_mode == "joint" and is_instance_valid(_body_a):
		var anchor := to_local(_body_a.to_global(_local_a))
		draw_circle(anchor, 5.0, Color(1.0, 0.9, 0.3, 0.9))
		draw_line(anchor, to_local(get_global_mouse_position()), Color(1.0, 0.9, 0.3, 0.5), 2.0)
	# Created joints (prune dead ones as we go).
	for i in range(_links.size() - 1, -1, -1):
		var link: Dictionary = _links[i]
		if not is_instance_valid(link.joint) or not is_instance_valid(link.body_a) or not is_instance_valid(link.body_b):
			_links.remove_at(i)
			continue
		var a := to_local(link.body_a.to_global(link.local_a))
		var b := to_local(link.body_b.to_global(link.local_b))
		if link.type == "Pin":
			draw_circle(b, 4.0, Color(0.9, 0.85, 0.4))
			draw_arc(b, 4.0, 0.0, TAU, 24, Color(0.4, 0.35, 0.1), 1.5)
		else:  # Spring: zigzag
			var dir := b - a
			var length := dir.length()
			if length < 1.0:
				continue
			var normal := dir.normalized().orthogonal()
			var points := PackedVector2Array([a])
			var coils := clampi(int(length / 14.0), 3, 12)
			for c in range(1, coils):
				var t := float(c) / coils
				var side: float = 6.0 if c % 2 == 0 else -6.0
				points.append(a + dir * t + normal * side)
			points.append(b)
			draw_polyline(points, Color(0.75, 0.75, 0.8), 2.5)
