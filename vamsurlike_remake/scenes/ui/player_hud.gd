class_name PlayerHud
extends CanvasLayer


## HUD overlay that displays player HP bar and current stage information.


@onready var hp_bar: TextureProgressBar = $HPBar
@onready var stage_label: Label = $StageLabel


func _ready() -> void:
	# Connect to the PlayerStats node if it exists in the tree
	var player_stats := _find_player_stats()
	if player_stats != null:
		player_stats.hp_changed.connect(update_hp)
		player_stats.died.connect(_on_player_died)


func _find_player_stats() -> Node:
	var tree := get_tree()
	if tree == null:
		return null

	for node in tree.get_root().get_children():
		if node is Node and node.has_signal("hp_changed"):
			return node

	# Fallback: search all nodes in the scene tree
	for node in tree.get_nodes_in_group("player_stats") if tree.has_group("player_stats") else []:
		if node is Node and node.has_signal("hp_changed"):
			return node

	return null


func update_hp(current: int, max_hp_val: int) -> void:
	if hp_bar != null:
		hp_bar.max_value = max_hp_val
		hp_bar.value = current


func update_stage(stage_id: int) -> void:
	if stage_label != null:
		stage_label.text = "Stage %d" % stage_id


func _on_player_died() -> void:
	print("Player has died — HUD updating for death state.")
	if hp_bar != null:
		hp_bar.value = 0
