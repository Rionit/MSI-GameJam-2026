@tool
extends HBoxContainer
class_name SplitScreen

@onready var viewport_left: SubViewportContainer = $SubViewportContainerLeft
@onready var viewport_right: SubViewportContainer = $SubViewportContainerRight

@onready var main_viewport: SubViewport = $SubViewportContainerRight/SubViewport

## Controls the width ratio between the left and right viewports (0.0 to 1.0).
@export_range(0.0, 1.0) var split_ratio: float = 0.5:
	set(value):
		split_ratio = value
		if not is_inside_tree():
			return
		
		_animate_split_to(value)

@export_category("Tween Settings")
@export var tween_length := 3.0
@export var tween_trans : Tween.TransitionType = Tween.TRANS_CUBIC
@export var tween_ease : Tween.EaseType = Tween.EASE_IN_OUT
@export_tool_button("Test Split Ratio")
var _test_split_button = _on_test_button_pressed

var _tween: Tween

func _ready() -> void:
	_update_split(split_ratio)

func _update_split(val: float) -> void:
	# If using as tool in inspector
	if !viewport_left and !viewport_right:
		var children = get_children()
		if children.size() < 2:
			return
	
		viewport_left = children[0] as Control
		viewport_right = children[1] as Control
	
	if viewport_left and viewport_right:
		# Apply ratios 
		viewport_left.size_flags_stretch_ratio = max(0.0001, val)
		viewport_right.size_flags_stretch_ratio = max(0.0001, 1.0 - val)
		
func _animate_split_to(target_value: float) -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
	
	# Determine the current actual ratio to start the transition smoothly from where it is
	var current_ratio = split_ratio
	var children = get_children()
	if children.size() >= 2 and children[0] is Control:
		current_ratio = children[0].size_flags_stretch_ratio

	_tween = create_tween()
	_tween.set_trans(tween_trans)
	_tween.set_ease(tween_ease)
	_tween.tween_method(_update_split, current_ratio, target_value, tween_length)

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

	#if main_viewport:
	#	main_viewport.push_input(event)

func _on_test_button_pressed() -> void:
	# Cycles between 0.5, 0.8, and 0.2 for quick testing
	if abs(split_ratio - 0.5) < 0.01:
		split_ratio = 0.8
	elif abs(split_ratio - 0.8) < 0.01:
		split_ratio = 0.2
	else:
		split_ratio = 0.5


func _on_interactable_interacted(interactable: Interactable) -> void:
	print("hello there")
