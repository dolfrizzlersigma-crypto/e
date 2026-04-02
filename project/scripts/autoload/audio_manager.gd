## AudioManager - Handles audio playback for ambience, SFX, music, and voice.
## Provides spatial audio zones and dynamic audio mixing.
extends Node

# --- Audio Bus Names ---
const BUS_MASTER := "Master"
const BUS_SFX := "SFX"
const BUS_AMBIENCE := "Ambience"
const BUS_MUSIC := "Music"
const BUS_VOICE := "Voice"
const BUS_RADIO := "Radio"

# --- Active Audio ---
var _sfx_players: Array[AudioStreamPlayer] = []
var _ambience_player: AudioStreamPlayer = null
var _music_player: AudioStreamPlayer = null
var _radio_player: AudioStreamPlayer = null

# --- Settings ---
var master_volume: float = 1.0
var sfx_volume: float = 1.0
var ambience_volume: float = 1.0
var music_volume: float = 1.0

const MAX_SFX_PLAYERS: int = 16


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_audio_players()


## Play a one-shot sound effect.
func play_sfx(stream: AudioStream, volume_db: float = 0.0, pitch: float = 1.0) -> void:
	var player := _get_available_sfx_player()
	if player:
		player.stream = stream
		player.volume_db = volume_db
		player.pitch_scale = pitch
		player.play()


## Play ambient background audio with crossfade.
func play_ambience(stream: AudioStream, fade_time: float = 2.0) -> void:
	if _ambience_player.playing:
		var tween := create_tween()
		tween.tween_property(_ambience_player, "volume_db", -40.0, fade_time)
		tween.tween_callback(func():
			_ambience_player.stream = stream
			_ambience_player.volume_db = 0.0
			_ambience_player.play()
		)
	else:
		_ambience_player.stream = stream
		_ambience_player.play()


## Stop ambient audio.
func stop_ambience(fade_time: float = 2.0) -> void:
	if _ambience_player.playing:
		var tween := create_tween()
		tween.tween_property(_ambience_player, "volume_db", -40.0, fade_time)
		tween.tween_callback(_ambience_player.stop)


## Play music track.
func play_music(stream: AudioStream, volume_db: float = -10.0, fade_time: float = 3.0) -> void:
	if _music_player.playing:
		var tween := create_tween()
		tween.tween_property(_music_player, "volume_db", -40.0, fade_time * 0.5)
		tween.tween_callback(func():
			_music_player.stream = stream
			_music_player.volume_db = volume_db
			_music_player.play()
		)
	else:
		_music_player.stream = stream
		_music_player.volume_db = volume_db
		_music_player.play()


## Stop music.
func stop_music(fade_time: float = 3.0) -> void:
	if _music_player.playing:
		var tween := create_tween()
		tween.tween_property(_music_player, "volume_db", -40.0, fade_time)
		tween.tween_callback(_music_player.stop)


## Play a radio transmission sound.
func play_radio(stream: AudioStream, volume_db: float = -5.0) -> void:
	_radio_player.stream = stream
	_radio_player.volume_db = volume_db
	_radio_player.play()


## Stop radio audio.
func stop_radio() -> void:
	_radio_player.stop()


# --- Private ---

func _setup_audio_players() -> void:
	_ambience_player = AudioStreamPlayer.new()
	_ambience_player.bus = BUS_AMBIENCE if AudioServer.get_bus_index(BUS_AMBIENCE) >= 0 else BUS_MASTER
	add_child(_ambience_player)

	_music_player = AudioStreamPlayer.new()
	_music_player.bus = BUS_MUSIC if AudioServer.get_bus_index(BUS_MUSIC) >= 0 else BUS_MASTER
	add_child(_music_player)

	_radio_player = AudioStreamPlayer.new()
	_radio_player.bus = BUS_RADIO if AudioServer.get_bus_index(BUS_RADIO) >= 0 else BUS_MASTER
	add_child(_radio_player)

	for i in MAX_SFX_PLAYERS:
		var player := AudioStreamPlayer.new()
		player.bus = BUS_SFX if AudioServer.get_bus_index(BUS_SFX) >= 0 else BUS_MASTER
		add_child(player)
		_sfx_players.append(player)


func _get_available_sfx_player() -> AudioStreamPlayer:
	for player in _sfx_players:
		if not player.playing:
			return player
	# All busy - reuse the first one
	return _sfx_players[0] if _sfx_players.size() > 0 else null
