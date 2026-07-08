# PhysicsLab

A learning-first Godot 4 project — the foundation for a future physics
sandbox. See `PhysicsLab_Project_Overview` (v1.2) for the full plan.

## Requirements

- Godot 4.3 or newer (2D project)

## Opening the project

1. Open Godot → Import → select this folder's `project.godot`.
2. Press F5. `Scenes/Main/World.tscn` (the Physics Test Room) runs.

Physics runs at 120 ticks/second with continuous collision detection on
all bodies — required for stable ragdoll piles and thin platforms.

The first time you open the project, Godot will show harmless warnings
while it generates UID files for scenes and scripts — just save once
and they go away.

## Controls

| Input | Action |
|---|---|
| Left-click on object | Grab and drag (joint-based; release to throw) |
| Left-click on empty space | Place the selected type (nothing in Drag mode) |
| Right-click on object | Remove it |
| Middle-mouse drag | Pan camera |
| Scroll wheel | Zoom |
| A / D or arrow keys | Drive any spawned Car |
| Joint tool (Pin/Spring/Rope) | Click two objects to connect them at the clicked points |

## Developer Panel

Top-left overlay: FPS, body/joint counts, gravity slider, pause,
slow motion, and spawn-tool buttons: pick a type, then left-click in
the world to place it. Drag Only disarms placing. Save writes the world
to user://physicslab_save.json; Load wipes and restores it (objects keep
health, velocity, and burning progress; composites respawn fresh; player
joints and rope-links persist, except ones tied to composite parts).
Clear Spawned wipes
every spawned object, ash pile, and blood stain — the environment stays. To see collision shapes while testing, use the
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
- [ ] Throw a box hard at a wall — it now shatters into fragments
- [ ] Drop an Ember on a box stack and watch fire spread, char, and break them
- [ ] Touch an Ember to a ragdoll — limbs char, burn to physical ash, and drop off
- [ ] Drive the Car through an ash pile, then reverse over it fast — wind scatters it
- [ ] Touch an Ember to the middle of a rope — fire crawls both ways and splits it

Burnable: Wood (Box, Beam), Rubber (Ball, Wheel, car wheels, spring ball), Flesh (ragdoll), Rope. Non-burnable by design: Steel (motor blade), Glass, the environment. The car is wood + rubber and burns completely.
- [ ] Throw a ragdoll hard at a wall — blood sprays from the limb that hits first
- [ ] Slam a heavy box into a resting ragdoll — blood stains where it was struck
- [ ] Watch a fresh stain on a wall: it splashes, runs downward, then dries dark
- [ ] Touch a Battery to a Motor's blade — it spins; pull the battery away — it stops
- [ ] Chain Steel boxes from a battery to the blade, then burn a wooden link out
- [ ] Hold a severed limb against the running saw — it grinds into
      blood flung tangentially, direction turning with the blade
- [ ] Build the gauntlet: Conveyor into Saw into Launcher over a
      Flamethrower, landing at a Crusher. Feed it a ragdoll.
- [ ] Swing a beam edge-first into a ragdoll's arm at full speed (severs);
      throw the ragdoll at a wall as hard as you can (never severs)
