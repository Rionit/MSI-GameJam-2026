@tool
extends Control
class_name AudioLibraryEditorUI

var audio_library: AudioLibrary

# UI Components
var tab_container: TabContainer
var sfx_list: ItemList
var music_list: ItemList
var search_bar: LineEdit
var details_panel: VBoxContainer
var preview_player: AudioStreamPlayer

# Active selection tracking
var current_selected_index: int = -1
var is_editing_sfx: bool = true
var search_query: String = ""

func _init() -> void:
	name = "AudioLibraryEditor"
	custom_minimum_size = Vector2(0, 350)

func _ready() -> void:
	_build_ui()
	preview_player = AudioStreamPlayer.new()
	add_child(preview_player)

func _build_ui() -> void:
	var main_layout = HBoxContainer.new()
	main_layout.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 5)
	add_child(main_layout)

	# --- Left Pane: List & Search ---
	var left_vbox = VBoxContainer.new()
	left_vbox.custom_minimum_size = Vector2(280, 0)
	main_layout.add_child(left_vbox)

	search_bar = LineEdit.new()
	search_bar.placeholder_text = "Search audio tags..."
	search_bar.clear_button_enabled = true
	search_bar.text_changed.connect(_on_search_text_changed)
	left_vbox.add_child(search_bar)

	tab_container = TabContainer.new()
	tab_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tab_container.tab_changed.connect(_on_tab_changed)
	left_vbox.add_child(tab_container)

	sfx_list = ItemList.new()
	sfx_list.name = "SFX"
	sfx_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sfx_list.item_selected.connect(_on_sfx_selected)
	tab_container.add_child(sfx_list)

	music_list = ItemList.new()
	music_list.name = "Music"
	music_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	music_list.item_selected.connect(_on_music_selected)
	tab_container.add_child(music_list)

	# Action Buttons (Add / Delete / Save / Refresh)
	var btn_hbox = HBoxContainer.new()
	left_vbox.add_child(btn_hbox)

	var add_btn = Button.new()
	add_btn.text = "Add"
	add_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_btn.pressed.connect(_on_add_pressed)
	btn_hbox.add_child(add_btn)

	var delete_btn = Button.new()
	delete_btn.text = "Delete"
	delete_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	delete_btn.pressed.connect(_on_delete_pressed)
	btn_hbox.add_child(delete_btn)

	var save_btn = Button.new()
	save_btn.text = "Save"
	save_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	save_btn.pressed.connect(func():
		_commit_change()
		print("AudioLibrary manually saved.")
	)
	btn_hbox.add_child(save_btn)

	var refresh_btn = Button.new()
	refresh_btn.text = "Refresh"
	refresh_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	refresh_btn.pressed.connect(_on_refresh_pressed)
	btn_hbox.add_child(refresh_btn)

	# --- Right Pane: Details & Preview ---
	details_panel = VBoxContainer.new()
	details_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	details_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_layout.add_child(details_panel)

func _on_refresh_pressed() -> void:
	if not audio_library or audio_library.resource_path.is_empty():
		print("No resource path found to refresh from.")
		return
	
	# Force reload from disk, ignoring memory cache to pick up external changes
	var reloaded = ResourceLoader.load(audio_library.resource_path, "", ResourceLoader.CACHE_MODE_IGNORE)
	if reloaded is AudioLibrary:
		audio_library = reloaded
		current_selected_index = -1
		refresh_lists()
		_clear_details()
		EditorInterface.get_inspector().update_tree()
		print("AudioLibrary successfully refreshed from disk.")
	else:
		print("Failed to reload AudioLibrary from disk.")

func set_audio_library(library: AudioLibrary) -> void:
	audio_library = library
	refresh_lists()

func _save_resource(resource: Resource) -> void:
	if resource and not resource.resource_path.is_empty():
		ResourceSaver.save(resource, resource.resource_path)
		EditorInterface.get_resource_filesystem().update_file(resource.resource_path)

func _commit_change() -> void:
	if audio_library:
		audio_library.emit_changed()
		_save_resource(audio_library)
		
