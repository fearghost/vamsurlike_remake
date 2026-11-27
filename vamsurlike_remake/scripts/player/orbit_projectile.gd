class_name OrbitProjectile
extends Area2D


## A flame shield that circles the player for a fixed lifetime, dealing collision
## damage to enemies it touches. After its lifetime expires it disappears and
## re-fires after a cooldown (collision disabled while hidden). Each pick of
## the "Flame Shield" skill adds one shield; shields are parented to the player
## so they follow automatically. All shields share the same activation time and
## lifetime, so they appear and vanish together.

@export var damage: int = 10
@export var orbit_radius: float = 70.0
@export var angular_speed: float = 2.8   # radians per second
@export var lifetime: float = 5.0        # seconds visible before disappearing
@export var cooldown: float = 3.0        # seconds hidden before re-firing

var phase: float = 0.0                   # starting angle offset (radians)
var is_active: bool = false

var _angle: float = 0.0
var _time_left: float = 0.0
var _cooldown_left: float = 0.0
var _hit_times := {}                       # enemy -> last hit timestamp (seconds)
var _visual: Node2D = null


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2   # enemies (same as player projectiles)
	monitoring = true
	var shape := CircleShape2D.new()
	shape.radius = 16.0
	var col := CollisionShape2D.new()
	col.shape = shape
	add_child(col)
	# Flame visual (built in code — no binary assets shipped with the project):
	# soft glow + outer flame + inner flame + white-hot core, pulsing gently.
	var visual := Node2D.new()
	visual.name = "Visual"
	add_child(visual)
	_visual = visual

	var glow := Polygon2D.new()
	glow.polygon = _ellipse_polygon(24.0, 22.0)
	glow.color = Color(1.0, 0.45, 0.08, 0.16)
	visual.add_child(glow)

	var outer := Polygon2D.new()
	outer.polygon = _flame_polygon(1.0)
	outer.color = Color(1.0, 0.42, 0.04)
	visual.add_child(outer)

	var inner := Polygon2D.new()
	inner.polygon = _flame_polygon(0.58)
	inner.position = Vector2(0, 4)
	inner.color = Color(1.0, 0.82, 0.22)
	visual.add_child(inner)

	var core := Polygon2D.new()
	core.polygon = _flame_polygon(0.30)
	core.position = Vector2(0, 7)
	core.color = Color(1.0, 0.96, 0.72)
	visual.add_child(core)

	body_entered.connect(_on_body_entered)
	_activate()


func set_phase(new_phase: float) -> void:
	phase = new_phase
	if is_active:
		# Keep an already-visible shield on the freshly computed angle so shields
		# redistribute immediately instead of drifting out of alignment.
		_angle = new_phase


## Force this shield active with a fresh lifetime. Called by AutoAttack when a
## new shield is added so every shield appears and vanishes at the same time.
func sync_activation() -> void:
	_activate()


func _physics_process(delta: float) -> void:
	if not is_active:
		_cooldown_left -= delta
		if _cooldown_left <= 0.0:
			_activate()
		return

	var t := Time.get_ticks_msec() / 1000.0
	if _visual != null and is_instance_valid(_visual):
		var s := 1.0 + 0.12 * sin(t * 9.0 + phase)
		_visual.scale = Vector2(s, s)

	_angle += angular_speed * delta
	position = Vector2(cos(_angle) * orbit_radius, sin(_angle) * orbit_radius)
	_time_left -= delta
	if _time_left <= 0.0:
		_deactivate()


func _activate() -> void:
	is_active = true
	monitoring = true
	visible = true
	_angle = phase
	_time_left = lifetime


func _deactivate() -> void:
	is_active = false
	monitoring = false
	visible = false
	_cooldown_left = cooldown
	# Drop stale per-enemy hit timestamps — the shield is gone until it re-fires.
	_hit_times.clear()


func _on_body_entered(body: Node2D) -> void:
	if not is_instance_valid(body) or not body.is_in_group("enemies"):
		return
	var now := Time.get_ticks_msec() / 1000.0
	var last = _hit_times.get(body, -1.0)
	if now - last < 0.5:
		return
	_hit_times[body] = now
	if body.has_method("take_damage"):
		body.take_damage(damage)


func _flame_polygon(scale_factor: float) -> PackedVector2Array:
	var raw := [
		Vector2(1, -20), Vector2(7, -11), Vector2(10, -2), Vector2(8, 6),
		Vector2(4, 12), Vector2(-5, 13), Vector2(-9, 7), Vector2(-11, 0),
		Vector2(-7, -8),
	]
	var pts := PackedVector2Array()
	for p in raw:
		pts.append(p * scale_factor)
	return pts


func _ellipse_polygon(rx: float, ry: float, segments: int = 20) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in range(segments):
		var a := TAU * float(i) / float(segments)
		pts.append(Vector2(cos(a) * rx, sin(a) * ry))
	return pts
