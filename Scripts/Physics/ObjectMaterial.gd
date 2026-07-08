class_name ObjectMaterial
extends Resource
## First-class material resource (see "Physics Material System" in the
## project doc). Wraps Godot's friction/bounce and adds our own fields.
## Density and strength are consumed by PhysicsObject / components;
## burnable & conductive are future-proofing for fire and electricity.

@export var display_name: String = "Material"
@export var color: Color = Color.WHITE

@export_group("Physics")
## Multiplies the object's base_mass. Wood ~0.8, Steel ~3.0.
@export var density: float = 1.0
@export_range(0.0, 1.0) var friction: float = 0.5
@export_range(0.0, 1.0) var bounce: float = 0.0

@export_group("Gameplay")
## Scales max health via the Health component (higher = tougher).
@export var strength: float = 1.0
## Blood splatters on hard impacts (auto-adds the Bleeder component).
@export var bleeds: bool = false

@export_group("Future Systems")
@export var burnable: bool = false
@export var conductive: bool = false
