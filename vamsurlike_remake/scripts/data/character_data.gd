class_name CharacterData
extends Resource

## Data-driven definition of a playable knight character.
## One .tres per character in data/characters/ — logic lives in CharacterBody
## (scripts/player/character_body.gd), never hardcoded there.

@export var character_id: String = "female_knight"
@export var display_name: String = "White Knight"
@export var gender: String = "female"  # "female" | "male"

# Visual palette (quarter-view body)
@export var skin_color: Color = Color(0.96, 0.80, 0.66)
@export var hair_color: Color = Color(0.07, 0.06, 0.08)   # black
@export var armor_color: Color = Color(0.90, 0.92, 0.96)  # white/silver
@export var cape_color: Color = Color(0.14, 0.30, 0.85)    # blue cloak
@export var band_color: Color = Color(0.95, 0.95, 1.00)   # white circlet (female)
@export var helmet_color: Color = Color(0.09, 0.09, 0.11) # black full helmet (male)
@export var has_helmet: bool = false                       # male: full-face helmet
@export var side_locks: bool = true                        # female long hair locks

# Sword held at the figure's right edge
@export var sword_blade_color: Color = Color(0.95, 0.97, 1.00)   # white blade
@export var sword_guard_color: Color = Color(0.78, 0.80, 0.88)   # silver guard
