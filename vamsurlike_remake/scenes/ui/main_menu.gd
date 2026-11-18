## Main menu scene controller — handles navigation and game state transitions.
extends CanvasLayer


@onready var start_button: Button = $StartButton
@onready var continue_button: Button = $ContinueButton
@onready var exit_button: Button = $ExitButton


func _ready() -> void:
	start_button.pressed.connect(_on_start_pressed)
	continue_button.pressed.connect(_on_continue_pressed)
	exit_button.pressed.connect(_on_exit_pressed)


func _on_start_pressed() -> void:
	print("Starting story demo...")
	transition_to_scene("res://scenes/story/story_demo.tscn")


func _on_continue_pressed() -> void:
	print("Continuing from last save...")
	var sm := get_node_or_null("/root/SaveManager")
	if sm != null and sm.save_data.has("current_stage"):
		var gm := get_node_or_null("/root/GameManager")
		if gm != null:
			gm.current_stage_id = sm.save_data["current_stage"] + 1
	transition_to_scene("res://scenes/game/combat_demo.tscn")


func _on_exit_pressed() -> void:
	get_tree().quit()


func transition_to_scene(scene_path: String) -> void:
	var tree := Engine.get_main_loop()
	if tree != null and tree.has_method("change_scene_to_file"):
		tree.change_scene_to_file(scene_path)
