class_name SawBlade
extends CompositeObject
## A spinning steel saw on a static mount. No scripted cutting: the
## blade is a real steel PhysicsObject spinning at high angular
## velocity, and Severable/Damage measure surface speed at the contact
## point — so severing limbs and grinding boxes apart is pure physics.

const BASE_SCENE := preload("res://Scenes/Base/PhysicsObject.tscn")
const STEEL := preload("res://Resources/Materials/Steel.tres")

@export var spin_speed: float = 30.0  # rad/s; rim speed = 30 * 30px = 900
@export var blade_radius: float = 30.0

var _blade: PhysicsObject

func _ready() -> void:
	var mount := StaticBody2D.new()
	mount.name = "Mount"
	var mount_cs := CollisionShape2D.new()
	var mount_shape := RectangleShape2D.new()
	mount_shape.size = Vector2(20, 26)
	mount_cs.shape = mount_shape
	mount.add_child(mount_cs)
	mount.position = Vector2(0, 22)
	add_child(mount)
	mount.owner = self
	_blade = BASE_SCENE.instantiate()
	_blade.name = "Blade"
	_blade.object_material = STEEL
	_blade.base_mass = 1.0
	add_child(_blade)
	_blade.owner = self
	(_blade.get_node(^"CollisionShape2D") as CollisionShape2D).shape = _make_circle()
	var joint := PinJoint2D.new()
	add_child(joint)
	joint.node_a = joint.get_path_to(mount)
	joint.node_b = joint.get_path_to(_blade)
	joint.motor_enabled = true
	joint.motor_target_velocity = spin_speed
	super._ready()

func _make_circle() -> CircleShape2D:
	var shape := CircleShape2D.new()
	shape.radius = blade_radius
	return shape

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	if not is_instance_valid(_blade):
		return
	# Teeth ring, rotating with the blade.
	var center := to_local(_blade.global_position)
	var teeth_color := Color(0.45, 0.48, 0.52)
	for i in 10:
		var angle := _blade.global_rotation + TAU * i / 10.0
		var inner := center + Vector2.RIGHT.rotated(angle) * blade_radius
		var outer := center + Vector2.RIGHT.rotated(angle + 0.12) * (blade_radius + 7.0)
		draw_line(inner, outer, teeth_color, 3.0)
