extends CanvasLayer
## Developer Panel (see project doc). Always-on debug overlay: stats,
## gravity slider, pause / slow motion, and quick spawn buttons.
## process_mode is ALWAYS so the Pause button can also un-pause.
##
## "Show collision shapes / joints / centers of mass" cannot be toggled
## at runtime without an addon — use the editor's Debug menu >
## "Visible Collision Shapes" when running from the editor.

const DEFAULT_GRAVITY := 980.0
const SLOWMO_SCALE := 0.2

@onready var fps_label: Label = %FpsLabel
@onready var bodies_label: Label = %BodiesLabel
@onready var joints_label: Label = %JointsLabel
@onready var gravity_slider: HSlider = %GravitySlider
@onready var gravity_label: Label = %GravityLabel
@onready var pause_button: Button = %PauseButton
@onready var slowmo_button: Button = %SlowMoButton
@onready var tool_label: Label = %ToolLabel

func _ready() -> void:
	gravity_slider.value = DEFAULT_GRAVITY
	gravity_slider.value_changed.connect(_on_gravity_changed)
	pause_button.toggled.connect(_on_pause_toggled)
	slowmo_button.toggled.connect(_on_slowmo_toggled)
	%SpawnBoxButton.pressed.connect(_quick_spawn.bind("Box"))
	%SpawnBallButton.pressed.connect(_quick_spawn.bind("Ball"))
	%SpawnBeamButton.pressed.connect(_quick_spawn.bind("Beam"))
	%SpawnRagdollButton.pressed.connect(_quick_spawn.bind("Ragdoll"))
	%SpawnRopeButton.pressed.connect(_quick_spawn.bind("Rope"))
	%SpawnSpringButton.pressed.connect(_quick_spawn.bind("Spring"))
	%SpawnWheelButton.pressed.connect(_quick_spawn.bind("Wheel"))
	%SpawnMotorButton.pressed.connect(_quick_spawn.bind("Motor"))
	%SpawnCarButton.pressed.connect(_quick_spawn.bind("Car"))
	%SpawnEmberButton.pressed.connect(_quick_spawn.bind("Ember"))
	%SpawnSteelButton.pressed.connect(_quick_spawn.bind("Steel"))
	%SpawnBatteryButton.pressed.connect(_quick_spawn.bind("Battery"))
	%SpawnConveyorButton.pressed.connect(_quick_spawn.bind("Conveyor"))
	%SpawnSawButton.pressed.connect(_quick_spawn.bind("Saw"))
	%SpawnLauncherButton.pressed.connect(_quick_spawn.bind("Launcher"))
	%SpawnFlamethrowerButton.pressed.connect(_quick_spawn.bind("Flamethrower"))
	%SpawnCrusherButton.pressed.connect(_quick_spawn.bind("Crusher"))
	%JointPinButton.pressed.connect(GameManager.set_joint.bind("Pin"))
	%JointSpringButton.pressed.connect(GameManager.set_joint.bind("Spring"))
	%JointRopeButton.pressed.connect(GameManager.set_joint.bind("Rope"))
	%DragButton.pressed.connect(GameManager.set_drag)
	%ClearButton.pressed.connect(GameManager.request_clear)
	%SaveButton.pressed.connect(SaveManager.save_world)
	%LoadButton.pressed.connect(SaveManager.load_world)
	GameManager.tool_changed.connect(_on_tool_changed)
	_on_tool_changed()

func _process(_delta: float) -> void:
	fps_label.text = "FPS: %d" % Engine.get_frames_per_second()
	bodies_label.text = "Bodies: %d" % get_tree().get_nodes_in_group("physics_objects").size()
	joints_label.text = "Joints: %d" % get_tree().get_nodes_in_group("joints").size()

func _quick_spawn(type: String) -> void:
	# Arms the click-to-place tool ONLY — nothing spawns until you
	# left-click in the world. (Drag Only disarms it again.)
	GameManager.set_spawn(type)

func _on_tool_changed() -> void:
	match GameManager.tool_mode:
		"drag":
			tool_label.text = "Drag mode: click only grabs"
		"spawn":
			tool_label.text = "Click to place: %s" % GameManager.selected_type
		"joint":
			tool_label.text = "Joint (%s): click two objects" % GameManager.joint_type

func _on_gravity_changed(value: float) -> void:
	gravity_label.text = "Gravity: %d" % int(value)
	PhysicsServer2D.area_set_param(
		get_viewport().find_world_2d().space,
		PhysicsServer2D.AREA_PARAM_GRAVITY,
		value
	)

func _on_pause_toggled(pressed: bool) -> void:
	get_tree().paused = pressed
	pause_button.text = "Resume" if pressed else "Pause"

func _on_slowmo_toggled(pressed: bool) -> void:
	Engine.time_scale = SLOWMO_SCALE if pressed else 1.0
