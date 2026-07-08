class_name AshParticle
extends RigidBody2D
## A single physical ash fleck: a tiny black rigid body that stays in
## the scene, gets shoved by objects that touch it, and gets blown by
## the wind of fast objects passing nearby (see EffectsManager).
##
## Collision setup: ash lives on layer 2 and scans layer 1 (world +
## objects). Ash does NOT scan layer 2, so flecks never collide with
## each other — piles overlap cheaply. Objects don't scan layer 2
## either, so 200 ash flecks add almost no cost to normal physics.

var radius: float = 2.5
var color: Color = Color(0.12, 0.11, 0.1)

func _ready() -> void:
	collision_layer = 2
	collision_mask = 1
	mass = 0.02
	linear_damp = 2.0
	angular_damp = 4.0
	continuous_cd = RigidBody2D.CCD_MODE_CAST_RAY
	var cs := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = radius
	cs.shape = shape
	add_child(cs)
	EffectsManager.register_ash(self)

func _draw() -> void:
	draw_circle(Vector2.ZERO, radius, color)
