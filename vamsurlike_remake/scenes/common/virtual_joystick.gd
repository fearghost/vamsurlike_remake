class_name VirtualJoystick
extends Control


## Full-screen touch layer for mobile movement input (floating joystick).
## Touch and drag anywhere on screen to move — the base appears under your
## finger. Emits value_changed with a normalized direction vector
## (-1..1 per axis), or Vector2.ZERO when released.
##
## The scene must give this Control full-rect anchors so touches anywhere
## are received (a small fixed-size rect was the old "joystick invisible /
## character doesn't move" bug).

signal value_changed(direction: Vector2)

@export var max_radius: float = 60.0
@export var base_color: Color = Color(1.0, 1.0, 1.0, 0.25)
@export var stick_color: Color = Color(1.0, 1.0, 1.0, 0.5)

var is_active: bool = false
var touch_id: int = -1
var base_position: Vector2 = Vector2.ZERO
var stick_position: Vector2 = Vector2.ZERO


func _ready() -> void:
	# Consume touches so they reach this control (display-only HUD controls
	# use MOUSE_FILTER_IGNORE and are unaffected).
	mouse_filter = Control.MOUSE_FILTER_STOP
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	# NOTE: gui_input events already carry LOCAL coordinates — do not subtract
	# the node position again (that was the old broken math).
	if event is InputEventScreenTouch:
		if event.pressed and touch_id == -1:
			touch_id = event.index
			is_active = true
			base_position = event.position
			stick_position = base_position
			value_changed.emit(Vector2.ZERO)
		elif not event.pressed and event.index == touch_id:
			_release()
	elif event is InputEventScreenDrag:
		if event.index == touch_id and is_active:
			var delta: Vector2 = event.position - base_position
			if delta.length() > max_radius:
				delta = delta.normalized() * max_radius
			stick_position = base_position + delta
			value_changed.emit((delta / max_radius).limit_length(1.0))
	queue_redraw()


func _release() -> void:
	is_active = false
	touch_id = -1
	stick_position = base_position
	value_changed.emit(Vector2.ZERO)
	queue_redraw()


func get_direction() -> Vector2:
	if not is_active:
		return Vector2.ZERO
	return ((stick_position - base_position) / max_radius).limit_length(1.0)


func _draw() -> void:
	if is_active:
		# Joystick under the finger
		draw_circle(base_position, max_radius, base_color)
		draw_circle(stick_position, max_radius * 0.5, stick_color)
	else:
		# Idle hint in the lower-left so players know where to touch.
		var hint := Vector2(140.0, size.y - 140.0)
		draw_circle(hint, max_radius, base_color)
		draw_circle(hint, max_radius * 0.5, stick_color)
