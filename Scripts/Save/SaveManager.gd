extends Node
## Autoload: saves and loads the world (Milestone 0.7). JSON at
## user://physicslab_save.json — never res:// (fails in exported builds).
##
## WHAT PERSISTS:
##  - Standalone objects (Box, Ball, Beam, Wheel, Ember...): transform,
##    velocities, health, and burning state (a half-charred burning box
##    loads half-charred and burning — deterministic char pays off here)
##  - Composites (Ragdoll, Rope, Spring, Motor, Car): respawned fresh at
##    their saved root transform (poses are not preserved)
##  - Player joints (Pin/Spring) and rope-links, including ones anchored
##    to the environment (referenced by stable node path)
## WHAT DOESN'T (by design, for now):
##  - Fragments/debris, ash, blood; joints attached to composite parts

const SAVE_PATH := "user://physicslab_save.json"
const BASE_SCENE_PATH := "res://Scenes/Base/PhysicsObject.tscn"

func save_world() -> void:
	var data := {"version": 1, "objects": [], "composites": [], "joints": [], "links": []}
	var id_map := {}  # body -> save id, for joint references
	var next_id := 0
	# Standalone physics objects (composite parts are saved via their root).
	for body in get_tree().get_nodes_in_group("physics_objects"):
		if not (body is PhysicsObject) or not is_instance_valid(body):
			continue
		if body.owner != null:
			continue  # part of a composite
		if body.scene_file_path == "" or body.scene_file_path == BASE_SCENE_PATH:
			continue  # procedural fragment/debris — not persisted
		var entry := {
			"id": next_id,
			"path": body.scene_file_path,
			"pos": _v(body.global_position),
			"rot": body.global_rotation,
			"lin": _v(body.linear_velocity),
			"ang": body.angular_velocity,
		}
		var health := body.get_node_or_null(^"Health") as Health
		if health:
			entry["health"] = health.current
		var flammable := body.get_node_or_null(^"Flammable") as Flammable
		if flammable and flammable.burning and not flammable.eternal:
			entry["burn"] = flammable.char_progress() * flammable.burn_out_time
		id_map[body] = next_id
		next_id += 1
		data.objects.append(entry)
	# Composite roots (skip RopeLinks — they save as links below).
	for composite in get_tree().get_nodes_in_group("composites"):
		if not is_instance_valid(composite) or composite is RopeLink:
			continue
		if composite.scene_file_path == "":
			continue
		data.composites.append({
			"path": composite.scene_file_path,
			"pos": _v(composite.global_position),
			"rot": composite.global_rotation,
		})
	# Player joints, via the JointTool's records.
	var joint_tool := get_tree().get_first_node_in_group("joint_tool")
	if joint_tool:
		for link in joint_tool.serialize_links():
			var ref_a: Dictionary = _body_ref(link.body_a, id_map)
			var ref_b: Dictionary = _body_ref(link.body_b, id_map)
			if ref_a.is_empty() or ref_b.is_empty():
				continue  # endpoint is a composite part — skipped for now
			data.joints.append({"type": link.type,
				"a": ref_a, "la": _v(link.local_a),
				"b": ref_b, "lb": _v(link.local_b)})
	# Player rope-links.
	for composite in get_tree().get_nodes_in_group("composites"):
		if composite is RopeLink and is_instance_valid(composite):
			var ends: Array = composite.endpoints()
			if ends.is_empty():
				continue
			var ref_a: Dictionary = _body_ref(ends[0], id_map)
			var ref_b: Dictionary = _body_ref(ends[2], id_map)
			if ref_a.is_empty() or ref_b.is_empty():
				continue
			data.links.append({"a": ref_a, "la": _v(ends[1]), "b": ref_b, "lb": _v(ends[3])})
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("SaveManager: could not open %s for writing." % SAVE_PATH)
		return
	file.store_string(JSON.stringify(data))
	file.close()

func load_world() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		push_warning("SaveManager: no save file yet.")
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	if not (parsed is Dictionary):
		push_warning("SaveManager: save file is corrupt.")
		return
	var data: Dictionary = parsed
	var spawner := get_tree().get_first_node_in_group("object_spawner")
	if spawner == null:
		push_warning("SaveManager: no spawner in scene.")
		return
	var container: Node = spawner.get_parent()
	# Wipe the current world, then wait for the frees to actually happen.
	spawner.clear_spawned()
	await get_tree().process_frame
	await get_tree().process_frame
	var by_id := {}  # save id -> live body
	for entry in data.get("objects", []):
		var scene := load(entry.path) as PackedScene
		if scene == null:
			continue
		var body: PhysicsObject = scene.instantiate()
		container.add_child(body)
		body.global_position = _a(entry.pos)
		body.global_rotation = entry.rot
		body.linear_velocity = _a(entry.lin)
		body.angular_velocity = entry.ang
		if entry.has("health"):
			var health := body.get_node_or_null(^"Health") as Health
			if health:
				health.current = minf(entry.health, health.max_health)
		if entry.has("burn"):
			var flammable := body.get_node_or_null(^"Flammable") as Flammable
			if flammable:
				flammable.resume_burn(entry.burn)
		by_id[int(entry.id)] = body
	for entry in data.get("composites", []):
		var scene := load(entry.path) as PackedScene
		if scene == null:
			continue
		var composite: Node2D = scene.instantiate()
		container.add_child(composite)
		composite.global_position = _a(entry.pos)
		composite.global_rotation = entry.rot
	var joint_tool := get_tree().get_first_node_in_group("joint_tool")
	if joint_tool:
		for entry in data.get("joints", []):
			var body_a := _resolve(entry.a, by_id)
			var body_b := _resolve(entry.b, by_id)
			if body_a and body_b:
				joint_tool.create_link(entry.type,
					body_a, body_a.to_global(_a(entry.la)),
					body_b, body_b.to_global(_a(entry.lb)))
	for entry in data.get("links", []):
		var body_a := _resolve(entry.a, by_id)
		var body_b := _resolve(entry.b, by_id)
		if body_a and body_b:
			var rope_link := RopeLink.new()
			container.add_child(rope_link)
			rope_link.build(body_a, body_a.to_global(_a(entry.la)),
				body_b, body_b.to_global(_a(entry.lb)))

func _body_ref(body: Node, id_map: Dictionary) -> Dictionary:
	if not is_instance_valid(body):
		return {}
	if id_map.has(body):
		return {"id": id_map[body]}
	if body is StaticBody2D:
		return {"env": str(body.get_path())}  # environment: stable path
	return {}

func _resolve(ref: Dictionary, by_id: Dictionary) -> PhysicsBody2D:
	if ref.has("id"):
		var body = by_id.get(int(ref.id))
		return body if is_instance_valid(body) else null
	if ref.has("env"):
		return get_node_or_null(NodePath(ref.env)) as PhysicsBody2D
	return null

func _v(vec: Vector2) -> Array:
	return [vec.x, vec.y]

func _a(arr) -> Vector2:
	return Vector2(arr[0], arr[1])
