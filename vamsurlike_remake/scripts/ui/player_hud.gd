class_name PlayerHud
extends CanvasLayer


## HUD overlay showing player HP bar, stage number, level and XP progress.


@onready var hp_bar: TextureProgressBar = $HPBar
@onready var stage_label: Label = $StageLabel

var level_label: Label = null
var xp_bar: TextureProgressBar = null


func _ready() -> void:
	# Build the XP bar + level label under the stage label (built in code so no
	# scene file needs to be kept in sync with the layout)
	level_label = Label.new()
	level_label.name = "LevelLabel"
	level_label.text = "Lv 1"
	# Stage label occupies y=60..90 (see player_hud.tscn) — keep the level
	# label below it so they don't overlap.
	level_label.position = Vector2(20, 96)
	add_child(level_label)

	xp_bar = TextureProgressBar.new()
	xp_bar.name = "XPBar"
	xp_bar.min_value = 0
	xp_bar.max_value = 100
	xp_bar.position = Vector2(20, 120)
	xp_bar.size = Vector2(300, 12)
	add_child(xp_bar)

	# Connect to the PlayerStats node if it exists in the tree
	var player_stats := _find_player_stats()
	if player_stats != null:
		if not player_stats.hp_changed.is_connected(update_hp):
			player_stats.hp_changed.connect(update_hp)
		if not player_stats.died.is_connected(_on_player_died):
			player_stats.died.connect(_on_player_died)
		if not player_stats.xp_changed.is_connected(update_xp):
			player_stats.xp_changed.connect(update_xp)

	# Connect to GameManager for stage updates
	var gm := get_node_or_null("/root/GameManager")
	if gm != null:
		if gm.has_signal("state_changed"):
			gm.state_changed.connect(_on_game_state_changed)
		update_stage(gm.current_stage_id)


func _on_game_state_changed(new_state: int) -> void:
	var gm := get_node_or_null("/root/GameManager")
	if gm != null and new_state == 2:  # COMBAT
		update_stage(gm.current_stage_id)


func _find_player_stats() -> Node:
	var tree := get_tree()
	if tree == null:
		return null

	for node in tree.get_root().get_children():
		if node is Node and node.has_signal("hp_changed"):
			return node

	# Fallback: search all nodes in the scene tree
	for node in tree.get_nodes_in_group("player_stats"):
		if node is Node and node.has_signal("hp_changed"):
			return node

	return null


func update_hp(current: int, max_hp_value: int) -> void:
	if hp_bar != null:
		hp_bar.max_value = max_hp_value
		hp_bar.value = current


func update_xp(current: int, needed: int, level: int) -> void:
	if xp_bar != null:
		xp_bar.max_value = max(1, needed)
		xp_bar.value = current
	if level_label != null:
		level_label.text = "Lv %d" % level


func update_stage(stage_id: int) -> void:
	if stage_label != null:
		stage_label.text = "Stage: %d" % stage_id


func _on_player_died() -> void:
	print("Player has died — HUD updating for death state.")
	if hp_bar != null:
		hp_bar.value = 0
