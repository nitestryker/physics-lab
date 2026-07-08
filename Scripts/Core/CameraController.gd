extends Camera2D
## Middle-mouse drag to pan, scroll wheel to zoom.

@export var zoom_step: float = 1.1
@export var min_zoom: float = 0.3
@export var max_zoom: float = 3.0

var _panning := false

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		match event.button_index:
			MOUSE_BUTTON_MIDDLE:
				_panning = event.pressed
			MOUSE_BUTTON_WHEEL_UP:
				if event.pressed: _zoom(zoom_step)
			MOUSE_BUTTON_WHEEL_DOWN:
				if event.pressed: _zoom(1.0 / zoom_step)
	elif event is InputEventMouseMotion and _panning:
		position -= event.relative / zoom

func _zoom(factor: float) -> void:
	var z := clampf(zoom.x * factor, min_zoom, max_zoom)
	zoom = Vector2(z, z)
