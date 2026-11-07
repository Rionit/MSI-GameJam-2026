extends Minigame

class_name GraetzMinigame

@export var ac_upper_pin_junction : Array[Node3D]
@export var ac_lower_pin_junction : Array[Node3D]

@export var dc_plus_pin_junction : Array[Node3D]
@export var dc_minus_pin_junction : Array[Node3D]

var ac_upper : GraetzPinJunction
var ac_lower : GraetzPinJunction
var dc_plus : GraetzPinJunction
var dc_minus : GraetzPinJunction


@export var test_button : Interactable

@export var signal_scene : PackedScene

@export var possible_paths : Array[Path3D]


@export var success_material : Material
@export var failure_material : Material

@export var upper_left_diode : GraetzDiode 
@export var upper_right_diode : GraetzDiode
@export var lower_left_diode : GraetzDiode
@export var lower_right_diode : GraetzDiode

var tween : Tween

func _ready() -> void:

	ac_upper = GraetzPinJunction.new()
	ac_lower = GraetzPinJunction.new()
	dc_plus = GraetzPinJunction.new()
	dc_minus = GraetzPinJunction.new()

	ac_upper.pin = ac_upper_pin_junction[0]
	ac_upper.junction = ac_upper_pin_junction[1]

	ac_lower.pin = ac_lower_pin_junction[0]
	ac_lower.junction = ac_lower_pin_junction[1]

	dc_plus.pin = dc_plus_pin_junction[0]
	dc_plus.junction = dc_plus_pin_junction[1]

	dc_minus.pin = dc_minus_pin_junction[0]
	dc_minus.junction = dc_minus_pin_junction[1]

	ac_upper.junction.add_connection(ac_upper.pin)
	ac_lower.junction.add_connection(ac_lower.pin)
	dc_plus.junction.add_connection(dc_plus.pin)
	dc_minus.junction.add_connection(dc_minus.pin)

	test_button.interacted.connect(_on_test_button_interacted)

func enter_game() -> void:
	enable_buttons(true)
func exit_game() -> void:
	enable_buttons(false)

func enable_buttons(enabled: bool) -> void:
	test_button.get_node("Collider").disabled = not enabled
	for diode in [upper_left_diode, upper_right_diode, lower_left_diode, lower_right_diode]:
		diode.collider.disabled = not enabled

func _on_test_button_interacted(interacted: Interactable) -> void:
	enable_buttons(false)

	#Debug - check if diode combination is valid
	var invalid_diodes = check_diode_validity()
	print("Are diodes invalid? " + str(invalid_diodes.size() > 0))
	for diode in invalid_diodes:
		print("Invalid diode: " + str(diode))

	# First check - build Path3D from AC upper to DC+
	var ac_upper_to_dc_plus = build_paths(ac_upper)
	var ac_upper_to_dc_plus_valid = validate_paths(ac_upper_to_dc_plus, ac_upper, dc_plus)
	print("Is AC upper to DC+ path valid? " + str(ac_upper_to_dc_plus_valid))

	await animate_signal(ac_upper_to_dc_plus, ac_upper.pin.global_position, invalid_diodes, ac_upper_to_dc_plus_valid)
	if not ac_upper_to_dc_plus_valid:
		enable_buttons(true)
		return
	print("Animation complete!")
	# Second check - build Path3D from DC- to AC lower

	var dc_minus_to_ac_lower = build_paths(dc_minus)
	var dc_minus_to_ac_lower_valid = validate_paths(dc_minus_to_ac_lower, dc_minus, ac_lower)
	print("Is DC- to AC lower path valid? " + str(dc_minus_to_ac_lower_valid))

	await animate_signal(dc_minus_to_ac_lower, dc_minus.pin.global_position, invalid_diodes, dc_minus_to_ac_lower_valid)
	if not dc_minus_to_ac_lower_valid:
		enable_buttons(true)
		return

	# Third check - build Path3D from AC lower to DC+
	var ac_lower_to_dc_plus = build_paths(ac_lower)
	var ac_lower_to_dc_plus_valid = validate_paths(ac_lower_to_dc_plus, ac_lower, dc_plus)
	print("Is AC lower to DC+ path valid? " + str(ac_lower_to_dc_plus_valid))

	await animate_signal(ac_lower_to_dc_plus, ac_lower.pin.global_position, invalid_diodes, ac_lower_to_dc_plus_valid)
	
	if not ac_lower_to_dc_plus_valid:
		
		enable_buttons(true)
		return
	print("Animation complete!")

	#Fourth check - build Path3D from DC- to AC upper

	var dc_minus_to_ac_upper = build_paths(dc_minus)
	var dc_minus_to_ac_upper_valid = validate_paths(dc_minus_to_ac_upper, dc_minus, ac_upper)
	print("Is DC- to AC upper path valid? " + str(dc_minus_to_ac_upper_valid))

	await animate_signal(dc_minus_to_ac_upper, dc_minus.pin.global_position, invalid_diodes, dc_minus_to_ac_upper_valid)

	if not dc_minus_to_ac_upper_valid:
		enable_buttons(true)
		return
	print("Graetz minigame completed successfully!")
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

