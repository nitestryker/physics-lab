class_name Conveyor
extends CompositeObject
## A conveyor belt: a static surface with constant_linear_velocity, so
## anything resting on it gets carried along without the belt moving.
## Drawn with scrolling chevrons so the direction is readable.

@export var belt_speed: float = 180.0  # px/s; negative reverses
@export var size: Vector2 = Vector2(210, 18)

var _belt: StaticBody2D
var _scroll: float = 0.0

func _ready() -> void:
	_belt = StaticBody2D.new()
	_belt.name = "Belt"
	var cs := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = size
	cs.shape = shape
	_belt.add_child(cs)
	add_child(_belt)
	_belt.owner = self
	_belt.constant_linear_velocity = Vector2(belt_speed, 0)
	super._ready()

func _process(delta: float) -> void:
	_scroll = fposmod(_scroll + belt_speed * delta, 26.0)
	queue_redraw()

func _draw() -> void:
	var half := size / 2.0
	draw_rect(Rect2(-half, size), Color(0.22, 0.24, 0.28))
	draw_rect(Rect2(-half, size), Color(0.1, 0.11, 0.13), false, 2.0)
	# Scrolling chevrons show direction and speed.
	var chevron := Color(0.55, 0.6, 0.68)
	var direction := signf(belt_speed) if belt_speed != 0.0 else 1.0
	var x := -half.x + _scroll
	while x < half.x - 6.0:
		if x > -half.x + 2.0:
			draw_line(Vector2(x, -half.y + 3), Vector2(x + 6 * direction, 0), chevron, 2.0)
			draw_line(Vector2(x + 6 * direction, 0), Vector2(x, half.y - 3), chevron, 2.0)
		x += 26.0
