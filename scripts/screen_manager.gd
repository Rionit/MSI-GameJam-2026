@tool
extends Node
class_name ScreenManager

@export var pairs: Array[VideoMeshPair] = []

@export_range(0, 100, 1) var active_screen_count: int = 0:
	set(value):
		active_screen_count = clampi(value, 0, pairs.size())
		# Only update if the node is already inside the scene tree / ready
		if is_node_ready():
			_update_screens()

@export var crt_shader : ShaderMaterial
@export var crt_turn_on : VideoStream
@export var crt_turn_off : VideoStream

func _ready() -> void:
	# Ensure initial value is clamped and set up screens on start
	active_screen_count = clampi(active_screen_count, 0, pairs.size())
	_update_screens()

func _update_screens() -> void:
	for i in range(pairs.size()):
		var pair = pairs[i]
		if not pair or pair.mesh_path.is_empty() or not pair.video_stream:
			continue
		
		var mesh_instance := get_node_or_null(pair.mesh_path) as MeshInstance3D
		if not mesh_instance:
			continue
		
		# If within the active count, turn it on (if not already on)
		if i < active_screen_count:
			if not mesh_instance.has_node("ScreenViewport"):
				_activate_screen(mesh_instance, pair)
		# If beyond the active count, turn it off (if currently on)
		else:
			if mesh_instance.has_node("ScreenViewport"):
				_deactivate_screen(mesh_instance, pair)

func _activate_screen(mesh_instance: MeshInstance3D, pair: VideoMeshPair) -> void:
	# 0. Wait a bit before splitscreen starts TODO: this is a bit dirty but whatever
	await get_tree().create_timer(1.0).timeout
	
	# 1. Create the VideoStreamPlayer node and assign the stream
	var video_player := VideoStreamPlayer.new()
	video_player.name = "VideoPlayer"
	
	if crt_turn_on:
		video_player.stream = crt_turn_on
		video_player.loop = false
	else:
		video_player.stream = pair.video_stream
		video_player.loop = true
		
	video_player.autoplay = true
	video_player.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	# 2. Extract the video resolution dynamically from the player's video texture
	var video_size: Vector2i = Vector2i(1280, 720) # Fallback default
	var video_texture := video_player.get_video_texture()
	if video_texture and video_texture.get_size() != Vector2.ZERO:
		video_size = Vector2i(video_texture.get_size())
	
	# 3. Create a SubViewport matching the exact video dimensions
	var viewport := SubViewport.new()
	viewport.name = "ScreenViewport"
	viewport.size = video_size
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	
	# Add the video player first so it renders in the background
	viewport.add_child(video_player)
	
	# 4. Add a full-rect ColorRect on top to act as the CRT post-processing layer
	if crt_shader:
		var color_rect := ColorRect.new()
		color_rect.name = "CRTFilter"
		color_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		
		# Duplicate the shader material so each screen manages its instance independently
		var mat = crt_shader.duplicate() as ShaderMaterial
		mat.set_shader_parameter("resolution", Vector2(video_size))
		
		# Give each screen a unique random time offset so their scanlines are desynchronized
		mat.set_shader_parameter("time_offset", randf() * 100.0)
		
		var tween = create_tween()
		tween.tween_interval(1.0) # wait for crt turn on to finish
		tween.tween_method(set_shader_parameter_value.bind("static_noise_intensity", mat), 1.0, 0.3, 0.5)
		tween.parallel().tween_method(set_shader_parameter_value.bind("vignette_intensity", mat), -1.0, 0.4, 0.5)
		tween.parallel().tween_method(
			set_shader_parameter_value.bind("resolution", mat), 
			Vector2(0.0, 0.0), 
			Vector2(video_size.x, video_size.y), 
			5.0
		)
		
		color_rect.material = mat
		viewport.add_child(color_rect)
	
	mesh_instance.add_child(viewport)
	
	# 5. Create an unshaded, emissive StandardMaterial3D to map the Viewport texture onto the 3D mesh
	var material := StandardMaterial3D.new()
	material.albedo_texture = viewport.get_texture()
	material.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	material.emission_enabled = true
	material.emission_texture = viewport.get_texture()
	material.emission_energy_multiplier = 1.0
	
	# 6. Apply to mesh
	mesh_instance.material_override = material
	
	# Once the turn-on video finishes, switch to mesh pair video and update viewport/shader size
	if crt_turn_on:
		video_player.finished.connect(func() -> void:
			if not is_instance_valid(video_player):
				return
			video_player.stream = pair.video_stream
			video_player.loop = true
			video_player.play()
			
			# Resize viewport and shader to match the new video stream dimensions
			_update_viewport_resolution(video_player, viewport)
		, CONNECT_ONE_SHOT)

	# 7. Play video
	video_player.play()

func _update_viewport_resolution(video_player: VideoStreamPlayer, viewport: SubViewport) -> void:
	# Give the video stream one frame to load its texture dimensions after changing streams
	await get_tree().process_frame
	if not is_instance_valid(video_player) or not is_instance_valid(viewport):
		return
		
	var new_size := Vector2i(1280, 720)
	var video_texture := video_player.get_video_texture()
	if video_texture and video_texture.get_size() != Vector2.ZERO:
		new_size = Vector2i(video_texture.get_size())
		
	viewport.size = new_size
	
	var color_rect = viewport.get_node_or_null("CRTFilter") as ColorRect
	if color_rect and color_rect.material is ShaderMaterial:
		var mat = color_rect.material as ShaderMaterial
		mat.set_shader_parameter("resolution", Vector2(new_size))

func set_shader_parameter_value(value, parameter: String, material: ShaderMaterial):
	material.set_shader_parameter(parameter, value)

func _deactivate_screen(mesh_instance: MeshInstance3D, pair: VideoMeshPair = null) -> void:
	var viewport = mesh_instance.get_node_or_null("ScreenViewport")
	if not viewport:
		return
		
	var video_player = viewport.get_node_or_null("VideoPlayer") as VideoStreamPlayer
	
	if crt_turn_off and video_player and video_player.stream != crt_turn_off:
		video_player.loop = false
		video_player.stream = crt_turn_off
		
		# If turn_off has a different resolution, update viewport size before playing it
		_update_viewport_resolution(video_player, viewport)
		video_player.play()
		
		video_player.finished.connect(func() -> void:
			if is_instance_valid(viewport):
				viewport.queue_free()
			if is_instance_valid(mesh_instance):
				mesh_instance.material_override = null
		, CONNECT_ONE_SHOT)
	else:
		viewport.queue_free()
		mesh_instance.material_override = null
