## UpgradeScreen controller — displayed after clearing all waves in combat.
## Lets the player choose a reward (heal or attack boost) before returning to main menu.
extends CanvasLayer


@onready var title_label: Label = $TitleLabel
@onready var heal_button: Button = $HealButton
@onready var attack_button: Button = $AttackButton
@onready var back_button: Button = $BackButton


func _ready() -> void:
	heal_button.pressed.connect(_on_heal_pressed)
	attack_button.pressed.connect(_on_attack_pressed)
	back_button.pressed.connect(_on_back_pressed)


func _on_heal_pressed() -> void:
	print("Reward: Full HP restored.")
	if GameManager != null:
		GameManager.player_base_stats["hp"] = GameManager.player_base_stats["max_hp"]
	_save_and_return()


func _on_attack_pressed() -> void:
	print("Reward: Attack +5.")
	if GameManager != null:
		GameManager.player_base_stats["attack"] = GameManager.player_base_stats.get("attack", 10) + 5
	_save_and_return()


func _on_back_pressed() -> void:
	_save_and_return()


func _save_and_return() -> void:
	# Persist player stats changes
	if SaveManager != null and GameManager != null:
		SaveManager.save_data["player_stats"] = GameManager.player_base_stats.duplicate()
		SaveManager.save()
	
	# Transition to main menu
	if SceneTransition != null and SceneTransition.has_method("transition_to_main_menu"):
		SceneTransition.transition_to_main_menu()
