class_name Projectile
extends Area2D


## A projectile fired by either the player or enemies.
## Uses PoolManager for object pooling when available.

@export var damage: int = 10
@export var speed: float = 400.0
@export var source_type: String = "player"  # "player" or "enemy"

var velocity: Vector2 = Vector2.ZERO


func _ready() -> void:
	add_to_group("projectiles")

	# Detect both the player (layer 1) and enemies (layer 2). Areas never
	# participate in physical collision, so layer 0 is fine.
	collision_layer = 0
	collision_mask = 3

	apply_source_style()


## (Re)applies the sprite color for the current source_type. Called after
## source_type changes — pooled projectiles are reused, and _ready only runs
## on first tree entry, so the style must be re-applied on every acquire.
func apply_source_style() -> void:
	var sprite := find_child("Sprite")
	if sprite is ColorRect:
		if source_type == "player":
			(sprite as ColorRect).color = Color(1, 1, 0, 1)       # Yellow for player
		else:
			(sprite as ColorRect).color = Color(1, 0.5, 0, 1)      # Orange for enemy


func _process(delta: float) -> void:
	position += velocity * delta


func set_velocity(dir: Vector2) -> void:
	velocity = dir.normalized() * speed


func set_direction(dir: Vector2) -> void:
	velocity = dir.normalized() * speed


func set_damage(amount: int) -> void:
	damage = amount


func _on_body_entered(body: Node) -> void:
	# Group/method checks instead of `is EnemyAI` / `is PlayerStats`: type
	# references force GDScript to compile those classes at load time, which
	# created a circular dependency (projectile.gd -> enemy_ai.gd -> ...).
	if source_type == "player" and body.is_in_group("enemies"):
		if body.has_method("take_damage"):
			body.take_damage(damage)
		_on_destroyed()
	elif source_type == "enemy":
		# Check if body is the player via group membership
		if body.is_in_group("player"):
			var stats := body.get_node_or_null("PlayerStats")
			if stats != null and stats.has_method("take_damage"):
				stats.take_damage(damage)
			_on_destroyed()


func _on_destroyed() -> void:
	# Try to release back to PoolManager
	var pool_manager := get_tree().get_first_node_in_group("pool_manager")
	if pool_manager != null and pool_manager.has_method("release"):
		pool_manager.release("projectile", self)
	else:
		queue_free()
