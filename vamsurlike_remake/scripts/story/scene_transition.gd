extends Node

## Handles transitions between story scenes by updating GameManager state
## and loading the target scene file.


static func _get_game_manager() -> Node:
	var tree := Engine.get_main_loop()
	if tree == null: return null
	return tree.get_root().get_node_or_null("/root/GameManager")


static func transition_to_combat() -> void:
	var gm := _get_game_manager()
	if gm != null and gm.has_method("change_state"):
		gm.change_state(2)  # COMBAT
	var tree := Engine.get_main_loop()
	if tree == null: return
	tree.change_scene_to_file("res://scenes/game/combat_demo.tscn")


static func transition_to_upgrade() -> void:
	var gm := _get_game_manager()
	if gm != null and gm.has_method("change_state"):
		gm.change_state(3)  # UPGRADE
	var tree := Engine.get_main_loop()
	if tree == null: return
	tree.change_scene_to_file("res://scenes/game/upgrade_screen.tscn")


static func transition_to_main_menu() -> void:
	var gm := _get_game_manager()
	if gm != null and gm.has_method("change_state"):
		gm.change_state(0)  # MAIN_MENU
	var tree := Engine.get_main_loop()
	if tree == null: return
	tree.change_scene_to_file("res://scenes/ui/main_menu.tscn")


static func transition_to_scene(scene_path: String) -> void:
	var tree := Engine.get_main_loop()
	if tree != null and tree.has_method("change_scene_to_file"):
		tree.change_scene_to_file(scene_path)
