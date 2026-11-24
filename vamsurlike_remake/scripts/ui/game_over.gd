extends CanvasLayer

## Game over screen with Retry and Main Menu buttons.

@onready var retry_button: Button = $RetryButton
@onready var menu_button: Button = $MenuButton


func _ready() -> void:
	retry_button.pressed.connect(_on_retry_pressed)
	menu_button.pressed.connect(_on_menu_pressed)


func _on_retry_pressed() -> void:
	print("[GameOver] Retry - restarting stage")
	get_tree().change_scene_to_file("res://scenes/game/combat_demo.tscn")


func _on_menu_pressed() -> void:
	print("[GameOver] Returning to main menu")
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
