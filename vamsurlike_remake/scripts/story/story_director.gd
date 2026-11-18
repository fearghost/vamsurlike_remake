class_name StoryDirector
extends Node2D

## Manages story sequence execution, parsing JSON scripts and orchestrating
## actor movement (Tween), dialogue display, and scene transitions.

signal sequence_finished
signal dialogue_started(text: String, speaker: String)
signal dialogue_ended
signal dialogue_completed
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

	var parsed: Variant = JSON.parse_string(json_string)
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
	var action: String = step.get("action", "")

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
	var actor_name: String = step.get("actor", "")
	var waypoints_raw: Array = step.get("waypoints", [])

	if not actors.has(actor_name):
		push_warning("StoryDirector: Actor '%s' not found in actors dictionary" % actor_name)
		_on_step_completed()
		return

	var actor_node = actors[actor_name]
	if not actor_node is Node2D:
		push_warning("StoryDirector: Actor '%s' is not a Node2D" % actor_name)
		_on_step_completed()
		return

	# Convert JSON arrays [x, y] to Vector2
	var waypoints: Array[Vector2] = []
	for wp in waypoints_raw:
		if wp is Array and wp.size() >= 2:
			waypoints.append(Vector2(wp[0], wp[1]))

	if waypoints.is_empty():
		actor_moved.emit(actor_name, actor_node.position)
		_on_step_completed()
		return

	# Tween between consecutive waypoints
	var tween := create_tween()
	tween.set_ease(Tween.EASE_OUT_IN)
	for i in range(waypoints.size() - 1):
		var from_pos := waypoints[i]
		var to_pos := waypoints[i + 1]
		var distance := from_pos.distance_to(to_pos)
		var duration := distance / 150.0
		tween.tween_property(actor_node, "position", to_pos, duration)

	await tween.finished

	actor_moved.emit(actor_name, waypoints[-1])
	_on_step_completed()


func _execute_dialogue(step: Dictionary) -> void:
	var speaker: String = step.get("speaker", "")
	var text: String = step.get("text", "")

	dialogue_started.emit(text, speaker)

	await dialogue_completed

	_on_step_completed()


func _execute_transition(step: Dictionary) -> void:
	var target_scene: String = step.get("scene", "")
	if target_scene.is_empty():
		push_warning("StoryDirector: No scene specified in transition step")
		_on_step_completed()
		return

	# Build full path if only filename was given
	var full_path: String = target_scene
	if not full_path.begins_with("res://"):
		full_path = "res://scenes/game/%s" % target_scene

	var st := get_node_or_null("/root/SceneTransition")
	if st != null:
		st.transition_to_scene(full_path)


func _on_step_completed() -> void:
	sequence_index += 1
	execute_next_step()
