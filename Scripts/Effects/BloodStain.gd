class_name BloodStain
extends Node2D
## A liquid blood stain. Parented to whatever the blood landed on, so it
## travels with moving objects. Behaves like a liquid, not a decal:
##  - splashes outward on landing (grows from 55% to full in ~0.15s)
##  - stays WET for several seconds: drips run downward in WORLD
##    gravity, recalculated every frame — so a drip on a swinging limb
##    keeps pulling toward the real down, like liquid would
##  - dries: brightens-to-darkens over DRY_TIME, then freezes in place
##    (a dried smear rotates with the surface it's stuck to)

var base_radius: float = 5.0
var color_fresh: Color = Color(0.85, 0.06, 0.08, 0.95)
var color_dry: Color = Color(0.45, 0.03, 0.05, 0.88)

const DRY_TIME := 6.0
const SPLASH_TIME := 0.15

var _age: float = 0.0
var _blobs: Array[Vector3] = []  # x, y = offset; z = radius
var _drips: Array[Vector3] = []  # x = lateral offset; y = full length; z = width
var _down_local: Vector2 = Vector2.DOWN

func _ready() -> void:
	rotation = randf() * TAU
	_blobs.append(Vector3(0, 0, base_radius))
	for i in randi_range(2, 4):
		var off := Vector2.RIGHT.rotated(randf() * TAU) * base_radius * randf_range(0.4, 1.0)
		_blobs.append(Vector3(off.x, off.y, base_radius * randf_range(0.35, 0.6)))
	for i in randi_range(1, 2):
		_drips.append(Vector3(
			randf_range(-0.6, 0.6) * base_radius,      # where the run starts
			base_radius * randf_range(1.8, 4.2),        # how far it runs
			maxf(1.5, base_radius * randf_range(0.18, 0.3))))  # thickness
	EffectsManager.register_stain(self)

func _process(delta: float) -> void:
	_age += delta
	if _age < DRY_TIME:
		# World-space down converted into this stain's local space —
		# drips chase true gravity while the stain is still wet.
		_down_local = Vector2.DOWN.rotated(-global_rotation)
		queue_redraw()
	else:
		set_process(false)  # dry: freeze as drawn, zero ongoing cost
		queue_redraw()

func _draw() -> void:
	var dryness := clampf(_age / DRY_TIME, 0.0, 1.0)
	var col := color_fresh.lerp(color_dry, dryness)
	var splash := minf(_age / SPLASH_TIME, 1.0)
	var spread := lerpf(0.55, 1.0, splash)
	for blob in _blobs:
		draw_circle(Vector2(blob.x, blob.y) * spread, blob.z * spread, col)
	# Drips grow during the wet phase, easing out, with a bead at the tip.
	var side := _down_local.orthogonal()
	var grow := clampf(_age / (DRY_TIME * 0.45), 0.0, 1.0)
	grow = 1.0 - pow(1.0 - grow, 2.0)
	for drip in _drips:
		if grow < 0.03:
			continue
		var start := side * drip.x
		var tip := start + _down_local * drip.y * grow
		draw_line(start, tip, col, drip.z)
		draw_circle(tip, drip.z * 0.75, col)
