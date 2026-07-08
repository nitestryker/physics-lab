class_name PhysicsObject
extends RigidBody2D
## Minimal shared base for every interactive object (see "Architecture
## Principle"). Holds ONLY: material handling, shared signals, removal,
## component lookup, and a debug draw of its collision shape. Everything
## else is a component (Grabbable, Health, Damage, Breakable, Saveable).

signal spawned
signal despawned

## Data-driven material — never hard-code friction/bounce/mass on objects.
@export var object_material: ObjectMaterial:
	set(value):
		object_material = value
		if is_inside_tree():
			_apply_material()
			queue_redraw()

## Mass before density is applied (roughly "size" of the object).
@export var base_mass: float = 1.0

func _ready() -> void:
	add_to_group("physics_objects")
	# Needed so the Damage component can receive body_entered signals.
	contact_monitor = true
	max_contacts_reported = 8
	_apply_material()
	spawned.emit()

func _apply_material() -> void:
	if object_material == null:
		return
	var pm := PhysicsMaterial.new()
	pm.friction = object_material.friction
	pm.bounce = object_material.bounce
	physics_material_override = pm
	mass = maxf(0.05, base_mass * object_material.density)

## Convention: component nodes are named after their script
## ("Grabbable", "Health", ...) so lookup is a simple get_node.
func get_component(component_name: String) -> Node:
	return get_node_or_null(NodePath(component_name))

func has_component(component_name: String) -> bool:
	return get_component(component_name) != null

## Every object must be removable (Development Rules).
func remove() -> void:
	despawned.emit()
	queue_free()

## Placeholder visuals: draw the collision shape in the material color.
## Replace with sprites later without touching any logic.
func _draw() -> void:
	var col: Color = object_material.color if object_material else Color.WHITE
	var outline := col.darkened(0.45)
	for child in get_children():
		if child is CollisionShape2D and child.shape:
			var s: Shape2D = child.shape
			if s is RectangleShape2D:
				var rect := Rect2(child.position - s.size / 2.0, s.size)
				draw_rect(rect, col)
				draw_rect(rect, outline, false, 2.0)
			elif s is CircleShape2D:
				draw_circle(child.position, s.radius, col)
				draw_arc(child.position, s.radius, 0.0, TAU, 32, outline, 2.0)
				# A spoke so you can see the ball roll.
				draw_line(child.position, child.position + Vector2(s.radius, 0), outline, 2.0)
