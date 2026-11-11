extends Minigame

class_name TriangularPipeMinigame

@export var cell_scene: PackedScene
@export_range(2, 20, 1) var rows: int = 4
@export var cell_spacing: float = .8
@export var test_button: Interactable
@export var result_label: Label3D
@export var success_label: Label3D
@export var success_side_label : Label3D
@export var start_active: bool = true
@export var success_path_material: Material

var cells: Array = []
var cells_by_row: Array[Array] = []
var input_cell: Interactable
var output_cell: Interactable
var input_side: int = -1
var output_side: int = -1
var _completed := false
var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	if cell_scene == null:
		push_error("TriangularPipeMinigame requires a cell_scene.")
		return
	if rows < 2:
		push_error("TriangularPipeMinigame requires at least two rows.")
		return

	_rng.randomize()
	_generate_board()
	_choose_endpoints()
	_build_solvable_layout()
	_create_endpoint_markers()

	if test_button:
		test_button.interacted.connect(_on_test_button_interacted)
	if start_active:
		enter_game()
	else:
		exit_game()
	self.visible = false

func enter_game() -> void:
	for cell in cells:
		cell.activate()
	if test_button and test_button.has_method("activate"):
		test_button.activate()
	self.visible = true

func exit_game() -> void:
	for cell in cells:
		cell.deactivate()
	if test_button and test_button.has_method("deactivate"):
		test_button.deactivate()
	self.visible = false

func _generate_board() -> void:
	cells.clear()
	cells_by_row.clear()

	for row in range(rows):
		var row_cells: Array = []
		for column in range(row * 2 + 1):
			var cell = cell_scene.instantiate()
			if not cell is Interactable:
				push_error("cell_scene must instantiate an Interactable triangular pipe cell.")
				return
			add_child(cell)
			cell.configure(row, column, column % 2 == 0)
			cell.position = _cell_position(row, column)
			cell.interacted.connect(_on_cell_interacted)
			row_cells.append(cell)
			cells.append(cell)
		cells_by_row.append(row_cells)

	for row in range(rows):
		var row_cells: Array = cells_by_row[row]
		for column in range(row_cells.size() - 1):
			var horizontal_side := 0 if column % 2 == 0 else 1
			_connect_cells(row_cells[column], horizontal_side, row_cells[column + 1], horizontal_side)

		if row == rows - 1:
			continue
		for column in range(row_cells.size()):
			if column % 2 == 0:
				var down_cell = cells_by_row[row + 1][column + 1]
				_connect_cells(row_cells[column], 2, down_cell, 2)

func _cell_position(row: int, column: int) -> Vector3:
	var first_row_height = float(rows) * cell_spacing * (1/0.86)
	var row_width := float(row * 2)
	var x = (float(column) - row_width / 2.0) * cell_spacing
	var y = first_row_height - float(row) * cell_spacing * 1.4
	return Vector3(x, y, 0.0)

func _connect_cells(first: Interactable, first_side: int, second: Interactable, second_side: int) -> void:
	first.set_neighbor(first_side, second)
	second.set_neighbor(second_side, first)

func _choose_endpoints() -> void:
	var left_candidates := _boundary_candidates(func(cell) -> bool:
		return cell.column == 0
	)
	var right_candidates := _boundary_candidates(func(cell) -> bool:
		return cell.column == cell.row * 2
	)
	var bottom_candidates := _boundary_candidates(func(cell) -> bool:
		return cell.row == rows - 1 and cell.faces_up
	)
	var candidates := {
		"left": left_candidates,
		"right": right_candidates,
		"bottom": bottom_candidates
	}
	var categories: Array[String] = ["left", "right", "bottom"]
	var input_category := categories[_rng.randi_range(0, categories.size() - 1)]
	var output_categories := categories.filter(func(category: String) -> bool:
		return category != input_category
	)
	var output_category: String = output_categories[_rng.randi_range(0, output_categories.size() - 1)]

	input_cell = _pick_endpoint(candidates[input_category])
	output_cell = _pick_endpoint(candidates[output_category], input_cell)
	if input_cell == null or output_cell == null:
		push_error("Could not place distinct triangular pipe endpoints.")
		return

	input_side = _pick_open_side(input_cell)
	output_side = _pick_open_side(output_cell)

func _boundary_candidates(predicate: Callable) -> Array:
	var result: Array = []
	for cell in cells:
		if predicate.call(cell) and not cell.get_open_sides().is_empty():
			result.append(cell)
	return result

func _pick_endpoint(candidates: Array, excluded: Interactable = null) -> Interactable:
	var available := candidates.filter(func(candidate) -> bool:
		return candidate != excluded
	)
	if available.is_empty():
		return null
	return available[_rng.randi_range(0, available.size() - 1)]

func _pick_open_side(cell: Interactable) -> int:
	var open_sides: Array = cell.get_outward_sides(rows)
	if open_sides.is_empty():
		print("What")
		open_sides = cell.get_open_sides()
	return open_sides[_rng.randi_range(0, open_sides.size() - 1)]

