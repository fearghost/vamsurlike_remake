class_name Projectile
extends Area2D


## A projectile fired by either the player or enemies.
## Uses PoolManager for object pooling when available.

@export var damage: int = 10
@export var speed: float = 400.0
@export var source_type: String = "player"  # "player" or "enemy"
## Max distance (px) this shot may travel from its spawn point before it
## self-destructs. 0 = unlimited (lifetime-only, legacy behavior). Set by the
## firing code — reset on every launch so a recycled/pooled instance never
## inherits a stale range from a previous owner.
@export var max_range: float = 0.0

var velocity: Vector2 = Vector2.ZERO

# Max time a projectile may live before self-destructing. Missed shots used to
# fly forever and accumulate in the scene tree — dozens of live Area2Ds add
# physics cost every tick, which drags down FPS on mobile (stutter). 3s is
# far more than any shot needs (max engagement distance ~300px at 300-400px/s).
const LIFETIME: float = 3.0
var _lifetime: float = LIFETIME
var _traveled: float = 0.0


## Runs on EVERY tree entry (including re-acquire from the pool, where _ready
## does not re-run), so group membership always reflects live shots only.
func _enter_tree() -> void:
	add_to_group("projectiles")


func _ready() -> void:
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


## _physics_process (not _process) so bullet speed is constant regardless of
## the device's render frame rate.
func _physics_process(delta: float) -> void:
	var step := velocity * delta
	position += step
	_traveled += step.length()
	_lifetime -= delta
	if _lifetime <= 0.0 or (max_range > 0.0 and _traveled >= max_range):
		_on_destroyed()


func set_velocity(dir: Vector2) -> void:
	velocity = dir.normalized() * speed
	_lifetime = LIFETIME  # pooled projectiles keep stale state — reset on acquire
	_traveled = 0.0
	max_range = 0.0  # firing code sets this explicitly after launch (see AutoAttack)


func set_direction(dir: Vector2) -> void:
	velocity = (dir.normalized() if dir.length() > 0.001 else Vector2.RIGHT) * speed
	_lifetime = LIFETIME
	_traveled = 0.0
	max_range = 0.0


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
	# Leave the group immediately so get_nodes_in_group("projectiles") only
	# ever reports live shots (released/pooled nodes stay out of the tree).
	remove_from_group("projectiles")
	var pool_manager := get_tree().get_first_node_in_group("pool_manager")
	if pool_manager != null and pool_manager.has_method("release"):
		pool_manager.release("projectile", self)
	else:
		queue_free()
