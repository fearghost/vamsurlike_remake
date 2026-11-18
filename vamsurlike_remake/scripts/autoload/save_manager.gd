class_name SaveManager
extends Node


## File path for the persistent save data (user:// is Godot's portable user dir).
const SAVE_PATH: String = "user://save_data.json"


## The current in-memory save data dictionary.
var save_data: Dictionary = {
	"current_stage": 1,
	"cleared_stages": [],
	"player_stats": {},
	"equipment": {},
	"skill_tree": {},
}


## Serializes [param save_data] to JSON and writes it to [param SAVE_PATH].
func save() -> void:
	var json_string: String = JSON.stringify(save_data)
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file != null:
		file.store_string(json_string)
		file.close()


## Reads the save file from [param SAVE_PATH], parses JSON, and populates [param save_data].
func load() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file != null:
		var json_string: String = file.get_as_text()
		file.close()

		var parse_result: Variant = JSON.parse_string(json_string)
		if parse_result is Dictionary:
			save_data = parse_result


## Removes the save file and resets [param save_data] to its default state.
func clear_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		FileAccess.remove(SAVE_PATH)

	save_data = {
		"current_stage": 1,
		"cleared_stages": [],
		"player_stats": {},
		"equipment": {},
		"skill_tree": {},
	}


## Returns true if a save file exists at [param SAVE_PATH].
func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)
