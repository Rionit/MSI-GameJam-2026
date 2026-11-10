@tool
extends Node
class_name GameManager

@onready var screen_manager: ScreenManager = %ScreenManager
@onready var split_screen: SplitScreen = %SplitScreen
@onready var player: PlayerController = %FirstPersonPlayer

@export var static_camera_parent: Node3D 
@export var doors: Array[Door]

@export_group("Screen Actions")
@export_tool_button("Connect Screen", "Add")
var connect_screen = on_screen_connected
@export_tool_button("Disconnect Screen", "Remove")
var disconnect_screen = on_screen_disconnected
@export_group("")

var next_door_index : int = 0

func _ready() -> void:
	# on_screen_connected()
	pass

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("jump"):
		on_screen_connected()
		print(screen_manager.pairs.size() / doors.size())

func on_screen_connected():
	screen_manager.active_screen_count += 1
	_update_split_ratio()
	
	# Check doors in order, accumulating their required screens cumulatively
	while next_door_index < doors.size():
		# Calculate the total cumulative screens needed for the next door in line
		var cumulative_required = 0
		for i in range(next_door_index + 1):
			cumulative_required += doors[i].number_of_games_to_open
			
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
