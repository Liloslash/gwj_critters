extends Area3D

func get_random_position() -> Vector3:
	var zones = get_children()
	var collision_shape = zones[randi() % zones.size()]
	var shape = collision_shape.shape
	var box = shape as BoxShape3D

	# Position aléatoire dans l'espace local de la shape
	var local_random_pos = Vector3(
		randf_range(-box.size.x / 2, box.size.x / 2),
		0,
		randf_range(-box.size.z / 2, box.size.z / 2)
	)

	# Appliquer la transformation du CollisionShape3D puis celle de l'Area3D
	var global_pos = global_transform * (collision_shape.transform * local_random_pos)
	return global_pos
