class_name SpringLauncher
extends CompositeObject
## A launch pad: anything landing on it gets flung upward. A static
## base with an Area2D pad on top; bodies entering the pad receive an
## upward impulse. Grab one ragdoll limb into it and the joints carry
## the whole doll skyward.

@export var launch_speed: float = 820.0

var _pad: Area2D
var _compress: float = 0.0  # 1.0 right after a launch, eases back
var _recent: Dictionary = {}  # launch target -> time until re-arm

func _ready() -> void:
	var base := StaticBody2D.new()
	base.name = "Base"
	var base_cs := CollisionShape2D.new()
	var base_shape := RectangleShape2D.new()
	base_shape.size = Vector2(64, 14)
	base_cs.shape = base_shape
	base.add_child(base_cs)
	add_child(base)
	base.owner = self
	_pad = Area2D.new()
	_pad.collision_mask = 1  # objects only; never ash/blood
	var pad_cs := CollisionShape2D.new()
	var pad_shape := RectangleShape2D.new()
	pad_shape.size = Vector2(58, 32)
	pad_cs.shape = pad_shape
	_pad.add_child(pad_cs)
	_pad.position = Vector2(0, -20)
	add_child(_pad)
	_pad.body_entered.connect(_on_pad_entered)
	super._ready()

func _on_pad_entered(body: Node) -> void:
	if body is RigidBody2D:
		_launch.call_deferred(body)  # never mutate physics mid-flush

func _launch(body: RigidBody2D) -> void:
	if not is_instance_valid(body):
		return
	# Cooldown per object (per composite root for ragdolls/cars), so one
	# doll doesn't retrigger the pad once per limb.
	var key: Node = body.owner if body.owner is CompositeObject else body
	if _recent.get(key, 0.0) > 0.0:
		return
	_recent[key] = 0.5
	# Launch the WHOLE thing: an impulse on one ragdoll limb dilutes to
	# nothing across the body. Boost every rigid part of a composite.
	var targets: Array = [body]
	if body.owner is CompositeObject:
		targets = []
		for child in body.owner.get_children():
			if child is RigidBody2D:
				targets.append(child)
	var side := randf_range(-50.0, 50.0)
	for target in targets:
		if not is_instance_valid(target):
			continue
		# SET velocity rather than adding an impulse — incoming fall
		# speed would otherwise cancel most of the kick.
		target.linear_velocity = Vector2(target.linear_velocity.x + side, -launch_speed)
	_compress = 1.0

func _physics_process(delta: float) -> void:
	for key in _recent.keys():
		_recent[key] -= delta
		if _recent[key] <= 0.0 or not is_instance_valid(key):
			_recent.erase(key)

func _process(delta: float) -> void:
	_compress = maxf(0.0, _compress - delta * 4.0)
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(Vector2(-32, -7), Vector2(64, 14)), Color(0.3, 0.32, 0.36))
	var top_y := lerpf(-26.0, -12.0, _compress)
	# Coil zigzag from base to pad.
	var points := PackedVector2Array()
	var steps := 6
	for i in steps + 1:
		var t := float(i) / steps
		var side: float = 10.0 if i % 2 == 0 else -10.0
		if i == 0 or i == steps:
			side = 0.0
		points.append(Vector2(side, lerpf(-7.0, top_y, t)))
	draw_polyline(points, Color(0.7, 0.55, 0.25), 3.0)
	draw_rect(Rect2(Vector2(-29, top_y - 5), Vector2(58, 6)), Color(0.75, 0.6, 0.3))
