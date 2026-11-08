@tool
extends Node
class_name GameManager

@onready var screen_manager: ScreenManager = %ScreenManager
@onready var split_screen: SplitScreen = %SplitScreen
@onready var player: PlayerController = %FirstPersonPlayer
@onready var static_camera_parent: Node3D = %SplitScreen/SubViewportContainerRight/SubViewport/StaticCameraParent

@export_group("Screen Actions")
@export_tool_button("Connect Screen", "Add")
var connect_screen = on_screen_connected
@export_tool_button("Disconnect Screen", "Remove")
var disconnect_screen = on_screen_disconnected
@export_group("")

func _ready() -> void:
	# on_screen_connected()
	pass

func on_screen_connected():
	screen_manager.active_screen_count += 1
	_update_split_ratio()

func on_screen_disconnected():
	screen_manager.active_screen_count -= 1
	_update_split_ratio()

func _update_split_ratio() -> void:
	var max_screens = screen_manager.pairs.size()
	
	if screen_manager.active_screen_count >= max_screens:
		split_screen.split_ratio = 1.0
	else:
		split_screen.split_ratio = remap(
			screen_manager.active_screen_count, 
			0, max_screens,
			0.0, 0.9
		)
