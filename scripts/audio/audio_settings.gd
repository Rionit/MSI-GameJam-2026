extends Control

@onready var volume_slider: HSlider = $VOLUME
@onready var sfx_slider: HSlider = $SFX
@onready var music_slider: HSlider = $MUSIC

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	volume_slider.value_changed.connect(func(v): AudioManager.set_bus_volume_linear("Master", v))
	sfx_slider.value_changed.connect(func(v): AudioManager.set_bus_volume_linear("SFX", v))
	music_slider.value_changed.connect(func(v): AudioManager.set_bus_volume_linear("Music", v))
	
