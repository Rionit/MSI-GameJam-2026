extends Minigame

class_name GraetzMinigame

signal signal_finished()
signal flow_finished()

@export var ac_upper_pin_junction : Array[Node3D]
@export var ac_lower_pin_junction : Array[Node3D]

@export var dc_plus_pin_junction : Array[Node3D]
@export var dc_minus_pin_junction : Array[Node3D]

var ac_upper : GraetzPinJunction
var ac_lower : GraetzPinJunction
var dc_plus : GraetzPinJunction
var dc_minus : GraetzPinJunction

@export var success_visualizer : MeshInstance3D
@export var test_button : Interactable

@export var signal_scene : PackedScene
@export var possible_paths : Array[Path3D]

@export var success_material : Material
@export var failure_material : Material

@export var upper_left_diode : GraetzDiode 
@export var upper_right_diode : GraetzDiode
@export var lower_left_diode : GraetzDiode
@export var lower_right_diode : GraetzDiode

var num_signals_finished = 0

func _ready() -> void:

	ac_upper = GraetzPinJunction.new()
	ac_lower = GraetzPinJunction.new()
	dc_plus = GraetzPinJunction.new()
	dc_minus = GraetzPinJunction.new()

	ac_upper.pin = ac_upper_pin_junction[0]
	ac_upper.junction = ac_upper_pin_junction[1]
	ac_upper.path_points = []

	for i in range(ac_upper_pin_junction.size()-2):
		ac_upper.path_points.append(ac_upper_pin_junction[i+2].global_position)


	ac_lower.pin = ac_lower_pin_junction[0]
	ac_lower.junction = ac_lower_pin_junction[1]
	ac_lower.path_points = []
	for i in range(ac_lower_pin_junction.size()-2):
		ac_lower.path_points.append(ac_lower_pin_junction[i+2].global_position)

	dc_plus.pin = dc_plus_pin_junction[0]
	dc_plus.junction = dc_plus_pin_junction[1]
	dc_plus.path_points = []

	for i in range(dc_plus_pin_junction.size()-2):
		dc_plus.path_points.append(dc_plus_pin_junction[i+2].global_position)

	dc_minus.pin = dc_minus_pin_junction[0]
	dc_minus.junction = dc_minus_pin_junction[1]
	dc_minus.path_points = []

	for i in range(dc_minus_pin_junction.size()-2):
		dc_minus.path_points.append(dc_minus_pin_junction[i+2].global_position)

	ac_upper.junction.add_connection(ac_upper.pin)
	ac_lower.junction.add_connection(ac_lower.pin)
	dc_plus.junction.add_connection(dc_plus.pin)
	dc_minus.junction.add_connection(dc_minus.pin)

	test_button.interacted.connect(_on_test_button_interacted)

	signal_finished.connect(signal_finished_callback)

func enter_game() -> void:
	enable_buttons(true)
func exit_game() -> void:
	enable_buttons(false)

func enable_buttons(enabled: bool) -> void:
	test_button.get_node("Collider").disabled = not enabled
	for diode in [upper_left_diode, upper_right_diode, lower_left_diode, lower_right_diode]:
		diode.collider.disabled = not enabled

func add_path_points(path):
	var start_pin = get_pin(path[0])
	if start_pin != null:
		print("Trying start pin for path " + str(path) + ": " + str(start_pin.pin))
		for i in range(start_pin.path_points.size()):
			path.insert(i+1, start_pin.path_points[i])
		
		print("Path after adding start pin points: " + str(path))


	var end_pin = get_pin(path[-1])
	if end_pin != null:
		print("Trying end pin for path " + str(path) + ": " + str(end_pin.pin))
		for i in range(end_pin.path_points.size(), 0, -1):
			path.insert(path.size()-1, end_pin.path_points[i-1])
		print("Path after adding end pin points: " + str(path))

func finish_paths(paths: Array):
	for path in paths:
		add_path_points(path)


func get_pin(pos : Vector3) -> GraetzPinJunction:
	for pin in [ac_upper, ac_lower, dc_plus, dc_minus]:
		if pin.pin.global_position == pos:
			return pin
	return null

