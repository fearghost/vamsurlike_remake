class_name SkillSelect
extends CanvasLayer


## Level-up overlay: shows 3 random skill choices and applies the picked one.
## The tree is paused by the caller while this is visible; buttons still fire
## while paused (standard pause-menu pattern). All UI nodes are built in code
## so no scene file needs to be kept in sync with the layout.

signal skill_chosen(skill_id: String)

const SKILLS := [
	{"id": "extra_projectile", "name": "Extra Projectile", "desc": "+1 attack projectile, spread evenly across 360°"},
	{"id": "attack_up", "name": "Attack Up", "desc": "+5 attack power"},
	{"id": "heal", "name": "Energy Restore", "desc": "Restore HP to full"},
	{"id": "range_up", "name": "Long Range", "desc": "+80 attack range"},
	{"id": "speed_up", "name": "Swift Boots", "desc": "+25 move speed"},
	{"id": "orbit_projectile", "name": "Orbital Blade", "desc": "A blade circles you for 5s dealing collision damage; re-fires after a cooldown. Each pick adds one blade."},
]

var _buttons: Array[Button] = []
var _choices: Array = []


func _ready() -> void:
	visible = false
	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 0.75)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var center := VBoxContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_theme_constant_override("separation", 16)
	add_child(center)
	var title := Label.new()
	title.text = "LEVEL UP!"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	title.add_theme_font_size_override("font_size", 40)
	title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	center.add_child(title)
	for i in range(3):
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(440, 72)
		btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		btn.autowrap_mode = TextServer.AUTOWRAP_WORD
		btn.add_theme_font_size_override("font_size", 18)
		var normal := StyleBoxFlat.new()
		normal.bg_color = Color(0.16, 0.2, 0.28)
		normal.set_corner_radius_all(8)
		normal.content_margin_left = 12
		normal.content_margin_right = 12
		normal.content_margin_top = 10
		normal.content_margin_bottom = 10
		var hover := normal.duplicate() as StyleBoxFlat
		hover.bg_color = Color(0.28, 0.36, 0.5)
		btn.add_theme_stylebox_override("normal", normal)
		btn.add_theme_stylebox_override("hover", hover)
		btn.add_theme_color_override("font_color", Color(0.95, 0.95, 0.98))
		btn.pressed.connect(_on_choice_pressed.bind(i))
		center.add_child(btn)
		_buttons.append(btn)


func open() -> void:
	var pool := SKILLS.duplicate()
	pool.shuffle()
	_choices = pool.slice(0, 3)
	for i in range(3):
		var skill = _choices[i]
		_buttons[i].text = "%s\n%s" % [skill["name"], skill["desc"]]
	visible = true


func close() -> void:
	visible = false


func _on_choice_pressed(index: int) -> void:
	if index < 0 or index >= _choices.size():
		return
	var skill = _choices[index]
	close()
	_apply_skill(skill["id"])
	skill_chosen.emit(skill["id"])


func _apply_skill(skill_id: String) -> void:
	var player := get_tree().get_first_node_in_group("player") as PlayerController
	if player == null or not is_instance_valid(player):
		return
	var auto_attack := player.auto_attack
	var stats := player.player_stats as PlayerStats
	match skill_id:
		"extra_projectile":
			if auto_attack != null:
				auto_attack.extra_shots += 1
		"attack_up":
			if stats != null:
				stats.attack += 5
			if auto_attack != null and stats != null:
				auto_attack.sync_damage(stats.attack)
		"heal":
			if stats != null:
				stats.heal(stats.max_hp)
		"range_up":
			if auto_attack != null:
				auto_attack.attack_range += 80.0
		"speed_up":
			player.move_speed += 25.0
		"orbit_projectile":
			if auto_attack != null:
				auto_attack.add_orbit()
