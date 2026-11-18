class_name SceneTransition
extends Node

## Handles transitions between story scenes by updating GameManager state
## and loading the target scene file.


static func transition_to_combat() -> void:
	GameManager.change_state(GameManager.GameState.COMBAT)
	var tree := Engine.get_main_loop()
	if tree != null:
		tree.change_scene_to_file("res://scenes/game/combat_demo.tscn")


static func transition_to_upgrade() -> void:
	GameManager.change_state(GameManager.GameState.UPGRADE)
	var tree := Engine.get_main_loop()
	if tree != null:
		tree.change_scene_to_file("res://scenes/game/upgrade_screen.tscn")


static func transition_to_main_menu() -> void:
	GameManager.change_state(GameManager.GameState.MAIN_MENU)
	var tree := Engine.get_main_loop()
	if tree != null:
		tree.change_scene_to_file("res://scenes/ui/main_menu.tscn")


static func transition_to_scene(scene_path: String) -> void:
	var tree := Engine.get_main_loop()
	if tree != null and tree.has_method("change_scene_to_file"):
		tree.change_scene_to_file(scene_path)
