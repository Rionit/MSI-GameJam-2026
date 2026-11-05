extends Minigame

class_name MatrixMinigame

@export var cell_scene : PackedScene

@export var grid : Array[Array]

@export var grid_size : int = 6

@export var num_cells_to_select : int

func enter_game() -> void:
	print("Entering Matrix Minigame")
	for row in grid:
		for cell in row:
			cell.activate()
	self.visible = true

func exit_game() -> void:
	for row in grid:
		for cell in row:
			cell.deactivate()
	self.visible = false

func _ready() -> void:

	# Generate blocked cells (first, set random free cells s.t. each row and column has at least one free cell)
	# Then, generate 1 to (grid_size/2) blocked cells randomly for each row, excluding the free cells in each row.
	
	var random = RandomNumberGenerator.new()

	var free_cells_in_row : Array[int] = []
	
	var blocked_cells_in_row : Array[Array] = []

	num_cells_to_select = grid_size * grid_size

	# Set random free cells
	for x in range(grid_size):
		var free_cell_y = random.randi() % grid_size
		free_cells_in_row.append(free_cell_y)
		blocked_cells_in_row.append([])
		
		var rand_num_blocked_cells = random.randi() % (grid_size / 2) + 1
		var y = 0
		num_cells_to_select -= rand_num_blocked_cells
		while y < rand_num_blocked_cells:
			var rand_blocked_cell_y = random.randi() % grid_size
			if rand_blocked_cell_y == free_cell_y || rand_blocked_cell_y in blocked_cells_in_row[x]:
				continue
			else:
				blocked_cells_in_row[x].append(rand_blocked_cell_y)
				y += 1
	self.visible = false

	for x in range(grid_size):
		grid.append([])
		for y in range(grid_size):
			var cell = cell_scene.instantiate()
			cell.setup_cell(y in blocked_cells_in_row[x], Vector2i(x, y))
			add_child(cell)
			cell.position = Vector3( x*1, y * 1, 0)

			cell.interacted.connect(_on_cell_interacted)
			cell.deactivate()

			grid[x].append(cell)

func _on_cell_interacted(cell: Interactable) -> void:
	print("Interacted with cell at " + str(cell.position))
	var matrix_cell = cell as MatrixCell
	var current_selection_state = matrix_cell.selected
	
	# 1. Toggle the clicked cell's selection state
	var new_selection_state = !current_selection_state
	#print("Directly selecting cell at " + str(matrix_cell.grid_position) + " to " + str(new_selection_state))
	matrix_cell.set_directly_selected(new_selection_state)
	
	# Track changes for the clicked cell
	var selected_before = current_selection_state
	var selected_after = new_selection_state
	var changed_count = 0

	if selected_before == false and selected_after == true:
		# Was unselected, now selected
		changed_count += 1
	elif selected_before == true and selected_after == false:
		# Was selected, now unselected
		changed_count -= 1
		
	# Indirectly select/unselect non-blocked cells in the same row and column
	var row = matrix_cell.grid_position.y
	var col = matrix_cell.grid_position.x
	
	for x in range(grid_size):
		var other_cell = grid[x][row]
		if !other_cell.blocked and other_cell != matrix_cell:
			var other_cell_selected_before = other_cell.num_selected > 0

			#print("Indirectly selecting cell at " + str(other_cell.grid_position) + " to " + str(new_selection_state))
			other_cell.set_indirectly_selected(new_selection_state)
			var other_cell_selected_after = other_cell.num_selected > 0
			
			if other_cell_selected_before == false and other_cell_selected_after == true:
				changed_count += 1
			elif other_cell_selected_before == true and other_cell_selected_after == false:
				changed_count -= 1

	for y in range(grid_size):
		var other_cell = grid[col][y]
		if !other_cell.blocked and other_cell != matrix_cell:
			var other_cell_selected_before = other_cell.num_selected > 0
			#print("Indirectly selecting cell at " + str(other_cell.grid_position) + " to " + str(new_selection_state))
			other_cell.set_indirectly_selected(new_selection_state)
			var other_cell_selected_after = other_cell.num_selected > 0
			
			# Update count
			if other_cell_selected_before == false and other_cell_selected_after == true:
				changed_count += 1
			elif other_cell_selected_before == true and other_cell_selected_after == false:
				changed_count -= 1

	# Apply total change to num_cells_to_select
	num_cells_to_select -= changed_count
	print("num_cells_to_select: " + str(num_cells_to_select))
	# Check for win condition
	if num_cells_to_select <= 0:
		print("Minigame completed!")
		minigame_completed.emit(self)

	
