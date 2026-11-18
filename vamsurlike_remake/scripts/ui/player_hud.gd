class_name PlayerHud
extends CanvasLayer


## HUD overlay showing player HP bar and current stage number.


@onready var hp_bar: TextureProgressBar = $HPBar
@onready var stage_label: Label = $StageLabel


func update_hp(current: int, max_hp_value: int) -> void:
	if hp_bar != null:
		hp_bar.max_value = max_hp_value
		hp_bar.value = current


func update_stage(stage_id: int) -> void:
	if stage_label != null:
		stage_label.text = "Stage: %d" % stage_id
