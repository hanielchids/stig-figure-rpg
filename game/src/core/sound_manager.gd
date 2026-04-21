## Global sound manager. Plays SFX and manages audio.
## Access via the SoundManager autoload singleton.
##
## To add sounds: place .wav or .ogg files in assets/sounds/
## then call SoundManager.play_sfx("gunshot") where "gunshot"
## matches a file named gunshot.wav or gunshot.ogg
extends Node

var _sfx_players: Array[AudioStreamPlayer] = []
var _sfx_pool_size: int = 8
var _sounds: Dictionary = {}  # name -> AudioStream


func _ready() -> void:
	# Create a pool of AudioStreamPlayers for SFX
	for i in _sfx_pool_size:
		var player := AudioStreamPlayer.new()
		player.bus = "SFX"
		add_child(player)
		_sfx_players.append(player)

	# Ensure audio buses exist
	_ensure_bus("SFX", "Master")
	_ensure_bus("Music", "Master")

	# Pre-load all sounds from assets/sounds/
	_load_sounds()


func play_sfx(sound_name: String, volume_db: float = 0.0) -> void:
	var stream: AudioStream = _sounds.get(sound_name)
	if not stream:
		return

	# Find a free player from the pool
	for player in _sfx_players:
		if not player.playing:
			player.stream = stream
			player.volume_db = volume_db
			player.play()
			return

	# All busy — use the first one (interrupt oldest)
	_sfx_players[0].stream = stream
	_sfx_players[0].volume_db = volume_db
	_sfx_players[0].play()


func _load_sounds() -> void:
	var dir := DirAccess.open("res://assets/sounds/")
	if not dir:
		return

	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	while file_name != "":
		if not dir.current_is_dir():
			var ext: String = file_name.get_extension().to_lower()
			if ext in ["wav", "ogg", "mp3"]:
				var sound_name: String = file_name.get_basename()
				var path: String = "res://assets/sounds/" + file_name
				var stream: AudioStream = load(path)
				if stream:
					_sounds[sound_name] = stream
		file_name = dir.get_next()
	dir.list_dir_end()


func _ensure_bus(bus_name: String, send_to: String) -> void:
	if AudioServer.get_bus_index(bus_name) == -1:
		AudioServer.add_bus()
		AudioServer.set_bus_name(AudioServer.bus_count - 1, bus_name)
		AudioServer.set_bus_send(AudioServer.get_bus_index(bus_name), send_to)
