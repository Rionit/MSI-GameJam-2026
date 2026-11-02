@tool
extends HBoxContainer

@onready var viewport_left: SubViewportContainer = $SubViewportContainerLeft
@onready var viewport_right: SubViewportContainer = $SubViewportContainerRight

@onready var main_viewport: SubViewport = $SubViewportContainerRight/SubViewport

## Controls the width ratio between the left and right viewports (0.0 to 1.0).
@export_range(0.0, 1.0) var split_ratio: float = 0.5:
	set(value):
		split_ratio = value
		_update_split()

func _ready() -> void:
	_update_split()

func _update_split() -> void:
	# If using as tool in inspector
	if !viewport_left and !viewport_right:
		var children = get_children()
		if children.size() < 2:
			return
	
		viewport_left = children[0] as Control
		viewport_right = children[1] as Control
	
	if viewport_left and viewport_right:
		# Apply ratios 
		viewport_left.size_flags_stretch_ratio = max(0.0001, split_ratio)
		viewport_right.size_flags_stretch_ratio = max(0.0001, 1.0 - split_ratio)
		
func _unhandled_input(event: InputEvent) -> void:
	if Engine.is_editor_hint():
		return
		
	# Press ESC to toggle mouse capture on/off 
	# TODO: Use this for menu cause player ESC rn doesnt work
	#if event.is_action_pressed("ui_cancel"):
		#if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			#Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		#else:
			#Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		#return

	# Intercept global mouse motion and feed it directly into the right SubViewport
	if event is InputEventMouseMotion and main_viewport:
		main_viewport.push_input(event)