func refresh_lists() -> void:
	if not audio_library:
		return
	
	sfx_list.clear()
	for i in range(audio_library.sound_effects.size()):
		var sfx = audio_library.sound_effects[i]
		if sfx:
			var tag_name = sfx.tag if not sfx.tag.is_empty() else "[Unnamed SFX]"
			if search_query.is_empty() or search_query in tag_name.to_lower():
				var idx = sfx_list.add_item(tag_name)
				sfx_list.set_item_metadata(idx, i)
		else:
			if search_query.is_empty() or "null" in search_query:
				var idx = sfx_list.add_item("[Null SFX Reference]")
				sfx_list.set_item_metadata(idx, i)

	music_list.clear()
	for i in range(audio_library.music_tracks.size()):
		var music = audio_library.music_tracks[i]
		if music:
			var tag_name = music.tag if not music.tag.is_empty() else "[Unnamed Track]"
			if search_query.is_empty() or search_query in tag_name.to_lower():
				var idx = music_list.add_item(tag_name)
				music_list.set_item_metadata(idx, i)
		else:
			if search_query.is_empty() or "null" in search_query:
				var idx = music_list.add_item("[Null Music Reference]")
				music_list.set_item_metadata(idx, i)

func _on_tab_changed(tab_idx: int) -> void:
	is_editing_sfx = (tab_idx == 0)
	current_selected_index = -1
	_clear_details()

func _on_sfx_selected(index: int) -> void:
	current_selected_index = sfx_list.get_item_metadata(index)
	is_editing_sfx = true
	_populate_sfx_details(audio_library.sound_effects[current_selected_index])

func _on_music_selected(index: int) -> void:
	current_selected_index = music_list.get_item_metadata(index)
	is_editing_sfx = false
	_populate_music_details(audio_library.music_tracks[current_selected_index])

func _clear_details() -> void:
	for child in details_panel.get_children():
		child.queue_free()

