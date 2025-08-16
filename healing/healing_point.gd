extends Area3D

@export var heal_amount: int = 10
@onready var healing_sound: AudioStreamPlayer3D = $HealingSound
@onready var csg_sphere_3d: CSGSphere3D = $CSGSphere3D

var is_healed = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D) -> void:
	if is_healed:
		return

	# Check if the body is the player
	if body.has_method("heal"):
		body.heal(heal_amount)
		is_healed = true
		csg_sphere_3d.visible = false
		healing_sound.play()
		await healing_sound.finished
		queue_free()
