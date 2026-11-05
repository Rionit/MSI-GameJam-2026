extends Node3D

## Base class for all minigames
class_name Minigame

signal minigame_completed(minigame: Minigame)

# @export var interactable_subelements : CollisionShape2D

## Called when the player (re-)enters the minigame. 
func enter_game() -> void:
	pass

## Called when the player exits the minigame.
func exit_game() -> void:
	minigame_completed.emit(self)