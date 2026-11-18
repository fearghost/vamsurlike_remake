extends Node


## GameState enum representing the current game mode.
enum GameState {
	MAIN_MENU,
	STORY_SCENE,
	COMBAT,
	UPGRADE,
	PAUSE,
}


## Emitted whenever the game state transitions to a new value.
signal state_changed(new_state: GameState)


## The currently active game state.
var current_state: GameState = GameState.MAIN_MENU

## Identifier for the stage the player is currently on.
var current_stage_id: int = 1

## Base statistics for the player character.
## These values are used as defaults and can be modified by equipment/skills.
var player_base_stats: Dictionary = {
	"hp": 100,
	"max_hp": 100,
	"attack": 10,
	"defense": 5,
	"speed": 200.0,
}


## Transitions the game to a new state.
## Emits [param state_changed] with the new state value.
func change_state(new_state: GameState) -> void:
	current_state = new_state
	state_changed.emit(new_state)


## Resets the game back to its initial MAIN_MENU state,
## clears current stage, and restores player base stats.
func reset_game() -> void:
	current_state = GameState.MAIN_MENU
	current_stage_id = 1
	player_base_stats = {
		"hp": 100,
		"max_hp": 100,
		"attack": 10,
		"defense": 5,
		"speed": 200.0,
	}
	state_changed.emit(GameState.MAIN_MENU)


## Returns a reference to the player base stats dictionary.
func get_player_stats() -> Dictionary:
	return player_base_stats
