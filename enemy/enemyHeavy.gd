extends CharacterBody3D

@export var SPEED = 2.3
@export var max_health := 250
var current_health := 250
@export var contact_damage: int = 10

@onready var greu: AudioStreamPlayer3D = $Greu
@onready var anim_sprite: AnimatedSprite3D = $AnimatedSprite3D

var player: CharacterBody3D
var is_dead = false

func _ready() -> void:
	add_to_group("Enemy")
	player = get_tree().get_first_node_in_group("Player")

func _physics_process(delta: float) -> void:
	if not player:
		return
	# Appliquer la gravité d'abord
	if not is_on_floor():
		velocity += get_gravity() * delta
	if is_dead:
		return
	# Direction vers le joueur SEULEMENT sur les axes X et Z
	var direction_to_player = player.global_position - global_position
	direction_to_player.y = 0 # Ignorer complètement l'axe Y
	direction_to_player = direction_to_player.normalized()
	# Appliquer la vitesse directement comme le joueur
	if direction_to_player.length() > 0:
		velocity.x = direction_to_player.x * SPEED
		velocity.z = direction_to_player.z * SPEED
	move_and_slide()

func get_contact_damage() -> int:
	if is_dead:
		return 0
	return contact_damage

func take_damage(amount: int) -> void:
	current_health = max(0, current_health - amount)
	anim_sprite.modulate = Color(0.64, 0.0384, 0.0384, 1)

	# Reset modulate back to normal after 0.5 seconds
	var tween = create_tween()
	tween.tween_interval(0.1)
	tween.tween_callback(func(): anim_sprite.modulate = Color(1, 1, 1, 1))

	if current_health == 0:
		die()

func die() -> void:
	if is_dead:
		return
	is_dead = true
	# Désactiver la collision
	set_collision_layer_value(1, false)
	set_collision_mask_value(1, false)
	# Mettre l'animation en pause
	anim_sprite.pause()
	greu.play()
	await greu.finished
	queue_free()
