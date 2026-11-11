extends Node3D

class_name RoomCableEnabler

@export var enabling_cable_minigame : CableMinigame
@export var lights_to_enable : Array[Light3D]

@export var servers_to_enable : Array[MinigameServer]

func _ready() -> void:
	enabling_cable_minigame.cable_connected.connect(_on_cable_minigame_completed)

func _on_cable_minigame_completed() -> void:
	for light in lights_to_enable:
		light.visible = true

	for server in servers_to_enable:
		server.enable_server()
