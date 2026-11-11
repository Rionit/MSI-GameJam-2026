extends CharacterBody3D
class_name PlayerController

const DOT = preload("uid://bghp8yqycy6qq")
const DOT_HOLE = preload("uid://bnk8g7td53uyy")

@export_category("Override")
@export var can_move: bool = true

@export var receives_input: bool = true

@export_category("Movement")
##Speed of the character movement
@export var speed: float = 5.0
##Enable if you want your character to be able to walk
@export var can_walk: bool = true
##Enable if you want your character to be able to run
@export var can_run: bool = true
##Value to multiply on the current speed when character is running
@export var run_multiplier: float = 1.5

@export_category("Jump")
##Enable if you want your character to be able to jump
@export var can_jump: bool = true
##The force applied when jumping
@export var jump_force: float = 1.0

@export_category("Gravity")
##Use fall multiplier to make character fall more realistic
@export var use_fall_multiplier: bool = true
##The force applied to make more realistic the character fall
@export var fall_multiplier: float = 2.0
##limit force applied when fall multiplier is used
@export var max_fall_multiplier: float = 20.0

@export_category("Camera")
##Camera sensiblity
@export var camera_sensitivty: float = 0.01
@export var camera_pivot: Node3D 
@export var camera_zoom_fov : float = 50
@onready var camera_original_fov = $Camera/Camera3D.fov
var is_zoomed_in : bool = false
var can_zoom : bool = true

@export_category("Camera Limits")
## Enable to restrict camera view rotation to a cone
@export var use_camera_limit: bool = false
## Maximum angle of the view cone in degrees
@export var camera_limit_angle: float = 30.0
## Center direction of the view cone in local space
@export var camera_limit_direction: Vector3 = Vector3(0, 0, -1)

@export_category("Interaction")
@export var can_interact: bool = true
@export var current_interaction = null
@onready var crosshair: TextureRect = $Crosshair
@onready var interact_ray_cast_3d: RayCast3D = %InteractRayCast3D
@onready var object_holder: Marker3D = %ObjectHolder

var _current_speed: float
var _current_fall_multiplier: float
var _mouse_motion: Vector2

var current_minigame_server: MinigameServer = null

var camera_tween : Tween = null
func _ready() -> void:
	set_process_input(receives_input)

	add_to_group("player")
	_current_fall_multiplier = fall_multiplier
	_current_speed = speed
	show_mouse(false)

	camera_tween = get_tree().create_tween()
	camera_tween.set_trans(Tween.TRANS_CUBIC)
	camera_tween.set_ease(Tween.EASE_IN_OUT)
	
func _physics_process(delta: float) -> void:
	crosshair.visible = can_interact
	
	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return
	
	if !can_move:
		return
	
	# Move Camera
	move_camera(delta)
	
	# FORCE raycast to update immediately after camera movement 
	interact_ray_cast_3d.force_raycast_update()
	
	# Interact
	if can_interact:
		check_interactions()
	
	# Add the gravity.
	add_gravity(delta)
	
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	
	# jump
	if can_jump:
		do_jump()
	
	#Make player movement
	if can_walk:
		do_movement(input_dir)
	else:
		do_movement(Vector2.ZERO)

	move_and_slide()

func enable_zoom():
	can_zoom = true

func disable_zoom():
	can_zoom = false
	if camera_tween.is_running():
		camera_tween.kill()

func check_interactions():
	var collider = interact_ray_cast_3d.get_collider()
	
	# Check if we are looking at a new Interactable
	if collider is Interactable or collider is Switch:
		if current_interaction != collider:
			# Unhighlight the previous one if it exists
			if current_interaction:
				current_interaction.unhighlight()
			
			# Highlight the new one
			current_interaction = collider
			current_interaction.highlight()
			
			crosshair.texture = DOT
	else:
		# If we aren't looking at anything interactable, clear the old highlight
		if current_interaction:
			current_interaction.unhighlight()
			current_interaction = null
			
		crosshair.texture = DOT_HOLE

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_mouse_motion = -event.relative * camera_sensitivty
		pass
	#Show or Hide mouse
	if event.is_action_pressed("escape"):
		show_mouse(Input.mouse_mode == Input.MOUSE_MODE_CAPTURED)
	
	if event.is_action_pressed("exit_minigame") and current_minigame_server:
		current_minigame_server.on_minigame_exited()

	#Run
	if event.is_action_pressed("run"):
		_current_speed = speed * run_multiplier
	elif event.is_action_released("run"):
		_current_speed = speed


	if event.is_action_pressed("interact") and current_interaction:
		current_interaction.interact(self)
		
	if can_zoom and event.is_action_pressed("zoom"):
		zoom_camera(true)
	if can_zoom and event.is_action_released("zoom"):
		zoom_camera(false)

