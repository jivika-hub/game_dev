extends Node

## AudioManager autoload providing seamless looping ambient & music beds
## and pooled 2D/UI/footstep SFX playback using procedural placeholder WAVs.

const AUDIO_PATHS: Dictionary = {
	"wind_dust": "res://assets/audio/wind_dust_loop.wav",
	"earth_theme": "res://assets/audio/earth_theme_loop.wav",
	"launch_rumble": "res://assets/audio/launch_rumble.wav",
	"cosmic_entity": "res://assets/audio/cosmic_entity_loop.wav",
	"market_ambient": "res://assets/audio/market_ambient_loop.wav",
	"footstep_dirt": "res://assets/audio/footstep_dirt.wav",
	"footstep_metal": "res://assets/audio/footstep_metal.wav",
	"ui_chime": "res://assets/audio/ui_chime.wav",
	"interact_click": "res://assets/audio/interact_click.wav",
	"puzzle_lock": "res://assets/audio/puzzle_lock.wav"
}

var _music_player: AudioStreamPlayer
var _ambient_player: AudioStreamPlayer
var _sfx_pool: Array[AudioStreamPlayer] = []
var _stream_cache: Dictionary = {}

var _current_music_key: String = ""
var _current_ambient_key: String = ""
var _music_looping: bool = false
var _ambient_looping: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	_music_player = AudioStreamPlayer.new()
	_music_player.name = "MusicPlayer"
	_music_player.volume_db = -8.0
	add_child(_music_player)
	_music_player.finished.connect(_on_music_finished)

	_ambient_player = AudioStreamPlayer.new()
	_ambient_player.name = "AmbientPlayer"
	_ambient_player.volume_db = -10.0
	add_child(_ambient_player)
	_ambient_player.finished.connect(_on_ambient_finished)

	for i in range(6):
		var sfx := AudioStreamPlayer.new()
		sfx.name = "SFXPlayer_%d" % i
		add_child(sfx)
		_sfx_pool.append(sfx)


func _load_stream(key: String) -> AudioStream:
	if _stream_cache.has(key):
		return _stream_cache[key]
	if not AUDIO_PATHS.has(key):
		return null
	var path: String = AUDIO_PATHS[key]
	if not ResourceLoader.exists(path):
		return null
	var stream := load(path) as AudioStream
	if stream != null:
		_stream_cache[key] = stream
	return stream


func play_music(key: String, target_db: float = -8.0, fade_time: float = 1.6) -> void:
	if key == _current_music_key and _music_player.playing:
		return
	var stream: AudioStream = _load_stream(key)
	if stream == null:
		return
	_current_music_key = key
	_music_looping = true
	_music_player.stream = stream
	_music_player.volume_db = -40.0
	_music_player.play()
	var tw := create_tween()
	tw.tween_property(_music_player, "volume_db", target_db, fade_time)


func stop_music(fade_time: float = 1.2) -> void:
	_music_looping = false
	_current_music_key = ""
	if not _music_player.playing:
		return
	var tw := create_tween()
	tw.tween_property(_music_player, "volume_db", -42.0, fade_time)
	tw.tween_callback(_music_player.stop)


func play_ambient(key: String, target_db: float = -10.0, fade_time: float = 1.4) -> void:
	if key == _current_ambient_key and _ambient_player.playing:
		return
	var stream: AudioStream = _load_stream(key)
	if stream == null:
		return
	_current_ambient_key = key
	_ambient_looping = true
	_ambient_player.stream = stream
	_ambient_player.volume_db = -40.0
	_ambient_player.play()
	var tw := create_tween()
	tw.tween_property(_ambient_player, "volume_db", target_db, fade_time)


func set_ambient_volume(target_db: float, fade_time: float = 0.8) -> void:
	if not _ambient_player.playing:
		return
	var tw := create_tween()
	tw.tween_property(_ambient_player, "volume_db", target_db, fade_time)


func stop_ambient(fade_time: float = 1.0) -> void:
	_ambient_looping = false
	_current_ambient_key = ""
	if not _ambient_player.playing:
		return
	var tw := create_tween()
	tw.tween_property(_ambient_player, "volume_db", -42.0, fade_time)
	tw.tween_callback(_ambient_player.stop)


func play_sfx(key: String, volume_db: float = -4.0, pitch_scale: float = 1.0) -> void:
	var stream: AudioStream = _load_stream(key)
	if stream == null:
		return
	var player: AudioStreamPlayer = _get_free_sfx_player()
	player.stream = stream
	player.volume_db = volume_db
	player.pitch_scale = pitch_scale
	player.play()


func play_footstep(is_metal: bool = false) -> void:
	var key: String = "footstep_metal" if is_metal else "footstep_dirt"
	var pitch: float = randf_range(0.90, 1.12)
	play_sfx(key, -11.0, pitch)


func _get_free_sfx_player() -> AudioStreamPlayer:
	for p in _sfx_pool:
		if not p.playing:
			return p
	return _sfx_pool[0]


func _on_music_finished() -> void:
	if _music_looping and _music_player.stream != null:
		_music_player.play()


func _on_ambient_finished() -> void:
	if _ambient_looping and _ambient_player.stream != null:
		_ambient_player.play()
