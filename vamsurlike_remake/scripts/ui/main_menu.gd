extends CanvasLayer


## Main menu screen with Start, Continue, and Exit buttons.


@onready var start_button: Button = $StartButton
@onready var continue_button: Button = $ContinueButton
@onready var exit_button: Button = $ExitButton


func _ready() -> void:
	start_button.pressed.connect(_on_start_pressed)
	continue_button.pressed.connect(_on_continue_pressed)
	exit_button.pressed.connect(_on_exit_pressed)

	# Disable Continue if no save exists
	_update_continue_button()


func _on_start_pressed() -> void:
	print("[MainMenu] Start button pressed!")
	var gm := get_node_or_null("/root/GameManager")
	if gm != null:
		gm.reset_game()
		print("[MainMenu] GameManager reset done")
	var scene_path := "res://scenes/ui/character_select.tscn"
	var scene := load(scene_path)
	if scene == null:
		push_error("[MainMenu] FAILED to load scene: %s" % scene_path)
		printerr("[MainMenu] Scene load failed!")
		return
	print("[MainMenu] Character select loaded, changing...")
	var result := get_tree().change_scene_to_packed(scene)
	print("[MainMenu] change_scene result: %d" % result)


func _on_continue_pressed() -> void:
	print("[MainMenu] Continuing saved game")
	var gm := get_node_or_null("/root/GameManager")
	if gm != null:
		gm.change_state(GameManager.GameState.COMBAT)
	get_tree().change_scene_to_file("res://scenes/game/combat_demo.tscn")


func _on_exit_pressed() -> void:
	print("[MainMenu] Exiting game")
	get_tree().quit()


func _update_continue_button() -> void:
	var has_save := FileAccess.file_exists("user://save_data.json")
	continue_button.disabled = not has_save
