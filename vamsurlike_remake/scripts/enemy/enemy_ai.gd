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
# Distance at which contact damage triggers — sum of enemy (16px) and player (18px) radii.
const CONTACT_RADIUS: float = 34.0

signal died

func _ready() -> void:
	# Add to enemies group so AutoAttack can find them
	add_to_group("enemies")

	# Collision setup: enemies live on layer 2 and detect only obstacles
	# (layer 4) so they cannot walk through trees/rocks. They never physically
	# collide with the player or each other — contact damage is distance-based
	# instead, so chasing enemies pass through the player without sticking to them.
	collision_layer = 2
	collision_mask = MapConfig.OBSTACLE_MASK

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

	# Build the quarter-view black-armored soldier (shadow + boots + tunic + helmet + weapon) if
	# the scene doesn't provide one — flat boxes read as top-down; this reads as
	# viewed from above at an angle. The armor is always black; only the helmet
	# plume stays pattern-coded so enemy types remain distinguishable at a glance.
	if find_child("Sprite") == null:
		var base := Color(1.0, 0.3, 0.3)   # chase red (default) — used for the plume only
		match current_pattern:
			"ranged":
				base = Color(0.8, 0.4, 0.8)  # purple for ranged
			"charge":
				base = Color(0.8, 0.2, 0.2)  # dark red for charge

		var body := Node2D.new()
		body.name = "Sprite"

		# Ground shadow — light from upper-left, so the shadow falls lower-right and peeks out below the base
		var shadow := Polygon2D.new()
		shadow.polygon = _ellipse_polygon(15.0, 6.0)
		shadow.color = Color(0, 0, 0, 0.30)
		shadow.position = Vector2(4, 9)
		body.add_child(shadow)

		# Boots — two small near-black feet peeking below the tunic
		for side in [-1, 1]:
			var leg := Polygon2D.new()
			leg.polygon = _ellipse_polygon(3.5, 4.5)
			leg.color = Color(0.08, 0.08, 0.10)   # near-black boots
			leg.position = Vector2(side * 5.0, 6.0)
			body.add_child(leg)

		# Tunic — slightly flattened ellipse reads as viewed from above at an angle; black armor
		var circle := Polygon2D.new()
		circle.polygon = _ellipse_polygon(13.0, 10.5)
		circle.color = Color(0.11, 0.12, 0.15, 1)   # black armor body
		circle.position = Vector2(0, -3)
		body.add_child(circle)

		# Highlight — upper-left light source (subtle steel sheen on the black armor)
		var hi := Polygon2D.new()
		hi.polygon = _ellipse_polygon(6.0, 4.5)
		hi.color = Color(0.30, 0.32, 0.38, 1)   # dark steel sheen
		hi.position = Vector2(-4.0, -7.0)
		body.add_child(hi)

		# Helmet — blackened iron circle with a small pattern-colored plume on top
		var helmet := Polygon2D.new()
		helmet.polygon = _ellipse_polygon(6.5, 6.0)
		helmet.color = Color(0.16, 0.17, 0.20, 1)   # blackened iron helmet
		helmet.position = Vector2(0, -13.5)
		body.add_child(helmet)
		var helmet_hi := Polygon2D.new()
		helmet_hi.polygon = _ellipse_polygon(3.0, 2.4)
		helmet_hi.color = Color(0.42, 0.44, 0.50, 1)   # steel rim highlight
		helmet_hi.position = Vector2(-1.8, -15.5)
		body.add_child(helmet_hi)
		var plume := Polygon2D.new()
		plume.polygon = PackedVector2Array([Vector2(-1.8, -18.5), Vector2(3.4, -18.5), Vector2(0.6, -24.5)])
		plume.color = base
		body.add_child(plume)

		# Weapon on the right side — spear for chase/charge, bow for ranged
		if current_pattern == "ranged":
			_build_bow(body)
		else:
			_build_spear(body)

		add_child(body)

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

## AI runs in _physics_process (NOT _process): move_and_slide() must be called
## on the physics tick, otherwise enemy speed is tied to the render frame rate
## and stutters whenever the device's FPS drops under load.
func _physics_process(delta: float) -> void:
	if not is_alive or player_ref == null:
		return

	match current_pattern:
		"chase":
			_ai_chase(delta)
		"ranged":
			_ai_ranged(delta)
		"charge":
			_ai_charge(delta)

	# Keep enemies inside the map — charge state can push past the edge.
	var margin := 16.0
	global_position = global_position.clamp(Vector2(margin, margin), MapConfig.MAP_SIZE - Vector2(margin, margin))

	# Contact damage is distance-based (enemies no longer physically collide
	# with the player — mask 0) so chasing enemies pass through without sticking.
	_check_contact_damage()

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

