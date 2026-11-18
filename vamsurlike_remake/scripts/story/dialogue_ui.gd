class_name DialogueUI
extends CanvasLayer


## Displays dialogue text at the bottom 30% of the screen.
## Connected to StoryDirector.signals for show/hide lifecycle.

@onready var speaker_label: Label = $SpeakerLabel
@onready var text_label: Label = $TextLabel
@onready var continue_button: Button = $ContinueButton
@onready var background: ColorRect = $Background

var is_displaying: bool = false

signal dialogue_completed


func _ready() -> void:
	hide_dialogue()
	continue_button.pressed.connect(_on_continue_button_pressed)


func show_dialogue(speaker: String, text: String) -> void:
	speaker_label.text = speaker
	text_label.text = text
	is_displaying = true
	visible = true


func hide_dialogue() -> void:
	is_displaying = false
	visible = false


func _on_continue_button_pressed() -> void:
	hide_dialogue()
	dialogue_completed.emit()
