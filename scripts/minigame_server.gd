extends Interactable
class_name MinigameServer

var minigame_completed = false

@export var minigame : Minigame
@export var collider : CollisionShape3D
@export var cameraPosition : Node3D
@onready var gameManager : GameManager = get_node("/root/Main")

func _ready() -> void:
	interacted.connect(on_interacted)
	minigame.minigame_completed.connect(on_minigame_completed)

func on_interacted(interactable: Interactable) -> void:
	print("Interacted with minigame server: " + str(minigame))
	gameManager.player.can_move = false
	gameManager.player.can_jump = false
	await animate_camera(true)

	minigame.enter_game()
	collider.disabled = true

func on_minigame_completed(minigame: Minigame) -> void:
	minigame_completed = true
	await animate_camera(false)

	gameManager.player.can_move = true
	gameManager.player.can_jump = true
	
	minigame.exit_game()

func animate_camera(to_game: bool) -> void:
	var player = gameManager.player
	var tween = create_tween()
	tween.set_parallel()
	
	var target_position: Vector3
	var target_rotation: Vector3
	var target_parent: Node3D

	var duration: float = 0.5 # Duration of the transition in seconds

	if to_game:
		# Transition from current camera position TO player position (Game view)
		target_position = cameraPosition.global_position
		target_rotation = cameraPosition.global_rotation.rotated(Vector3.RIGHT, deg_to_rad(180))
		target_parent = gameManager.static_camera_parent
	else:
		# Transition from player position TO cameraPosition (Player view)
		target_position = player.global_position + Vector3(0, 0.5, 0) # Adjust the offset as needed
		target_rotation = player.global_rotation
		target_parent = player


	# Tween the position
	tween.tween_property(player.camera_pivot, "global_position", target_position, duration)
	
	# Tween the basis (rotation)
	tween.tween_property(player.camera_pivot, "global_rotation", target_rotation, duration)

	await tween.finished

	player.camera_pivot.reparent(target_parent)

