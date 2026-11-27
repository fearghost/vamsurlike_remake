class_name Projectile
extends Area2D


## A projectile fired by either the player or enemies.
## Uses PoolManager for object pooling when available.
## Straight flight: velocity is set once at launch and never adjusted afterwards —
## no homing, no steering; the shot travels in the direction it was fired.

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


## (Re)applies the vector-drawn visual and collision mask for the current
## source_type. Called after source_type changes — pooled projectiles are reused,
## and _ready only runs on first tree entry, so both must be re-applied every acquire.
func apply_source_style() -> void:
	# The scene's legacy ColorRect is replaced by a vector-drawn visual per source type.
	var legacy := find_child("Sprite")
	if legacy != null:
		legacy.visible = false

	if source_type == "player":
		# Player shots only ever hit enemies (layer 2) — never the player itself.
		collision_mask = 2 | MapConfig.OBSTACLE_MASK
	else:
		# Enemy shots only ever hit the player (layer 1) — never other enemies.
		collision_mask = 1 | MapConfig.OBSTACLE_MASK

	var visual := get_node_or_null("Visual") as Node2D
	if visual == null:
		visual = Node2D.new()
		visual.name = "Visual"
		add_child(visual)
	for child in visual.get_children():
		visual.remove_child(child)
		child.free()

	if source_type == "player":
		_build_dark_magic(visual)
	else:
		_build_arrow(visual)


## Dark magic (검기) profile (pointing +X): a shadow-energy comet — soft violet halo,
## dark teardrop body with a bright violet-white core trailing behind the head.
func _build_dark_magic(parent: Node2D) -> void:
	# Soft outer glow — large translucent ellipse reads as an energy aura
	var glow := Polygon2D.new()
	glow.polygon = PackedVector2Array([
		Vector2(14, 0), Vector2(8, -6.5), Vector2(-10, -5.0), Vector2(-12, 0),
		Vector2(-10, 5.0), Vector2(8, 6.5),
	])
	glow.color = Color(0.35, 0.12, 0.55, 0.30)   # translucent violet aura
	parent.add_child(glow)
	# Dark teardrop body — head at +X tapering to a tail behind it
	var outer := Polygon2D.new()
	outer.polygon = PackedVector2Array([
		Vector2(16, 0), Vector2(5, -4.8), Vector2(-11, -3.6), Vector2(-14, 0),
		Vector2(-11, 3.6), Vector2(5, 4.8),
	])
	outer.color = Color(0.20, 0.07, 0.36, 1)   # deep shadow violet body
	parent.add_child(outer)
	# Mid layer — brighter inner teardrop for depth
	var mid := Polygon2D.new()
	mid.polygon = PackedVector2Array([
		Vector2(11, 0), Vector2(4, -3.1), Vector2(-8, -2.2), Vector2(-9.5, 0),
		Vector2(-8, 2.2), Vector2(4, 3.1),
	])
	mid.color = Color(0.48, 0.20, 0.72, 1)   # violet mid layer
	parent.add_child(mid)
	# Core — bright white-violet hot center near the head
	var core := Polygon2D.new()
	core.polygon = PackedVector2Array([
		Vector2(8, 0), Vector2(3, -1.9), Vector2(-4, -1.5), Vector2(-4.6, 0),
		Vector2(-4, 1.5), Vector2(3, 1.9),
	])
	core.color = Color(0.88, 0.72, 1.00, 1)   # bright violet-white core
	parent.add_child(core)


## Arrow profile (pointing +X): brown shaft, steel head, light fletching at the tail.
func _build_arrow(parent: Node2D) -> void:
	var shaft := Polygon2D.new()
	shaft.polygon = PackedVector2Array([
		Vector2(9, -1.3), Vector2(-7, -1.3), Vector2(-7, 1.3), Vector2(9, 1.3),
	])
	shaft.color = Color(0.45, 0.28, 0.15)   # brown shaft
	parent.add_child(shaft)
	var head := Polygon2D.new()
	head.polygon = PackedVector2Array([
		Vector2(14, 0), Vector2(8, -2.6), Vector2(8, 2.6),
	])
	head.color = Color(0.85, 0.87, 0.9)     # steel head
	parent.add_child(head)
	var fin_top := Polygon2D.new()
	fin_top.polygon = PackedVector2Array([
		Vector2(-7, -1.3), Vector2(-12, -4.6), Vector2(-10, 0),
	])
	fin_top.color = Color(0.9, 0.85, 0.75)   # light fletching
	parent.add_child(fin_top)
	var fin_bottom := Polygon2D.new()
	fin_bottom.polygon = PackedVector2Array([
		Vector2(-7, 1.3), Vector2(-12, 4.6), Vector2(-10, 0),
	])
	fin_bottom.color = Color(0.9, 0.85, 0.75)
	parent.add_child(fin_bottom)


## _physics_process (not _process) so bullet speed is constant regardless of
## the device's render frame rate.
func _physics_process(delta: float) -> void:
	var step := velocity * delta
	position += step
	if velocity.length() > 0.001:
		rotation = velocity.angle()
	_traveled += step.length()
	_lifetime -= delta
	if _lifetime <= 0.0 or (max_range > 0.0 and _traveled >= max_range):
		_on_destroyed()


func set_velocity(dir: Vector2) -> void:
	velocity = dir.normalized() * speed
	if velocity.length() > 0.001:
		rotation = velocity.angle()
	_lifetime = LIFETIME  # pooled projectiles keep stale state — reset on acquire
	_traveled = 0.0
	max_range = 0.0  # firing code sets this explicitly after launch (see AutoAttack)


func set_direction(dir: Vector2) -> void:
	velocity = (dir.normalized() if dir.length() > 0.001 else Vector2.RIGHT) * speed
	if velocity.length() > 0.001:
		rotation = velocity.angle()
	_lifetime = LIFETIME
	_traveled = 0.0
	max_range = 0.0


## Legacy alias kept for callers that still use the old name.
func set_damage(amount: int) -> void:
	damage = amount


func _handle_body_entered(body: Node) -> void:
	# Obstacles (trees/rocks on layer 4) block the shot — it dies on impact,
	# before any damage logic runs. No group check needed: obstacles are the only
	# StaticBody2D in this mask and never carry gameplay groups.
	if body is StaticBody2D and (body as StaticBody2D).collision_layer & MapConfig.OBSTACLE_MASK != 0:
		_on_destroyed()
		return
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
