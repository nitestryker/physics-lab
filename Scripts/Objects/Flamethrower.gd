class_name Flamethrower
extends CompositeObject
## Cycling flamethrower: fires a flame jet for fire_time seconds, then
## cools down, then fires again — forever. While firing, a heat zone in
## front of the nozzle pumps heat into every flammable inside it, so
## things ignite after brief exposure and burn via the normal fire
## system. Aims along local +X (right, by default spawn orientation).

@export var fire_time: float = 5.0
@export var cooldown_time: float = 3.0
@export var flame_range: float = 190.0

var _zone: Area2D
var _jet: CPUParticles2D
var _firing: bool = false
var _timer: float = 0.0

func _ready() -> void:
	var body := StaticBody2D.new()
	body.name = "Body"
	var body_cs := CollisionShape2D.new()
	var body_shape := RectangleShape2D.new()
	body_shape.size = Vector2(36, 26)
	body_cs.shape = body_shape
	body.add_child(body_cs)
	add_child(body)
	body.owner = self
	_zone = Area2D.new()
	_zone.collision_mask = 1
	_zone.monitoring = false
	var zone_cs := CollisionShape2D.new()
	var zone_shape := RectangleShape2D.new()
	zone_shape.size = Vector2(flame_range, 46)
	zone_cs.shape = zone_shape
	_zone.add_child(zone_cs)
	_zone.position = Vector2(24 + flame_range / 2.0, 0)
	add_child(_zone)
	_jet = CPUParticles2D.new()
	_jet.emitting = false
	_jet.amount = 70
	_jet.lifetime = 0.45
	_jet.local_coords = false
	_jet.direction = Vector2.RIGHT
	_jet.spread = 7.0
	_jet.gravity = Vector2(0, -70)  # flame drifts up
	_jet.initial_velocity_min = flame_range / 0.55
	_jet.initial_velocity_max = flame_range / 0.42
	_jet.scale_amount_min = 2.5
	_jet.scale_amount_max = 5.0
	_jet.color = Color(1.0, 0.55, 0.1, 0.85)
	_jet.position = Vector2(24, 0)
	add_child(_jet)
	_timer = cooldown_time * randf()  # desync multiple flamethrowers
	super._ready()

func _physics_process(delta: float) -> void:
	_timer -= delta
	if _timer <= 0.0:
		_firing = not _firing
		_timer = fire_time if _firing else cooldown_time
		_zone.monitoring = _firing
		_jet.emitting = _firing
	if _firing:
		for body in _zone.get_overlapping_bodies():
			var flammable := body.get_node_or_null(^"Flammable") as Flammable
			if flammable and not flammable.burning:
				flammable.add_heat(delta * 3.0)

func _draw() -> void:
	draw_rect(Rect2(Vector2(-18, -13), Vector2(36, 26)), Color(0.35, 0.3, 0.28))
	draw_rect(Rect2(Vector2(14, -6), Vector2(14, 12)), Color(0.2, 0.18, 0.17))  # nozzle
	if _firing:
		draw_circle(Vector2(26, 0), 4.0, Color(1.0, 0.7, 0.2))

func _process(_delta: float) -> void:
	queue_redraw()
