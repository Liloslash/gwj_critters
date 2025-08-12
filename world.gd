extends Node3D

@onready var spawn_timer: Timer = $SpawnTimer

@onready var spawn_points: Node3D = $SpawnPoints
@onready var spawn_markers: Array[Marker3D] = []

@export var enemy_scene: PackedScene
@export var spawn_interval_seconds: float = 3.0

func _ready() -> void:
	spawn_timer.wait_time = spawn_interval_seconds
	spawn_timer.autostart = false
	spawn_timer.one_shot = false
	if not spawn_timer.timeout.is_connected(_on_spawn_timer_timeout):
		spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	# Seed RNG and cache all Marker3D children under SpawnPoints
	randomize()
	spawn_markers.clear()
	for child in spawn_points.get_children():
		if child is Marker3D:
			spawn_markers.append(child)
	spawn_timer.start()

func _on_spawn_timer_timeout() -> void:
	if enemy_scene == null:
		return
	if spawn_markers.is_empty():
		return
	var random_index := randi() % spawn_markers.size()
	var chosen_marker: Marker3D = spawn_markers[random_index]
	var enemy_instance: Node3D = enemy_scene.instantiate()
	enemy_instance.transform = chosen_marker.global_transform
	add_child(enemy_instance)
