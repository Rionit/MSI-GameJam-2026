extends CharacterBody3D

class_name AntivirusBall

@export var horizontal_speed: float = 0.5
@export var gravity: float = 1.0
@export var bounce_y_speed: float = 0.5

var _spawn_position: Vector3

func _ready() -> void:
	_spawn_position = global_position
	velocity = Vector3.ZERO
	set_physics_process(false)

func activate(spawn_position: Vector3) -> void:
	_spawn_position = spawn_position
	set_physics_process(true)
	reset_to_spawn()

func deactivate() -> void:
	set_physics_process(false)
	velocity = Vector3.ZERO

func reset_to_spawn() -> void:
	global_position = _spawn_position
	velocity = Vector3(0.0, bounce_y_speed, 0.0)

func reverse_horizontal_velocity() -> void:
	velocity.x = -velocity.x

func _physics_process(delta: float) -> void:
	var horizontal_input := Input.get_axis("move_left", "move_right")
	velocity.x = horizontal_input * horizontal_speed
	velocity.z = 0.0
	velocity.y -= gravity * delta

	var collision := move_and_collide(velocity * delta)
	if collision != null and collision.get_normal().y > 0.5 and velocity.y <= 0.0:
		velocity.y = bounce_y_speed
