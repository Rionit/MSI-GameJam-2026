extends Interactable

class_name TriangularPipeTestButton

@export var collider: CollisionShape3D
@export var mesh: MeshInstance3D
@export var active_material: Material
@export var inactive_material: Material

func activate() -> void:
	if collider:
		collider.disabled = false
	if mesh and active_material:
		mesh.material_override = active_material

func deactivate() -> void:
	if collider:
		collider.disabled = true
	if mesh and inactive_material:
		mesh.material_override = inactive_material
