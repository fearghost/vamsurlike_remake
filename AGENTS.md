# Genesis 2 Remake (Vamsurlike) — Project Instructions

**Godot 4.3** Soulslike survival game. Phase 1 code exists and runs in CI; specs are in `doc/`. The Godot project lives in the `vamsurlike_remake/` subdirectory (repo root holds docs, CI workflows, and this file).

## What to do first

1. Read `genesis2_remake.md` for the full design doc (architecture, systems, CI spec).
2. Read `doc/phase_roadmap.md` for the 3-phase development plan.
3. Work through sub-phases in `doc/subphase/` in order (1-1 → 1-6 → 2-1 → … → 3-9).

## Build & test — GitHub Actions only

**All builds and tests run through GitHub Actions, never locally.** Do not attempt local `godot --headless` runs or local APK exports; validate via CI instead.

Workflow: push to origin (main/master) → check results with `gh` → debug until both pass:

```sh
git push origin main
gh run list --limit 5                     # find the workflow runs for this push
gh run watch <run-id>                     # or poll: gh run view <run-id> --log-failed
```

Both of these must pass before work is considered done:
- `Headless Smoke Test` (`.github/workflows/smoke_test.yml`) — import + probe + smoke test
- `Android Build` (`.github/workflows/android_build.yml`) — APK build, keystore, apksigner sign, artifact upload

If either fails: read the failing log with `gh run view <run-id> --log-failed`, fix the root cause in the repo, push again, and re-check. Do not declare done while CI is red.

## Target project structure

```
vamsurlike_remake/          # the actual Godot project root
├── assets/{sprites,ui,audio}/
├── data/{characters,enemies,items,skills,stages}/   # .tres or .json
├── scenes/{common,ui,game,story}/
├── scripts/{autoload,player,enemy,item,skill,story}/
├── tests/                  # smoke_test.gd (SceneTree script) + _probe.gd
├── export_presets.cfg
└── project.godot
```
(`.github/workflows/` lives at the repo root, not inside `vamsurlike_remake/`.)

## Key systems (from design doc)

| System | File | Notes |
|--------|------|-------|
| GameManager | `scripts/autoload/game_manager.gd` | GameState enum: MAIN_MENU → STORY_SCENE → COMBAT → UPGRADE → PAUSE (autoload) |
| StoryDirector | `scripts/story/story_director.gd` | Quarter-view auto-movement + dialogue sequence from JSON script |
| EquipmentManager | `scripts/item/equipment_manager.gd` | 8 slots; two-handed weapon ↔ shield mutual exclusion (not yet implemented) |
| PoolManager | `scripts/autoload/pool_manager.gd` | Object pooling for projectiles, enemies, effects (autoload) |
| SaveManager | `scripts/autoload/save_manager.gd` | JSON serialization to `user://save_data.json` (autoload) |
| SoundManager | `scripts/autoload/sound_manager.gd` | BGM/SFX playback, volume control (autoload) |

Autoloads registered in `project.godot`: GameManager, SaveManager, PoolManager, SoundManager, SceneTransition (`scripts/story/scene_transition.gd`).

## Build & deploy notes

- **Engine**: Godot 4.3. CI downloads the CLI binary directly from GitHub releases and export templates to `~/.local/share/godot/export_templates/4.3.stable/` (not a container).
- **Viewport**: 1280×720 landscape, `stretch/mode="canvas_items"`, `stretch/aspect="keep"`. Renderer: mobile / gl_compatibility. Main scene: `res://scenes/ui/main_menu.tscn`.
- **Input**: movement actions (move_left/right/up/down) are declared in project.godot but intentionally empty — VirtualJoystick drives player input, not keyboard.

## Pitfalls

- **GDScript only** — this is a Godot project, not Android/Java/Kotlin. Use `.gd` files with `extends Node`, `extends Node2D`, `class_name`, etc.
- **Data-driven design** — all entities (characters, enemies, skills, equipment) must be defined as `Resource` classes or JSON in `data/`. Logic and data are strictly separated.
- **Two-handed weapon ↔ shield constraint**: equipping a two-handed weapon auto-unequips the shield; equipping a shield rejects if a two-handed weapon is already equipped. Implement this in `EquipmentManager.equip_item()` (Phase 2).
- **Save path**: always use `user://save_data.json` (not a hardcoded path).
- **Mobile input**: VirtualJoystick is mandatory — all player movement must go through it, not keyboard input.
- **Smoke test is the verification gate** — CI fails on any script parse error or scene load failure; keep `tests/smoke_test.gd` green. `tests/_probe.gd` is a focused diagnostic probe (input/combat) used for debugging, not a pass/fail gate.
- **Do not hand-edit generated files**: `.godot/` cache and `build/android/*.apk` are build artifacts; regenerate via CI, never commit them.
