@tool
extends Interactable
class_name CableMinigame

signal cable_connected

@onready var connector: RigidBody3D = $DynamicCable/Connector
@onready var camera_position: Marker3D = $CameraPosition
@onready var connector_hold_position: Marker3D = $ConnectorHoldPosition
@onready var connector_insert_position: Marker3D = $ConnectorInsertPosition
@onready var hitbox: CollisionShape3D = $Hitbox

@export_category("Game Setup")
@export_range(0, 7, 1) var type : int = 0.0:
	set(value):
		type = value
		if Engine.is_editor_hint():
			_set_type()
@export var screen_override := 1

@export_category("Exports")
@export var connector_types: Array[MeshInstance3D]
@export var rotating_part: MeshInstance3D
@export var player: PlayerController
@export var game: GameManager

var is_interacting = false
var is_checking = false
var rotation_tween: Tween

# Track rotation as a discrete step (0 to 7) to avoid floating-point drift
var current_step: int = 0

# Caches for restoring the camera later
var original_camera_parent: Node
var original_local_transform: Transform3D

func _enter_tree() -> void:
	if Engine.is_editor_hint():
		_auto_assign_connector_types()

func _ready() -> void:
	_auto_assign_connector_types()
	_set_type()

func _auto_assign_connector_types() -> void:
	connector_types.clear()
	var mesh_node = get_node_or_null("DynamicCable/Connector/mesh")
	if not mesh_node:
		return
	
	for i in range(1, 9):
		var child_name = "connector_type_%03d" % i
		var child = mesh_node.get_node_or_null(child_name)
		if child is MeshInstance3D:
			connector_types.append(child)

func _set_type():
	for t in range(connector_types.size()):
		connector_types[t].visible = t == type
	
	# Set correct step and scramble by a random integer offset (2 to 6 steps)
	current_step = type
	var scramble_offset = randi_range(2, 6)
	current_step = posmod(current_step + scramble_offset, 8)
	
	rotating_part.rotation.x = deg_to_rad(45 * current_step)

func highlight() -> void:
	if not is_interacting:
		super()

func interact(player: PlayerController) -> void:
	if is_interacting:
		if not is_checking:
			check_cable()
		return
	
	super(player)
	
	is_interacting = true
	unhighlight()
	
	original_camera_parent = player.camera_pivot.get_parent()
	original_local_transform = player.camera_pivot.transform
	
	connector.freeze = true
	var tween = create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(connector, "global_transform", connector_hold_position.global_transform, 1.0)
	tween.tween_property(player.camera_pivot, "global_transform", camera_position.global_transform, 1.0)
	
	player.can_walk = false
	player.can_jump = false
	
	AudioManager.play_sfx("whoosh")
	await tween.finished
	
	player.camera_pivot.reparent(game.static_camera_parent)

func check_cable():
	if is_checking:
		return
	is_checking = true
	
	# 1. Tween connector to insert position
	var insert_tween = create_tween()
	insert_tween.set_trans(Tween.TRANS_CUBIC)
	insert_tween.set_ease(Tween.EASE_IN_OUT)
	insert_tween.tween_property(connector, "global_transform", connector_insert_position.global_transform, 0.5)
	await insert_tween.finished
	
	AudioManager.play_sfx_at_3d("cable_plug_in", connector_insert_position.global_position)
	
	# 2. Perfect, bug-free discrete integer comparison
	if current_step == type:
		print("yippee its correct")
		AudioManager.play_sfx_at_3d("zap", connector_insert_position.global_position)
		
		cable_connected.emit()

		for i in range(screen_override):
			game.on_screen_connected()
			await get_tree().create_timer(2.0).timeout
		
		if hitbox:
			hitbox.disabled = true
		
		player.camera_pivot.reparent(original_camera_parent, true)
		
		var exit_tween = create_tween()
		exit_tween.set_trans(Tween.TRANS_CUBIC)
		exit_tween.set_ease(Tween.EASE_IN_OUT)
		exit_tween.tween_property(player.camera_pivot, "transform", original_local_transform, 1.0)
		
		player.can_walk = true
		player.can_jump = true
		
		await exit_tween.finished
		MonologueManager.display_next_batch()
		is_interacting = false
		
	else:
		print("nope")
		var return_tween = create_tween()
		return_tween.set_trans(Tween.TRANS_CUBIC)
		return_tween.set_ease(Tween.EASE_IN_OUT)
		return_tween.tween_property(connector, "global_transform", connector_hold_position.global_transform, 0.5)
		await return_tween.finished
		is_checking = false

func _input(event: InputEvent) -> void:
	if not is_interacting or is_checking:
		return
	
	if event.is_action_pressed("move_left"):
		AudioManager.play_sfx_at_3d("breaker_flip", connector_insert_position.global_position)
		rotate_steps(1)
	elif event.is_action_pressed("move_right"):
		AudioManager.play_sfx_at_3d("breaker_flip", connector_insert_position.global_position)
		rotate_steps(-1)

func rotate_steps(step_delta: int):
	# Update the discrete step index (0 to 7)
	current_step = posmod(current_step + step_delta, 8)
	
	if rotation_tween and rotation_tween.is_valid():
		rotation_tween.kill()
	
	rotation_tween = create_tween()
	rotation_tween.set_trans(Tween.TRANS_CUBIC)
	rotation_tween.set_ease(Tween.EASE_OUT)
	
	# Get current rotation and target rotation in radians
	var current_rad = rotating_part.rotation.x
	var target_rad = deg_to_rad(45 * current_step)
	
	# Calculate the shortest angular difference to prevent 360-degree whipping across boundaries
	var diff = wrapf(target_rad - current_rad, -PI, PI)
	var final_target = current_rad + diff
	
	var target_rotation = rotating_part.rotation
	target_rotation.x = final_target
	rotation_tween.tween_property(rotating_part, "rotation", target_rotation, 0.15)
	
	# Clean up and normalize the rotation value once the tween finishes
	rotation_tween.tween_callback(func():
		rotating_part.rotation.x = fposmod(rotating_part.rotation.x, TAU)
	)
