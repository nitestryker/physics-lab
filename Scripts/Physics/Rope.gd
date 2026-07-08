class_name Rope
extends CompositeObject
## Procedurally built rope: a chain of small rigid segments connected
## by PinJoint2Ds, optionally pinned to a static anchor at the rope's
## origin. Segments are grabbable, so you can swing or throw the rope.
## Rendered as a single polyline over the segment positions, so the
## physics chain is invisible and the rope looks continuous.

@export_range(2, 40) var segment_count: int = 12
@export var segment_length: float = 18.0
@export var thickness: float = 6.0
## Pin the top of the rope where it spawns. Un-anchored ropes fall free.
@export var anchored: bool = true
@export var color: Color = Color(0.76, 0.6, 0.38)
@export var segment_mass: float = 0.15

var _segments: Array[RigidBody2D] = []

func _ready() -> void:
	_build()
	super._ready()  # registers the joints we just created

func _build() -> void:
	var prev: PhysicsBody2D = null
	if anchored:
		var anchor := StaticBody2D.new()
		anchor.name = "Anchor"
		add_child(anchor)
		prev = anchor
	for i in segment_count:
		var seg := RigidBody2D.new()
		seg.name = "Segment%d" % i
		seg.mass = segment_mass
		seg.linear_damp = 0.4  # tames jitter in long chains
		var cs := CollisionShape2D.new()
		var shape := RectangleShape2D.new()
		shape.size = Vector2(thickness, segment_length * 0.9)
		cs.shape = shape
		seg.add_child(cs)
		seg.position = Vector2(0, (i + 0.5) * segment_length)
		seg.add_to_group("grabbable")
		seg.add_to_group("physics_objects")
		add_child(seg)
		# Owner points at this root so the Grabber's right-click removal
		# deletes the whole rope, and so removal delegation works for
		# code-built nodes exactly like scene-built ones.
		seg.owner = self
		_segments.append(seg)
		if prev != null:
			var joint := PinJoint2D.new()
			joint.position = Vector2(0, i * segment_length)
			add_child(joint)
			joint.node_a = joint.get_path_to(prev)
			joint.node_b = joint.get_path_to(seg)
		prev = seg

func _process(_delta: float) -> void:
	queue_redraw()  # segments move every frame; redraw the polyline

func _draw() -> void:
	var points := PackedVector2Array()
	if anchored:
		points.append(Vector2.ZERO)
	for seg in _segments:
		if is_instance_valid(seg):
			points.append(to_local(seg.global_position))
	if points.size() >= 2:
		draw_polyline(points, color, thickness)
	if anchored:
		draw_circle(Vector2.ZERO, thickness * 1.2, color.darkened(0.35))
