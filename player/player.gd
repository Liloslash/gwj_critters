extends CharacterBody3D

@export var SPEED = 9.5
const JUMP_VELOCITY = 4.5

signal health_changed(current, max)
signal game_over

@onready var damage_zone: Area3D = $DamageZone
@onready var raycast_weapon: RaycastWeapon = $RaycastWeapon
@onready var auto_weapon: AutoWeapon = $AutoWeapon
@onready var raycast_animation: AnimatedSprite2D = $CanvasLayer/MainWeaponAnimation
@onready var auto_animation: AnimatedSprite2D = $CanvasLayer/AutoWeaponAnimation
@onready var footsteps_boots: AudioStreamPlayer = $"Footsteps-boots"
@onready var death_scream: AudioStreamPlayer = $DeathScream

# Weapon management
var current_weapon_index: int = 0
var weapons: Array = []
var weapon_animations: Array = []
var auto_weapon_unlocked: bool = false


@onready var heartbeat_player: AudioStreamPlayer3D = $HeartbeatPlayer

# Référence au ColorRect pour l'effet de dégâts
@onready var damage_vignette: ColorRect = $DamageAnimation/ColorRect

@export var max_health = 100
@export var current_health = 100
@export var damage_per_tick = 5
@export var damage_interval = 1

var damage_timer = 0.0
var enemies_in_range = []
var damage_per_enemy_default := 5
var is_taking_damage = false
var is_walking = false

# Variables pour l'effet de flash de dégâts
var damage_effect_tween: Tween
var damage_flash_duration = 0.08

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	damage_zone.body_entered.connect(_on_enemy_entered)
	damage_zone.body_exited.connect(_on_enemy_exited)

	# Initialize weapons array
	weapons = [raycast_weapon, auto_weapon]
	weapon_animations = [raycast_animation, auto_animation]

	# Connect animation finished signals
	raycast_animation.animation_finished.connect(_on_gun_animation_finished)
	auto_animation.animation_finished.connect(_on_gun_animation_finished)

	# Initialize both weapon animations
	for anim in weapon_animations:
		anim.frame = 0
		anim.pause()

	# Hide auto weapon initially (only raycast weapon is active)
	auto_animation.visible = false
	raycast_animation.visible = true

	# Initialiser l'effet de dégâts (invisible au départ)
	if damage_vignette:
		damage_vignette.color = Color.RED
		damage_vignette.color.a = 0.0

func _on_enemy_entered(body):
	if not _is_enemy(body):
		return
	if not enemies_in_range.has(body):
		enemies_in_range.append(body)
	is_taking_damage = true

func _on_enemy_exited(body):
	if not _is_enemy(body):
		return
	enemies_in_range.erase(body)
	is_taking_damage = enemies_in_range.size() > 0

func _input(event: InputEvent) -> void:
	if is_dead():
		return
	if event is InputEventMouseMotion:
		_handle_mouse_motion(event)
	elif event.is_action_pressed("fire"):
		_start_firing()
	elif event.is_action_released("fire"):
		_stop_firing()
	elif Input.is_action_just_pressed("switchWeapon"):
		_switch_weapon()

func _physics_process(delta: float) -> void:
	if is_dead():
		return
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	if Input.is_action_just_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir := Input.get_vector("left", "right", "up", "down")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()

	# Gestion des sons de pas améliorée
	var should_play_footsteps = input_dir.length() > 0 and is_on_floor() and velocity.length() > 0.1

	if should_play_footsteps and not is_walking:
		footsteps_boots.play()
		is_walking = true
	elif not should_play_footsteps and is_walking:
		footsteps_boots.stop()
		is_walking = false

	_process_damage(delta)

func _handle_mouse_motion(event: InputEventMouseMotion) -> void:
	rotate_y(-event.relative.x * 0.002)

func _switch_weapon() -> void:
	# Stop current weapon firing
	_stop_firing()

	# If auto weapon is not unlocked, can't switch to it
	if not auto_weapon_unlocked and current_weapon_index == 0:
		return # Stay on raycast weapon

	# Switch to next weapon
	if auto_weapon_unlocked:
		current_weapon_index = (current_weapon_index + 1) % weapons.size()
	else:
		current_weapon_index = 0 # Force stay on raycast weapon

	# Update weapon visibility
	for i in range(weapon_animations.size()):
		weapon_animations[i].visible = (i == current_weapon_index)

