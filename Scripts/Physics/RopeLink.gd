class_name RopeLink
extends CompositeObject
## A rope built BETWEEN two bodies by the joint tool: a chain of small
## rigid segments pinned to body A at one end and body B at the other.
## Same construction and fire behavior as the spawnable Rope — segments
## are grabbable and flammable, fire crawls along the chain, and burned
## segments turn to ash and split the rope.

const FLAMMABLE_SCRIPT := preload("res://Scripts/Components/Flammable.gd")
const CHAR_COLOR := Color(0.28, 0.23, 0.2)

var thickness: float = 5.0
var color: Color = Color(0.76, 0.6, 0.38)
var fire_crawl_delay: float = 0.35

var _segments: Array[RigidBody2D] = []
var _body_a: PhysicsBody2D
var _local_a: Vector2
var _body_b: PhysicsBody2D
var _local_b: Vector2

## Call AFTER this node is in the tree. Builds the chain from pa to pb.
func build(body_a: PhysicsBody2D, pa: Vector2, body_b: PhysicsBody2D, pb: Vector2) -> void:
	_body_a = body_a
	_local_a = body_a.to_local(pa)
	_body_b = body_b
	_local_b = body_b.to_local(pb)
	var dist := maxf(pa.distance_to(pb), 24.0)
	var count := clampi(int(dist / 16.0), 2, 30)
	var seg_len := dist / count
	var dir := (pb - pa) / dist
	var seg_rotation := dir.angle() - PI / 2.0  # segment long axis = local Y
	var prev: PhysicsBody2D = body_a
	var prev_anchor := pa
	for i in count:
		var seg := RigidBody2D.new()
		seg.name = "Segment%d" % i
		seg.mass = 0.12
		seg.linear_damp = 0.4
		seg.contact_monitor = true
		seg.max_contacts_reported = 4
		seg.continuous_cd = RigidBody2D.CCD_MODE_CAST_RAY
		var cs := CollisionShape2D.new()
		var shape := RectangleShape2D.new()
		shape.size = Vector2(thickness, seg_len * 0.9)
		cs.shape = shape
		seg.add_child(cs)
		add_child(seg)
		seg.global_position = pa + dir * (i + 0.5) * seg_len
		seg.global_rotation = seg_rotation
		seg.add_to_group("grabbable")
		seg.add_to_group("physics_objects")
		seg.owner = self
		_segments.append(seg)
		var flammable: Flammable = FLAMMABLE_SCRIPT.new()
		flammable.name = "Flammable"
		flammable.burn_out_time = 3.5
		flammable.ignited.connect(_on_segment_ignited.bind(i))
		seg.add_child(flammable)
		var joint := PinJoint2D.new()
		add_child(joint)
		joint.global_position = prev_anchor
		joint.node_a = joint.get_path_to(prev)
		joint.node_b = joint.get_path_to(seg)
		prev = seg
		prev_anchor = pa + dir * (i + 1) * seg_len
	# Final pin: last segment to body B at the clicked point.
	var end_joint := PinJoint2D.new()
	add_child(end_joint)
	end_joint.global_position = pb
	end_joint.node_a = end_joint.get_path_to(prev)
	end_joint.node_b = end_joint.get_path_to(body_b)
	register_joints()  # _ready already ran before build; register now

## Save support: [body_a, local_a, body_b, local_b], or [] if either
## endpoint body no longer exists.
func endpoints() -> Array:
	if not is_instance_valid(_body_a) or not is_instance_valid(_body_b):
		return []
	return [_body_a, _local_a, _body_b, _local_b]

func _on_segment_ignited(index: int) -> void:
	for neighbor_index in [index - 1, index + 1]:
		if neighbor_index < 0 or neighbor_index >= _segments.size():
			continue
		var neighbor: RigidBody2D = _segments[neighbor_index]
		if not is_instance_valid(neighbor):
			continue
		get_tree().create_timer(fire_crawl_delay).timeout.connect(
			_ignite_segment.bind(neighbor))

func _ignite_segment(segment: RigidBody2D) -> void:
	if not is_instance_valid(segment):
		return
	var flammable := segment.get_node_or_null(^"Flammable") as Flammable
	if flammable:
		flammable.ignite()

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	var max_span := 45.0
	var prev_point: Vector2
	var prev_progress: float = 0.0
	var has_prev := false
	if is_instance_valid(_body_a):
		prev_point = to_local(_body_a.to_global(_local_a))
		has_prev = true
	for seg in _segments:
		if not is_instance_valid(seg):
			has_prev = false  # burned away: real gap
			continue
		var point := to_local(seg.global_position)
		var progress := 0.0
		var flammable := seg.get_node_or_null(^"Flammable") as Flammable
		if flammable:
			progress = flammable.char_progress()
		if has_prev and prev_point.distance_to(point) < max_span:
			draw_line(prev_point, point, color.lerp(CHAR_COLOR, (prev_progress + progress) / 2.0), thickness)
		prev_point = point
		prev_progress = progress
		has_prev = true
	if has_prev and is_instance_valid(_body_b):
		var end := to_local(_body_b.to_global(_local_b))
		if prev_point.distance_to(end) < max_span:
			draw_line(prev_point, end, color.lerp(CHAR_COLOR, prev_progress), thickness)
