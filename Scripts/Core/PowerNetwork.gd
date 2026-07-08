extends Node
## World node: computes electricity each physics tick. Flood-fill from
## every PowerSource through the contact graph of conductive bodies —
## a chain of touching steel is all live at once; break the chain
## anywhere (grab a link, burn a support) and everything downstream
## goes dead the same tick.

func _physics_process(_delta: float) -> void:
	var components := get_tree().get_nodes_in_group("conductive_components")
	if components.is_empty():
		return
	var by_body := {}
	for component in components:
		var body := component.get_parent()
		if is_instance_valid(body):
			by_body[body] = component
	var powered := {}
	var frontier: Array = []
	for source in get_tree().get_nodes_in_group("power_sources"):
		var body := source.get_parent()
		if is_instance_valid(body):
			powered[body] = true
			frontier.append(body)
	while not frontier.is_empty():
		var body = frontier.pop_back()
		if not (body is RigidBody2D):
			continue
		for other in body.get_colliding_bodies():
			if powered.has(other) or not by_body.has(other):
				continue
			powered[other] = true
			frontier.append(other)
	for body in by_body:
		by_body[body].set_powered(powered.has(body))