func get_current_weapon():
	return weapons[current_weapon_index]

func get_current_animation():
	return weapon_animations[current_weapon_index]

func _try_fire_weapon() -> void:
	var weapon = get_current_weapon()
	var animation = get_current_animation()

	if weapon and weapon.has_method("fire"):
		var has_fired = weapon.fire()
		if has_fired:
			# Play appropriate animation based on weapon type
			if weapon is RaycastWeapon:
				animation.play("Revolveranim")
			elif weapon is AutoWeapon:
				animation.play("fire")

func _start_firing() -> void:
	var weapon = get_current_weapon()
	var animation = get_current_animation()

	if weapon is AutoWeapon:
		# Auto weapon always uses auto fire
		weapon.set_auto_fire_enabled(true)
		animation.play("fire")
		weapon.start_firing()
	elif weapon is RaycastWeapon:
		# Raycast weapon is always single fire
		weapon.set_auto_fire_enabled(false)
		_try_fire_weapon()

func _stop_firing() -> void:
	var weapon = get_current_weapon()
	var animation = get_current_animation()

	if weapon.has_method("stop_firing"):
		weapon.stop_firing()

	# Arrêter l'animation de tir automatique et la remettre en position
	if weapon.auto_fire_enabled:
		animation.stop()
		animation.frame = 0
		animation.pause()

func _on_gun_animation_finished() -> void:
	var weapon = get_current_weapon()
	var animation = get_current_animation()

	# En mode automatique, relancer l'animation si on tire encore
	if weapon.auto_fire_enabled and weapon.is_firing:
		animation.play("fire")
	else:
		# Tir simple ou arrêt du tir automatique
		animation.frame = 0
		animation.pause()

func _process_damage(delta: float) -> void:
	if enemies_in_range.is_empty() or is_dead():
		return
	damage_timer += delta
	if damage_timer < float(damage_interval):
		return
	var total_tick_damage := _compute_total_tick_damage()
	if total_tick_damage <= 0:
		total_tick_damage = damage_per_tick
	take_damage(total_tick_damage)
	damage_timer = 0.0

func is_dead() -> bool:
	return current_health <= 0

func _compute_total_tick_damage() -> int:
	var total := 0
	for enemy in enemies_in_range:
		if enemy and enemy.has_method("get_contact_damage"):
			total += int(enemy.get_contact_damage())
		else:
			total += damage_per_enemy_default
	return total

func _is_enemy(body) -> bool:
	return body != null and body.is_in_group("Enemy")


func take_damage(amount: int) -> void:
	current_health = max(0, current_health - amount)
	emit_signal("health_changed", current_health)

	# Déclencher l'effet de vignettage rouge
	if amount > 0:
		damage_animation()

	if current_health < max_health * 0.25:
		if not heartbeat_player.playing:
			heartbeat_player.play()
	else:
		if heartbeat_player.playing:
			heartbeat_player.stop()

	if current_health <= 0:
		die()

func heal(amount: int) -> void:
	current_health = min(max_health, current_health + amount)
	emit_signal("health_changed", current_health)

func die() -> void:
	velocity = Vector3.ZERO
	death_scream.play()
	AudioManager.stop_music()
	set_process_input(false)
	set_physics_process(false)

	if heartbeat_player.playing:
		heartbeat_player.stop()

	game_over.emit()

func damage_animation() -> void:
	# Arrêter le tween précédent s'il existe
	if damage_effect_tween:
		damage_effect_tween.kill()

	# Créer un nouveau tween
	damage_effect_tween = create_tween()
	damage_effect_tween.set_ease(Tween.EASE_OUT)
	damage_effect_tween.set_trans(Tween.TRANS_QUART)

	# Flash rouge simple: apparition rapide puis disparition
	damage_effect_tween.tween_property(damage_vignette, "color:a", 0.4, 0.05)
	damage_effect_tween.tween_property(damage_vignette, "color:a", 0.0, damage_flash_duration)
