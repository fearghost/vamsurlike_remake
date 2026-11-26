class_name OrbitProjectile
extends Area2D


## A blade that circles the player for a fixed lifetime, dealing collision
## damage to enemies it touches. After its lifetime expires it disappears and
## re-fires after a cooldown (collision disabled while hidden). Each pick of
## the "Orbital Blade" skill adds one blade; blades are parented to the player
## so they follow automatically.

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


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2   # enemies (same as player projectiles)
	monitoring = true
	var shape := CircleShape2D.new()
	shape.radius = 12.0
	var col := CollisionShape2D.new()
	col.shape = shape
	add_child(col)
	# dummy visual (same style as other placeholder sprites)
	var rect := ColorRect.new()
	rect.color = Color(0.3, 1.0, 0.6)
	rect.size = Vector2(14, 14)
	rect.position = Vector2(-7, -7)
	add_child(rect)
	body_entered.connect(_on_body_entered)
	_activate()


func set_phase(new_phase: float) -> void:
	phase = new_phase
	if is_active:
		# Keep an already-visible blade on the freshly computed angle so blades
		# redistribute immediately instead of drifting out of alignment.
		_angle = new_phase


func _physics_process(delta: float) -> void:
	if not is_active:
		_cooldown_left -= delta
		if _cooldown_left <= 0.0:
			_activate()
		return

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
	# Drop stale per-enemy hit timestamps — the blade is gone until it re-fires.
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
