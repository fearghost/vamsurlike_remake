extends CanvasLayer

## Character selection screen — picks one of two knights before combat starts.
## Each card shows a live quarter-view preview (same drawing path as the in-game body).

@onready var preview_female: Node2D = $PreviewFemale
@onready var preview_male: Node2D = $PreviewMale
@onready var female_button: Button = $FemaleSelectButton
@onready var male_button: Button = $MaleSelectButton
@onready var back_button: Button = $BackButton


func _ready() -> void:
	_build_preview(preview_female, "female_knight")
	_build_preview(preview_male, "male_knight")
	female_button.pressed.connect(func(): _on_select("female_knight"))
	male_button.pressed.connect(func(): _on_select("male_knight"))
	back_button.pressed.connect(_on_back_pressed)


func _build_preview(node: Node2D, character_id: String) -> void:
	if node == null or not is_instance_valid(node):
		push_error("[CharacterSelect] preview node missing for %s" % character_id)
		return
	var body_script := load("res://scripts/player/character_body.gd") as Script
	if body_script == null:
		push_error("[CharacterSelect] failed to load character_body.gd — no preview for %s" % character_id)
		return
	var data = load("res://data/characters/%s.tres" % character_id) as CharacterData
	if data == null:
		push_error("[CharacterSelect] character '%s' missing — preview will fall back to female knight" % character_id)
	var body  # untyped — dynamic dispatch to the attached CharacterBody script
	body = Node2D.new()
	body.set_script(body_script)
	body.name = "CharacterBody"
	body.setup(data)
	node.add_child(body)


func _on_select(character_id: String) -> void:
	print("[CharacterSelect] selected %s" % character_id)
	var gm := get_node_or_null("/root/GameManager")
	if gm != null and gm.has_method("set_selected_character"):
		gm.set_selected_character(character_id)
	var scene := load("res://scenes/game/combat_demo.tscn") as PackedScene
	if scene == null:
		push_error("[CharacterSelect] FAILED to load combat scene")
		return
	get_tree().change_scene_to_packed(scene)


func _on_back_pressed() -> void:
	var scene := load("res://scenes/ui/main_menu.tscn") as PackedScene
	if scene == null:
		push_error("[CharacterSelect] FAILED to load main menu scene")
		return
	get_tree().change_scene_to_packed(scene)