func _build_spear(body: Node2D) -> void:
	# Long shaft with a steel tip, held up-right at rest (chase / charge soldiers).
	var weapon := Node2D.new()
	weapon.position = Vector2(9, -6)
	weapon.rotation = -0.62
	body.add_child(weapon)

	var shaft := Polygon2D.new()
	shaft.polygon = PackedVector2Array([
		Vector2(0, -1.4), Vector2(26, -1.4), Vector2(26, 1.4), Vector2(0, 1.4),
	])
	shaft.color = Color(0.45, 0.28, 0.15)   # brown shaft
	weapon.add_child(shaft)

	var tip := Polygon2D.new()
	tip.polygon = PackedVector2Array([Vector2(25, -3.4), Vector2(34, 0), Vector2(25, 3.4)])
	tip.color = Color(0.88, 0.9, 0.93)       # steel tip
	weapon.add_child(tip)


func _build_bow(body: Node2D) -> void:
	# Bow arc bulging forward (+X) with a string between the tips — ranged soldiers.
	var weapon := Node2D.new()
	weapon.position = Vector2(10, -6)
	body.add_child(weapon)

	var bow_pts := PackedVector2Array()
	for i in range(9):
		var a := lerpf(-1.15, 1.15, float(i) / 8.0)
		bow_pts.append(Vector2(cos(a) * 13.0 - 5.0, sin(a) * 13.0))
	var bow := Line2D.new()
	bow.points = bow_pts
	bow.width = 3.0
	bow.default_color = Color(0.45, 0.28, 0.15)   # brown bow
	weapon.add_child(bow)

	var string := Line2D.new()
	string.points = PackedVector2Array([bow_pts[0], bow_pts[8]])
	string.width = 1.5
	string.default_color = Color(0.85, 0.82, 0.75)   # light string
	weapon.add_child(string)


func _fire_projectile(direction: Vector2) -> void:
	# Lazy load: avoids a compile-time dependency cycle with projectile.tscn
	var scene := load("res://scenes/game/projectile.tscn") as PackedScene
	if scene == null:
		return

	SoundManager.play_shoot()

	# Try to use PoolManager for projectile pooling
	var pool_manager := get_tree().get_first_node_in_group("pool_manager")
	if pool_manager != null and pool_manager.has_method("acquire"):
		var projectile: Projectile = pool_manager.acquire("projectile") as Projectile
		if projectile != null:
			projectile.global_position = global_position
			projectile.source_type = "enemy"
			projectile.apply_source_style()
			projectile.set_velocity(direction * 300.0)
			if enemy_data != null:
				projectile.set_damage(enemy_data.attack)
	else:
		# Fallback: instantiate directly
		var projectile := scene.instantiate() as Projectile
		if projectile != null:
			var container := get_tree().current_scene
			if container == null:
				container = get_parent() if get_parent() != null else get_tree().root
			container.add_child(projectile)
			projectile.global_position = global_position
			projectile.source_type = "enemy"
			projectile.apply_source_style()
			projectile.set_velocity(direction * 300.0)
			if enemy_data != null:
				projectile.set_damage(enemy_data.attack)

func take_damage(amount: int) -> void:
	if not is_alive:
		return

	SoundManager.play_hit()
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
	# Grant XP to the player for this kill (amount varies by enemy type/strength)
	# BEFORE emitting died: a level-up may pause the tree and show the skill
	# overlay, so it must not race with wave-clear handling inside `died`.
	var stats := _find_player_stats()
	if stats != null and stats.has_method("gain_xp"):
		var xp_value := 10
		if enemy_data != null:
			xp_value = enemy_data.xp_value
		stats.gain_xp(xp_value)
	died.emit()
	queue_free()


func _find_player_stats() -> Node:
	var player := _find_player()
	if player == null or not is_instance_valid(player):
		return null
	if player.has_method("get_node_or_null") and player.has_node("PlayerStats"):
		return player.get_node_or_null("PlayerStats")
	return null


func _check_contact_damage() -> void:
	if not is_alive or player_ref == null:
		return
	var distance := global_position.distance_to(player_ref.global_position)
	if distance > CONTACT_RADIUS:
		return
	# Cooldown so one enemy can't re-trigger every frame while in contact.
	var now := Time.get_ticks_msec() / 1000.0
	if now - last_contact_hit_time < CONTACT_HIT_COOLDOWN:
		return
	last_contact_hit_time = now

	var stats := player_ref.get_node_or_null("PlayerStats")
	if stats == null or not stats.has_method("take_damage"):
		return

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

func _ellipse_polygon(rx: float, ry: float, segments: int = 20) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in range(segments):
		var a := TAU * float(i) / float(segments)
		pts.append(Vector2(cos(a) * rx, sin(a) * ry))
	return pts
