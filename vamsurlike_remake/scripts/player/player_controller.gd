class_name PlayerController
extends CharacterBody2D


## Player controller that reads input from VirtualJoystick and drives movement.
## Uses a ColorRect as a dummy sprite (blue rectangle) for visual representation.


@export var move_speed: float = 200.0

var current_direction: Vector2 = Vector2.ZERO
var is_attacking: bool = false
var player_stats: Node  # reference to PlayerStats node
var auto_attack: AutoAttack  # reference to AutoAttack component


func _ready() -> void:
	add_to_group("player")

	# Collision setup: player lives on layer 1 and collides with NOTHING
	# (mask 0). Enemies must not physically block the player — a chasing
	# enemy pushes the player and, with two or more enemies, boxes it in so
	# it cannot move at all. Contact damage is distance-based on the enemy
	# side (see EnemyAI._check_contact_damage), not collision-driven.
	collision_layer = 1
	collision_mask = 0

	# Create dummy sprite (blue ColorRect) if no child sprite exists
	if find_child("Body") == null:
		var dummy := ColorRect.new()
		dummy.name = "Body"
		dummy.color = Color.BLUE
		dummy.position = Vector2(-16, -16)
		dummy.size = Vector2(32, 32)
		add_child(dummy)

	# Add collision shape for Area2D projectile detection
	var collision := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 18.0
	collision.shape = shape
	add_child(collision)

	# Create a default PlayerStats node if none is assigned
	if player_stats == null:
		player_stats = $PlayerStats if has_node("PlayerStats") else null

	# Create default AutoAttack if none is assigned
	if auto_attack == null:
		auto_attack = $AutoAttack if has_node("AutoAttack") else null


## Movement runs in _physics_process (NOT _process): move_and_slide() must be
## called on the physics tick. In _process the step size is tied to the RENDER
## frame rate, so on a device whose FPS drops under combat load the player
## crawls/freezes and then speeds back up — the on-device "controls stop
## working, stutters, then moves again" bug.
func _physics_process(delta: float) -> void:
	velocity = current_direction * move_speed
	move_and_slide()

	# Keep the player inside the map — no walking off into the void.
	var margin := 18.0  # player collision radius
	global_position = global_position.clamp(Vector2(margin, margin), MapConfig.MAP_SIZE - Vector2(margin, margin))


func set_input_direction(direction: Vector2) -> void:
	current_direction = direction.normalized()


func start_auto_attack() -> void:
	is_attacking = true
	if auto_attack != null:
		auto_attack.start_attack()


func stop_auto_attack() -> void:
	is_attacking = false
	if auto_attack != null:
		auto_attack.stop_attack()


func _on_player_stats_died() -> void:
	stop_auto_attack()
	print("Player has died.")
