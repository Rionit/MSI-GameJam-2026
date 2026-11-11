extends Minigame

class_name AntivirusMinigame

const EMISSIVE_WHITE = preload("uid://b10ebpa8i8ioo")

@export var player_ball: AntivirusBall
@export var top_spawn: Node3D
@export var platform_levels: Array[StaticBody3D]
@export var antivirus_platforms: Array[AntivirusPlatform]
@export var side_bounds: Array[Area3D]
@export var bottom_hole: Area3D

@export var platform_hole_left : PackedScene
@export var platform_hole_right : PackedScene
@export var platform_hole_middle : PackedScene
@export var platform_hole_both : PackedScene

@export var success_label : Label3D
@export var success_material : Material

var num_levels = 4
var start_level_height = 1.5
var level_height_decrement = 1.0

enum LevelPlatformType
{
	HOLE_LEFT,
	HOLE_RIGHT,
	HOLE_MIDDLE,
	HOLE_BOTH
}

var permitted_next_platforms = {
	LevelPlatformType.HOLE_LEFT: [LevelPlatformType.HOLE_RIGHT, LevelPlatformType.HOLE_MIDDLE],
	LevelPlatformType.HOLE_RIGHT: [LevelPlatformType.HOLE_LEFT, LevelPlatformType.HOLE_MIDDLE],
	LevelPlatformType.HOLE_MIDDLE: [LevelPlatformType.HOLE_LEFT, LevelPlatformType.HOLE_RIGHT, LevelPlatformType.HOLE_BOTH],
	LevelPlatformType.HOLE_BOTH: [LevelPlatformType.HOLE_MIDDLE]
}

var platform_x_offsets = {
	LevelPlatformType.HOLE_LEFT: 0.5,
	LevelPlatformType.HOLE_RIGHT: -0.5,
	LevelPlatformType.HOLE_MIDDLE: 0.0,
	LevelPlatformType.HOLE_BOTH: 0.0
}

@onready var platform_scenes = {
	LevelPlatformType.HOLE_LEFT: platform_hole_left,
	LevelPlatformType.HOLE_RIGHT: platform_hole_right,
	LevelPlatformType.HOLE_MIDDLE: platform_hole_middle,
	LevelPlatformType.HOLE_BOTH: platform_hole_both
}

var _active := false
var _completed := false

func _apply_material_to_node_tree(node: Node, material: Material) -> void:
	if node is MeshInstance3D:
		node.material_override = material
	for child in node.get_children():
		_apply_material_to_node_tree(child, material)

func generate_levels():
	platform_levels.clear()
	antivirus_platforms.clear()

	var random = RandomNumberGenerator.new()

	var current_platform_type = LevelPlatformType.HOLE_LEFT
	var current_platform_instance = platform_scenes[current_platform_type].instantiate()
	$Platforms.add_child(current_platform_instance)
	current_platform_instance.position.x = platform_x_offsets[current_platform_type]
	current_platform_instance.position.y = start_level_height

	var platform_children = current_platform_instance.get_children()

	for child in platform_children:
		if child is StaticBody3D:
			platform_levels.append(child)
			_apply_material_to_node_tree(child, EMISSIVE_WHITE)
		elif child is AntivirusPlatform:
			antivirus_platforms.append(child)
	
	for i in range(1, num_levels):
		var random_platform_num = random.randi() % permitted_next_platforms[current_platform_type].size()
		current_platform_type = permitted_next_platforms[current_platform_type][random_platform_num]

		current_platform_instance = platform_scenes[current_platform_type].instantiate()
		$Platforms.add_child(current_platform_instance)
		current_platform_instance.position.x = platform_x_offsets[current_platform_type]
		current_platform_instance.position.y = start_level_height - i * level_height_decrement

		platform_children = current_platform_instance.get_children()
		for child in platform_children:
			if child is StaticBody3D:
				platform_levels.append(child)
				_apply_material_to_node_tree(child, EMISSIVE_WHITE)
			elif child is AntivirusPlatform:
				child.speed += (random.randf() * 2 - 1) * 0.2  
				antivirus_platforms.append(child)
		
func _ready() -> void:
	self.visible = false
	generate_levels()
	if player_ball == null:
		push_error("AntivirusMinigame requires a player_ball.")
	if top_spawn == null:
		push_error("AntivirusMinigame requires a top_spawn.")
	if bottom_hole == null:
		push_error("AntivirusMinigame requires a bottom_hole.")

	for antivirus_platform in antivirus_platforms:
		if antivirus_platform == null:
			continue
		antivirus_platform.body_entered.connect(_on_antivirus_body_entered)
		antivirus_platform.deactivate()

	for side_bound in side_bounds:
		if side_bound != null:
			side_bound.body_entered.connect(_on_side_bound_body_entered)

	if bottom_hole != null:
		bottom_hole.body_entered.connect(_on_bottom_hole_body_entered)

	if player_ball != null:
		player_ball.deactivate()

func enter_game() -> void:
	self.visible = true
	if player_ball == null or top_spawn == null:
		return

	_active = true
	_completed = false
	player_ball.activate(top_spawn.global_position)
	for antivirus_platform in antivirus_platforms:
		if antivirus_platform != null:
			antivirus_platform.activate()

func exit_game() -> void:
	self.visible = false
	_active = false
	if player_ball != null:
		player_ball.deactivate()
	for antivirus_platform in antivirus_platforms:
		if antivirus_platform != null:
			antivirus_platform.deactivate()

func _on_antivirus_body_entered(body: Node3D) -> void:
	if not _active or body != player_ball or top_spawn == null:
		return
	print("Antivirus body entered by: ", body)
	#AudioManager.play_sfx(Antivirus zvuk (třeba nějakej distorted error sound))
	player_ball.activate(top_spawn.global_position)

func _on_side_bound_body_entered(body: Node3D) -> void:
	print("Side bound entered by: ", body)
	#AudioManager.play_sfx(Ball bounce zvuk)
	if not _active or body != player_ball:
		return
	player_ball.reverse_horizontal_velocity()

func _on_bottom_hole_body_entered(body: Node3D) -> void:
	if not _active or _completed or body != player_ball:
		return
	_completed = true
	_active = false
	#AudioManager.play_sfx(Pass zvuk)
	print("Antivirus minigame completed!")

	await success_anim()
	minigame_completed.emit(self)

func success_anim() -> void:
	for antivirus_platform in antivirus_platforms:
		if antivirus_platform != null:
			antivirus_platform.deactivate()

	for bound in side_bounds:
		var visualizer = bound.get_node("CollisionShape/Visualizer") as MeshInstance3D
		visualizer.material_override = success_material
	
	await(get_tree().create_timer(0.5).timeout)
	#AudioManager.play_sfx(Typing zvuk na text)
	var text_tween = create_tween()

	text_tween.set_trans(Tween.TRANS_LINEAR)
	text_tween.tween_property(success_label, "text", "Security breached", 1.0)

	await(text_tween.finished)
	await(get_tree().create_timer(1.0).timeout)
	return 
