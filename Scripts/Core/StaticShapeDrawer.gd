class_name StaticShapeDrawer
extends StaticBody2D
## Placeholder visuals for environment pieces: draws this static body's
## rectangle collision shapes in a flat color. Swap for tiles/sprites
## later without touching collision.

@export var color: Color = Color(0.35, 0.38, 0.42)

func _draw() -> void:
	for child in get_children():
		if child is CollisionShape2D and child.shape is RectangleShape2D:
			var s: RectangleShape2D = child.shape
			var rect := Rect2(child.position - s.size / 2.0, s.size)
			draw_rect(rect, color)
			draw_rect(rect, color.darkened(0.35), false, 2.0)
