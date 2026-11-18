## Main menu scene controller — handles navigation and game state transitions.
extends CanvasLayer


@onready var play_button: Button = $PlayButton
@onready var exit_button: Button = $ExitButton


func _ready() -> void:
	play_button.pressed.connect(_on_play_pressed)
	exit_button.pressed.connect(_on_exit_pressed)

	# Set initial state
	change_state(0)  # MAIN_MENU


func _on_play_pressed() -> void:
	print("Starting story demo...")
	transition_to_scene("res://scenes/story/story_demo.tscn")


func _on_exit_pressed() -> void:
	get_tree().quit()


func change_state(state: int) -> void:
	# Update UI based on game state
	match state:
		0:  # MAIN_MENU
			print("Main Menu")
		1:  # STORY_SCENE
			print("Story Scene")
		2:  # COMBAT
			print("Combat")
		3:  # UPGRADE
			print("Upgrade")


func transition_to_scene(scene_path: String) -> void:
	var tree := Engine.get_main_loop()
	if tree != null and tree.has_method("change_scene_to_file"):
		tree.change_scene_to_file(scene_path)
