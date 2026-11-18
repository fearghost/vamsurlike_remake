class_name AutoAttack
extends Node


## Automatic attack system that fires projectiles at the nearest enemy.
## Uses PoolManager for projectile pooling and object lifecycle management.


@export var attack_interval: float = 1.0
@export var attack_range: float = 300.0
@export var attack_damage: int = 10

var timer: Timer
var nearest_enemy: Node2D
var is_attacking: bool = false


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

	var direction: Vector2 = (target_position - parent.global_position).normalized()

	# Try to use PoolManager for projectile pooling
	var pool_manager := get_tree().get_first_node_in_group("pool_manager")
	if pool_manager != null and pool_manager.has_method("acquire"):
		var projectile: Projectile = pool_manager.acquire("projectile") as Projectile
		if projectile != null:
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
			projectile.global_position = parent.global_position
			if projectile.has_method("set_direction"):
				projectile.set_direction(direction)
			if projectile.has_method("set_damage"):
				projectile.set_damage(attack_damage)
			get_tree().root.add_child(projectile)


func _on_attack_timer_timeout() -> void:
	if is_attacking and nearest_enemy != null:
		fire_projectile(nearest_enemy.global_position)
		timer.start()
