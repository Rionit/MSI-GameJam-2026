extends Node3D
class_name Door

@onready var animation_player: AnimationPlayer = $AnimationPlayer

func open():
	print("opening")
	animation_player.play("open")

func close():
	animation_player.play("close")
