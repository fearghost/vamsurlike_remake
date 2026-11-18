class_name EnemyAI
extends CharacterBody2D

@export var enemy_data: EnemyData
var current_pattern: String = "chase"
var player_ref: Node2D

@export var move_speed: float = 80.0

# Chase state
var chase_distance: float = 50.0

# Ranged state
var ranged_target_distance: float = 200.0
var last_shot_time: float = 0.0
var shot_interval: float = 2.0
var projectile_scene: PackedScene

# Charge state
var charge_cooldown: float = 0.0
var is_charging: bool = false
var charge_wait_time: float = 1.0
var charge_duration: float = 0.5
var charge_speed_multiplier: float = 2.0
var charge_timer: float = 0.0

# Combat state
var current_hp: int = 50

func _ready() -> void:
	# Add to enemies group so AutoAttack can find them
	add_to_group("enemies")

	# Initialize from enemy_data if set
	if enemy_data != null:
		current_hp = enemy_data.hp
		current_pattern = enemy_data.ai_pattern
		move_speed = enemy_data.speed
	
	# Create dummy sprite (ColorRect)
	var sprite := ColorRect.new()
	sprite.size = Vector2(32, 32)
	sprite.position = Vector2(-16, -16)
	match current_pattern:
		"ranged":
			sprite.color = Color(0.8, 0.4, 0.8)  # Purple for ranged
		"charge":
			sprite.color = Color(0.8, 0.2, 0.2)  # Red for charge
		_:
			sprite.color = Color(1.0, 0.3, 0.3)  # Red for chase
	add_child(sprite)
	
	# Add collision shape for CharacterBody2D
	var collision := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 16.0
	collision.shape = shape
	add_child(collision)

func _process(delta: float) -> void:
	if player_ref == null:
		return
	
	match current_pattern:
		"chase":
			_ai_chase(delta)
		"ranged":
			_ai_ranged(delta)
		"charge":
			_ai_charge(delta)

func _ai_chase(delta: float) -> void:
	var direction := (player_ref.global_position - global_position).normalized()
	velocity = direction * move_speed
	move_and_slide()

func _ai_ranged(delta: float) -> void:
	var distance_to_player := global_position.distance_to(player_ref.global_position)
	var direction := (player_ref.global_position - global_position).normalized()
	
	if distance_to_player > ranged_target_distance:
		# Move toward player to get in range
		velocity = direction * move_speed
	elif distance_to_player < ranged_target_distance - 50.0:
		# Move away to maintain distance
		velocity = -direction * move_speed
	else:
		# Maintain position, stop moving
		velocity = Vector2.ZERO
	
	move_and_slide()
	
	# Fire projectiles at intervals
	if projectile_scene != null and Time.get_ticks_msec() / 1000.0 - last_shot_time >= shot_interval:
		last_shot_time = Time.get_ticks_msec() / 1000.0
		_fire_projectile(direction)

func _ai_charge(delta: float) -> void:
	if is_charging:
		charge_timer += delta
		var direction := (player_ref.global_position - global_position).normalized()
		velocity = direction * move_speed * charge_speed_multiplier
		move_and_slide()
		
		if charge_timer >= charge_duration:
			is_charging = false
			charge_cooldown = 2.0
			velocity = Vector2.ZERO
	else:
		charge_cooldown -= delta
		if charge_cooldown <= 0:
			charge_wait_time -= delta
			if charge_wait_time <= 0:
				is_charging = true
				charge_timer = 0.0
				charge_wait_time = 1.0

func _fire_projectile(direction: Vector2) -> void:
	if projectile_scene == null:
		return
	
	var projectile := projectile_scene.instantiate() as Projectile
	if projectile == null:
		return
	
	get_tree().current_scene.add_child(projectile)
	projectile.global_position = global_position
	projectile.velocity = direction * 200.0
	projectile.owner = "enemy"

func take_damage(amount: int) -> void:
	current_hp -= amount
	if current_hp <= 0:
		_on_defeated()
		queue_free()

func _on_defeated() -> void:
	# TODO: Spawn drop items from enemy_data.drop_table
	pass
