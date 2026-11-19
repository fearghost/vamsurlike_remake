extends Node


## AudioStreamPlayer used for background music.
var bgm_player: AudioStreamPlayer

## AudioStreamPlayer used for sound effects.
var sfx_player: AudioStreamPlayer


## Creates the underlying AudioStreamPlayer nodes and adds them as children.
## Nodes are created lazily on first use to avoid issues if audio server
## is not ready during autoload initialization (especially on mobile).
func _init_bgm_player() -> void:
	if bgm_player == null:
		bgm_player = AudioStreamPlayer.new()
		bgm_player.name = "BGMPlayer"
		add_child(bgm_player)


func _init_sfx_player() -> void:
	if sfx_player == null:
		sfx_player = AudioStreamPlayer.new()
		sfx_player.name = "SFXPlayer"
		add_child(sfx_player)


## Plays a background music [param stream]. Looping is enabled by default.
func play_bgm(stream: AudioStream, loop: bool = true) -> void:
	_init_bgm_player()
	bgm_player.stream = stream
	bgm_player.loop = loop
	bgm_player.play()


## Stops the current BGM. If [param fade_out] is greater than zero,
## the volume will be ramped down over the given number of seconds before stopping.
func stop_bgm(fade_out: float = 0.0) -> void:
	_init_bgm_player()
	if fade_out > 0.0:
		var original_volume: float = bgm_player.volume_db
		var steps: int = max(int(fade_out * 10), 1)
		var step_duration: float = fade_out / steps

		for i in range(steps):
			await get_tree().create_timer(step_duration).timeout
			bgm_player.volume_db = original_volume * (1.0 - float(i + 1) / steps)

	bgm_player.stop()
	bgm_player.volume_db = 0


## Plays a one-shot sound effect [param stream] on the SFX channel.
func play_sfx(stream: AudioStream) -> void:
	_init_sfx_player()
	sfx_player.stream = stream
	sfx_player.play()


## Sets the BGM volume to [param db] decibels.
func set_bgm_volume(db: float) -> void:
	_init_bgm_player()
	bgm_player.volume_db = db


## Sets the SFX volume to [param db] decibels.
func set_sfx_volume(db: float) -> void:
	_init_sfx_player()
	sfx_player.volume_db = db


## Mutes or unmutes both BGM and SFG channels when [param mute] is true/false.
func mute_all(mute: bool) -> void:
	_init_bgm_player()
	_init_sfx_player()
	bgm_player.volume_db = -80 if mute else 0
	sfx_player.volume_db = -80 if mute else 0
