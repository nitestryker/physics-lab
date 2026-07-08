# PhysicsLab

A learning-first Godot 4 project — the foundation for a future physics
sandbox. See `PhysicsLab_Project_Overview` (v1.2) for the full plan.

## Requirements

- Godot 4.3 or newer (2D project)

## Opening the project

1. Open Godot → Import → select this folder's `project.godot`.
2. Press F5. `Scenes/Main/World.tscn` (the Physics Test Room) runs.

The first time you open the project, Godot will show harmless warnings
while it generates UID files for scenes and scripts — just save once
and they go away.

## Controls

| Input | Action |
|---|---|
| Left-click on object | Grab and drag (joint-based; release to throw) |
| Left-click on empty space | Place the selected object type |
| Right-click on object | Remove it |
| Middle-mouse drag | Pan camera |
| Scroll wheel | Zoom |
| A / D or arrow keys | Drive any spawned Car |

## Developer Panel

Top-left overlay: FPS, body/joint counts, gravity slider, pause,
slow motion, and quick-spawn buttons (which also set the
click-to-place tool). To see collision shapes while testing, use the
editor's **Debug → Visible Collision Shapes** before running — Godot
has no built-in runtime toggle for this.

## Architecture (quick orientation)

- `Scenes/Base/PhysicsObject.tscn` + `Scripts/Core/PhysicsObject.gd` —
  minimal base: material handling, spawned/despawned signals, removal,
  placeholder shape drawing. Nothing else belongs here.
- `Scripts/Components/` — attachable behaviors (Grabbable, Health,
  Damage, Breakable, Saveable). Objects get only the components they
  need. **Convention: the component node is named after its script.**
- `Scripts/Physics/ObjectMaterial.gd` + `Resources/Materials/*.tres` —
  the material system. No hard-coded friction/bounce/mass on objects.
- `Scripts/Physics/Grabber.gd` — joint-based mouse grabbing. Must stay
  *below* the Spawner in the World scene tree (it needs first claim on
  input; nodes lower in the tree receive `_unhandled_input` first).

## Adding a new object (the whole point)

1. New scene → inherit `Scenes/Base/PhysicsObject.tscn`.
2. Set the collision shape.
3. Assign a material from `Resources/Materials/`.
4. Add the component nodes it needs.
5. Register it in `ObjectSpawner.SCENES` and add a spawn button.

## First session checklist

- [ ] `git init && git add -A && git commit -m "Scaffold"`
- [ ] Run, spawn boxes, stack them, throw a ball at the stack
- [ ] Drag the gravity slider to 0 mid-flight
- [ ] Throw a box at a wall hard enough to break it (wood is weak)
- [ ] Spawn a ragdoll, grab it by one arm, and swing it around
- [ ] Hang a rope from a platform edge and throw a ragdoll at it
- [ ] Grab a spring's ball, pull it down, and release
- [ ] Spawn a Car, drive it up the ramp with A/D
- [ ] Spawn a Motor next to a box stack and watch the blade clear it
