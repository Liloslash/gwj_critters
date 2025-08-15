extends CharacterBody3D


@export var SPEED = 10.0
@export var acceleration = 10.0
@export var max_health := 25
var current_health := 25
@export var contact_damage: int = 2

var player: CharacterBody3D

func _ready() -> void:
	add_to_group("Enemy")
	player = get_tree().get_first_node_in_group("Player")

func _physics_process(delta: float) -> void:
	if not player:
		return

	# Appliquer la gravité d'abord
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Direction vers le joueur SEULEMENT sur les axes X et Z
	var direction_to_player = player.global_position - global_position
	direction_to_player.y = 0 # Ignorer complètement l'axe Y
	direction_to_player = direction_to_player.normalized()

	# Ne modifier que les composantes X et Z de la vélocité
	if direction_to_player.length() > 0:
		velocity.x = velocity.x + (direction_to_player.x * SPEED - velocity.x) * acceleration * delta
		velocity.z = velocity.z + (direction_to_player.z * SPEED - velocity.z) * acceleration * delta

	move_and_slide()

func get_contact_damage() -> int:
	return contact_damage

func take_damage(amount: int) -> void:
	current_health = max(0, current_health - amount)
	if current_health == 0:
		die()

func die() -> void:
	queue_free()
