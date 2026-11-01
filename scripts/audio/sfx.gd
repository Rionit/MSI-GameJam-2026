@tool
extends Resource
class_name SFX

enum VariationMode {
	SEQUENTIAL,
	RANDOM,
	RANDOM_WITHOUT_REPEATS
}

@export var tag: String
@export var streams: Array[AudioStream]:
	set(value):
		streams = value
		notify_property_list_changed()

@export_group("Variation Settings")
@export var variation_mode: VariationMode = VariationMode.RANDOM
@export_range(0.0, 0.5, 0.01) var pitch_randomness: float = 0.0

@export_group("Audio Settings")
@export_range(0.5, 2.0, 0.05) var pitch_scale: float = 1.0
@export_range(-50.0, 20.0, 0.5) var volume_db: float = 0.0

# Internal state tracking
var _sequential_index: int = 0
var _remaining_pool: Array[AudioStream] = []

func _validate_property(property: Dictionary) -> void:
	if property.name == "variation_mode":
		if streams.size() <= 1:
			property.usage &= ~PROPERTY_USAGE_EDITOR

func get_next_stream() -> AudioStream:
	if streams.is_empty():
		return null
		
	if streams.size() == 1:
		return streams[0]
		
	match variation_mode:
		VariationMode.SEQUENTIAL:
			var stream = streams[_sequential_index]
			_sequential_index = (_sequential_index + 1) % streams.size()
			return stream
			
		VariationMode.RANDOM:
			return streams[randi() % streams.size()]
			
		VariationMode.RANDOM_WITHOUT_REPEATS:
			if _remaining_pool.is_empty():
				_remaining_pool = streams.duplicate()
				_remaining_pool.shuffle()
			return _remaining_pool.pop_back()
			
	return streams[0]
