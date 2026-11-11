@tool
extends Node
class_name GameManager

@onready var screen_manager: ScreenManager = %ScreenManager
@onready var split_screen: SplitScreen = %SplitScreen
@onready var player: PlayerController = %FirstPersonPlayer
@onready var screen_room: Node3D = $Level/ScreenRoom
@onready var map: Node3D = $map
@onready var red_light: SpotLight3D = $Lights/RedLight
@onready var game_over_screen: ColorRect = $SplitScreen/SubViewportContainerLeft/EndgameScreen
@onready var endgame_quit_button : Button = $SplitScreen/SubViewportContainerLeft/EndgameScreen/QuitButton
@onready var switch : Switch = $Level/Switch

@export var static_camera_parent: Node3D 
@export var doors: Array[Door]
@export var rooms: Array[Node3D]
@export_group("Debug")
@export_tool_button("Connect Screen", "Add")
var connect_screen = on_screen_connected
@export_tool_button("Disconnect Screen", "Remove")
var disconnect_screen = on_screen_disconnected
@export_group("")

var next_door_index : int = 0

func _ready() -> void:
	# Disable the default root window audio listener to prevent conflicts
	get_tree().get_root().audio_listener_enable_3d = false
	play_sounds()
	switch.interacted.connect(switch_pressed)

	# on_screen_connected()
	#open_all_doors()
	pass

func play_sounds() -> void:
	for child in map.get_children():
		if child is MeshInstance3D and child.name.begins_with("server_row"):
			AudioManager.play_sfx_at_3d("server_hum", child.global_position)
	AudioManager.play_sfx_at_3d("screen_room_ambience", screen_room.global_position)
	for room in rooms:
		AudioManager.play_sfx_at_3d("server_room_ambience", room.global_position)
	
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("jump"):
		on_screen_connected()
		print(screen_manager.pairs.size() / doors.size())

func open_all_doors():
	for door in doors:
		door.open()

func on_screen_connected():
	screen_manager.active_screen_count += 1
	_update_split_ratio()
	
	# Check doors in order, accumulating their required screens cumulatively
	while next_door_index < doors.size():
		# Calculate the total cumulative screens needed for the next door in line
		var cumulative_required = 0
		for i in range(next_door_index + 1):
			cumulative_required += doors[i].number_of_games_to_open
			print("Cumulative required for door %d: %d" % [i, cumulative_required])

		# If we've reached or exceeded this door's threshold, open it and move to the next
		if screen_manager.active_screen_count >= cumulative_required:
			doors[next_door_index].open()
			next_door_index += 1
		else:
			break

func on_screen_disconnected():
	screen_manager.active_screen_count -= 1
	_update_split_ratio()

func _update_split_ratio() -> void:
	var max_screens = screen_manager.pairs.size()
	
	player.can_move = false
	split_screen.on_tween_finished.connect(func(): player.can_move = true)
	
	if screen_manager.active_screen_count == 1:
		split_screen.split_ratio = 0.075
	elif screen_manager.active_screen_count >= max_screens:
		split_screen.split_ratio = 1.0
	else:
		split_screen.split_ratio = remap(
			screen_manager.active_screen_count, 
			1, max_screens,
			0.075, 0.8
		)
func switch_pressed() -> void:
	MonologueManager.display_next_batch()
	player.can_walk = false
	player.can_jump = false
	player.can_move = false
	MonologueManager.can_skip = false

	await MonologueManager.reading_finished
	endgame_animation()

func endgame_animation() -> void:
	var tween = create_tween()
	tween.set_parallel()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_IN)

	tween.tween_property(red_light, "attenuation", -3.0, 4.0)
	# TODO: ADD AUDIO TWEEN
	await tween.finished
	AudioManager.set_bus_volume_linear("SFX", -100.0)
	AudioManager.set_bus_volume_linear("SFX_ScreenRoom", -100.0)
	game_over_screen.visible = true
	# TODO: Animate text


func on_endgame_quit_pressed() -> void:
	get_tree().quit()
