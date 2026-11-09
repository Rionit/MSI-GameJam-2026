extends Minigame

class_name AntivirusMinigame

@export var player_ball: AntivirusBall
@export var top_spawn: Node3D
@export var platform_levels: Array[StaticBody3D]
@export var antivirus_platforms: Array[AntivirusPlatform]
@export var side_bounds: Array[Area3D]
@export var bottom_hole: Area3D

var _active := false
var _completed := false

func _ready() -> void:
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
	if player_ball == null or top_spawn == null:
		return

	_active = true
	_completed = false
	player_ball.activate(top_spawn.global_position)
	for antivirus_platform in antivirus_platforms:
		if antivirus_platform != null:
			antivirus_platform.activate()

func exit_game() -> void:
	_active = false
	if player_ball != null:
		player_ball.deactivate()
	for antivirus_platform in antivirus_platforms:
		if antivirus_platform != null:
			antivirus_platform.deactivate()

func _on_antivirus_body_entered(body: Node3D) -> void:
	if not _active or body != player_ball or top_spawn == null:
		return
	player_ball.activate(top_spawn.global_position)

func _on_side_bound_body_entered(body: Node3D) -> void:
	if not _active or body != player_ball:
		return
	player_ball.reverse_horizontal_velocity()

func _on_bottom_hole_body_entered(body: Node3D) -> void:
	if not _active or _completed or body != player_ball:
		return
	_completed = true
	_active = false
	minigame_completed.emit(self)