func build_paths(start_pin : GraetzPinJunction) -> Dictionary:
	var paths = []
	var splits = []
	var used_junctions = []

	build_path(paths, splits, used_junctions, start_pin.junction, start_pin.pin)


	var path_dict = {}

	for i in range(paths.size()):
		path_dict[paths[i]] = splits[i]

	return path_dict

func build_path(paths : Array, splits : Array, used_junctions : Array, starting_junction : GraetzJunction, source : Node3D) -> void:
	
	var path = [source.global_position, starting_junction.global_position] 
	var next_steps = forward_signal(starting_junction, source)
	var split = false

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
				next_steps = forward_signal(next_step, source)
		
	if next_steps.size() == 0:
		paths.append(path)
		splits.append(false)
		return
	elif next_steps.size() > 1:
		split = true
		paths.append(path)
		splits.append(true)
		for i in range(next_steps.size()):
			if next_steps[i] is not GraetzJunction:
				paths.append([starting_junction.global_position, next_steps[i].global_position])
				splits.append(false)
				return
			else:
				build_path(paths, splits, used_junctions, next_steps[i], starting_junction)


func forward_signal(junction: GraetzJunction, source : Node3D) -> Array[Node3D]:
	var next_steps : Array[Node3D] = []

	for connection in junction.get_connections():
		if connection != source: # We're not moving back
			# Diode - we only forward signal if the diode is allowing it to pass through
			if connection is GraetzDiode:
				var diode = connection as GraetzDiode
				if diode.left_junction == source or diode.right_junction == source:
					continue
				if diode.resolve_signal_from(junction) != null:
					next_steps.append(diode.get_destinations())
			# Non-diode connections (pins, junctions) 
			else:
				next_steps.append(connection)

	return next_steps

func animate_signal(paths : Dictionary, signal_start : Vector3 , result_diodes : Array[GraetzDiode], result_success : bool) -> void:
	var start_paths_idx = find_split_paths(signal_start, paths.keys())
	var next_paths = []
	var scale = 1.0

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

		await signal_step(current_paths, scale)
		scale *= 0.5

	if result_diodes.size() > 0:
		for result_diode in result_diodes:
			result_diode.mesh.material_override = success_material if result_success else failure_material

		await get_tree().create_timer(3.0).timeout

		for result_diode in result_diodes:
			result_diode.mesh.material_override = null
	
func signal_step(current_paths: Array, scale : float) -> void:

	var signal_instances = []

	print (" Paths: " + str(current_paths))
	tween = create_tween()
	
	for i in range(current_paths.size()):
		var path = current_paths[i]
		var signal_instance = signal_scene.instantiate() as Path3D
		signal_instances.append(signal_instance)
		add_child(signal_instance)
		signal_instance.global_rotation = Vector3.ZERO

		var signal_follow = signal_instance.get_node("SignalFollow") as PathFollow3D
		var signal_visualizer = signal_instance.get_node("SignalFollow/SignalVisualizer") as MeshInstance3D
		signal_visualizer.scale *= Vector3(scale, scale, scale)

		signal_instance.curve = Curve3D.new()
		signal_instance.curve.clear_points()
		for j in range(len(path)):
			signal_instance.curve.add_point(path[j] - signal_instance.global_position)
		
	for i in range(signal_instances.size()):
		var signal_follow = signal_instances[i].get_node("SignalFollow") as PathFollow3D
		signal_follow.progress_ratio = 0.0
		tween.tween_property(signal_follow, "progress_ratio", 1.0, 2.5).set_trans(Tween.TRANS_LINEAR)
		tween.set_parallel()

	await(tween.finished)

	for i in range(signal_instances.size()):
		signal_instances[i].queue_free()

func find_split_paths(split_point : Vector3, paths : Array) -> Array[int]:
	var indices : Array[int] = []
	for i in range(paths.size()):
		if paths[i][0] == split_point:
			indices.append(i)
	
	return indices
