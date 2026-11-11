extends Interactable

class_name Switch

@export var switch_down_mesh: Mesh
@export var mesh_instance: MeshInstance3D

func _ready() -> void:
    interacted.connect(_on_switch_activated)

    
func _on_switch_activated() -> void:
    mesh_instance.mesh = switch_down_mesh