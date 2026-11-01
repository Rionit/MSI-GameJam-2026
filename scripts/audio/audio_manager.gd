extends Node

@onready var sfx_player: AudioStreamPlayer = $SFX
@export var audio_library: AudioLibrary

@export_category("Audio Buses")
@export var sfx_bus: String = "SFX"
@export var bgm_bus: String = "Music"

@onready var settings: Control = $Settings

# Dual BGM players for smooth crossfading
var bgm_player_1: AudioStreamPlayer
var bgm_player_2: AudioStreamPlayer
var active_bgm_player: AudioStreamPlayer

func _ready() -> void:
	audio_library = load("res://resources/audio_library.tres")
	
	# Auto-assign polyphonic stream if you forgot to set it in the editor scene
	if not sfx_player.stream is AudioStreamPolyphonic:
		sfx_player.stream = AudioStreamPolyphonic.new()

	if not sfx_player.playing:
		sfx_player.play()

	# Initialize BGM crossfading players programmatically for plug-and-play ease
	bgm_player_1 = AudioStreamPlayer.new()
	bgm_player_1.bus = bgm_bus
	add_child(bgm_player_1)

	bgm_player_2 = AudioStreamPlayer.new()
	bgm_player_2.bus = bgm_bus
	add_child(bgm_player_2)
	
	active_bgm_player = bgm_player_1

func _process(delta: float) -> void:
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		settings.visible = false
	else:
		settings.visible = true

# --- Lookup Helpers ---
func _get_audio_sfx(_tag: String) -> SFX:
	if not _tag:
		printerr("No tag provided, cannot get sound effect!")
		return null

	if not audio_library:
		printerr("No AudioLibrary assigned to AudioManager!")
		return null

	for sound in audio_library.sound_effects:
		if sound and sound.tag == _tag:
			return sound

	printerr("Sound with tag [", _tag, "] not found!")
	return null

func _get_audio_music(_tag: String) -> Music:
	if not _tag:
		printerr("No tag provided, cannot get music track!")
		return null

	if not audio_library:
		printerr("No AudioLibrary assigned to AudioManager!")
		return null

	for track in audio_library.music_tracks:
		if track and track.tag == _tag:
			return track

	printerr("Music track with tag [", _tag, "] not found!")
	return null

# --- SFX Playback ---
func play_sfx(_tag: String) -> void:
	var sound_def = _get_audio_sfx(_tag)
	if not sound_def:
		return
		
	var stream = sound_def.get_next_stream()
	if not stream:
		return

	var player = AudioStreamPlayer.new()
	player.stream = stream
	player.volume_db = sound_def.volume_db
	player.pitch_scale = sound_def.pitch_scale + randf_range(-sound_def.pitch_randomness, sound_def.pitch_randomness)
	player.bus = sfx_bus

	var parent_node = get_tree().current_scene
	if not parent_node:
		parent_node = get_tree().root

	parent_node.add_child(player)
	if not player.is_inside_tree():
		await player.tree_entered

	player.finished.connect(player.queue_free)
	player.play()

func play_sfx_at_2d(_tag: String, world_position: Vector2) -> void:
	_play_positional_sfx(_tag, world_position, AudioStreamPlayer2D, get_tree().root)

func play_sfx_at_3d(_tag: String, world_position: Vector3) -> void:
	_play_positional_sfx(_tag, world_position, AudioStreamPlayer3D, get_tree().current_scene)

func _play_positional_sfx(_tag: String, world_position, player_class, parent_node: Node) -> void:
	var sound_def = _get_audio_sfx(_tag)
	if not sound_def:
		return
		
	var stream = sound_def.get_next_stream()
	if not stream:
		return

	var player = player_class.new()
	player.stream = stream
	player.volume_db = sound_def.volume_db
	print("randomness = ", str(sound_def.pitch_randomness))
	player.pitch_scale = sound_def.pitch_scale + randf_range(-sound_def.pitch_randomness, sound_def.pitch_randomness)
	player.bus = sfx_player.bus

	parent_node.add_child(player)
	if not player.is_inside_tree():
		await player.tree_entered

	player.global_position = world_position
	player.finished.connect(player.queue_free)
	player.play()

# --- Smooth BGM Crossfading System ---
func play_bgm(tag: String, fade_duration: float = 1.0) -> void:
	if tag.is_empty():
		stop_bgm(fade_duration)
		return

	var music_def = _get_audio_music(tag)
	if not music_def or not music_def.stream:
		return

	# If the requested track tag is already playing actively, do nothing
	if active_bgm_player and active_bgm_player.has_meta("current_tag") and active_bgm_player.get_meta("current_tag") == tag and active_bgm_player.playing:
		return

	var inactive_bgm_player = bgm_player_2 if active_bgm_player == bgm_player_1 else bgm_player_1

	inactive_bgm_player.stream = music_def.stream
	inactive_bgm_player.pitch_scale = music_def.pitch_scale
	inactive_bgm_player.volume_db = -80.0
	inactive_bgm_player.set_meta("current_tag", tag)
	inactive_bgm_player.play()

	var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	if active_bgm_player and active_bgm_player.playing:
		tween.tween_property(active_bgm_player, "volume_db", -80.0, fade_duration)
	
	tween.tween_property(inactive_bgm_player, "volume_db", music_def.volume_db, fade_duration)
	
	await tween.finished
	
	if active_bgm_player and active_bgm_player != inactive_bgm_player:
		active_bgm_player.stop()
		active_bgm_player.remove_meta("current_tag")
	
	active_bgm_player = inactive_bgm_player

func stop_bgm(fade_duration: float = 1.0) -> void:
	if not active_bgm_player or not active_bgm_player.playing:
		return

	var tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(active_bgm_player, "volume_db", -80.0, fade_duration)
	await tween.finished
	active_bgm_player.stop()
	active_bgm_player.remove_meta("current_tag")

func pause_bgm() -> void:
	if active_bgm_player:
		active_bgm_player.stream_paused = true

func resume_bgm() -> void:
	if active_bgm_player:
		active_bgm_player.stream_paused = false

# --- Bus Volume Helpers (Linear to dB for Options Menus) ---
func set_bus_volume_linear(bus_name: String, linear_value: float) -> void:
	var bus_idx = AudioServer.get_bus_index(bus_name)
	if bus_idx == -1:
		printerr("Audio bus [", bus_name, "] not found!")
		return
	
	var db_value = linear_to_db(clamp(linear_value, 0.0001, 1.0)) if linear_value > 0.0 else -80.0
	AudioServer.set_bus_volume_db(bus_idx, db_value)

func get_bus_volume_linear(bus_name: String) -> float:
	var bus_idx = AudioServer.get_bus_index(bus_name)
	if bus_idx == -1:
		printerr("Audio bus [", bus_name, "] not found!")
		return 0.0
	
	return db_to_linear(AudioServer.get_bus_volume_db(bus_idx))
