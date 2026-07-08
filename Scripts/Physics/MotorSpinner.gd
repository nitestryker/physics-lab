class_name MotorSpinner
extends CompositeObject
## A motorized pin joint spinning a blade around a static mount.
## In Godot 2D, a "hinge" IS a PinJoint2D — the motor properties
## (motor_enabled, motor_target_velocity) were added in 4.3, which is
## why this project requires it.

## Spin speed in radians/second. Negative spins the other way.
@export var spin_speed: float = 12.0

var _joint: PinJoint2D

func _ready() -> void:
	super._ready()
	_joint = get_node(^"Joint") as PinJoint2D
	_joint.motor_enabled = true
	_joint.motor_target_velocity = 0.0  # dead until powered

func _physics_process(_delta: float) -> void:
	# Milestone 0.8: motors need electricity. The blade is steel
	# (conductive) — touch a battery or a steel chain to it to run.
	var conductive := get_node(^"Blade").get_node_or_null(^"Conductive") as Conductive
	var live := conductive != null and conductive.powered
	_joint.motor_target_velocity = spin_speed if live else 0.0
