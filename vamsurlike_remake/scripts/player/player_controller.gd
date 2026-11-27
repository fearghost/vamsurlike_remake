class_name PlayerController
extends CharacterBody2D


## Player controller that reads input from VirtualJoystick and drives movement.
## Builds its own quarter-view body (shadow + flattened circle + highlight) when no child Body exists — flat boxes read as top-down, this reads as viewed from above at an angle.


@export var move_speed: float = 200.0

var current_direction: Vector2 = Vector2.ZERO
var is_attacking: bool = false
var player_stats: Node  # reference to PlayerStats node
var auto_attack: AutoAttack  # reference to AutoAttack component


func _ready() -> void:
	add_to_group("player")

	# Collision setup: player lives on layer 1 and detects only obstacles
	# (layer 4) — trees/rocks block movement. Enemies must NOT physically
	# block the player (a chasing enemy pushes it and boxes it in), so they
	# stay out of the mask; contact damage is distance-based on the enemy
	# side (see EnemyAI._check_contact_damage), not collision-driven.
	collision_layer = 1
	collision_mask = MapConfig.OBSTACLE_MASK

	# Build the quarter-view body (shadow + flattened ellipse + highlight) if no child Body exists
	if find_child("Body") == null:
		var body := Node2D.new()
		body.name = "Body"

		# Ground shadow — light from upper-left, so the shadow falls lower-right and peeks out below the base
		var shadow := Polygon2D.new()
		shadow.polygon = _ellipse_polygon(15.0, 6.0)
		shadow.color = Color(0, 0, 0, 0.30)
		shadow.position = Vector2(4, 9)
		body.add_child(shadow)

		# Body — slightly flattened ellipse reads as viewed from above at an angle
		var circle := Polygon2D.new()
		circle.polygon = _ellipse_polygon(15.0, 12.5)
		circle.color = Color(0.20, 0.42, 1.00, 1)
		circle.position = Vector2(0, -3)
		body.add_child(circle)

		# Highlight — upper-left light source
		var hi := Polygon2D.new()
		hi.polygon = _ellipse_polygon(6.5, 4.5)
		hi.color = Color(0.55, 0.75, 1.00, 1)
		hi.position = Vector2(-4.5, -7.5)
		body.add_child(hi)

		add_child(body)

	# Add collision shape for Area2D projectile detection
	var collision := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 18.0
	collision.shape = shape
	add_child(collision)

	# Create a default PlayerStats node if none is assigned
	if player_stats == null:
		player_stats = $PlayerStats if has_node("PlayerStats") else null

	# Create default AutoAttack if none is assigned
	if auto_attack == null:
		auto_attack = $AutoAttack if has_node("AutoAttack") else null


## Movement runs in _physics_process (NOT _process): move_and_slide() must be
## called on the physics tick. In _process the step size is tied to the RENDER
## frame rate, so on a device whose FPS drops under combat load the player
## crawls/freezes and then speeds back up — the on-device "controls stop
## working, stutters, then moves again" bug.
func _physics_process(delta: float) -> void:
	velocity = current_direction * move_speed
	move_and_slide()

	# Keep the player inside the map — no walking off into the void.
	var margin := 18.0  # player collision radius
	global_position = global_position.clamp(Vector2(margin, margin), MapConfig.MAP_SIZE - Vector2(margin, margin))


func set_input_direction(direction: Vector2) -> void:
	current_direction = direction.normalized()


func start_auto_attack() -> void:
	is_attacking = true
	if auto_attack != null:
		auto_attack.start_attack()


func stop_auto_attack() -> void:
	is_attacking = false
	if auto_attack != null:
		auto_attack.stop_attack()


func _on_player_stats_died() -> void:
	stop_auto_attack()
	print("Player has died.")

func _ellipse_polygon(rx: float, ry: float, segments: int = 20) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in range(segments):
		var a := TAU * float(i) / float(segments)
		pts.append(Vector2(cos(a) * rx, sin(a) * ry))
	return pts
