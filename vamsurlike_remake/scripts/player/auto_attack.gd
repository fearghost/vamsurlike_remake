class_name AutoAttack
extends Node


## Automatic attack system that fires projectiles at the nearest enemy.
## Uses PoolManager for projectile pooling and object lifecycle management.
## `extra_shots` adds additional shots spread evenly across a full circle
## (360°) starting from the aim direction — each pick of the "Extra Projectile"
## skill increases it by one. Orbiting blades are managed here as well: each
## pick of the "Orbital Blade" skill adds one blade that circles the player.

@export var attack_interval: float = 1.0
@export var attack_range: float = 300.0
@export var attack_damage: int = 10
@export var extra_shots: int = 0   # additional shots beyond the base one (360° spread)

var timer: Timer
var nearest_enemy: Node2D
var is_attacking: bool = false

var orbit_count: int = 0
var _orbiters: Array[Node] = []


func _ready() -> void:
	timer = Timer.new()
	timer.wait_time = attack_interval
	timer.one_shot = true
	timer.autostart = false
	add_child(timer)
	timer.timeout.connect(_on_attack_timer_timeout)


func start_attack() -> void:
	is_attacking = true
	timer.start()


func stop_attack() -> void:
	is_attacking = false
	timer.stop()


func _process(delta: float) -> void:
	if is_attacking:
		find_nearest_enemy()


func find_nearest_enemy() -> Node2D:
	var parent := get_parent()
	if parent == null:
		return null

	var parent_pos: Vector2 = Vector2.ZERO
	if parent is Node2D:
		parent_pos = (parent as Node2D).global_position
	var closest: Node2D = null
	var closest_dist_sq: float = attack_range * attack_range

	for child in parent.get_tree().get_nodes_in_group("enemies"):
		if child is Node2D:
			var dist_sq: float = (child as Node2D).global_position.distance_squared_to(parent_pos)
			if dist_sq < closest_dist_sq:
				closest_dist_sq = dist_sq
				closest = child

	nearest_enemy = closest
	return nearest_enemy


func fire_projectile(target_position: Vector2) -> void:
	if nearest_enemy == null:
		return

	var parent := get_parent()
	if parent == null or not is_inside_tree():
		return

	var aim: float = (target_position - parent.global_position).angle()
	var total: int = 1 + extra_shots
	for i in range(total):
		var angle: float = aim + TAU * float(i) / float(total)
		_spawn_shot(Vector2(cos(angle), sin(angle)))


func _spawn_shot(direction: Vector2) -> void:
	var parent := get_parent()
	if parent == null or not is_inside_tree():
		return

	# Try to use PoolManager for projectile pooling
	var pool_manager := get_tree().get_first_node_in_group("pool_manager")
	if pool_manager != null and pool_manager.has_method("acquire"):
		var projectile: Projectile = pool_manager.acquire("projectile") as Projectile
		if projectile != null:
			# Pooled projectiles are reused — reset stale state from a
			# previous owner (an "enemy" shot would hit the player).
			projectile.source_type = "player"
			projectile.apply_source_style()
			projectile.global_position = parent.global_position
			if projectile.has_method("set_velocity"):
				projectile.set_velocity(direction * 400.0)
			if projectile.has_method("set_damage"):
				projectile.set_damage(attack_damage)
	else:
		# Fallback: instantiate a simple projectile if PoolManager is unavailable
		var projectile_scene := preload("res://scenes/game/projectile.tscn") as PackedScene
		if projectile_scene != null:
			var projectile: Projectile = projectile_scene.instantiate() as Projectile
			projectile.source_type = "player"
			projectile.apply_source_style()
			projectile.global_position = parent.global_position
			if projectile.has_method("set_direction"):
				projectile.set_direction(direction)
			if projectile.has_method("set_damage"):
				projectile.set_damage(attack_damage)
			get_tree().root.add_child(projectile)


func add_orbit() -> void:
	orbit_count += 1
	var index := _orbiters.size()
	_spawn_orbiter(index)
	# Re-phase every blade so they stay evenly spread across the circle.
	for i in range(_orbiters.size()):
		var o = _orbiters[i]
		if is_instance_valid(o) and o.has_method("set_phase"):
			o.set_phase(TAU * float(i) / float(max(1, _orbiters.size())))


func sync_damage(amount: int) -> void:
	attack_damage = amount
	for o in _orbiters:
		if is_instance_valid(o) and "damage" in o:
			o.damage = amount


func _spawn_orbiter(index: int) -> void:
	var parent := get_parent()
	if parent == null or not is_inside_tree():
		return
	var script := load("res://scripts/player/orbit_projectile.gd") as Script
	if script == null:
		return
	var orbiter := Area2D.new()
	orbiter.set_script(script)
	orbiter.damage = attack_damage
	orbiter.phase = TAU * float(index) / float(max(1, orbit_count))
	parent.add_child(orbiter)
	_orbiters.append(orbiter)


func _on_attack_timer_timeout() -> void:
	if not is_attacking:
		return
	if nearest_enemy != null:
		fire_projectile(nearest_enemy.global_position)
	# ALWAYS restart: the timer is one-shot, so skipping start() here when no
	# enemy is in range kills auto-attack permanently (enemies spawn outside
	# attack_range, so the first timeout always has no target).
	timer.start()
