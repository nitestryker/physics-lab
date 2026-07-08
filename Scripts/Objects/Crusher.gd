class_name Crusher
extends CompositeObject
## A hydraulic crusher: a genuinely heavy steel head on a vertical
## GrooveJoint2D rail, driven by real forces — raised slowly, held,
## then slammed down at ~900 px/s with ~24 mass units. No scripted
## damage: the slam clears the CRUSH severing threshold and the Damage
## component's thresholds through ordinary physics.

const BASE_SCENE := preload("res://Scenes/Base/PhysicsObject.tscn")
const STEEL := preload("res://Resources/Materials/Steel.tres")

@export var travel: float = 140.0
@export var hold_up_time: float = 1.2
@export var hold_down_time: float = 0.6

var _head: PhysicsObject
var _frame: StaticBody2D
var _state: String = "raising"
var _timer: float = 0.0

func _ready() -> void:
	# Top frame the head hangs from.
	_frame = StaticBody2D.new()
	_frame.name = "Frame"
	var frame_cs := CollisionShape2D.new()
	var frame_shape := RectangleShape2D.new()
	frame_shape.size = Vector2(96, 16)
	frame_cs.shape = frame_shape
	_frame.add_child(frame_cs)
	_frame.position = Vector2(0, -travel - 40)
	add_child(_frame)
	_frame.owner = self
	# The head: heavy steel, real physics.
	_head = BASE_SCENE.instantiate()
	_head.name = "Head"
	_head.object_material = STEEL
	_head.base_mass = 8.0  # x steel density 3.0 = 24 mass
	add_child(_head)
	_head.owner = self
	var head_shape := RectangleShape2D.new()
	head_shape.size = Vector2(76, 36)
	(_head.get_node(^"CollisionShape2D") as CollisionShape2D).shape = head_shape
	_head.position = Vector2(0, -travel)
	# Vertical rail.
	var groove := GrooveJoint2D.new()
	add_child(groove)
	groove.position = Vector2(0, -travel - 32)
	groove.length = travel + 40.0
	groove.node_a = groove.get_path_to(_frame)
	groove.node_b = groove.get_path_to(_head)
	super._ready()

func _physics_process(delta: float) -> void:
	if not is_instance_valid(_head):
		set_physics_process(false)
		return
	var gravity_force := 980.0 * _head.mass
	var head_local_y := to_local(_head.global_position).y
	match _state:
		"raising":
			_head.apply_central_force(Vector2(0, -gravity_force * 2.2))
			if head_local_y <= -travel + 6.0:
				_state = "hold_up"
				_timer = hold_up_time
		"hold_up":
			_head.apply_central_force(Vector2(0, -gravity_force))  # hover
			_timer -= delta
			if _timer <= 0.0:
				_state = "slamming"
		"slamming":
			_head.apply_central_force(Vector2(0, gravity_force * 2.0))  # 3g total
			if head_local_y >= -24.0 or _head.linear_velocity.length() < 5.0 and head_local_y > -travel * 0.5:
				_state = "hold_down"
				_timer = hold_down_time
		"hold_down":
			_timer -= delta
			if _timer <= 0.0:
				_state = "raising"

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	# Frame crossbar + side rails.
	var rail := Color(0.3, 0.32, 0.36)
	draw_rect(Rect2(Vector2(-48, -travel - 48), Vector2(96, 16)), rail)
	draw_line(Vector2(-42, -travel - 32), Vector2(-42, 0), rail, 5.0)
	draw_line(Vector2(42, -travel - 32), Vector2(42, 0), rail, 5.0)
