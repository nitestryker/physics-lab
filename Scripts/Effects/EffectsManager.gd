extends Node
## Autoload: owns all persistent world effects — physical ash and blood.
## Responsibilities:
##  1. Spawning (ash bursts, blood splatters, stains).
##  2. Hard caps so effects can never tank the framerate: when a cap is
##     exceeded the OLDEST effect is removed. Burn down a whole village
##     and the frame rate survives.
##  3. Wind: fast-moving physics objects push nearby ash flecks.

const ASH_SCRIPT := preload("res://Scripts/Effects/AshParticle.gd")
const DROPLET_SCRIPT := preload("res://Scripts/Effects/BloodDroplet.gd")
const STAIN_SCRIPT := preload("res://Scripts/Effects/BloodStain.gd")

const MAX_ASH := 200
const MAX_STAINS := 250
const MAX_DROPLETS := 80

## Objects slower than this create no wind.
const WIND_MIN_SPEED := 130.0

var _ash: Array = []  # untyped: may briefly hold freed instances
var _stains: Array = []  # untyped: stains die with their parent objects
var _droplet_count: int = 0

# ---------------------------------------------------------------- ash

## Turn a burned-up object into a burst of persistent ash flecks.
func spawn_ash_burst(global_pos: Vector2, body_radius: float, container: Node) -> void:
	var count := clampi(int(body_radius / 2.5) + 5, 6, 18)
	for i in count:
		var ash: AshParticle = ASH_SCRIPT.new()
		ash.radius = randf_range(1.6, 3.2)
		ash.color = Color(0.12, 0.11, 0.1).lightened(randf_range(0.0, 0.15))
		container.add_child(ash)
		# Set global_position AFTER add_child: the container may itself be
		# offset (ragdoll/rope roots), so local coords would land far away.
		ash.global_position = global_pos + Vector2.RIGHT.rotated(randf() * TAU) * randf_range(0.0, body_radius * 0.7)
		# Gentle settle instead of a burst — the pile forms where it burned.
		ash.linear_velocity = Vector2.RIGHT.rotated(randf() * TAU) * randf_range(8.0, 35.0) + Vector2(0, -randf_range(5.0, 25.0))

func register_ash(ash: AshParticle) -> void:
	_ash.append(ash)
	while _ash.size() > MAX_ASH:
		# Untyped on purpose: the popped entry may be a freed instance
		# (assigning one to a typed var raises an error).
		var oldest = _ash.pop_front()
		if is_instance_valid(oldest):
			oldest.queue_free()

# -------------------------------------------------------------- blood

## Impact splatter: an immediate stain on the thing that was hit, plus
## droplets flung with the impact velocity that stain whatever they land on.
func splatter(contact: Vector2, impact_velocity: Vector2, severity: float, source: PhysicsBody2D, other: Node) -> void:
	severity = clampf(severity, 0.15, 1.0)
	# Blood in the area where he was hit.
	if other is Node2D:
		add_stain(other, (other as Node2D).to_local(contact), 4.0 + severity * 6.0)
	# Blood flung through the air.
	var count := int(4 + severity * 10.0)
	for i in count:
		if _droplet_count >= MAX_DROPLETS:
			return
		var drop: BloodDroplet = DROPLET_SCRIPT.new()
		drop.radius = randf_range(1.8, 3.0)
		if is_instance_valid(source):
			var tree_parent := source.get_parent()
			# Composite parts (ragdoll limbs) live under the composite root,
			# which can be freed while droplets are still flying — and is
			# offset in space. Parent droplets to the world above it.
			if tree_parent is CompositeObject:
				tree_parent = tree_parent.get_parent()
			tree_parent.add_child(drop)
			drop.add_collision_exception_with(source)
		else:
			add_child(drop)
		drop.global_position = contact + Vector2.RIGHT.rotated(randf() * TAU) * 4.0
		var spray := impact_velocity * randf_range(0.15, 0.4)
		spray = spray.rotated(randf_range(-0.5, 0.5))
		spray += Vector2(0, -randf_range(40.0, 140.0))
		drop.linear_velocity = spray
		_droplet_count += 1
		drop.tree_exited.connect(func() -> void: _droplet_count = maxi(0, _droplet_count - 1))

func add_stain(target: Node2D, local_pos: Vector2, size: float) -> void:
	var stain: BloodStain = STAIN_SCRIPT.new()
	stain.base_radius = size
	stain.position = local_pos
	target.add_child(stain)

func register_stain(stain: BloodStain) -> void:
	_stains.append(stain)
	while _stains.size() > MAX_STAINS:
		# Untyped on purpose: stains are parented to objects and die with
		# them (burned, shattered), so the oldest entries are often freed
		# already — assigning a freed instance to a typed var errors.
		var oldest = _stains.pop_front()
		if is_instance_valid(oldest):
			oldest.queue_free()

## Wipe all persistent effects (Clear button): ash piles, every stain
## (including ones on the environment), and droplets still in flight.
func clear_effects() -> void:
	for ash in _ash:
		if is_instance_valid(ash):
			ash.queue_free()
	_ash.clear()
	for stain in _stains:
		if is_instance_valid(stain):
			stain.queue_free()
	_stains.clear()
	for droplet in get_tree().get_nodes_in_group("blood_droplets"):
		if is_instance_valid(droplet):
			droplet.queue_free()

# --------------------------------------------------------------- wind

func _physics_process(delta: float) -> void:
	if _ash.is_empty():
		return
	# Prune freed flecks in place (filter() returns an UNTYPED Array,
	# which cannot be assigned back to Array[AshParticle] at runtime).
	for i in range(_ash.size() - 1, -1, -1):
		if not is_instance_valid(_ash[i]):
			_ash.remove_at(i)
	if _ash.is_empty():
		return
	for mover in get_tree().get_nodes_in_group("physics_objects"):
		if not (mover is RigidBody2D):
			continue
		var velocity: Vector2 = mover.linear_velocity
		var speed := velocity.length()
		if speed < WIND_MIN_SPEED:
			continue
		var radius := 50.0 + speed * 0.08
		var mover_pos: Vector2 = mover.global_position
		# Typed loop var: _ash is untyped (may hold freed entries between
		# prunes), but we pruned just above, so every entry here is live.
		for ash: AshParticle in _ash:
			var dist := ash.global_position.distance_to(mover_pos)
			if dist < radius:
				var falloff := 1.0 - dist / radius
				# Impulse (not force) so it wakes sleeping flecks.
				var gust := (velocity * 1.5 + Vector2(0, -speed * 0.4)) * falloff
				ash.apply_central_impulse(gust * ash.mass * delta)
