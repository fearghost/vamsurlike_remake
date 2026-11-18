class_name SceneTransition
extends Node

## Handles transitions between story scenes by updating GameManager state
## and loading the target scene file.


static func transition_to_combat() -> void:
	var tree := Engine.get_main_loop()
	if tree == null: return
	var root: Node = tree.get_root()
	var gm_node: Node = root.get_node_or_null("GameManager")
	if gm_node != null and gm_node.has_method("change_state"):
		gm_node.change_state(gm_node.GameState.COMBAT)
	tree.change_scene_to_file("res://scenes/game/combat_demo.tscn")


static func transition_to_upgrade() -> void:
	var tree := Engine.get_main_loop()
	if tree == null: return
	var root: Node = tree.get_root()
	var gm_node: Node = root.get_node_or_null("GameManager")
	if gm_node != null and gm_node.has_method("change_state"):
		gm_node.change_state(gm_node.GameState.UPGRADE)
	tree.change_scene_to_file("res://scenes/game/upgrade_screen.tscn")


static func transition_to_main_menu() -> void:
	var tree := Engine.get_main_loop()
	if tree == null: return
	var root: Node = tree.get_root()
	var gm_node: Node = root.get_node_or_null("GameManager")
	if gm_node != null and gm_node.has_method("change_state"):
		gm_node.change_state(gm_node.GameState.MAIN_MENU)
	tree.change_scene_to_file("res://scenes/ui/main_menu.tscn")


static func transition_to_scene(scene_path: String) -> void:
	var tree := Engine.get_main_loop()
	if tree != null and tree.has_method("change_scene_to_file"):
		tree.change_scene_to_file(scene_path)
