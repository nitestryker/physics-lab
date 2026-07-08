class_name BloodDroplet
extends RigidBody2D
## A drop of blood in flight. Reads as liquid: the drop stretches into
## a streak along its velocity (fast = long teardrop, slow = round
## bead), then converts into a BloodStain stuck to the first thing it
## touches. Layer 3 (bit value 4), scanning layer 1 only — droplets
## pass through each other and through ash.

var radius: float = 2.4
var color: Color = Color(0.86, 0.06, 0.08)

func _ready() -> void:
	collision_layer = 4
	collision_mask = 1
	mass = 0.03
	linear_damp = 0.1
	lock_rotation = true  # keeps the streak math in world space
	contact_monitor = true
	max_contacts_reported = 2
	continuous_cd = RigidBody2D.CCD_MODE_CAST_RAY
	var cs := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = radius
	cs.shape = shape
	add_child(cs)
	add_to_group("blood_droplets")
	body_entered.connect(_on_body_entered)
	# Safety net: a droplet that never lands frees itself.
	get_tree().create_timer(6.0).timeout.connect(queue_free)

func _process(_delta: float) -> void:
	queue_redraw()  # streak follows current velocity every frame

func _draw() -> void:
	var speed := linear_velocity.length()
	var dir := linear_velocity / speed if speed > 1.0 else Vector2.DOWN
	# Stretch with speed: a falling drop is a teardrop, not a ball.
	var streak_len := clampf(speed * 0.025, radius, radius * 4.5)
	var tail := -dir * streak_len
	draw_line(tail, Vector2.ZERO, color, radius * 1.6)
	draw_circle(Vector2.ZERO, radius, color)          # fat head
	draw_circle(tail, radius * 0.55, color.darkened(0.12))  # thin tail

func _on_body_entered(other: Node) -> void:
	# body_entered fires during the physics flush — defer tree changes.
	_stick.call_deferred(other)

func _stick(other: Node) -> void:
	if not is_inside_tree():
		return
	if other is Node2D:
		EffectsManager.add_stain(other, (other as Node2D).to_local(global_position), radius * randf_range(1.6, 2.6))
	queue_free()
