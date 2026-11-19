class_name VirtualJoystick
extends Control


## Virtual on-screen joystick for mobile touch input.
## Touch anywhere on the lower screen area to activate; drag to control direction.


signal value_changed(direction: Vector2)

@export var base_radius: float = 80.0
@export var max_radius: float = 50.0
@export var base_color: Color = Color(0.3, 0.3, 0.3, 0.5)
@export var stick_color: Color = Color(0.6, 0.6, 0.6, 0.7)

var base_position: Vector2 = Vector2.ZERO
var stick_position: Vector2 = Vector2.ZERO
var is_active: bool = false
var touch_id: int = -1


func _ready() -> void:
	# Position joystick in the lower-left area of the screen (150, 550)
	position = Vector2(150.0, 550.0)
	# Base center is at local offset (60, 60) → screen (210, 610)
	base_position = Vector2(60.0, 60.0)
	stick_position = base_position
	queue_redraw()
	grab_focus()


func gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and touch_id == -1:
			# Only activate if touch is in the lower half of the screen
			var local_pos: Vector2 = event.position - position
			if local_pos.y > size.y * 0.4:
				touch_id = event.index
				is_active = true
				base_position = event.position
				stick_position = base_position
				queue_redraw()
				value_changed.emit(Vector2.ZERO)

		elif not event.pressed and event.index == touch_id:
			reset_joystick()

	elif event is InputEventScreenDrag:
		if event.index == touch_id and is_active:
			var delta: Vector2 = event.position - base_position
			var distance: float = delta.length()
			if distance > max_radius:
				delta = delta.normalized() * max_radius
			stick_position = base_position + delta
			queue_redraw()
			value_changed.emit(delta / max_radius)


func reset_joystick() -> void:
	is_active = false
	touch_id = -1
	stick_position = base_position
	value_changed.emit(Vector2.ZERO)
	queue_redraw()


func get_direction() -> Vector2:
	if not is_active:
		return Vector2.ZERO
	var delta: Vector2 = stick_position - base_position
	return (delta / max_radius).limit_length(1.0)


func _process(_delta: float) -> void:
	# Visual update handled by _draw() via queue_redraw()
	pass


func _draw() -> void:
	# Draw the outer base circle
	draw_circle(base_position, base_radius, base_color)

	# Draw the inner stick circle
	var delta: Vector2 = stick_position - base_position
	draw_circle(stick_position, max_radius * 0.6, stick_color)
