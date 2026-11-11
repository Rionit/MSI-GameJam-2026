extends Interactable

class_name GraetzDiode

## Direction the diode is passing current TO. (LEFT -> passes signal from RIGHT to LEFT, blocks signal from LEFT to RIGHT)
enum DiodeDirection {
	LEFT,
	RIGHT,
	INVALID
}

@export var left_junction : GraetzJunction
@export var right_junction : GraetzJunction
@export var collider : CollisionShape3D
@export var direction : DiodeDirection
@export var mesh : MeshInstance3D

func _ready() -> void:
	left_junction.add_connection(self)
	right_junction.add_connection(self)

	interacted.connect(on_diode_interacted)
	if direction == DiodeDirection.RIGHT:
		rotate_meshes()

func resolve_signal_from(source : GraetzJunction) -> GraetzJunction:
	# Pass - right junction
	if source == left_junction and direction == DiodeDirection.RIGHT:
		return right_junction
	# Pass - left junction
	elif source == right_junction and direction == DiodeDirection.LEFT:
		return left_junction
	# Block
	else:
		return null

## Returns where is the source connected to this diode. (LEFT or RIGHT)
func getDirFrom(source : Node3D) -> DiodeDirection:
	if source == left_junction:
		return DiodeDirection.LEFT
	elif source == right_junction:
		return DiodeDirection.RIGHT
	else:
		return DiodeDirection.INVALID

func on_diode_interacted(source : Node3D) -> void:
	change_dir()
	AudioManager.play_sfx_at_3d("breaker_flip", global_position)

## Returns the destinations that the diode is connected to, based on its current direction.
func get_destinations() -> GraetzJunction:
	if direction == DiodeDirection.LEFT:
		return left_junction
	else:
		return right_junction

func change_dir():
	direction = DiodeDirection.LEFT if direction == DiodeDirection.RIGHT else DiodeDirection.RIGHT
	rotate_meshes()

func rotate_meshes():
	mesh.rotate_z(deg_to_rad(180))	# visual
	rotate_z(deg_to_rad(180))		# input
