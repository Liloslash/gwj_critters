extends CanvasLayer

@onready var health_bar: ProgressBar = $HBoxContainer/ProgressBar
@onready var value_label: Label = $HBoxContainer/Value

func _ready() -> void:
	var player := get_tree().get_first_node_in_group("Player")
	if player:
		if player.has_signal("health_changed"):
			player.health_changed.connect(_on_health_changed)
		_on_health_changed(player.current_health, player.max_health)

func _on_health_changed(current: int, max_value: int) -> void:
	health_bar.max_value = max_value
	health_bar.value = current
	value_label.text = str(current, "/", max_value)
