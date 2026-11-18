class_name SceneTransition
extends Node

## Handles transitions between story scenes by updating GameManager state
## and loading the target scene file.


func transition_to_combat() -> void:
	GameManager.change_state(GameManager.GameState.COMBAT)
	get_tree().change_scene_to_file("res://scenes/game/combat_demo.tscn")


func transition_to_upgrade() -> void:
	GameManager.change_state(GameManager.GameState.UPGRADE)
	get_tree().change_scene_to_file("res://scenes/game/upgrade_screen.tscn")


func transition_to_main_menu() -> void:
	GameManager.change_state(GameManager.GameState.MAIN_MENU)
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
