@tool
extends Node
class_name GameManager

@onready var screen_manager: ScreenManager = %ScreenManager
@onready var split_screen: SplitScreen = %SplitScreen
@onready var player: PlayerController = %FirstPersonPlayer

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
	split_screen.split_ratio = remap(screen_manager.active_screen_count + 1, 
									0, screen_manager.pairs.size(),
									0.0, 1.0)
	screen_manager.active_screen_count += 1

func on_screen_disconnected():
	screen_manager.active_screen_count -= 1
	split_screen.split_ratio = remap(screen_manager.active_screen_count, 
									0, screen_manager.pairs.size(),
									0.0, 1.0)
