extends CanvasLayer

@onready var health_bar: ProgressBar = $HBoxContainer/ProgressBar
@onready var value_label: Label = $HBoxContainer/Value
@onready var crosshair_label: Label = $CenterContainer/Label
@onready var wave_label: Label = $MarginContainer/WaveLabel

func _ready() -> void:
	var player := get_tree().get_first_node_in_group("Player")

	if player and player.has_signal("health_changed"):
		player.health_changed.connect(_on_health_changed)
	_on_health_changed(player.current_health, player.max_health)

	# Try to connect to weapon hit signals for crosshair flash
	var weapon: Node = player.get_node_or_null("RaycastWeapon") if player else null
	if weapon and weapon.has_signal("hit_confirmed"):
		weapon.connect("hit_confirmed", Callable(self, "show_hitmarker"))

func set_wave(wave_number: int) -> void:
	if is_instance_valid(wave_label):
		wave_label.text = "Wave %d" % wave_number

func _on_health_changed(current: int, max_value: int) -> void:
	health_bar.max_value = max_value
	health_bar.value = current
	value_label.text = str(current, "/", max_value)

func show_hitmarker() -> void:
	if not is_instance_valid(crosshair_label):
		return
	var original: Color = crosshair_label.modulate
	crosshair_label.modulate = Color.RED
	var tween := create_tween()
	tween.tween_property(crosshair_label, "modulate", original, 0.12).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
