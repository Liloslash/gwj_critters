extends Node3D

@onready var spawn_timer: Timer = $SpawnTimer

@onready var spawn_points: Node3D = $SpawnPoints
@onready var spawn_markers: Array[Marker3D] = []
@onready var wave_timer: Timer = $WaveTimer

@export var enemy_scene: PackedScene
@export var spawn_interval_seconds: float = 1.0
@export var wave_pause_seconds: float = 2.0
@export var enemy_count_base: int = 4
@export var enemy_count_multiplier: float = 3.0
@export var enemy_linear_increment: int = 4
@export var spawn_delay_min_seconds: float = 0.2
@export var spawn_delay_numerator: float = 2.0

var current_wave: int = 0
var enemies_to_spawn_this_wave: int = 0
var enemies_spawned_in_wave: int = 0
var enemies_alive_count: int = 0
var is_between_waves: bool = false

func _ready() -> void:
	_configure_spawn_timer()
	_configure_wave_timer()
	_seed_rng()
	_cache_spawn_markers()
	_start_next_wave()


func _on_spawn_timer_timeout() -> void:
	if _spawn_enemy_random():
		enemies_spawned_in_wave += 1
		if enemies_spawned_in_wave >= enemies_to_spawn_this_wave:
			spawn_timer.stop()
			# If all spawned enemies are already dead, finish the wave now
			if enemies_alive_count <= 0:
				_finish_wave()

func _start_next_wave() -> void:
	is_between_waves = false
	current_wave += 1
	enemies_spawned_in_wave = 0
	enemies_to_spawn_this_wave = _compute_enemy_count_for_wave(current_wave)
	spawn_timer.wait_time = _compute_spawn_interval_for_wave(current_wave)
	print("Wave %d: %d enemies to spawn (spawn delay: %.2fs)" % [current_wave, enemies_to_spawn_this_wave, spawn_timer.wait_time])
	_update_hud_wave_started()
	spawn_timer.start()

func _on_wave_timer_timeout() -> void:
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
	enemies_alive_count += 1
	if not enemy_instance.tree_exited.is_connected(_on_enemy_tree_exited):
		enemy_instance.tree_exited.connect(_on_enemy_tree_exited)
	return true

func _spawn_enemy_random() -> bool:
	var marker: Marker3D = _get_random_spawn_marker()
	return _spawn_enemy_at_marker(marker)

func _finish_wave() -> void:
	if is_between_waves:
		return
	is_between_waves = true
	_update_hud_wave_ended()
	wave_timer.stop()
	wave_timer.start(wave_pause_seconds)

func _on_enemy_tree_exited() -> void:
	enemies_alive_count = max(0, enemies_alive_count - 1)
	if spawn_timer.is_stopped() and enemies_alive_count == 0:
		_finish_wave()

func _update_hud_wave_started() -> void:
	var hud: Node = get_node_or_null("HUD")
	if hud and hud.has_method("set_wave"):
		hud.set_wave("Wave %d" % current_wave)

func _update_hud_wave_ended() -> void:
	var hud: Node = get_node_or_null("HUD")
	if hud and hud.has_method("set_wave"):
		hud.set_wave("Waiting for next wave...")

# --- Difficulty/Scaling Logic ---

func _compute_enemy_count_for_wave(wave_number: int) -> int:
	# Linear increase: base + 4 per wave (configurable)
	var waves_after_first: int = max(0, wave_number - 1)
	var count: int = enemy_count_base + (waves_after_first * enemy_linear_increment)
	return max(1, count)

func _compute_spawn_interval_for_wave(wave_number: int) -> float:
	# spawnDelay = max(min, numerator / ln(wave + 2))
	var ln_component: float = sqrt(float(wave_number))
	if ln_component <= 0.0:
		return spawn_interval_seconds
	var delay: float = spawn_delay_numerator / ln_component
	return max(spawn_delay_min_seconds, delay)