func _populate_sfx_details(sfx: SFX) -> void:
	_clear_details()
	if not sfx:
		return

	var scroll = ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	details_panel.add_child(scroll)

	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(vbox)

	# Header / Preview section
	var header_lbl = Label.new()
	header_lbl.text = "Editing SFX: " + (sfx.tag if not sfx.tag.is_empty() else "[Unnamed]")
	header_lbl.add_theme_font_size_override("font_size", 18)
	vbox.add_child(header_lbl)

	var preview_hbox = HBoxContainer.new()
	vbox.add_child(preview_hbox)

	var preview_btn = Button.new()
	preview_btn.text = "▶ Preview Sound Effect"
	preview_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	preview_btn.pressed.connect(func():
		var stream = sfx.get_next_stream()
		if stream:
			preview_player.stream = stream
			preview_player.volume_db = sfx.volume_db
			
			# Apply base pitch scale combined with randomness offset
			var final_pitch = sfx.pitch_scale + randf_range(-sfx.pitch_randomness, sfx.pitch_randomness)
			preview_player.pitch_scale = final_pitch
			
			preview_player.play()
	)
	preview_hbox.add_child(preview_btn)

	var stop_btn = Button.new()
	stop_btn.text = "⏹ Stop"
	stop_btn.pressed.connect(func():
		if preview_player.playing:
			preview_player.stop()
	)
	preview_hbox.add_child(stop_btn)

	# Tag Field
	_add_input_field(vbox, "Tag Name:", sfx.tag, func(new_text):
		sfx.tag = new_text
		_commit_change()
		refresh_lists()
	)

	# Volume & Pitch Sliders
	_add_slider_field(vbox, "Volume (dB):", sfx.volume_db, -50.0, 20.0, 0.5, func(val):
		sfx.volume_db = val
		_commit_change()
	)

	_add_slider_field(vbox, "Pitch Scale:", sfx.pitch_scale, 0.5, 2.0, 0.05, func(val):
		sfx.pitch_scale = val
		_commit_change()
	)

	# Variation Settings Section
	var var_sep = HSeparator.new()
	vbox.add_child(var_sep)
	
	var var_lbl = Label.new()
	var_lbl.text = "Variation Settings"
	var_lbl.add_theme_font_size_override("font_size", 14)
	vbox.add_child(var_lbl)

	_add_slider_field(vbox, "Pitch Randomness:", sfx.pitch_randomness, 0.0, 0.5, 0.01, func(val):
		sfx.pitch_randomness = val
		_commit_change()
	)

	# Variation Mode OptionButton
	var mode_hbox = HBoxContainer.new()
	var mode_lbl = Label.new()
	mode_lbl.text = "Variation Mode:"
	mode_lbl.custom_minimum_size = Vector2(140, 0)
	mode_hbox.add_child(mode_lbl)

	var mode_option = OptionButton.new()
	mode_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mode_option.add_item("Sequential", SFX.VariationMode.SEQUENTIAL)
	mode_option.add_item("Random", SFX.VariationMode.RANDOM)
	mode_option.add_item("Random Without Repeats", SFX.VariationMode.RANDOM_WITHOUT_REPEATS)
	mode_option.select(sfx.variation_mode)
	mode_option.item_selected.connect(func(idx):
		sfx.variation_mode = mode_option.get_item_id(idx)
		_commit_change()
	)
	mode_hbox.add_child(mode_option)
	vbox.add_child(mode_hbox)

	# Streams Management Section
	var stream_sep = HSeparator.new()
	vbox.add_child(stream_sep)

	var stream_header = HBoxContainer.new()
	var str_lbl = Label.new()
	str_lbl.text = "Audio Streams (" + str(sfx.streams.size()) + ")"
	str_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stream_header.add_child(str_lbl)

	var add_stream_btn = Button.new()
	add_stream_btn.text = "+ Add Empty Stream"
	add_stream_btn.pressed.connect(func():
		sfx.streams.append(null)
		_commit_change()
		_populate_sfx_details(sfx)
	)
	stream_header.add_child(add_stream_btn)
	vbox.add_child(stream_header)

	for i in range(sfx.streams.size()):
		var stream_row = HBoxContainer.new()

		# Index Label (#1, #2, etc.)
		var idx_lbl = Label.new()
		idx_lbl.text = "#" + str(i + 1)
		idx_lbl.custom_minimum_size = Vector2(35, 0)
		stream_row.add_child(idx_lbl)

		# Move Up Button
		var up_btn = Button.new()
		up_btn.text = "▲"
		up_btn.disabled = (i == 0)
		up_btn.pressed.connect(func():
			var temp = sfx.streams[i]
			sfx.streams[i] = sfx.streams[i - 1]
			sfx.streams[i - 1] = temp
			_commit_change()
			_populate_sfx_details(sfx)
		)
		stream_row.add_child(up_btn)

		# Move Down Button
		var down_btn = Button.new()
		down_btn.text = "▼"
		down_btn.disabled = (i == sfx.streams.size() - 1)
		down_btn.pressed.connect(func():
			var temp = sfx.streams[i]
			sfx.streams[i] = sfx.streams[i + 1]
			sfx.streams[i + 1] = temp
			_commit_change()
			_populate_sfx_details(sfx)
		)
		stream_row.add_child(down_btn)

		# Native Godot Editor Resource Picker
		var picker = EditorResourcePicker.new()
		picker.base_type = "AudioStream"
		picker.edited_resource = sfx.streams[i]
		picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		# Explicit File Name Label
		var name_lbl = Label.new()
		var current_stream = sfx.streams[i]
		name_lbl.text = current_stream.resource_path.get_file() if current_stream and not current_stream.resource_path.is_empty() else "[No File Assigned]"
		name_lbl.custom_minimum_size = Vector2(140, 0)

		picker.resource_changed.connect(func(res):
			sfx.streams[i] = res
			if res and not res.resource_path.is_empty():
				name_lbl.text = res.resource_path.get_file()
			else:
				name_lbl.text = "[No File Assigned]"
			_commit_change()
		)

		stream_row.add_child(name_lbl)
		stream_row.add_child(picker)

		# Remove Stream Button
		var remove_btn = Button.new()
		remove_btn.text = "✕"
		remove_btn.pressed.connect(func():
			sfx.streams.remove_at(i)
			_commit_change()
			_populate_sfx_details(sfx)
		)
		stream_row.add_child(remove_btn)
		
		vbox.add_child(stream_row)

