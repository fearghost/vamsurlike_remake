class_name StoryDirector
extends Node2D

## Manages story sequence execution, parsing JSON scripts and orchestrating
## actor movement, dialogue, and scene transitions.

signal sequence_finished
signal dialogue_started(text: String, speaker: String)
signal dialogue_ended
signal actor_moved(actor_name: String, target_pos: Vector2)

@export var actors: Dictionary = {}
@export_file("*.json") var script_file: String

var current_sequence: Array[Dictionary] = []
var sequence_index: int = 0
var is_running: bool = false


func _ready():
	if script_file.is_empty() == false:
		start_automatic_sequence()


func start_automatic_sequence() -> void:
	parse_script(script_file)
	is_running = true
	execute_next_step()


func parse_script(file_path: String) -> Array[Dictionary]:
	var file := FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		push_error("StoryDirector: Failed to open script file: %s" % file_path)
		return []

	var json_string := file.get_as_text()
	file.close()

	var parsed = JSON.parse_string(json_string)
	if parsed == null:
		push_error("StoryDirector: Failed to parse JSON from %s" % file_path)
		return []

	if typeof(parsed) != TYPE_ARRAY:
		push_error("StoryDirector: Expected JSON array at root")
		return []

	current_sequence = parsed
	return current_sequence


func execute_next_step() -> void:
	if sequence_index >= current_sequence.size():
		is_running = false
		emit_signal("sequence_finished")
		return

	var step := current_sequence[sequence_index]
	var action := step.get("action", "")

	match action:
		"move":
			_execute_move(step)
		"dialogue":
			_execute_dialogue(step)
		"transition":
			_execute_transition(step)
		_:
			push_warning("StoryDirector: Unknown action '%s' at step %d" % [action, sequence_index])
			_on_step_completed()


func _execute_move(step: Dictionary) -> void:
	var actor_name := step.get("actor", "")
	var waypoints := step.get("waypoints", [])

	if not actors.has(actor_name):
		push_warning("StoryDirector: Actor '%s' not found in actors dictionary" % actor_name)
		_on_step_completed()
		return

	var actor_node = actors[actor_name]
	if actor_node is Node2D:
		actor_moved.emit(actor_name, Vector2(waypoints[-1][0], waypoints[-1][1]))


func _execute_dialogue(step: Dictionary) -> void:
	var speaker := step.get("speaker", "")
	var text := step.get("text", "")

	dialogue_started.emit(text, speaker)


func _execute_transition(step: Dictionary) -> void:
	var target_scene := step.get("scene", "")
	if target_scene.is_empty():
		push_warning("StoryDirector: No scene specified in transition step")
		return

	# Transition is handled externally; signal completion
	_on_step_completed()


func _on_step_completed() -> void:
	sequence_index += 1
	execute_next_step()
