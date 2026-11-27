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


# --- Synthesized SFX (no audio assets shipped with the project) -------------
# Short procedural streams generated once and cached; keeps every sound free of
# binary asset dependencies while still reading clearly as "shoot" / "hit".
var _shoot_stream: AudioStreamWAV = null
var _hit_stream: AudioStreamWAV = null
var _last_shoot_time := -1.0
var _last_hit_time := -1.0


## Plays a short "projectile fired" blip (rate-limited to avoid clipping when
## multi-shot waves spawn several shots in the same frame).
func play_shoot() -> void:
	var now := Time.get_ticks_msec() / 1000.0
	if now - _last_shoot_time < 0.05:
		return
	_last_shoot_time = now
	if _shoot_stream == null:
		_shoot_stream = _build_shoot_stream()
	play_sfx(_shoot_stream)


## Plays a short "enemy hit" thud (rate-limited for the same reason).
func play_hit() -> void:
	var now := Time.get_ticks_msec() / 1000.0
	if now - _last_hit_time < 0.05:
		return
	_last_hit_time = now
	if _hit_stream == null:
		_hit_stream = _build_hit_stream()
	play_sfx(_hit_stream)


func _build_shoot_stream() -> AudioStreamWAV:
	var rate := 44100
	var dur := 0.10
	var n := int(rate * dur)
	var data := PackedByteArray()
	data.resize(n * 2)
	var phase := 0.0
	for i in range(n):
		var t := float(i) / rate
		var freq := lerpf(920.0, 240.0, t / dur)
		phase += TAU * freq / rate
		var env := pow(1.0 - t / dur, 1.6)
		var sample := sin(phase) * env
		var u := int(sample * 26000.0) & 0xFFFF
		data[i * 2] = u & 0xFF
		data[i * 2 + 1] = (u >> 8) & 0xFF
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = rate
	stream.stereo = false
	stream.data = data
	return stream


func _build_hit_stream() -> AudioStreamWAV:
	var rate := 44100
	var dur := 0.14
	var n := int(rate * dur)
	var data := PackedByteArray()
	data.resize(n * 2)
	var lp := 0.0
	for i in range(n):
		var t := float(i) / rate
		var env := exp(-t * 18.0)
		var noise := randf() * 2.0 - 1.0
		lp = lp * 0.55 + noise * 0.45   # one-pole lowpass — soft thud, not static
		var thump := sin(TAU * 130.0 * t) * exp(-t * 26.0)
		var sample := clampf((lp * 1.4 + thump * 0.9) * env, -1.0, 1.0)
		var u := int(sample * 24000.0) & 0xFFFF
		data[i * 2] = u & 0xFF
		data[i * 2 + 1] = (u >> 8) & 0xFF
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = rate
	stream.stereo = false
	stream.data = data
	return stream
