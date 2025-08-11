extends Node
class_name RaycastWeapon

@export var damage: int = 25
@export var ray_distance: float = 2000.0
@export var collision_mask: int = 1
@export var camera_path: NodePath
@export var player_body_path: NodePath

var _camera: Camera3D
var _player_body: CharacterBody3D

func _ready() -> void:
	_camera = get_node_or_null(camera_path) as Camera3D
	_player_body = get_node_or_null(player_body_path) as CharacterBody3D

func fire() -> bool:
	if _camera == null:
		_camera = get_node_or_null(camera_path) as Camera3D
	if _player_body == null:
		_player_body = get_node_or_null(player_body_path) as CharacterBody3D
	if _camera == null:
		push_warning("RaycastWeapon: camera is null; cannot fire")
		return false
	_raycast_and_apply_damage()
	return true

func _raycast_and_apply_damage() -> void:
	var from: Vector3 = _camera.global_transform.origin
	var to: Vector3 = _compute_ray_end(from)
	var space: PhysicsDirectSpaceState3D = get_viewport().world_3d.direct_space_state
	var query := _build_query(from, to)
	var result: Dictionary = space.intersect_ray(query)
	if result.is_empty():
		return
	_apply_damage(result.collider)

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
	if target == null:
		return

	if target.has_method("apply_damage"):
		target.apply_damage(damage)
		return

	if target.has_method("take_damage"):
		target.take_damage(damage)
		return
