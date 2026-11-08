extends Interactable
class_name MinigameServer

var minigame_completed = false

@export var minigame : Minigame
@export var collider : CollisionShape3D

func _ready() -> void:
	interacted.connect(on_interacted)
	minigame.minigame_completed.connect(on_minigame_completed)

func on_interacted(interactable: Interactable) -> void:
	print("Interacted with minigame server: " + str(minigame))
	minigame.enter_game()
	collider.disabled = true

func on_minigame_completed(minigame: Minigame) -> void:
	minigame_completed = true
	minigame.exit_game()

	
