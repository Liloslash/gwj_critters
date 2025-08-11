extends Node3D

@onready var spawn_point: Marker3D = $SpawnPoint
@onready var spawn_timer: Timer = $SpawnTimer

@export var enemy_scene: PackedScene
@export var spawn_interval_seconds: float = 3.0

func _ready() -> void:
	spawn_timer.wait_time = spawn_interval_seconds
	spawn_timer.autostart = false
	spawn_timer.one_shot = false
	if not spawn_timer.timeout.is_connected(_on_spawn_timer_timeout):
		spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	spawn_timer.start()

func _on_spawn_timer_timeout() -> void:
	if enemy_scene == null:
		return
	var enemy_instance: Node3D = enemy_scene.instantiate()
	add_child(enemy_instance)
	enemy_instance.global_transform = spawn_point.global_transform
