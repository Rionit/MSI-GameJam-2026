@tool
extends Node
class_name GameManager

@onready var screen_manager: ScreenManager = %ScreenManager
@onready var split_screen: SplitScreen = %SplitScreen
@onready var player: PlayerController = %FirstPersonPlayer

@export var doors: Array[Door]

@export_group("Screen Actions")
@export_tool_button("Connect Screen", "Add")
var connect_screen = on_screen_connected
@export_tool_button("Disconnect Screen", "Remove")
var disconnect_screen = on_screen_disconnected
@export_group("")

func _ready() -> void:
	# on_screen_connected()
	pass

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("jump"):
		on_screen_connected()

func on_screen_connected():
	screen_manager.active_screen_count += 1
	_update_split_ratio()
	if screen_manager.active_screen_count % 5 == 0:
		doors[(screen_manager.active_screen_count / 5) - 1].open()

func on_screen_disconnected():
	screen_manager.active_screen_count -= 1
	_update_split_ratio()

func _update_split_ratio() -> void:
	var max_screens = screen_manager.pairs.size()
	
	player.can_move = false
	split_screen.on_tween_finished.connect(func(): player.can_move = true)
	
	if screen_manager.active_screen_count >= max_screens:
		split_screen.split_ratio = 1.0
	else:
		split_screen.split_ratio = remap(
			screen_manager.active_screen_count, 
			0, max_screens,
			0.0, 0.9
		)
