# Genesis 2 Remake (Vamsurlike) — Project Instructions

**Godot 4.3** Soulslike survival game. Current state: **documentation only** — no code, no git, no project files exist yet. All specs are in `doc/`.

## What to do first

1. Read `genesis2_remake.md` for the full design doc (architecture, systems, CI spec).
2. Read `doc/phase_roadmap.md` for the 3-phase development plan.
3. Work through sub-phases in `doc/subphase/` in order (1-1 → 1-6 → 2-1 → … → 3-9).

## Target project structure

```
vamsurlike_remake/
├── .github/workflows/android_build.yml   # CI: godot --headless --export-debug "Android"
├── assets/{sprites,ui,audio}/
├── data/{characters,enemies,items,skills,stages}/   # .tres or .json
├── scenes/{common,ui,game,story}/
├── scripts/{autoload,player,enemy,item,skill,story}/
├── export_presets.cfg
└── project.godot
```

## Key systems (from design doc)

| System | File | Notes |
|--------|------|-------|
| GameManager | `scripts/autoload/game_manager.gd` | GameState enum: MAIN_MENU → STORY_SCENE → COMBAT → UPGRADE → PAUSE |
| StoryDirector | `scripts/story/story_director.gd` | Quarter-view auto-movement + dialogue sequence from JSON script |
| EquipmentManager | `scripts/item/equipment_manager.gd` | 8 slots; two-handed weapon ↔ shield mutual exclusion |
| PoolManager | `scripts/autoload/pool_manager.gd` | Object pooling for projectiles, enemies, effects |
| SaveManager | `scripts/autoload/save_manager.gd` | JSON serialization to `user://save_data.json` |
| SoundManager | `scripts/autoload/sound_manager.gd` | BGM/SFX playback, volume control |

## Build & deploy

- **Engine**: Godot 4.3 (use `godot --headless --export-debug "Android" <path>` for CLI builds)
- **CI**: `.github/workflows/android_build.yml` — uses `barichello/godot-ci:4.3-stable` container, generates debug keystore via `keytool`, uploads APK as artifact
- **Viewport**: 1280×720 landscape, `stretch/mode="canvas_items"`, `stretch/aspect="keep"`

## Pitfalls

- **No code exists yet** — every file must be created from scratch following the sub-phase docs. Do not invent architecture; follow `genesis2_remake.md` sections 4.x exactly.
- **GDScript only** — this is a Godot project, not Android/Java/Kotlin. Use `.gd` files with `extends Node`, `extends Node2D`, `class_name`, etc.
- **Data-driven design** — all entities (characters, enemies, skills, equipment) must be defined as `Resource` classes or JSON in `data/`. Logic and data are strictly separated.
- **Two-handed weapon ↔ shield constraint**: equipping a two-handed weapon auto-unequips the shield; equipping a shield rejects if a two-handed weapon is already equipped. Implement this in `EquipmentManager.equip_item()`.
- **Save path**: always use `user://save_data.json` (not a hardcoded path).
- **Mobile input**: VirtualJoystick is mandatory — all player movement must go through it, not keyboard input.
