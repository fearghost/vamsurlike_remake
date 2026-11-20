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
var last_shot_time: float = -999.0
var shot_interval: float = 2.0

# Charge state
enum ChargeState { IDLE, CHARGING, COOLDOWN }
var charge_state: int = ChargeState.IDLE
var charge_timer: float = 0.0
const CHARGE_DURATION: float = 0.5
const CHARGE_COOLDOWN: float = 2.0
const CHARGE_SPEED_MULTIPLIER: float = 3.0

# Combat state
var current_hp: int = 50
var is_alive: bool = true

# Contact attack state (damage dealt when the player touches this enemy)
var last_contact_hit_time: float = -999.0
const CONTACT_HIT_COOLDOWN: float = 0.8

signal died

func _ready() -> void:
	# Add to enemies group so AutoAttack can find them
	add_to_group("enemies")

	# Contact damage: deal damage when the player body touches this enemy
	body_entered.connect(_on_body_entered)

	# Auto-discover player reference
	player_ref = _find_player()

	# Initialize from enemy_data if set
	if enemy_data != null:
		current_hp = enemy_data.hp
		current_pattern = enemy_data.ai_pattern
		move_speed = enemy_data.speed

	# NOTE: projectile scene is loaded lazily in _fire_projectile() — a compile-
	# time preload here creates a circular dependency (projectile.tscn ->
	# projectile.gd -> EnemyAI class -> enemy_ai.gd -> projectile.tscn) that
	# intermittently breaks resource loading with "Parse Error: Busy".

	# Create dummy sprite (ColorRect) if the scene doesn't provide one
	if find_child("Sprite") == null:
		var sprite := ColorRect.new()
		sprite.name = "Sprite"
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

	# Add collision shape if the scene doesn't provide one
	if not _has_collision_shape():
		var collision := CollisionShape2D.new()
		var shape := CircleShape2D.new()
		shape.radius = 16.0
		collision.shape = shape
		add_child(collision)


func _has_collision_shape() -> bool:
	for child in get_children():
		if child is CollisionShape2D:
			return true
	return false

func _process(delta: float) -> void:
	if not is_alive or player_ref == null:
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

	# Fire projectiles at intervals using PoolManager
	var current_time := Time.get_ticks_msec() / 1000.0
	if current_time - last_shot_time >= shot_interval:
		last_shot_time = current_time
		_fire_projectile(direction)

func _ai_charge(delta: float) -> void:
	match charge_state:
		ChargeState.IDLE:
			velocity = Vector2.ZERO
			charge_timer += delta
			if charge_timer >= 1.0:
				charge_timer = 0.0
				charge_state = ChargeState.CHARGING

		ChargeState.CHARGING:
			var direction := (player_ref.global_position - global_position).normalized()
			velocity = direction * move_speed * CHARGE_SPEED_MULTIPLIER
			move_and_slide()
			charge_timer += delta
			if charge_timer >= CHARGE_DURATION:
				charge_timer = 0.0
				charge_state = ChargeState.COOLDOWN

		ChargeState.COOLDOWN:
			velocity = Vector2.ZERO
			charge_timer += delta
			if charge_timer >= CHARGE_COOLDOWN:
				charge_timer = 0.0
				charge_state = ChargeState.IDLE

func _fire_projectile(direction: Vector2) -> void:
	# Lazy load: avoids a compile-time dependency cycle with projectile.tscn
	var scene := load("res://scenes/game/projectile.tscn") as PackedScene
	if scene == null:
		return

	# Try to use PoolManager for projectile pooling
	var pool_manager := get_tree().get_first_node_in_group("pool_manager")
	if pool_manager != null and pool_manager.has_method("acquire"):
		var projectile: Projectile = pool_manager.acquire("projectile") as Projectile
		if projectile != null:
			projectile.global_position = global_position
			projectile.source_type = "enemy"
			projectile.set_velocity(direction * 300.0)
			if enemy_data != null:
				projectile.set_damage(enemy_data.attack)
	else:
		# Fallback: instantiate directly
		var projectile := scene.instantiate() as Projectile
		if projectile != null:
			get_tree().get_current_scene().add_child(projectile)
			projectile.global_position = global_position
			projectile.source_type = "enemy"
			projectile.set_velocity(direction * 300.0)
			if enemy_data != null:
				projectile.set_damage(enemy_data.attack)

func take_damage(amount: int) -> void:
	if not is_alive:
		return

	var defense_value: int = 0
	if enemy_data != null:
		defense_value = enemy_data.defense
	var actual_damage: int = max(1, amount - defense_value)
	current_hp -= actual_damage

	if current_hp <= 0:
		current_hp = 0
		is_alive = false
		_on_defeated()


func _on_defeated() -> void:
	died.emit()
	queue_free()


func _on_body_entered(body: Node) -> void:
	if not is_alive:
		return

	# Group/method checks (project convention — same pattern as projectile.gd;
	# static type references create circular class dependencies at load time).
	if not body.is_in_group("player"):
		return
	var stats := body.get_node_or_null("PlayerStats")
	if stats == null or not stats.has_method("take_damage"):
		return

	# Cooldown so one enemy can't re-trigger on collision jitter.
	var now := Time.get_ticks_msec() / 1000.0
	if now - last_contact_hit_time < CONTACT_HIT_COOLDOWN:
		return
	last_contact_hit_time = now

	var damage: int = 5
	if enemy_data != null:
		damage = enemy_data.attack
	stats.take_damage(damage)


func _find_player() -> Node2D:
	# Search for PlayerController in the scene tree
	var tree := get_tree()
	if tree == null:
		return null

	for node in tree.get_nodes_in_group("player"):
		if node is CharacterBody2D:
			return node as Node2D

	# Fallback: find by name or type
	for node in tree.get_root().get_children():
		if node is PlayerController:
			return node

	return null
