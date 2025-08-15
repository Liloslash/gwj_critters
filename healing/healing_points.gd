extends Node3D

const HEALING_POINT = preload("res://healing/healing_point.tscn")

func spawn_healing_point() -> void:
	var points = get_children()
	var rand_point = points[randi() % points.size()]
	var healing_point = HEALING_POINT.instantiate()
	healing_point.position = rand_point.position
	add_child(healing_point)
