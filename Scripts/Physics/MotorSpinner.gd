class_name MotorSpinner
extends CompositeObject
## A motorized pin joint spinning a blade around a static mount.
## In Godot 2D, a "hinge" IS a PinJoint2D — the motor properties
## (motor_enabled, motor_target_velocity) were added in 4.3, which is
## why this project requires it.

## Spin speed in radians/second. Negative spins the other way.
@export var spin_speed: float = 12.0

func _ready() -> void:
	super._ready()
	var joint := get_node(^"Joint") as PinJoint2D
	joint.motor_enabled = true
	joint.motor_target_velocity = spin_speed
