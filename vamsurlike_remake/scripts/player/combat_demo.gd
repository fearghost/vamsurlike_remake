## CombatDemo controller — coordinates player, spawner, and HUD in the combat scene.
extends Node2D


@onready var player: PlayerController = $Player
@onready var spawner: Spawner = $Spawner
@onready var virtual_joystick: VirtualJoystick = $JoystickLayer/VirtualJoystick
@onready var hud: PlayerHud = $PlayerHud

var skill_select: SkillSelect = null
var pending_levels: int = 0


func _ready() -> void:
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
