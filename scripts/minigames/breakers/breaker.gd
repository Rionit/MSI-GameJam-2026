extends Interactable

class_name Breaker

@export var flip : Node3D
@export var switch_flipped : bool

@export var collider : CollisionShape3D
@export var breaker_mesh : MeshInstance3D

@export var default_material : StandardMaterial3D
@export var flipped_material : StandardMaterial3D


func flip_breaker() -> void:
	switch_flipped = !switch_flipped

	breaker_mesh.set_surface_override_material(0, flipped_material if switch_flipped else default_material)

	# TODO: Flip sound
	flip.rotate_y(deg_to_rad(90) * (1 if switch_flipped else -1))

func deactivate():
	collider.disabled = true

func activate():
	collider.disabled = false
