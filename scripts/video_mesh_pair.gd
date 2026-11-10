@tool
class_name VideoMeshPair
extends Resource

@export var mesh_path: NodePath
@export var video_stream: VideoStream
@export_tool_button("Select Mesh Node", "AcceptDialog") var select_mesh_button = _select_mesh

func _select_mesh() -> void:
	if mesh_path.is_empty():
		print("VideoMeshPair: mesh_path is empty.")
		return
	
	# Defer selection so the tool button finishes emitting its signal 
	# before the inspector updates/rebuilds and frees the button object.
	_perform_select.call_deferred()

func _perform_select() -> void:
	if Engine.is_editor_hint():
		var editor_interface = Engine.get_singleton("EditorInterface")
		if editor_interface:
			var scene_root = editor_interface.get_edited_scene_root()
			if scene_root:
				var node = scene_root.get_node_or_null(mesh_path)
				if not node:
					var path_str = str(mesh_path)
					if path_str.begins_with("."):
						node = scene_root.get_node_or_null(path_str.trim_prefix("."))
				
				if node:
					editor_interface.get_selection().clear()
					editor_interface.get_selection().add_node(node)
					editor_interface.edit_node(node)
					print("Successfully selected node: ", node.name)
				else:
					print("VideoMeshPair: Could not find node at path: ", mesh_path)
