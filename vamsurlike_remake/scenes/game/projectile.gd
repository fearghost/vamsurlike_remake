class_name Projectile
extends Area2D


## A projectile fired by either the player or enemies.
## Uses PoolManager for object pooling when available.


@export var damage: int = 10
@export var speed: float = 400.0
@export var owner: String = "player"  # "player" or "enemy"

var velocity: Vector2 = Vector2.ZERO


func _ready() -> void:
	# Set sprite color based on owner
	var sprite := find_child("Sprite")
	if sprite != null:
		if owner == "player":
			sprite.color = Color(1, 1, 0, 1)       # Yellow for player
		else:
			sprite.color = Color(1, 0.5, 0, 1)      # Orange for enemy


func _process(delta: float) -> void:
	position += velocity * delta


func set_velocity(dir: Vector2) -> void:
	velocity = dir.normalized() * speed


func set_direction(dir: Vector2) -> void:
	velocity = dir.normalized() * speed


func set_damage(amount: int) -> void:
	damage = amount


func _on_body_entered(body: Node) -> void:
	if owner == "player" and body is EnemyAI:
		body.take_damage(damage)
		_on_destroyed()
	elif owner == "enemy" and body.has_node("PlayerStats"):
		var stats := body.get_node("PlayerStats")
		if stats is PlayerStats:
			stats.take_damage(damage)
		_on_destroyed()


func _on_destroyed() -> void:
	# Try to release back to PoolManager
	var pool_manager := get_tree().get_first_node_in_group("pool_manager")
	if pool_manager != null and pool_manager.has_method("release"):
		pool_manager.release("projectile", self)
	else:
		queue_free()
