class_name Car
extends CompositeObject
## A driveable vehicle: steel chassis + two wheels on motorized pin
## joints. Hold drive_left / drive_right (A/D or arrow keys) to drive.
## With the motor always enabled, a target velocity of 0 acts as a
## brake — release the keys and the car stops instead of coasting.

## Wheel spin speed in radians/second while driving.
@export var motor_speed: float = 25.0

@onready var _wheel_joints: Array[PinJoint2D] = [
	$JointLeft, $JointRight,
]

func _ready() -> void:
	super._ready()
	for joint in _wheel_joints:
		joint.motor_enabled = true

func _physics_process(_delta: float) -> void:
	var direction := Input.get_axis("drive_left", "drive_right")
	for joint in _wheel_joints:
		if is_instance_valid(joint):
			joint.motor_target_velocity = direction * motor_speed
