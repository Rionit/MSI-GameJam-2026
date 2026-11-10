extends Interactable

class_name MatrixCell

@export var collider : CollisionShape3D

@export var normal_material : Material = preload("uid://b10ebpa8i8ioo")
@export var blocked_material : Material = preload("uid://bbptyvtgk0cd4")
@export var directly_selected_material : Material = preload("uid://dfiheunguoabh")
@export var indirectly_selected_material : Material = preload("uid://dkmwl6wuwbb60")

@export var grid_position : Vector2i = Vector2i(0, 0)


var blocked : bool = false
var selected : bool = false

func activate():
	collider.disabled = blocked || (!selected && num_selected > 0)

func deactivate():
	collider.disabled = true

## Number of times this cell has been selected (directly or indirectly). Used to determine when to reset the cell's material to normal.
var num_selected : int = 0 

func setup_cell(blocked: bool, gridPos: Vector2i):
	grid_position = gridPos
	self.blocked = blocked
	if blocked:
		print("Blocking cell at " + str(gridPos))
		mesh_instance.material_override = blocked_material
		collider.disabled = true
	else:
		set_normal()


func set_directly_selected(selected: bool):
	#AudioManager.play_sfx(Cell selection zvuk (click/switch flip/...))
	if selected:
		self.selected = true
		mesh_instance.material_override = directly_selected_material
		num_selected += 1
	else:
		self.selected = false
		num_selected -= 1
		set_normal()
	
func set_indirectly_selected(indir_selected: bool):
	if blocked:
		return

	if indir_selected:
		num_selected += 1
		if num_selected == 1:
			mesh_instance.material_override = indirectly_selected_material
			collider.disabled = true
	else:
		num_selected -= 1
		if num_selected == 0:
			set_normal()

func set_normal():
	mesh_instance.material_override = normal_material
	collider.disabled = false
