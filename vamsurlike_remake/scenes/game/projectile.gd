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

	# Areas never participate in physical collision, so layer 0 is fine.
	collision_layer = 0

	apply_source_style()

	# Connect explicitly (guarded) instead of relying on the _on_body_entered
	# auto-connection: pooled projectiles are removed from and re-added to the
	# tree, which made the automatic connection unreliable — hits were lost.
	if not body_entered.is_connected(_handle_body_entered):
		body_entered.connect(_handle_body_entered as Callable)


## (Re)applies the sprite color and collision mask for the current source_type.
## Called after source_type changes — pooled projectiles are reused, and _ready
## only runs on first tree entry, so both must be re-applied every acquire.
func apply_source_style() -> void:
	var sprite := find_child("Sprite")
	if source_type == "player":
		# Player shots only ever hit enemies (layer 2) — never the player itself.
		collision_mask = 2
		if sprite is ColorRect:
			(sprite as ColorRect).color = Color(1, 1, 0, 1)       # Yellow for player
	else:
		# Enemy shots only ever hit the player (layer 1) — never other enemies.
		collision_mask = 1
		if sprite is ColorRect:
			(sprite as ColorRect).color = Color(1, 0.5, 0, 1)      # Orange for enemy


func _process(delta: float) -> void:
	position += velocity * delta


func set_velocity(dir: Vector2) -> void:
	velocity = dir.normalized() * speed


func set_direction(dir: Vector2) -> void:
	velocity = (dir.normalized() if dir.length() > 0.001 else Vector2.RIGHT) * speed


## Legacy alias kept for callers that still use the old name.
func set_damage(amount: int) -> void:
	damage = amount


func _handle_body_entered(body: Node) -> void:
	# Group/method checks instead of `is EnemyAI` / `is PlayerStats`: type
	# references force GDScript to compile those classes at load time, which
	# created a circular dependency (projectile.gd -> enemy_ai.gd -> ...).
	if source_type == "player" and body.is_in_group("enemies"):
		if body.has_method("take_damage"):
			body.take_damage(damage)
		_on_destroyed()
	elif source_type == "enemy":
		if body.is_in_group("player"):
			var stats := body.get_node_or_null("PlayerStats")
			if stats != null and stats.has_method("take_damage"):
				stats.take_damage(damage)
		_on_destroyed()


func _on_destroyed() -> void:
	var pool_manager := get_tree().get_first_node_in_group("pool_manager")
	if pool_manager != null and pool_manager.has_method("release"):
		pool_manager.release("projectile", self)
	else:
		queue_free()
