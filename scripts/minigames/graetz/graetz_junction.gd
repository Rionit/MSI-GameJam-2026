extends Node3D

class_name GraetzJunction

## Connected diodes or pins (only connect pins in editor)
@export var connected : Array

func add_connection(node : Node3D) -> void:
	if node not in connected:
		connected.append(node)

func get_connections() -> Array:
	return connected
