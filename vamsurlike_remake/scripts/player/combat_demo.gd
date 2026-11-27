## CombatDemo controller — coordinates player, spawner, and HUD in the combat scene.
extends Node2D


@onready var player: PlayerController = $Player
@onready var spawner: Spawner = $Spawner
@onready var virtual_joystick: VirtualJoystick = $JoystickLayer/VirtualJoystick
@onready var hud: PlayerHud = $PlayerHud

var skill_select: SkillSelect = null
var pending_levels: int = 0


func _ready() -> void:
	# Build the forest-floor backdrop (grass patches + blocking trees/rocks).
	_setup_environment()

	# Create the level-up skill selection overlay (hidden until a level is gained)
	skill_select = SkillSelect.new()
	skill_select.name = "SkillSelect"
	add_child(skill_select)
	skill_select.skill_chosen.connect(_on_skill_chosen)

	# Register projectile pool for PoolManager
	var projectile_scene := preload("res://scenes/game/projectile.tscn") as PackedScene
	var pm := get_node_or_null("/root/PoolManager")
	if projectile_scene != null and pm != null and pm.has_method("register_pool"):
		pm.register_pool("projectile", projectile_scene, 20)

	# Connect VirtualJoystick to player input
	if virtual_joystick != null and player != null:
		virtual_joystick.value_changed.connect(player.set_input_direction)

	# Start auto-attack on the player
	if player != null:
		player.start_auto_attack()

	# Start first wave after a short delay
	if spawner != null:
		spawner.start_wave(0)

	# Sync HUD with player stats (HUD may have already self-connected in _ready)
	if player != null and player.player_stats != null:
		hud.update_hp(player.player_stats.current_hp, player.player_stats.max_hp)
		if not player.player_stats.hp_changed.is_connected(hud.update_hp):
			player.player_stats.hp_changed.connect(hud.update_hp)

	# Connect level-ups to the skill selection overlay
	if player != null and player.player_stats != null:
		if not player.player_stats.leveled_up.is_connected(_on_level_up):
			player.player_stats.leveled_up.connect(_on_level_up)
		var stats := player.player_stats as PlayerStats
		if stats != null and hud != null:
			hud.update_xp(stats.xp, stats.xp_to_next(), stats.level)

	var gm := get_node_or_null("/root/GameManager")
	if gm != null:
		gm.current_stage_id = 1
		hud.update_stage(gm.current_stage_id)

	# Connect spawner signal to combat demo
	if spawner != null:
		spawner.all_waves_cleared.connect(_on_all_waves_cleared)

	# Connect player death to main menu return
	if player != null and player.player_stats != null:
		player.player_stats.died.connect(_on_player_died)


func _on_player_died() -> void:
	if get_tree().paused:
		get_tree().paused = false
	print("Player died. Showing game over screen.")
	var sm := get_node_or_null("/root/SaveManager")
	var gm := get_node_or_null("/root/GameManager")
	if sm != null and gm != null:
		sm.save_data["current_stage"] = gm.current_stage_id
		sm.save()
	get_tree().change_scene_to_file("res://scenes/game/game_over.tscn")


func _on_level_up(new_level: int) -> void:
	pending_levels += 1
	if skill_select != null and not skill_select.visible:
		get_tree().paused = true
		skill_select.open()


func _on_skill_chosen(skill_id: String) -> void:
	pending_levels -= 1
	if pending_levels > 0:
		# Multiple levels gained at once — offer another random choice set while paused
		skill_select.open()
	else:
		get_tree().paused = false


func _on_all_waves_cleared() -> void:
	print("All waves cleared! Returning to main menu.")

	# Discard any pending level-up overlay before leaving the scene — a final
	# kill can trigger one, and it must not leak into the next scene.
	pending_levels = 0
	if skill_select != null:
		skill_select.close()

	# Save cleared stage progress
	var sm := get_node_or_null("/root/SaveManager")
	var gm := get_node_or_null("/root/GameManager")
	if sm != null and gm != null:
		sm.save_data["current_stage"] = gm.current_stage_id
		if not sm.save_data["cleared_stages"].has(gm.current_stage_id):
			sm.save_data["cleared_stages"].append(gm.current_stage_id)
		sm.save()

	# Safety: never leave the tree paused when leaving this scene
	if get_tree().paused:
		get_tree().paused = false

	var st := get_node_or_null("/root/SceneTransition")
	if st != null and st.has_method("transition_to_main_menu"):
		st.transition_to_main_menu()


