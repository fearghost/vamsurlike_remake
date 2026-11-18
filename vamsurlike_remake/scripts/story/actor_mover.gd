class_name ActorMover
extends Node2D

## Handles smooth waypoint-based movement for story actors using Tween.

@export var speed: float = 150.0

var waypoints: Array[Vector2] = []
var current_waypoint_index: int = 0

signal waypoint_reached


func set_waypoints(waypoints_array: Array[Vector2]) -> void:
	waypoints = waypoints_array
	current_waypoint_index = 0


func start_movement() -> void:
	if waypoints.is_empty():
		return

	var tween := create_tween()
	for i in range(1, waypoints.size()):
		var from_pos := waypoints[i - 1]
		var to_pos := waypoints[i]
		var distance := from_pos.distance_to(to_pos)
		var duration := distance / speed

		tween.tween_property(self, "position", to_pos, duration).set_ease(Tween.EASE_OUT_IN)

	await tween.finished
	_on_reached_waypoint()


func _on_reached_waypoint() -> void:
	current_waypoint_index += 1
	if current_waypoint_index < waypoints.size():
		waypoint_reached.emit()
	else:
		# All waypoints reached, movement complete
		pass
