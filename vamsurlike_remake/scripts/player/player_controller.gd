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
	# Create dummy sprite (blue ColorRect) if no child sprite exists
	if find_child("DummySprite") == null:
		var dummy := ColorRect.new()
		dummy.name = "DummySprite"
		dummy.color = Color.BLUE
		dummy.position = Vector2(-16, -16)
		add_child(dummy)

	# Create a default PlayerStats node if none is assigned
	if player_stats == null:
		player_stats = $PlayerStats if has_node("PlayerStats") else null
		if player_stats == null:
			player_stats = preload("res://scripts/player/player_stats.gd").new()
			player_stats.name = "PlayerStats"
			add_child(player_stats)

	# Create default AutoAttack if none is assigned
	if auto_attack == null:
		auto_attack = $AutoAttack if has_node("AutoAttack") else null
		if auto_attack == null:
			auto_attack = preload("res://scripts/player/auto_attack.gd").new()
			auto_attack.name = "AutoAttack"
			add_child(auto_attack)


func _process(delta: float) -> void:
	if not is_attacking:
		velocity = current_direction * move_speed
	else:
		velocity = Vector2.ZERO
	move_and_slide()


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
