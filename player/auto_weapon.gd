extends Node
class_name AutoWeapon

@onready var gun_shot: AudioStreamPlayer = $GunShot
@onready var fire_rate_timer: Timer = $FireRateTimer
@onready var auto_weapon_animation: AnimatedSprite2D = $"../CanvasLayer/Control/AutoWeaponAnimation"

signal hit_confirmed(target, position: Vector3)

@export var damage: int = 20
@export var ray_distance: float = 2000.0
@export var collision_mask: int = 1
@export var camera_path: NodePath
@export var player_body_path: NodePath

# Variables pour le tir automatique (always enabled for auto weapon)
var auto_fire_enabled: bool = true
var is_firing: bool = false

# Configuration des cadences de tir (always fast for auto weapon)
@export var fire_rate: float = 0.12 # Délai entre les tirs automatiques

# Recoil configuration
@export var recoil_pitch_deg: float = 2.0
@export var recoil_yaw_deg: float = 0.6
@export var recoil_up_duration: float = 0.05
@export var recoil_return_duration: float = 0.1

var _camera: Camera3D
var _player_body: CharacterBody3D
var _recoil_tween: Tween

func _ready() -> void:
	_camera = get_node_or_null(camera_path) as Camera3D
	_player_body = get_node_or_null(player_body_path) as CharacterBody3D

	# Set auto fire rate
	fire_rate_timer.wait_time = fire_rate

func fire() -> bool:
	if not can_fire():
		return false

	# Start the timer
	fire_rate_timer.start()

	var from: Vector3 = _camera.global_transform.origin
	var to: Vector3 = _compute_ray_end(from)
	var space: PhysicsDirectSpaceState3D = get_viewport().world_3d.direct_space_state
	var query := _build_query(from, to)
	var result: Dictionary = space.intersect_ray(query)

	if result.is_empty():
		return true
	_apply_damage(result.collider)
	return true

func can_fire() -> bool:
	return fire_rate_timer.time_left <= 0.0

func set_auto_fire_enabled(_enabled: bool) -> void:
	# Auto weapon is always in auto mode, but we keep this for compatibility
	auto_fire_enabled = true

func start_firing() -> void:
	is_firing = true
	if auto_fire_enabled:
		if not gun_shot.playing:
			gun_shot.play()
		_continue_auto_fire()

func stop_firing() -> void:
	is_firing = false
	if gun_shot.playing:
		gun_shot.stop()
	auto_weapon_animation.play("idle")

func _continue_auto_fire() -> void:
	if not is_firing or not auto_fire_enabled:
		return

	fire()

	# Programmer le prochain tir automatique
	if is_firing and auto_fire_enabled:
		await fire_rate_timer.timeout
		_continue_auto_fire()

func _compute_ray_end(from: Vector3) -> Vector3:
	return from + (-_camera.global_transform.basis.z) * ray_distance

func _build_query(from: Vector3, to: Vector3) -> PhysicsRayQueryParameters3D:
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.collision_mask = collision_mask
	query.exclude = _collect_excludes()
	return query

func _collect_excludes() -> Array:
	var excludes: Array = []
	if _player_body:
		excludes.append(_player_body)
	excludes.append(get_parent())
	excludes.append(self)
	return excludes

func _apply_damage(target: Object) -> void:
	if target.has_method("take_damage"):
		emit_signal("hit_confirmed")
		target.take_damage(damage)

func _apply_recoil() -> void:
	if _camera == null:
		return
	if _recoil_tween and _recoil_tween.is_running():
		_recoil_tween.kill()

	# Define a neutral/base rotation that is locked to the horizon for pitch (x = 0)
	# This prevents cumulative upwards drift if firing rapidly.
	var current_rot: Vector3 = _camera.rotation_degrees
	var base_rot: Vector3 = current_rot
	base_rot.x = 0.0

	var target_rot: Vector3 = base_rot

	# Recul réduit pour l'arme automatique
	var pitch_modifier: float = 0.4 # Recul encore plus réduit pour l'auto weapon
	var yaw_modifier: float = 0.5

	# Pitch up from the horizon
	target_rot.x = base_rot.x + (recoil_pitch_deg * pitch_modifier)
	# Slight random yaw left/right around the current yaw
	var yaw_offset: float = randf_range(-recoil_yaw_deg * yaw_modifier, recoil_yaw_deg * yaw_modifier)
	target_rot.y = base_rot.y + yaw_offset

	_recoil_tween = create_tween()
	_recoil_tween.set_parallel(false)
	_recoil_tween.tween_property(_camera, "rotation_degrees", target_rot, recoil_up_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_recoil_tween.tween_property(_camera, "rotation_degrees", base_rot, recoil_return_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
