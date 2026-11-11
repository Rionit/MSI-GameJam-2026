extends StaticBody3D
class_name Switch

@export var mesh_instance: MeshInstance3D
@export var outline_material: Material 
@export var handle: MeshInstance3D
@onready var main: GameManager = $"../.."

# 1. Declare the signal to accept the player parameter
signal interacted(player: PlayerController)

func _ready() -> void:
	interacted.connect(_on_switch_activated)
	
func _on_switch_activated(player: PlayerController) -> void:
	print("hello?")
	var tween = create_tween()
	# Note: Godot uses radians for rotation. Vector3(0,0,30.0) rotates 30 radians (~1718 degrees). 
	# If you want 30 degrees, use deg_to_rad(30.0) instead!
	tween.tween_property(handle, "rotation", Vector3(0.0, 0.0, deg_to_rad(30.0)), 1.0)
	tween.finished.connect(func(): main.on_screen_connected())

func interact(player: PlayerController) -> void:
	# 2. Emit the 'player' passed into this function, NOT 'self'
	interacted.emit(player)
	print("halo?")

func highlight() -> void:
	if mesh_instance and outline_material:
		mesh_instance.material_overlay = outline_material

func unhighlight() -> void:
	if mesh_instance:
		mesh_instance.material_overlay = null
