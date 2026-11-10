extends Area3D

class_name AntivirusPlatform

@export var speed: float = 0.3
@export var left_x: float = -1.0
@export var right_x: float = 1.0
@export var direction: float = 1.0

var _active := false

func _ready() -> void:
	direction = 1.0 if direction >= 0.0 else -1.0
	set_physics_process(false)

func activate() -> void:
	_active = true
	set_physics_process(true)

func deactivate() -> void:
	_active = false
	set_physics_process(false)

func _physics_process(delta: float) -> void:
	position.x += direction * speed * delta

	if position.x >= right_x:
		position.x = right_x
		direction = -1.0
	elif position.x <= left_x:
		position.x = left_x
		direction = 1.0
