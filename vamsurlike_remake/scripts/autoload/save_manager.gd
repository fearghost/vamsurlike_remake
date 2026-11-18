## SaveManager handles persistent game data using JSON serialization.
## Saves to user://save_data.json for cross-session persistence.
class_name SaveManager
extends Node

var save_data: Dictionary = {
	"current_stage": 0,
	"cleared_stages": [],
	"player_stats": {},
}


func _ready() -> void:
	load_data()


## Loads saved data from user://save_data.json
func load_data() -> void:
	var path := "user://save_data.json"
	if not FileAccess.file_exists(path):
		print("SaveManager: No save file found, creating new save.")
		save()
		return

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("SaveManager: Failed to open save file at %s" % path)
		return

	var json_string := file.get_as_text()
	file.close()

	var parsed = JSON.parse_string(json_string)
	if parsed != null and parsed is Dictionary:
		save_data = parsed as Dictionary
		print("SaveManager: Data loaded successfully.")
	else:
		push_error("SaveManager: Failed to parse save data.")


## Saves current data to user://save_data.json
func save() -> void:
	var path := "user://save_data.json"
	var json_string := JSON.stringify(save_data)

	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("SaveManager: Failed to open save file for writing at %s" % path)
		return

	file.store_string(json_string)
	file.close()
	print("SaveManager: Data saved successfully.")


## Updates the current stage ID from GameManager
func update_stage_from_game_manager(stage_id: int) -> void:
	save_data["current_stage"] = stage_id
	save()


## Gets the player base stats from GameManager
func get_player_stats() -> Dictionary:
	if save_data.has("player_stats"):
		return save_data["player_stats"]
	return {}
