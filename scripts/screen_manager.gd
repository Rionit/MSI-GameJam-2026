@tool
extends Node
class_name ScreenManager

enum AspectRatio {
	R_1x1,
	R_1x2,
	R_2x1,
	R_4x3,
	R_16x9,
	R_9x16,
	R_32x5
}

const RATIO_STRINGS = {
	AspectRatio.R_1x1: "1x1",
	AspectRatio.R_1x2: "1x2",
	AspectRatio.R_2x1: "2x1",
	AspectRatio.R_4x3: "4x3",
	AspectRatio.R_16x9: "16x9",
	AspectRatio.R_9x16: "9x16",
	AspectRatio.R_32x5: "32x5",
}

@export_category("Setup Helper")
@export_group("Asset Scanning")
@export var target_ratio: AspectRatio = AspectRatio.R_16x9
@export_dir var video_folder: String = "res://videos/"
@export var mesh_search_root: NodePath ## Optional root node to search. If left empty, defaults to the current edited scene root.
@export_tool_button("Find Unused Assets", "AcceptDialog") var find_unused_assets = _scan_unused_assets
@export_tool_button("Find Duplicate Assets", "AcceptDialog") var find_duplicate_pairs = _scan_duplicate_pairs
@export_tool_button("Find Invalid Pairs", "AcceptDialog") var find_invalid_pairs = _scan_invalid_pairs
@export_group("")

@export_category("Setup")
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
	viewport.render_target_update_mode = SubViewport.UPDATE_WHEN_VISIBLE
	viewport.gui_disable_input = true
	viewport.disable_3d = true
	
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

#region helper stuff for searching

func _scan_unused_assets():
	var ratio_str = RATIO_STRINGS[target_ratio]
	print("\n--- [ScreenManager] Scanning for Unused Assets (Target Ratio: %s) ---" % ratio_str)
	
	# 1. Collect currently used video streams and mesh nodes
	var used_videos: Array[VideoStream] = []
	var used_mesh_nodes: Array[Node] = []
	
	for pair in pairs:
		if not pair:
			continue
		if pair.video_stream and not pair.video_stream in used_videos:
			used_videos.append(pair.video_stream)
		if not pair.mesh_path.is_empty():
			var node = get_node_or_null(pair.mesh_path)
			if node and not node in used_mesh_nodes:
				used_mesh_nodes.append(node)

	# 2. Scan and check Unused Videos (from folder)
	var all_videos = _get_files_in_directory(video_folder, [".ogv", ".webm", ".mp4"])
	var unused_videos_count = 0
	
	print("\n[Unused Videos for %s]" % ratio_str)
	for file_path in all_videos:
		var file_name = file_path.get_file().get_basename()
		if _matches_ratio(file_name, ratio_str):
			var res = load(file_path) as VideoStream
			if res and not res in used_videos:
				print("  - ", file_path)
				unused_videos_count += 1
	if unused_videos_count == 0:
		print("  (None found - all %s-named videos are in use)" % ratio_str)

	# 3. Scan and check Unused Meshes (from Scene Tree)
	print("\n[Unused Mesh Nodes in Tree for %s]" % ratio_str)
	var root_node: Node = null
	if not mesh_search_root.is_empty():
		root_node = get_node_or_null(mesh_search_root)
	elif Engine.is_editor_hint():
		var editor_interface = Engine.get_singleton("EditorInterface")
		if editor_interface:
			root_node = editor_interface.get_edited_scene_root()
	
	if not root_node:
		root_node = self

	var unused_meshes_count = 0
	if root_node:
		var ratio_nodes = _find_ratio_nodes_recursive(root_node, ratio_str)
		for node in ratio_nodes:
			if not node in used_mesh_nodes:
				var path_str = str(root_node.get_path_to(node))
				print("  - Node Name: ", node.name, " | Path: ", path_str)
				unused_meshes_count += 1
				
	if unused_meshes_count == 0:
		print("  (None found - all %s-named mesh nodes are in use)" % ratio_str)
		
	print("---------------------------------------------------\n")

func _scan_duplicate_pairs():
	print("\n--- [ScreenManager] Scanning for Duplicate Meshes/Videos in Pairs ---")
	var mesh_indices = {}
	var video_indices = {}
	
	for i in range(pairs.size()):
		var pair = pairs[i]
		if not pair:
			continue
		if not pair.mesh_path.is_empty():
			var path_str = str(pair.mesh_path)
			if not mesh_indices.has(path_str):
				mesh_indices[path_str] = []
			mesh_indices[path_str].append(i)
		if pair.video_stream:
			if not video_indices.has(pair.video_stream):
				video_indices[pair.video_stream] = []
			video_indices[pair.video_stream].append(i)
			
	print("\n[Duplicate Mesh Paths]")
	var dup_meshes = 0
	for path in mesh_indices:
		if mesh_indices[path].size() > 1:
			print("  - Mesh Path '%s' used at indices: %s" % [path, mesh_indices[path]])
			dup_meshes += 1
	if dup_meshes == 0:
		print("  (None found)")
		
	print("\n[Duplicate Video Streams]")
	var dup_videos = 0
	for stream in video_indices:
		if video_indices[stream].size() > 1:
			print("  - Video Stream '%s' used at indices: %s" % [stream.resource_path if stream else "Unknown", video_indices[stream]])
			dup_videos += 1
	if dup_videos == 0:
		print("  (None found)")
	print("---------------------------------------------------\n")

func _scan_invalid_pairs():
	print("\n--- [ScreenManager] Scanning for Invalid/Incomplete Pairs ---")
	var invalid_count = 0
	for i in range(pairs.size()):
		var pair = pairs[i]
		var issues = []
		if not pair:
			print("  - Index %d: Pair is null" % i)
			invalid_count += 1
			continue
		if pair.mesh_path.is_empty():
			issues.append("Mesh path is empty")
		if not pair.video_stream:
			issues.append("Video stream is nil")
			
		if issues.size() > 0:
			print("  - Index %d: %s" % [i, ", ".join(issues)])
			invalid_count += 1
			
	if invalid_count == 0:
		print("  (None found - all pairs have valid mesh paths and video streams)")
	print("---------------------------------------------------\n")

# Recursively search the tree for nodes matching the target ratio prefix
func _find_ratio_nodes_recursive(node: Node, ratio_str: String) -> Array[Node]:
	var result: Array[Node] = []
	if _matches_ratio(node.name, ratio_str):
		result.append(node)
	
	for child in node.get_children():
		result.append_array(_find_ratio_nodes_recursive(child, ratio_str))
	return result

# Helper to find video files in a folder
func _get_files_in_directory(path: String, valid_extensions: Array) -> Array[String]:
	var files: Array[String] = []
	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "" :
			if dir.current_is_dir():
				if not file_name.begins_with("."):
					files.append_array(_get_files_in_directory(path.path_join(file_name), valid_extensions))
			else:
				var ext = "." + file_name.get_extension().to_lower()
				if ext in valid_extensions:
					files.append(path.path_join(file_name))
			file_name = dir.get_next()
	return files

# Checks if a name starts with the ratio string followed by a separator (e.g., "16x9_screen")
func _matches_ratio(text: String, ratio_str: String) -> bool:
	var lower_text = text.to_lower()
	var lower_ratio = ratio_str.to_lower()
	return lower_text.begins_with(lower_ratio + "_") or lower_text.begins_with(lower_ratio + "-") or lower_text == lower_ratio
#endregion
