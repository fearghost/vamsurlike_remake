## Main menu scene controller — handles navigation and game state transitions.
extends CanvasLayer


func _ready() -> void:
	$StartButton.pressed.connect(_on_StartButton_pressed)
	$ContinueButton.pressed.connect(_on_ContinueButton_pressed)
	$ExitButton.pressed.connect(_on_ExitButton_pressed)


func _on_StartButton_pressed() -> void:
	print("Starting story demo...")
	transition_to_scene("res://scenes/story/story_demo.tscn")


func _on_ContinueButton_pressed() -> void:
	print("Continuing from last save...")
	var sm := get_node_or_null("/root/SaveManager")
	if sm != null and sm.save_data.has("current_stage"):
		var gm := get_node_or_null("/root/GameManager")
		if gm != null:
			gm.current_stage_id = sm.save_data["current_stage"] + 1
	transition_to_scene("res://scenes/game/combat_demo.tscn")


func _on_ExitButton_pressed() -> void:
	get_tree().quit()


func transition_to_scene(scene_path: String) -> void:
	get_tree().change_scene_to_file(scene_path)