func _on_test_button_interacted(interacted: Interactable) -> void:
	enable_buttons(false)

	#Debug - check if diode combination is valid
	var invalid_diodes = check_diode_validity()
	print("Are diodes invalid? " + str(invalid_diodes.size() > 0))
	for diode in invalid_diodes:
		print("Invalid diode: " + str(diode))

	var ac_plus_minus = build_paths_bidir(ac_upper, dc_minus)

	print("Starting simulation: AC+ = upper, AC- = lower")
	var plus_to_plus_valid = validate_paths(ac_plus_minus[0], ac_upper, dc_plus)
	print("> Is AC+ to DC+ path valid? " + str(plus_to_plus_valid))
	var minus_to_minus_valid = validate_paths(ac_plus_minus[1], dc_minus, ac_lower)
	print("> Is DC- to AC- path valid? " + str(minus_to_minus_valid))

	await animate_flow(ac_plus_minus, [ac_upper.pin.global_position, dc_minus.pin.global_position], success_visualizer, plus_to_plus_valid, minus_to_minus_valid)

	if not plus_to_plus_valid or not minus_to_minus_valid:
		enable_buttons(true)
		return
	print(">First animation complete!")


	var ac_minus_plus = build_paths_bidir(ac_lower, dc_minus)

	print("Starting simulation: AC+ = lower, AC- = upper")
	plus_to_plus_valid = validate_paths(ac_minus_plus[0], ac_lower, dc_plus)
	print("> Is AC- to DC+ path valid? " + str(plus_to_plus_valid))
	minus_to_minus_valid = validate_paths(ac_minus_plus[1], dc_minus, ac_upper)
	print("> Is DC- to AC+ path valid? " + str(minus_to_minus_valid))

	await animate_flow(ac_minus_plus, [ac_lower.pin.global_position, dc_minus.pin.global_position], success_visualizer, plus_to_plus_valid , minus_to_minus_valid)

	if not plus_to_plus_valid or not minus_to_minus_valid:
		enable_buttons(true)
		return
	print(">Second animation complete!")
	minigame_completed.emit(self)

## Checks if diode states are valid for passing
func check_diode_validity() -> Array[GraetzDiode]:
	var invalid_diodes : Array[GraetzDiode] = []

	if upper_left_diode.direction != GraetzDiode.DiodeDirection.RIGHT:
		invalid_diodes.append(upper_left_diode)
	if upper_right_diode.direction != GraetzDiode.DiodeDirection.LEFT:
		invalid_diodes.append(upper_right_diode)
	if lower_left_diode.direction != GraetzDiode.DiodeDirection.LEFT:
		invalid_diodes.append(lower_left_diode)
	if lower_right_diode.direction != GraetzDiode.DiodeDirection.RIGHT:
		invalid_diodes.append(lower_right_diode)

	return invalid_diodes
	
func validate_paths(paths : Dictionary, start_pin: GraetzPinJunction, end_pin: GraetzPinJunction) -> bool:
	return paths.keys().size() == 1 and paths.keys()[0][-1] == end_pin.pin.global_position and paths.values()[0] == false


func build_paths_bidir(start_pin_1 : GraetzPinJunction, start_pin_2 : GraetzPinJunction) -> Array[Dictionary]:
	var used_junctions : Array[GraetzJunction] = []
	var paths_1 = build_paths_unidir(start_pin_1, used_junctions)
	print("First pass over ... Used junctions: " + str(used_junctions))
	var paths_2 = build_paths_unidir(start_pin_2, used_junctions)

	return [paths_1, paths_2]

func build_paths_unidir(start_pin : GraetzPinJunction, used_junctions : Array[GraetzJunction]) -> Dictionary:
	var paths = []
	var splits = []

	build_path(paths, splits, used_junctions, start_pin.junction, start_pin.pin)
	finish_paths(paths)

	var path_dict = {}

	for i in range(paths.size()):
		path_dict[paths[i]] = splits[i]

	return path_dict

func build_path(paths : Array, splits : Array, used_junctions : Array, starting_junction : GraetzJunction, source : Node3D) -> void:
	
	var path = [source.global_position, starting_junction.global_position]
	used_junctions.append(starting_junction)
	var next_steps = forward_signal(starting_junction, source, used_junctions)

	# continue until we reach a pin or a split
	while next_steps.size() == 1:
		var next_step = next_steps[0]
		source = starting_junction
		if next_step is GraetzJunction:
			starting_junction = next_step
		path.append(next_step.global_position)
		# We found a pin -> return the path
		if next_step is not GraetzJunction: 
			paths.append(path)
			splits.append(false)
			return
		else:
			# We entered a junction -> check if we have already used it
			if used_junctions.has(next_step):
				paths.append(path)
				splits.append(false)
				return
			else:
				used_junctions.append(next_step)
				next_steps = forward_signal(next_step, source, used_junctions)
		
	if next_steps.size() == 0:
		paths.append(path)
		splits.append(false)
		return
	elif next_steps.size() > 1:
		paths.append(path)
		splits.append(true)
		for i in range(next_steps.size()):
			if next_steps[i] is not GraetzJunction:
				paths.append([starting_junction.global_position, next_steps[i].global_position])
				splits.append(false)
				return
			else:
				build_path(paths, splits, used_junctions, next_steps[i], starting_junction)

