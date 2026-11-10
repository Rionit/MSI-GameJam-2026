extends Minigame

class_name BreakersMinigame

@export var breakers : Array[Breaker]

var breaker_connections = {}

var breakers_to_connect : int

func enter_game() -> void:
	for breaker in breakers:
		breaker.activate()

func exit_game() -> void:
	for breaker in breakers:
		breaker.deactivate()

func _ready() -> void:
	var random = RandomNumberGenerator.new()
	breakers_to_connect = breakers.size()
	
	for i in range(breakers.size()):
		var breaker = breakers[i]

		breaker.interacted.connect(_on_breaker_interacted)
		breaker.deactivate()
		var num_connected_breakers = random.randi() % 2 + 1 # Each breaker can connect to 1 or 2 other breakers

		breaker_connections[breaker] = []

		while(len(breaker_connections[breaker]) < num_connected_breakers):
			var random_index = random.randi() % breakers.size()
			var connected_breaker = breakers[random_index]

			if connected_breaker != breaker and connected_breaker not in breaker_connections[breaker]:
				breaker_connections[breaker].append(connected_breaker)

func _on_breaker_interacted(interacted: Interactable):
	#AudioManager.play_sfx(Switch flip sound)
	var interacted_breaker = interacted as Breaker
	print("Breaker " + str(interacted) + " interacted.")
	interacted_breaker.flip_breaker()
	# Check if the breaker is connected to another breaker
	if interacted_breaker in breaker_connections:
		var connected_breakers = breaker_connections[interacted_breaker]
		for connected_breaker in connected_breakers:
			connected_breaker.flip_breaker()
	else:
		print ("Breaker " + str(interacted_breaker) + " is not connected to any other breaker.")

	var currently_connected = 0
	for breaker in breakers:
		if breaker.switch_flipped:
			currently_connected += 1

	if currently_connected == len(breakers):
		print("All breakers are connected! Minigame completed.")
		minigame_completed.emit(self)
