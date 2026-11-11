extends Interactable
class_name MinigameServer

var minigame_completed = false

@export var minigame : Minigame
@export var collider : CollisionShape3D
@export var cameraPosition : Marker3D
@onready var gameManager : GameManager = get_node("/root/Main")

var laptop_hum : AudioStreamPlayer3D

func _ready() -> void:
	laptop_hum = AudioManager.play_sfx_at_3d("laptop_hum", global_position)
	
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
	gameManager.on_screen_connected()
	
	minigame_completed = true
	minigame.exit_game()

	await animate_camera(false)

	gameManager.player.current_minigame_server = null
	gameManager.player.can_walk = true
	gameManager.player.can_jump = true
	
	AudioManager.stop_sfx(laptop_hum)


func animate_camera(to_game: bool) -> void:
	var player = gameManager.player
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_IN_OUT)
	
	var target_transform: Transform3D
	var target_parent: Node3D
	var duration: float = 1.0 # Duration of the transition in seconds

	if to_game:
		# Transition from current camera position TO minigame camera position
		target_transform = cameraPosition.global_transform
		target_parent = gameManager.static_camera_parent
	else:
		# Transition from minigame back to player position/rotation
		var back_pos = player.global_position + Vector3(0, 0.5, 0) # Adjust offset as needed
		target_transform = Transform3D(player.global_basis, back_pos)
		target_parent = player

	# Tween the global_transform directly (smooth position & quaternion rotation)
	tween.tween_property(player.camera_pivot, "global_transform", target_transform, duration)

	#AudioManager.play_sfx(Whoosh SFX (pro přechod kamery))
	await tween.finished

	print("Reparenting camera pivot from " + str(player.camera_pivot.get_parent()) + " to " + str(target_parent))
	player.camera_pivot.reparent(target_parent)