func _populate_music_details(music: Music) -> void:
	_clear_details()
	if not music:
		return

	var scroll = ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	details_panel.add_child(scroll)

	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(vbox)

	var header_lbl = Label.new()
	header_lbl.text = "Editing Music Track: " + (music.tag if not music.tag.is_empty() else "[Unnamed]")
	header_lbl.add_theme_font_size_override("font_size", 18)
	vbox.add_child(header_lbl)

	var preview_hbox = HBoxContainer.new()
	vbox.add_child(preview_hbox)

	var preview_btn = Button.new()
	preview_btn.text = "▶ Preview Track"
	preview_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	preview_btn.pressed.connect(func():
		if music.stream:
			preview_player.stream = music.stream
			preview_player.volume_db = music.volume_db
			preview_player.pitch_scale = music.pitch_scale
			preview_player.play()
	)
	preview_hbox.add_child(preview_btn)

	var stop_btn = Button.new()
	stop_btn.text = "⏹ Stop"
	stop_btn.pressed.connect(func():
		if preview_player.playing:
			preview_player.stop()
	)
	preview_hbox.add_child(stop_btn)

	_add_input_field(vbox, "Tag Name:", music.tag, func(new_text):
		music.tag = new_text
		_commit_change()
		refresh_lists()
	)

	_add_slider_field(vbox, "Volume (dB):", music.volume_db, -50.0, 20.0, 0.5, func(val):
		music.volume_db = val
		_commit_change()
	)

	_add_slider_field(vbox, "Pitch Scale:", music.pitch_scale, 0.5, 2.0, 0.05, func(val):
		music.pitch_scale = val
		_commit_change()
	)

	var stream_sep = HSeparator.new()
	vbox.add_child(stream_sep)

	var str_lbl = Label.new()
	str_lbl.text = "Music Stream File:"
	vbox.add_child(str_lbl)

	var picker = EditorResourcePicker.new()
	picker.base_type = "AudioStream"
	picker.edited_resource = music.stream
	picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	picker.resource_changed.connect(func(res):
		music.stream = res
		_commit_change()
	)
	vbox.add_child(picker)

func _add_input_field(parent: Control, label_text: String, current_value: String, callback: Callable) -> void:
	var hbox = HBoxContainer.new()
	var lbl = Label.new()
	lbl.text = label_text
	lbl.custom_minimum_size = Vector2(140, 0)
	hbox.add_child(lbl)

	var line_edit = LineEdit.new()
	line_edit.text = current_value
	line_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line_edit.text_changed.connect(callback)
	hbox.add_child(line_edit)
	parent.add_child(hbox)

func _add_slider_field(parent: Control, label_text: String, current_value: float, min_val: float, max_val: float, step_val: float, callback: Callable) -> void:
	var hbox = HBoxContainer.new()
	var lbl = Label.new()
	lbl.text = label_text
	lbl.custom_minimum_size = Vector2(140, 0)
	hbox.add_child(lbl)

	var slider = HSlider.new()
	slider.min_value = min_val
	slider.max_value = max_val
	slider.step = step_val
	slider.value = current_value
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER

	var spin = SpinBox.new()
	spin.min_value = min_val
	spin.max_value = max_val
	spin.step = step_val
	spin.value = current_value
	spin.custom_minimum_size = Vector2(90, 0)

	slider.value_changed.connect(func(val):
		spin.set_value_no_signal(val)
		callback.call(val)
	)
	spin.value_changed.connect(func(val):
		slider.set_value_no_signal(val)
		callback.call(val)
	)

	hbox.add_child(slider)
	hbox.add_child(spin)
	parent.add_child(hbox)

func _on_add_pressed() -> void:
	if not audio_library:
		return
	
	if is_editing_sfx:
		var new_sfx = SFX.new()
		new_sfx.tag = "RENAME_ME!"
		audio_library.sound_effects.append(new_sfx)
	else:
		var new_music = Music.new()
		new_music.tag = "RENAME_ME!"
		audio_library.music_tracks.append(new_music)
	
	# Mark resource as modified, save to disk, and update editor inspector
	audio_library.emit_changed()
	audio_library.notify_property_list_changed()
	_save_resource(audio_library)
	
	refresh_lists()
	EditorInterface.get_inspector().update_tree()

func _on_delete_pressed() -> void:
	if not audio_library or current_selected_index == -1:
		return
		
	if is_editing_sfx and current_selected_index < audio_library.sound_effects.size():
		audio_library.sound_effects.remove_at(current_selected_index)
	elif not is_editing_sfx and current_selected_index < audio_library.music_tracks.size():
		audio_library.music_tracks.remove_at(current_selected_index)
	
	current_selected_index = -1
	
	# Mark resource as modified, save to disk, and update editor inspector
	audio_library.emit_changed()
	audio_library.notify_property_list_changed()
	_save_resource(audio_library)
	
	refresh_lists()
	_clear_details()
	EditorInterface.get_inspector().update_tree()

func _on_search_text_changed(new_text: String) -> void:
	search_query = new_text.strip_edges().to_lower()
	current_selected_index = -1
	refresh_lists()
	_clear_details()
