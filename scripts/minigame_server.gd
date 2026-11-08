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
	gameManager.player.can_walk = false
	gameManager.player.can_jump = false

	gameManager.player.current_minigame_server = self
	await animate_camera(true)

	minigame.enter_game()
	collider.disabled = true

func on_minigame_exited() -> void:
	minigame.exit_game()
	await animate_camera(false)
	gameManager.player.can_walk = true
	gameManager.player.can_jump = true
	gameManager.player.current_minigame_server = null

	collider.disabled = false


func on_minigame_completed(minigame: Minigame) -> void:
	minigame_completed = true
	minigame.exit_game()

	await animate_camera(false)

	gameManager.player.current_minigame_server = null
	gameManager.player.can_walk = true
	gameManager.player.can_jump = true
	


func animate_camera(to_game: bool) -> void:
	var player = gameManager.player
	var tween = create_tween()
	tween.set_parallel()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_IN_OUT)
	var target_position: Vector3
	var target_rotation: Vector3
	var target_parent: Node3D

	var duration: float = 1 # Duration of the transition in seconds

	if to_game:
		# Transition from current camera position TO player position (Game view)
		target_position = cameraPosition.global_position
		target_rotation = cameraPosition.global_rotation
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

	print("Reparenting camera pivot from " + str(player.camera_pivot.get_parent()) + " to " + str(target_parent))
	player.camera_pivot.reparent(target_parent)

