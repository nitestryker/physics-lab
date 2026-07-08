class_name Breakable
extends Node
## Component: when the sibling Health dies, the object shatters into
## smaller PhysicsObject fragments that inherit its material, velocity,
## and a radial impulse. If the object was burning, its fragments spawn
## already on fire. Fragments have no Health, so they don't split again.

const BASE_SCENE := preload("res://Scenes/Base/PhysicsObject.tscn")

## Outward kick applied to fragments, in px/s of velocity change.
@export var fragment_impulse: float = 140.0
## Fragments smaller than this (largest dimension) are not spawned.
@export var min_fragment_extent: float = 12.0

func _ready() -> void:
	var health := get_parent().get_node_or_null(^"Health") as Health
	if health == null:
		push_warning("Breakable requires a sibling Health component.")
		return
	health.died.connect(_on_died)

func _on_died() -> void:
	# died can fire during physics callbacks (collision damage), when the
	# scene tree is locked — defer all spawning/freeing to be safe.
	_break.call_deferred()

func _break() -> void:
	var parent := get_parent()
	if not (parent is PhysicsObject) or not parent.is_inside_tree():
		if is_instance_valid(parent):
			parent.queue_free()
		return
	_spawn_fragments(parent)
	parent.remove()

func _spawn_fragments(parent: PhysicsObject) -> void:
	var cs: CollisionShape2D = null
	for child in parent.get_children():
		if child is CollisionShape2D and child.shape:
			cs = child
			break
	if cs == null:
		return
	var flammable := parent.get_node_or_null(^"Flammable") as Flammable
	var was_burning := flammable != null and flammable.burning
	var s: Shape2D = cs.shape
	if s is RectangleShape2D:
		var rect: RectangleShape2D = s
		var frag_size: Vector2 = rect.size * 0.46
		if maxf(frag_size.x, frag_size.y) < min_fragment_extent:
			return
		# Thin shapes (beams): don't let a dimension collapse to a sliver.
		frag_size.x = clampf(frag_size.x, minf(min_fragment_extent, rect.size.x * 0.9), rect.size.x)
		frag_size.y = clampf(frag_size.y, minf(min_fragment_extent, rect.size.y * 0.9), rect.size.y)
		var q: Vector2 = rect.size / 4.0
		for offset: Vector2 in [Vector2(-q.x, -q.y), Vector2(q.x, -q.y), Vector2(-q.x, q.y), Vector2(q.x, q.y)]:
			var shape := RectangleShape2D.new()
			shape.size = frag_size
			_make_fragment(parent, shape, offset, was_burning)
	elif s is CircleShape2D:
		var circle: CircleShape2D = s
		var frag_radius: float = circle.radius * 0.5
		if frag_radius * 2.0 < min_fragment_extent:
			return
		for i in 3:
			var offset: Vector2 = Vector2.RIGHT.rotated(TAU * i / 3.0) * circle.radius * 0.5
			var shape := CircleShape2D.new()
			shape.radius = frag_radius
			_make_fragment(parent, shape, offset, was_burning)

func _make_fragment(parent: PhysicsObject, shape: Shape2D, offset: Vector2, was_burning: bool) -> void:
	var frag: PhysicsObject = BASE_SCENE.instantiate()
	frag.object_material = parent.object_material
	frag.base_mass = maxf(0.1, parent.base_mass / 4.0)
	(frag.get_node(^"CollisionShape2D") as CollisionShape2D).shape = shape
	var rotated_offset := offset.rotated(parent.rotation)
	frag.position = parent.position + rotated_offset
	frag.rotation = parent.rotation
	frag.linear_velocity = parent.linear_velocity
	parent.get_parent().add_child(frag)
	frag.add_to_group("grabbable")
	frag.apply_central_impulse(rotated_offset.normalized() * fragment_impulse * frag.mass)
	if was_burning:
		var f := frag.get_node_or_null(^"Flammable") as Flammable
		if f:
			f.ignite()
