extends StaticBody3D
class_name Switch

@export var switch_down_mesh: Mesh
@export var mesh_instance: MeshInstance3D
@export var outline_material: Material 

signal interacted()

func _ready() -> void:
    interacted.connect(_on_switch_activated)

    
func _on_switch_activated() -> void:
    mesh_instance.mesh = switch_down_mesh
    interacted.emit()

func highlight() -> void:
    if mesh_instance and outline_material:
        mesh_instance.material_overlay = outline_material

func unhighlight() -> void:
    if mesh_instance:
        mesh_instance.material_overlay = null