func forward_signal(junction: GraetzJunction, source : Node3D, used_junctions : Array[GraetzJunction]) -> Array[Node3D]:
	var next_steps : Array[Node3D] = []

	for connection in junction.get_connections():
		if connection != source: # We're not moving back
			# Diode - we only forward signal if the diode is allowing it to pass through
			if connection is GraetzDiode:
				var diode = connection as GraetzDiode
				if diode.left_junction == source or diode.right_junction == source:
					continue
				var next_junction = diode.resolve_signal_from(junction)
				if next_junction != null:
					print("Found next possible junction: Is it used? " + str(used_junctions.has(next_junction)))
					if not used_junctions.has(next_junction):
						next_steps.append(next_junction)
			# Non-diode connections (pins, junctions) 
			else:
				if connection is GraetzJunction:
					print("Found next possible junction: Is it used? " + str(used_junctions.has(connection)))
					if used_junctions.has(connection):
						continue
				next_steps.append(connection)

	return next_steps

func animate_flow(flow_paths: Array[Dictionary], flow_starts : Array[Vector3], result_visualizer : MeshInstance3D, plus_plus_success : bool, minus_minus_success : bool) -> void:
	num_signals_finished = 0
	var tween = create_tween()
	tween.set_parallel()

	tween.tween_callback(func() -> void: await animate_signal(flow_paths[0], flow_starts[0]))
	if plus_plus_success:
		tween.tween_callback(func() -> void: await animate_signal(flow_paths[1], flow_starts[1])).set_delay(2.0)

	await flow_finished
	
	await get_tree().create_timer(2.0).timeout

	result_visualizer.material_override = success_material if plus_plus_success and minus_minus_success else failure_material
	#AudioManager.play_sfx(Flow success/failure zvuk)
	await get_tree().create_timer(3.0).timeout
	result_visualizer.material_override = null

func animate_signal(paths : Dictionary, signal_start : Vector3) -> void:
	var start_paths_idx = find_split_paths(signal_start, paths.keys())
	var next_paths = []
	var electron_scale = 1.0

	for start_idx in start_paths_idx:
		next_paths.append(paths.keys()[start_idx])

	while next_paths.size() > 0:
		var current_paths = next_paths.duplicate()
		next_paths.clear()


		for path in current_paths:
			if paths[path] == true:
				var next_path_idxs = find_split_paths(path[-1], paths.keys())

				for next_idx in next_path_idxs:
					next_paths.append(paths.keys()[next_idx])

		await signal_step(current_paths, electron_scale)
		electron_scale *= 0.5
	
	signal_finished.emit()
	
func signal_step(current_paths: Array, electron_scale : float) -> void:

	var signal_instances = []
	var tween = create_tween()

	var max_step_time = 0.0

	for i in range(current_paths.size()):
		var path = current_paths[i]
		var signal_instance = signal_scene.instantiate() as GraetzSignal

		signal_instances.append(signal_instance)
		add_child(signal_instance)

		signal_instance.global_rotation = Vector3.ZERO
		signal_instance.scale_electrons(electron_scale)
		
		signal_instance.curve = Curve3D.new()
		signal_instance.curve.clear_points()
		for j in range(len(path)):
			signal_instance.curve.add_point(path[j] - signal_instance.global_position)
	
	for i in range(signal_instances.size()):
		max_step_time = max(max_step_time, signal_instances[i].curve.get_baked_length() / signal_instances[i].speed)
		tween.tween_callback(signal_instances[i].start_signal)

	await get_tree().create_timer(max_step_time).timeout

func find_split_paths(split_point : Vector3, paths : Array) -> Array[int]:
	var indices : Array[int] = []
	for i in range(paths.size()):
		if paths[i][0] == split_point:
			indices.append(i)
	
	return indices

func signal_finished_callback() -> void:
	num_signals_finished += 1
	if num_signals_finished >= 2:
		flow_finished.emit()
