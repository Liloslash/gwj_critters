extends Area3D

@export var heal_amount: int = 10
@onready var healing_sound: AudioStreamPlayer3D = $HealingSound
@onready var csg_sphere_3d: CSGSphere3D = $CSGSphere3D

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D) -> void:
	# Check if the body is the player
	if body.has_method("heal"):
		body.heal(heal_amount)
		healing_sound.play()
		csg_sphere_3d.queue_free()
		heal_amount = 0
		await healing_sound.finished

		queue_free()

func _on_body_exited(body: Node3D) -> void:
	pass # Not needed for this implementation
