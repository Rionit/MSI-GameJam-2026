@tool
extends EditorPlugin

var editor_panel: Control
var undo_redo_mgr: EditorUndoRedoManager

func _enter_tree() -> void:
	undo_redo_mgr = get_undo_redo()

func _exit_tree() -> void:
	if editor_panel:
		editor_panel.queue_free()

func _has_main_screen() -> bool:
	return false

func _handles(object: Object) -> bool:
	return object is AudioLibrary

func _edit(object: Object) -> void:
	if object is AudioLibrary:
		if not editor_panel:
			_init_editor_panel()
		editor_panel.set_audio_library(object)

func _init_editor_panel() -> void:
	editor_panel = AudioLibraryEditorUI.new() # Or load your instantiated scene
	# Add to bottom panel or main editor interface
	add_control_to_bottom_panel(editor_panel, "Audio Library")
	make_bottom_panel_item_visible(editor_panel)
