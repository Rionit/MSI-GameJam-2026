extends Resource
class_name Music

@export var tag: String
@export var stream: AudioStream

@export_group("Music Settings")
@export_range(-50.0, 20.0, 0.5) var volume_db: float = 0.0
@export_range(0.5, 2.0, 0.05) var pitch_scale: float = 1.0
