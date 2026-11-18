class_name MainMenu
extends CanvasLayer


func _on_StartButton_pressed() -> void:
	GameManager.change_state(GameManager.GameState.STORY_SCENE)
	get_tree().change_scene_to_file("res://scenes/story/story_demo.tscn")


func _on_ContinueButton_pressed() -> void:
	# Save any pending progress before loading
	SaveManager.save()
	SaveManager.load()
	GameManager.change_state(GameManager.GameState.COMBAT)
	get_tree().change_scene_to_file("res://scenes/game/combat_demo.tscn")


func _on_ExitButton_pressed() -> void:
	get_tree().quit()
