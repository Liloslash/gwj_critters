extends CharacterBody3D


const SPEED = 3.0
@export var acceleration = 10.0

var player: CharacterBody3D

func _ready() -> void:
	add_to_group("Enemy")
	player = get_tree().get_first_node_in_group("Player")

func _physics_process(delta: float) -> void:
	if not player:
		return
		
	var direction = (player.global_position - global_position).normalized()
	
	direction.y = 0
	direction = direction.normalized()
	
	if direction.length() > 0:
		velocity = velocity.move_toward(direction * SPEED, acceleration * delta)
	else:
		velocity = velocity.move_toward(Vector3.ZERO, acceleration * delta)
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	move_and_slide()
