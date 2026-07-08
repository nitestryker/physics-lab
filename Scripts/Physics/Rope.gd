class_name Rope
extends CompositeObject
## Procedurally built rope: a chain of small rigid segments connected
## by PinJoint2Ds, optionally pinned to a static anchor at the rope's
## origin. Segments are grabbable, so you can swing or throw the rope.
## Rendered as per-pair lines over the segment positions, so the
## physics chain is invisible and the rope looks continuous.
##
## FIRE: segments carry Flammable components. Contact spread can't pass
## between adjacent segments (their joints disable mutual collision),
## so ignition also chains along the rope with a short delay — touch an
## Ember to any point and fire crawls in both directions. Burning spans
## tint toward char; fully burned segments turn to ash and drop out,
## splitting the rope where they were.

const FLAMMABLE_SCRIPT := preload("res://Scripts/Components/Flammable.gd")

@export_range(2, 40) var segment_count: int = 12
@export var segment_length: float = 18.0
@export var thickness: float = 6.0
## Pin the top of the rope where it spawns. Un-anchored ropes fall free.
@export var anchored: bool = true
@export var color: Color = Color(0.76, 0.6, 0.38)
@export var segment_mass: float = 0.15
## Seconds for fire to crawl from one segment to the next.
@export var fire_crawl_delay: float = 0.35
## Seconds for a segment to burn from ignition to ash.
@export var segment_burn_time: float = 3.5

const CHAR_COLOR := Color(0.28, 0.23, 0.2)

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
		# Contact monitoring lets a burning segment spread fire to
		# whatever the rope touches (boxes, ragdolls...).
		seg.contact_monitor = true
		seg.max_contacts_reported = 4
		seg.continuous_cd = RigidBody2D.CCD_MODE_CAST_RAY
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
		# Flammable per segment: ropes have no material resource, so the
		# component is attached directly instead of material-driven.
		var flammable: Flammable = FLAMMABLE_SCRIPT.new()
		flammable.name = "Flammable"
		flammable.burn_out_time = segment_burn_time
		flammable.ignited.connect(_on_segment_ignited.bind(i))
		seg.add_child(flammable)
		if prev != null:
			var joint := PinJoint2D.new()
			joint.position = Vector2(0, i * segment_length)
			add_child(joint)
			joint.node_a = joint.get_path_to(prev)
			joint.node_b = joint.get_path_to(seg)
		prev = seg

## Fire crawls to neighboring segments after a short delay.
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
	queue_redraw()  # segments move every frame; redraw the lines

func _draw() -> void:
	# Per-pair lines instead of one polyline: burned-away segments leave
	# a real gap, and each span tints with its char progress.
	var prev_point: Vector2
	var prev_progress: float = 0.0
	var has_prev := false
	if anchored:
		prev_point = Vector2.ZERO
		has_prev = true
		draw_circle(Vector2.ZERO, thickness * 1.2, color.darkened(0.35))
	var max_span := segment_length * 2.5
	for seg in _segments:
		if not is_instance_valid(seg):
			has_prev = false  # segment burned away: break the line here
			continue
		var point := to_local(seg.global_position)
		var progress := 0.0
		var flammable := seg.get_node_or_null(^"Flammable") as Flammable
		if flammable:
			progress = flammable.char_progress()
		if has_prev and prev_point.distance_to(point) < max_span:
			var span_color := color.lerp(CHAR_COLOR, (prev_progress + progress) / 2.0)
			draw_line(prev_point, point, span_color, thickness)
		prev_point = point
		prev_progress = progress
		has_prev = true
