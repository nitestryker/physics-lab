class_name CompositeObject
extends Node2D
## Shared base for multi-body objects (Ragdoll, Rope, Spring): a plain
## Node2D root over several physics bodies and joints. Mirrors just
## enough of the PhysicsObject API (spawned/despawned, remove) that the
## Grabber and Spawner treat composites like any other object.
## Extracted from RagdollController once a second composite existed —
## "build systems, not one-off mechanics" (Development Rules).

signal spawned
signal despawned

func _ready() -> void:
	add_to_group("composites")
	register_joints()
	spawned.emit()

## Registers direct-child joints with the Developer Panel's counter.
func register_joints() -> void:
	for child in get_children():
		if child is Joint2D and not child.is_in_group("joints"):
			child.add_to_group("joints")

var _removed: bool = false

## Removing any part removes the whole composite (the Grabber delegates
## body removal to the scene owner — see Grabber._try_remove).
## Idempotent: bulk-clear asks once per part (6x for a ragdoll).
func remove() -> void:
	if _removed:
		return
	_removed = true
	despawned.emit()
	queue_free()
