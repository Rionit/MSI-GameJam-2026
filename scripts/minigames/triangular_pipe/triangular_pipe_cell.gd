extends Interactable

class_name TriangularPipeCell

enum PipeShape {
	PAIR_12,
	PAIR_13,
	ALL
}

const SIDE_MASKS := {
	PipeShape.PAIR_12: 0b011,
	PipeShape.PAIR_13: 0b101,
	PipeShape.ALL: 0b111
}

@export var collider: CollisionShape3D
@export var pipe_segments: Array[MeshInstance3D]

var row: int
var column: int
var faces_up: bool
var connections: int = 0
var rotation_index: int = 0
var neighbors: Array[TriangularPipeCell] = [null, null, null]

func configure(cell_row: int, cell_column: int, points_up: bool) -> void:
	row = cell_row
	column = cell_column
	faces_up = points_up
	rotation.z = 0.0 if faces_up else PI
	_update_pipe_visual()

func set_neighbor(side: int, neighbor: TriangularPipeCell) -> void:
	if side < 0 or side > 2:
		push_error("TriangularPipeCell side must be between 0 and 2.")
		return
	neighbors[side] = neighbor

func get_neighbor(side: int) -> TriangularPipeCell:
	if side < 0 or side > 2:
		return null
	return neighbors[side]

func get_side_to(other: TriangularPipeCell) -> int:
	for side in range(neighbors.size()):
		if neighbors[side] == other:
			return side
	return -1

func get_open_sides() -> Array[int]:
	var open_sides: Array[int] = []
	for side in range(neighbors.size()):
		if neighbors[side] == null:
			open_sides.append(side)
	return open_sides

func get_outward_sides(num_rows: int) -> Array[int]:
	var outward_sides: Array[int] = []
	if row == num_rows - 1 and not faces_up:
		outward_sides.append(2)
	elif column == 0:
		outward_sides.append(1)
	elif column == row * 2:
		outward_sides.append(0)

	return outward_sides

func set_connections(connection_mask: int) -> void:
	connections = connection_mask & 0b111
	rotation_index = 0
	_update_pipe_visual()

func set_pair_connections(first_side: int, second_side: int) -> void:
	var connection_mask := (1 << first_side) | (1 << second_side)
	if connection_mask == 0b111:
		push_error("A pair pipe must use two different sides.")
		return
	set_connections(connection_mask)

func set_pipe_rotation(new_rotation: int) -> void:
	rotation_index = posmod(new_rotation, 3)
	connections = _rotate_mask(connections, rotation_index)
	_update_pipe_visual()

func rotate_pipe() -> void:
	if connections == SIDE_MASKS[PipeShape.ALL]:
		return
	rotation_index = (rotation_index + 1) % 3
	AudioManager.play_sfx_at_3d("text", global_position)
	connections = _rotate_mask(connections, 1)
	_update_pipe_visual()

func interact(_player: PlayerController) -> void:
	rotate_pipe()
	interacted.emit(self)

func activate() -> void:
	if collider:
		collider.disabled = false

func deactivate() -> void:
	if collider:
		collider.disabled = true

func highlight_pipe(material: Material) -> void:
	if material == null:
		return
	for pipe_segment in pipe_segments:
		if pipe_segment:
			pipe_segment.material_override = material

func _rotate_mask(mask: int, rotations: int) -> int:
	var rotated_mask := 0
	for side in range(3):
		if mask & (1 << side):
			rotated_mask |= 1 << ((side + rotations) % 3)
	return rotated_mask

func _update_pipe_visual() -> void:
	if pipe_segments.size() < 3:
		return
	for side in range(3):
		pipe_segments[side].visible = (connections & (1 << side)) != 0
