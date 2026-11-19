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
	var gm := get_node_or_null("/root/GameManager")
	if gm != null and gm.has_method("get_player_stats"):
		gm.get_player_stats()["hp"] = gm.get_player_stats().get("max_hp", 100)
	_save_and_return()


func _on_attack_pressed() -> void:
	print("Reward: Attack +5.")
	var sm := get_node_or_null("/root/SaveManager")
	if sm != null and sm.save_data.has("player_stats"):
		sm.save_data["player_stats"]["attack"] = sm.save_data["player_stats"].get("attack", 10) + 5
	_save_and_return()


func _on_back_pressed() -> void:
	_save_and_return()


func _save_and_return() -> void:
	# Persist player stats changes
	var sm := get_node_or_null("/root/SaveManager")
	if sm != null:
		sm.save_data["player_stats"] = sm.save_data.get("player_stats", {}).duplicate()
		sm.save()

	# Transition to main menu
	var st := get_node_or_null("/root/SceneTransition")
	if st != null:
		st.transition_to_main_menu()
