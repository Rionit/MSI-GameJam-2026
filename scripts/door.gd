extends Node3D
class_name Door

@onready var animation_player: AnimationPlayer = $AnimationPlayer

@export var number_of_games_to_open : int = 6 
var is_open : bool = false

func open():
	if is_open:
		return
	is_open = true
	print("opening")
	animation_player.play("open")

func close():
	is_open = false
	animation_player.play("close")
