extends CharacterBody3D

const SPEED = 5.0
const JUMP_VELOCITY = 4.5

signal health_changed(current, max)

@onready var damage_zone: Area3D = $DamageZone
@onready var weapon: RaycastWeapon = $MainWeapon

@export var max_health = 100
@export var current_health = 100
@export var damage_per_tick = 5
@export var damage_interval = 1

var damage_timer = 0.0
var enemies_in_range = []
var damage_per_enemy_default := 5
var is_taking_damage = false

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	damage_zone.body_entered.connect(_on_enemy_entered)
	damage_zone.body_exited.connect(_on_enemy_exited)

func _on_enemy_entered(body):
	if body and body.is_in_group("Enemy"):
		if not enemies_in_range.has(body):
			enemies_in_range.append(body)
		is_taking_damage = true

func _on_enemy_exited(body):
	if body and body.is_in_group("Enemy"):
		enemies_in_range.erase(body)
		is_taking_damage = enemies_in_range.size() > 0

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * 0.002)
	if event.is_action_pressed("fire"):
		if weapon and weapon.has_method("fire"):
			weapon.fire()

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	if Input.is_action_just_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.sd
	var input_dir := Input.get_vector("left", "right", "up", "down")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()

	# Apply periodic damage while any enemy is within the damage zone
	if enemies_in_range.size() > 0 and current_health > 0:
		damage_timer += delta
		if damage_timer >= float(damage_interval):
			var total_tick_damage := 0
			for enemy in enemies_in_range:
				if enemy and enemy.has_method("get_contact_damage"):
					total_tick_damage += int(enemy.get_contact_damage())
				else:
					total_tick_damage += damage_per_enemy_default
			if total_tick_damage <= 0:
				total_tick_damage = damage_per_tick
			take_damage(total_tick_damage)
			damage_timer = 0.0

func heal(amount: int) -> void:
	current_health = clamp(current_health + amount, 0, max_health)
	emit_signal("health_changed", current_health, max_health)

func take_damage(amount: int) -> void:
	current_health = max(0, current_health - amount)
	emit_signal("health_changed", current_health, max_health)

func is_dead() -> bool:
	return current_health <= 0
