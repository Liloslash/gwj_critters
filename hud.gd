extends CanvasLayer
class_name HUD

@onready var health_bar: ProgressBar = $HBoxContainer/ProgressBar
@onready var crosshair_label: Label = $CenterContainer/Label
@onready var wave_label: Label = $MarginContainer/WaveLabel
@onready var game_over_panel: CenterContainer = $GameOver
@onready var wave_start: CenterContainer = $WaveStart
@onready var wave_start_label: Label = $WaveStart/WaveStartLabel

@onready var start_game_panel: Panel = $StartGamePanel

@onready var new_weapon: CenterContainer = $NewWeapon
@onready var new_weapon_timer: Timer = $NewWeapon/NewWeaponTimer

@onready var wave_hud_timer: Timer = $WaveHUDTimer

func _ready() -> void:
	var player := get_tree().get_first_node_in_group("Player")
	game_over_panel.visible = false
	wave_start.visible = false
	new_weapon.visible = false
	start_game_panel.visible = true # Make sure start panel is visible initially

	player.health_changed.connect(_on_health_changed)

	new_weapon_timer.one_shot = true
	new_weapon_timer.timeout.connect(hide_new_weapon)

	wave_hud_timer.one_shot = true
	wave_hud_timer.timeout.connect(hide_wave_start)

	var weapon: Node = player.get_node_or_null("MainWeapon")
	if weapon and weapon.has_signal("hit_confirmed"):
		weapon.connect("hit_confirmed", Callable(self, "show_hitmarker"))

	player.game_over.connect(game_over)

func set_wave(wave_label_value: String) -> void:
	wave_label.text = wave_label_value

func _on_health_changed(current: int) -> void:
	health_bar.value = current

func show_hitmarker() -> void:
	if not is_instance_valid(crosshair_label):
		return
	var original: Color = crosshair_label.modulate
	crosshair_label.modulate = Color.RED
	var tween := create_tween()
	tween.tween_property(crosshair_label, "modulate", original, 0.12).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func show_wave_start(wave_number: int) -> void:
	wave_start.visible = true
	wave_start_label.text = "Wave %d" % wave_number + " !"
	wave_hud_timer.start()

func show_new_weapon() -> void:
	new_weapon.visible = true
	new_weapon_timer.start()

func hide_wave_start() -> void:
	wave_start.visible = false

func hide_new_weapon() -> void:
	new_weapon.visible = false

func _on_button_pressed() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	get_tree().reload_current_scene()

func game_over() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	game_over_panel.show()


func _on_start_game_button_pressed() -> void:
	start_game_panel.visible = false
	# Get the world node and start the game
	var world = get_tree().get_first_node_in_group("World")
	world.start_game()