func zoom_camera(zoom_in: bool):
	if camera_tween.is_running():
		camera_tween.kill()

	camera_tween = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
	var current_fov = camera_pivot.get_node("Camera3D").fov
	print("Current camera FOV: ", current_fov, " Target FOV: ", camera_zoom_fov if zoom_in else camera_original_fov)
	if zoom_in:
		print("Zooming in camera.")
		#camera_tween.tween_property(camera_pivot.get_node("Camera3D") as Camera3D, "fov", camera_zoom_fov, 0.5)
		camera_tween.tween_method(set_camera_fov, current_fov, camera_zoom_fov, 0.3)
	else:
		print("Zooming out camera.")
		camera_tween.tween_method(set_camera_fov, current_fov, camera_original_fov, 0.3)
		#camera_tween.tween_property(camera_pivot.get_node("Camera3D") as Camera3D, "fov", camera_original_fov, 0.5)

func set_camera_fov(fov: float):
	var camera = camera_pivot.get_node("Camera3D") as Camera3D
	if camera:
		camera.fov = fov
		print("Camera FOV set to: ", fov)
	else:
		print("Camera node not found. Cannot set FOV.")

func add_gravity(delta: float):
	if use_fall_multiplier:
		if not is_on_floor():
			_current_fall_multiplier +=  delta if velocity.y >= 0.0 else delta * 3.0
			_current_fall_multiplier = clamp(_current_fall_multiplier, fall_multiplier, max_fall_multiplier)
			velocity += get_gravity() * delta * _current_fall_multiplier
		else:
			_current_fall_multiplier = fall_multiplier
			pass
		pass
	else:
		velocity += get_gravity() * delta
		pass 
	
func do_jump():
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = sqrt(jump_force * 5.0 * abs(get_gravity().y))
		pass
	pass

func do_movement(input_dir: Vector2):
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * _current_speed
		velocity.z = direction.z * _current_speed
	else:
		velocity.x = move_toward(velocity.x, 0, _current_speed)
		velocity.z = move_toward(velocity.z, 0, _current_speed)
	pass
	

func show_mouse(mouse_visiblity: bool):
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if mouse_visiblity else Input.MOUSE_MODE_CAPTURED
	pass

func move_camera(delta: float):
	if use_camera_limit:
		# Accumulate rotation locally on the camera pivot (Yaw and Pitch)
		camera_pivot.rotation.y += _mouse_motion.x
		camera_pivot.rotation.x += _mouse_motion.y
		
		var target_dir = camera_limit_direction.normalized()
		var target_yaw = atan2(-target_dir.x, -target_dir.z)
		var target_pitch = asin(clamp(target_dir.y, -1.0, 1.0))
		
		var yaw_offset = camera_pivot.rotation.y - target_yaw
		var pitch_offset = camera_pivot.rotation.x - target_pitch
		
		var max_rad = deg_to_rad(camera_limit_angle)
		var view_offset = Vector2(yaw_offset, pitch_offset)
		if view_offset.length() > max_rad:
			view_offset = view_offset.limit_length(max_rad)
			camera_pivot.rotation.y = target_yaw + view_offset.x
			camera_pivot.rotation.x = target_pitch + view_offset.y
			
		camera_pivot.rotation.x = clamp(camera_pivot.rotation.x, -deg_to_rad(90), deg_to_rad(90))
	else:
		if camera_pivot.get_parent() == self:
			# Normal gameplay: rotate player body (Y) and camera pivot (X)
			rotate_y(_mouse_motion.x)
			camera_pivot.rotate_x(_mouse_motion.y)
		else:
			# Minigame view: rotate yaw on Y and pitch cleanly on local right axis
			camera_pivot.rotate_y(_mouse_motion.x)
			camera_pivot.rotate_object_local(Vector3.RIGHT, _mouse_motion.y)
			
			# Prevent any unintended roll/tilt drift
			var rot = camera_pivot.rotation
			rot.z = 0.0
			camera_pivot.rotation = rot
		
		camera_pivot.rotation_degrees.x = clamp(camera_pivot.rotation_degrees.x, -90, 90)
	
	_mouse_motion = Vector2.ZERO
	pass
