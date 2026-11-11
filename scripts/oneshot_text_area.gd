extends Area3D

class_name OneShotTextArea

func _ready() -> void:
	
	body_entered.connect(_body_entered)

func _body_entered(body: Node3D) -> void:
	print("OneShotTextArea: Body entered: " + str(body))
	if body is PlayerController:
		monitoring = false
		MonologueManager.display_next_batch()
		queue_free()