## Builds the forest-floor backdrop: grass patches (decorative) plus blocking
## trees and rocks on layer 4 (MapConfig.OBSTACLE_LAYER). Everything lives in a
## single "Environment" node inserted just above MapFloor so it renders behind
## the player, enemies and projectiles. Deterministic layout via a local RNG —
## the global seed is left alone so enemy spawn randomness is unchanged.
func _setup_environment() -> void:
	if has_node("Environment"):
		return
	var env := Node2D.new()
	env.name = "Environment"
	add_child(env)
	move_child(env, 1)  # above MapFloor (index 0), below everything else

	var rng := RandomNumberGenerator.new()
	rng.seed = 1234

	# --- grass tufts / ground patches (decorative, non-colliding) ---
	var palette := [
		Color(0.24, 0.40, 0.17, 1),   # light moss green
		Color(0.12, 0.22, 0.10, 1),   # dark forest floor
		Color(0.32, 0.45, 0.20, 1),   # bright grass
		Color(0.34, 0.28, 0.18, 1),   # bare dirt patch
	]
	for i in range(80):
		var w := rng.randf_range(10.0, 48.0)
		var h := rng.randf_range(6.0, 22.0)
		# Flat ellipse tufts (wider than tall) — reads as ground texture in quarter view
		# instead of floating rotated rectangles.
		var patch := Polygon2D.new()
		patch.polygon = _ellipse_polygon(w * 0.5, h * 0.45)
		patch.color = palette[rng.randi() % palette.size()]
		patch.position = Vector2(
			rng.randf_range(w + 20.0, MapConfig.MAP_SIZE.x - w - 20.0),
			rng.randf_range(h + 20.0, MapConfig.MAP_SIZE.y - h - 20.0)
		)
		patch.rotation = rng.randf_range(-0.6, 0.6)
		env.add_child(patch)

	# --- blocking obstacles (trees and rocks on layer 4) ---
	var obstacles := [
		{"pos": Vector2(950, 420), "radius": 52.0, "type": "tree"},
		{"pos": Vector2(1500, 350), "radius": 46.0, "type": "tree"},
		{"pos": Vector2(1900, 800), "radius": 58.0, "type": "tree"},
		{"pos": Vector2(700, 1000), "radius": 44.0, "type": "tree"},
		{"pos": Vector2(1200, 900), "radius": 66.0, "type": "tree"},
		{"pos": Vector2(2100, 450), "radius": 46.0, "type": "tree"},
		{"pos": Vector2(1100, 650), "radius": 32.0, "type": "rock"},
		{"pos": Vector2(1700, 1150), "radius": 38.0, "type": "rock"},
		{"pos": Vector2(500, 600), "radius": 34.0, "type": "rock"},
		{"pos": Vector2(2300, 1000), "radius": 40.0, "type": "rock"},
	]
	var idx := 0
	for spec in obstacles:
		env.add_child(_make_obstacle(spec["pos"], spec["radius"], spec["type"], "Obstacle_%d" % idx, rng))
		idx += 1


func _ellipse_polygon(rx: float, ry: float, segments: int = 20) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in range(segments):
		var a := TAU * float(i) / float(segments)
		pts.append(Vector2(cos(a) * rx, sin(a) * ry))
	return pts


func _circle_polygon(radius: float, segments: int = 16) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in range(segments):
		var a := TAU * float(i) / float(segments)
		pts.append(Vector2(cos(a) * radius, sin(a) * radius))
	return pts


func _make_obstacle(pos: Vector2, radius: float, type: String, node_name: String, rng: RandomNumberGenerator) -> StaticBody2D:
	var body := StaticBody2D.new()
	body.name = node_name
	body.position = pos
	body.collision_layer = MapConfig.OBSTACLE_LAYER
	body.collision_mask = 0

	# Fair-sized hitbox slightly smaller than the visual so edge touches don't feel sticky.
	var shape := CircleShape2D.new()
	shape.radius = radius * (0.8 if type == "tree" else 0.85)
	var col := CollisionShape2D.new()
	col.shape = shape
	body.add_child(col)

	# Ground shadow — grounds the object in quarter view (light from upper-left,
	# so the shadow falls lower-right and peeks out below the base). Added first so it renders behind the trunk/crown.
	var shadow := Polygon2D.new()
	shadow.polygon = _ellipse_polygon(radius * 1.05, radius * 0.40)
	shadow.color = Color(0, 0, 0, 0.28)
	shadow.position = Vector2(4, radius * 0.58)
	body.add_child(shadow)

	if type == "tree":
		# Trunk (drawn first so the crown covers its top), then a two-tone crown slightly flattened for quarter view.
		var trunk := ColorRect.new()
		trunk.color = Color(0.32, 0.22, 0.12, 1)
		trunk.size = Vector2(radius * 0.28, radius * 0.55)
		trunk.position = Vector2(-radius * 0.14, radius * 0.25)
		body.add_child(trunk)

		var crown := Polygon2D.new()
		crown.polygon = _circle_polygon(radius, 18)
		crown.color = Color(0.11, 0.30, 0.10, 1)
		crown.scale = Vector2(1.0, 0.85)   # quarter-view flattening
		crown.position = Vector2(0, -radius * 0.12)
		body.add_child(crown)

		var crown_hi := Polygon2D.new()
		crown_hi.polygon = _circle_polygon(radius * 0.62, 14)
		crown_hi.color = Color(0.18, 0.42, 0.15, 1)
		crown_hi.position = Vector2(-radius * 0.12, -radius * 0.26)
		crown_hi.scale = Vector2(1.0, 0.85)
		body.add_child(crown_hi)
	else:
		# Irregular rock — vertex radii vary a little so no two rocks look identical.
		var pts := PackedVector2Array()
		var segs := 10
		for i in range(segs):
			var a := TAU * float(i) / float(segs)
			var r := radius * rng.randf_range(0.78, 1.05)
			pts.append(Vector2(cos(a) * r, sin(a) * r))
		var rock := Polygon2D.new()
		rock.polygon = pts
		rock.color = Color(0.46, 0.45, 0.43, 1)
		rock.scale = Vector2(1.0, 0.82)   # quarter-view flattening
		rock.position = Vector2(0, -radius * 0.10)
		body.add_child(rock)

		var rock_hi := Polygon2D.new()
		rock_hi.polygon = _circle_polygon(radius * 0.55, 10)
		rock_hi.color = Color(0.58, 0.57, 0.54, 1)
		rock_hi.position = Vector2(-radius * 0.15, -radius * 0.26)
		rock_hi.scale = Vector2(1.0, 0.82)
		body.add_child(rock_hi)

	return body
