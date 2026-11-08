extends Path3D

class_name GraetzSignal

signal signal_over(source : GraetzSignal)

@export var speed : float = 1.0
@export var num_electrons : int = 10

## How long should it take until all electrons' animation starts (in seconds)
@export var anim_time : float = 3

@export var electron_scene : PackedScene



var electrons : Array[PathFollow3D] = []
var tween : Tween
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for i in range(num_electrons):
		var electron = electron_scene.instantiate() as PathFollow3D
		electron.visible = false

		electrons.append(electron)
		add_child(electron)


## MULTIPLY the scale of electrons by a given value
func scale_electrons(scale_mult : float) -> void:
	for electron in electrons:
		var visualizer = electron.get_node("Visualizer") as Node3D
		visualizer.scale *= scale_mult



func start_signal() -> void:
	var length = curve.get_baked_length()
	# print("Animating movement for " + str(num_electrons) + " electrons along path of length " + str(length) + " (" + str(length / speed) + " seconds)")

	tween = create_tween()

	tween.set_parallel(true)
	for i in range(num_electrons):
		var electron = electrons[i]
		electron.visible = true
		# print(" Is electron " + str(i) + " visible? " + str(electron.visible))
		var delay = (anim_time / num_electrons) * i

		tween.tween_property(electron, "progress", length, length / speed).set_delay(delay).set_trans(Tween.TRANS_LINEAR)
		tween.tween_property(electron, "visible", false, 0).set_delay(delay + (length / speed)).set_trans(Tween.TRANS_LINEAR)
	await(tween.finished)

	# print("Electron animation over!")
	signal_over.emit(self)
	queue_free()
