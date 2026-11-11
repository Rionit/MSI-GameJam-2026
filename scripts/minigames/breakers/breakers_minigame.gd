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
	breakers_to_connect = breakers.size()

	var randomized_breakers = breakers.duplicate()
	randomized_breakers.shuffle()

	for i in range(randomized_breakers.size()):
		var breaker = randomized_breakers[i]

		breaker.interacted.connect(_on_breaker_interacted)
		breaker.deactivate()

		var connected_breakers = []
		if randomized_breakers.size() > 1:
			var next_breaker = randomized_breakers[(i + 1) % randomized_breakers.size()]
			connected_breakers.append(next_breaker)

		# An extra link makes the cycle solvable when there is an odd number of breakers.
		if randomized_breakers.size() > 2 and randomized_breakers.size() % 2 == 1 and i == 0:
			connected_breakers.append(randomized_breakers[2])

		breaker_connections[breaker] = connected_breakers

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
