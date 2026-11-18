## StoryDemo controller — sets up actors and connects them to the StoryDirector.
extends Node2D


@onready var story_director: StoryDirector = $StoryDirector as StoryDirector
@onready var actor1: Node2D = $Actor1
@onready var actor2: Node2D = $Actor2
@onready var dialogue_ui: Node = $DialogueUI as Node


func _ready() -> void:
	# Register actors with the StoryDirector
	story_director.actors = {
		"G.S": actor1,
		"Iolin": actor2,
	}

	# Connect dialogue signals to UI
	story_director.dialogue_started.connect(dialogue_ui.show_dialogue)
	dialogue_ui.dialogue_completed.connect(story_director.emit_signal.bind("dialogue_completed"))

	# Connect sequence finished to scene transition
	story_director.sequence_finished.connect(_on_sequence_finished)


func _on_sequence_finished() -> void:
	print("Story sequence finished. Transitioning to combat.")
	SceneTransition.transition_to_combat()
