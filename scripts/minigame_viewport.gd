extends SubViewport

@onready var mesh_instance: MeshInstance3D = get_parent()

func _ready() -> void:
	# 1. Get the texture from this SubViewport
	var viewport_texture = get_texture()
	
	# 2. Check for an existing surface override material
	var mat: StandardMaterial3D = mesh_instance.get_surface_override_material(0) as StandardMaterial3D
	
	if not mat:
		# Fall back to the active material (checks override, then mesh resource)
		var active_mat = mesh_instance.get_active_material(0)
		if active_mat:
			mat = active_mat.duplicate() as StandardMaterial3D
		else:
			mat = StandardMaterial3D.new()
		
		# Apply it back as a surface override so it won't affect other objects
		mesh_instance.set_surface_override_material(0, mat)
	
	# 3. Enable emission and assign the SubViewport texture
	mat.emission_enabled = true
	mat.emission_texture = viewport_texture
	mat.emission_energy_multiplier = 1.0 # Adjust brightness if needed
	
