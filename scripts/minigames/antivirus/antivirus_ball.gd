extends CharacterBody3D

class_name AntivirusBall

@export var horizontal_speed: float = 10
@export var gravity: float = 150
@export var bounce_y_speed: float = 30
var velocity_vector : Vector3
var can_move := false

var _spawn_position: Vector3

func _ready() -> void:
	_spawn_position = global_position
	velocity_vector = Vector3.ZERO
	set_physics_process(false)

func activate(spawn_position: Vector3) -> void:
	print("Activating AntivirusBall at position: ", spawn_position)
	_spawn_position = spawn_position
	can_move = true
	set_physics_process(true)
	reset_to_spawn()

func deactivate() -> void:
	print("Deactivating AntivirusBall.")
	can_move = false
	set_physics_process(false)
	velocity_vector = Vector3.ZERO

func reset_to_spawn() -> void:
	global_position = _spawn_position
	velocity_vector = Vector3(0.0, bounce_y_speed, 0.0)

func reverse_horizontal_velocity() -> void:
	print("Reversing horizontal velocity. Current velocity: ", velocity_vector)
	velocity_vector.x = -velocity_vector.x
	disable_horizontal_coroutine()

func disable_horizontal_coroutine() -> void:
	var could_move = can_move
	can_move = false
	await get_tree().create_timer(0.5).timeout
	can_move = could_move

func _physics_process(delta: float) -> void:
	if can_move:
		var horizontal_input := Input.get_axis("move_left", "move_right")
		velocity_vector.x = -horizontal_input * horizontal_speed
	
	velocity_vector.z = 0.0
	velocity_vector.y -= gravity * delta
	velocity_vector.y = max(-bounce_y_speed, velocity_vector.y)  # Prevents the ball from falling too fast


	var velocity_dir = velocity_vector.normalized()
	var velocity_length = velocity_vector.length()

	var collision := move_and_collide((to_global(velocity_dir)-global_position) * velocity_length * delta)
	#AudioManager.play_sfx(Ball bounce zvuk)
	if collision != null:
		print("Collision detected with velocity Y: ", velocity_vector.y, " and bounce_y_speed: ", bounce_y_speed)
		velocity_vector.y = bounce_y_speed


