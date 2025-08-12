extends Node3D

signal wave_started(wave_number: int)
signal wave_waiting(seconds_left: int, next_wave_number: int)

@onready var spawn_timer: Timer = $SpawnTimer

@onready var spawn_points: Node3D = $SpawnPoints
@onready var spawn_markers: Array[Marker3D] = []
@onready var wave_timer: Timer = $WaveTimer

@export var enemy_scene: PackedScene
@export var spawn_interval_seconds: float = 2.0
@export var wave_pause_seconds: float = 4.0
@export var wave_spawn_count_base: int = 1
@export var wave_spawn_count_increment: int = 2

var current_wave: int = 0
var enemies_to_spawn_this_wave: int = 0
var enemies_spawned_in_wave: int = 0
var _last_wait_seconds_left: int = -1

func _ready() -> void:
	_configure_spawn_timer()
	_configure_wave_timer()
	_seed_rng()
	_cache_spawn_markers()
	set_process(true)
	_start_next_wave()

func _process(_delta: float) -> void:
	# Emit countdown updates while waiting between waves (on whole-second ticks)
	if wave_timer and not wave_timer.is_stopped():
		var seconds_left: int = int(ceil(wave_timer.time_left))
		if seconds_left != _last_wait_seconds_left:
			_last_wait_seconds_left = seconds_left
			emit_signal("wave_waiting", seconds_left, current_wave + 1)

func _on_spawn_timer_timeout() -> void:
	if _spawn_enemy_random():
		enemies_spawned_in_wave += 1
		if enemies_spawned_in_wave >= enemies_to_spawn_this_wave:
			spawn_timer.stop()
			wave_timer.start()

func _start_next_wave() -> void:
	current_wave += 1
	enemies_spawned_in_wave = 0
	enemies_to_spawn_this_wave = wave_spawn_count_base + (current_wave - 1) * wave_spawn_count_increment
	_notify_wave_started()
	spawn_timer.start()

func _on_wave_timer_timeout() -> void:
	_last_wait_seconds_left = -1
	_start_next_wave()

# --- Helpers ---

func _configure_spawn_timer() -> void:
	spawn_timer.wait_time = spawn_interval_seconds
	spawn_timer.autostart = false
	spawn_timer.one_shot = false
	if not spawn_timer.timeout.is_connected(_on_spawn_timer_timeout):
		spawn_timer.timeout.connect(_on_spawn_timer_timeout)

func _configure_wave_timer() -> void:
	wave_timer.wait_time = wave_pause_seconds
	wave_timer.autostart = false
	wave_timer.one_shot = true
	if not wave_timer.timeout.is_connected(_on_wave_timer_timeout):
		wave_timer.timeout.connect(_on_wave_timer_timeout)

func _seed_rng() -> void:
	randomize()

func _cache_spawn_markers() -> void:
	spawn_markers.clear()
	if not is_instance_valid(spawn_points):
		return
	for child in spawn_points.get_children():
		if child is Marker3D:
			spawn_markers.append(child)

func _get_random_spawn_marker() -> Marker3D:
	if spawn_markers.is_empty():
		return null
	var random_index: int = randi() % spawn_markers.size()
	return spawn_markers[random_index]

func _spawn_enemy_at_marker(marker: Marker3D) -> bool:
	if enemy_scene == null or marker == null:
		return false
	var enemy_instance: Node3D = enemy_scene.instantiate()
	enemy_instance.transform = marker.global_transform
	add_child(enemy_instance)
	return true

func _spawn_enemy_random() -> bool:
	var marker: Marker3D = _get_random_spawn_marker()
	return _spawn_enemy_at_marker(marker)

func _notify_wave_started() -> void:
	emit_signal("wave_started", current_wave)
	var hud: Node = get_node_or_null("HUD")
	if hud and hud.has_method("set_wave"):
		hud.call("set_wave", current_wave)