func _build_solvable_layout() -> void:
	var path := _find_cell_path(input_cell, output_cell)
	if path.is_empty():
		push_error("Could not build a path between triangular pipe endpoints.")
		return

	var path_indices := {}
	for index in range(path.size()):
		path_indices[path[index]] = index

	for cell in cells:
		if not path_indices.has(cell):
			cell.set_connections(_random_pipe_mask())

	for index in range(path.size()):
		var cell: Interactable = path[index]
		var mask := 0
		if index > 0:
			mask |= 1 << cell.get_side_to(path[index - 1])
		if index < path.size() - 1:
			mask |= 1 << cell.get_side_to(path[index + 1])
		if mask == 0b001 or mask == 0b010 or mask == 0b100:
			var path_side: int = cell.get_side_to(path[index - 1]) if index > 0 else cell.get_side_to(path[index + 1])
			mask |= 1 << ((path_side + 1) % 3)
		cell.set_connections(mask)

	for cell in cells:
		if cell.connections != 0b111:
			cell.set_pipe_rotation(_rng.randi_range(0, 2))

func _random_pipe_mask() -> int:
	if _rng.randi_range(0, 3) == 0:
		return 0b111
	var masks := [0b011, 0b101, 0b110]
	return masks[_rng.randi_range(0, masks.size() - 1)]

func _find_cell_path(start: Interactable, goal: Interactable) -> Array:
	var queue: Array[Interactable] = [start]
	var previous := {start: null}
	while not queue.is_empty():
		var current: Interactable = queue.pop_front()
		if current == goal:
			break
		for neighbor in current.neighbors:
			if neighbor != null and not previous.has(neighbor):
				previous[neighbor] = current
				queue.append(neighbor)
	if not previous.has(goal):
		return []

	var path: Array = []
	var current_cell = goal
	while current_cell != null:
		path.push_front(current_cell)
		current_cell = previous[current_cell]
	return path

func _create_endpoint_markers() -> void:
	_create_marker(input_cell, input_side, Color(0.2, 0.85, 1.0), "InputMarker")
	_create_marker(output_cell, output_side, Color(1.0, 0.35, 0.2), "OutputMarker")

func _create_marker(cell: Interactable, side: int, color: Color, marker_name: String) -> void:
	if cell == null or side < 0 or side > 2:
		push_error("Cannot create marker for invalid cell or side.")
		return
	var marker := MeshInstance3D.new()
	marker.name = marker_name
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.12
	mesh.bottom_radius = 0.12
	mesh.height = 0.2
	mesh.radial_segments = 6
	marker.mesh = mesh
	marker.rotation.x = PI / 2.0
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = 2.0
	marker.material_override = material
	add_child(marker)
	marker.position = cell.position + _side_direction(cell, side) * cell_spacing

func _side_direction(cell: Interactable, side: int) -> Vector3:
	var directions := [
		Vector3(0.986, 0.164, 0.0) * 0.5,
		Vector3(-0.986, 0.164, 0.0) * 0.5,
		Vector3(0.0, -0.5, 0.0)
	]
	return directions[side].rotated(Vector3.FORWARD, cell.global_rotation.z)

func _on_cell_interacted(_cell: Interactable) -> void:
	pass

func _on_test_button_interacted(_button: Interactable) -> void:
	AudioManager.play_sfx_at_3d("text", global_position)
	result_label.text = ""
	success_label.text = ""
	if _completed:
		return
	var connected := _is_input_connected_to_output()

	var label_tween = create_tween()
	label_tween.set_trans(Tween.TRANS_LINEAR)
	label_tween.tween_property(result_label, "text", "Result:", 1.0)
	await label_tween.finished
	await get_tree().create_timer(1.0).timeout

	success_label.modulate = Color(0.0, 0.5, 0) if connected else Color(1.0, 0.1, 0.1)

	label_tween = create_tween()
	label_tween.set_trans(Tween.TRANS_LINEAR)
	label_tween.tween_property(success_label, "text", "SUCCESS" if connected else "FAILURE", 1.0)
	
	if connected:
		var path := find_input_output_path()
		for cell in path:
			cell.highlight_pipe(success_path_material)
		label_tween.set_parallel()
		label_tween.tween_property(success_side_label, "text", "Knowledge data\nflow connected", 1.0)
		await label_tween.finished
		AudioManager.play_sfx_at_3d("antivirus_pass", global_position)
		await get_tree().create_timer(2.0).timeout
		_completed = true
		exit_game()		
		minigame_completed.emit(self)
	else:
		AudioManager.play_sfx_at_3d("error", global_position)
		await get_tree().create_timer(2.0).timeout
		result_label.text = ""
		success_label.text = ""


func _is_input_connected_to_output() -> bool:
	return not find_input_output_path().is_empty()

func find_input_output_path() -> Array:
	if input_cell == null or output_cell == null:
		return []
	if input_side < 0 or output_side < 0:
		return []
	if (input_cell.connections & (1 << input_side)) == 0:
		return []
	if (output_cell.connections & (1 << output_side)) == 0:
		return []
	var queue: Array[Interactable] = [input_cell]
	var previous := {input_cell: null}
	while not queue.is_empty():
		var current: Interactable = queue.pop_front()
		if current == output_cell:
			break
		for side in range(3):
			var neighbor: Interactable = current.get_neighbor(side)
			if neighbor == null or previous.has(neighbor):
				continue
			var other_side: int = neighbor.get_side_to(current)
			if (current.connections & (1 << side)) == 0:
				continue
			if (neighbor.connections & (1 << other_side)) == 0:
				continue
			previous[neighbor] = current
			queue.append(neighbor)
	if not previous.has(output_cell):
		return []

	var path: Array = []
	var current_cell: Interactable = output_cell
	while current_cell != null:
		path.push_front(current_cell)
		current_cell = previous[current_cell]
	return path
