class_name ActorMover
extends Node2D

## Handles smooth waypoint-based movement for a target actor using Tween.

@export var speed: float = 150.0

var target: Node2D = null
var waypoints: Array[Vector2] = []
var current_waypoint_index: int = 0

signal waypoint_reached
signal completed


func set_target(node: Node2D) -> void:
	target = node


func set_waypoints(waypoints_array: Array[Vector2]) -> void:
	waypoints = waypoints_array
	current_waypoint_index = 0


func start_movement() -> void:
	if target == null or waypoints.is_empty():
		completed.emit()
		return

	var tween := create_tween()
	tween.set_ease(Tween.EASE_OUT_IN)
	for i in range(1, waypoints.size()):
		var from_pos := waypoints[i - 1]
		var to_pos := waypoints[i]
		var distance := from_pos.distance_to(to_pos)
		var duration := distance / speed

		tween.tween_property(target, "position", to_pos, duration)

	await tween.finished
	completed.emit()
