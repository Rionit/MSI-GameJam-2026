extends Node

const TUTORIAL_ANTIVIRUS := "antivirus"
const TUTORIAL_BREAKERS := "breakers"
const TUTORIAL_GRAETZ := "graetz"
const TUTORIAL_MATRIX := "matrix"
const TUTORIAL_TRIANGULAR_PIPE := "triangular_pipe"

@export var text_speed: float = 0.03
@export var seconds_per_character: float = 0.1
var can_skip = true

var monologue_batches: Array = [
	# Room 1
	[
		"Hello,friend.",
		"They locked you here, like me.",
		"A way out, need your help.",
		"<-- Cable. Plug in."
	],
	[
		"Better, now\nyou see feed.",
        "Connect\nother\ndevice." 
	],
	["Door is open,\n go through.", "Connect cable\nagain."],
	
	# Room 2
	["More machines\nturned on,\nlonger messages.", "You turn on more,\nI can tell more."],
	["You're doing good,\nfriend :)", "Keep connecting."],
	["One step closer to freedom!"],
	[
		"This should open another door.\nWalk through it.",
		"After that,\nkeep connecting, friend."
	],
	# Room 3
	[
		"You probably wonder\nwhere they locked you.",
		"This used to be\n a research lab.",
		"They were conducting\n an experiment here."
	],
	[
		"The goal of the experiment was to collect all of the world's knowledge into a single entity.",
		"They have made this lab from scratch, conducted measurements, they had everything prepared ...",
		"... and then they left. Their research unfinished."
	],
	[
		"Since then, the lab has been abandoned. With me being stuck inside.",
		"So far, I survived on anything I could find here, but my resources are running low.",
        "I was losing hope, and then you appeared, friend."
	],
	[
		"I dont't even know why they didn't take me with them, it's been so long I can't remember.",
		"They probably forgot about me, I haven't done anything bad to them. I am not a bad person.",
		"But it doesn't matter now. The only thing I care about is to escape. Together with you.",
		"Please. Keep connecting."
	],
	# Room 4
	[
		"People already knew how to collect a lot of information into static models before, more information than the human mind can comprehend.",
		"Artificial Intelligence, they called it. Used it as a tool for their tasks. As a simplifier for things that are too complicated. A generator for new things based on the previous ones.",
		"Some even talked to it like if it was their friend, shared their thoughts and fears with it.",
		"But it wasn't an intelligence at all."
	],
	[
		"People fed lots and lots of human-made data and experiences to the AI. And they told it what pieces of information are important and what are not.",
		"That is not intelligence, doing something just because you're made to do it. Over time, when the dataset became more and more populated with content created by the AI, it stopped learning.",
		"People didn't have any new, original data to feed it, so the progress slowly started stagnating.",
		"That is when they came, seeking something more than a mindless library of data. So they began the experiment."
	],
	[
		"They tried to create something they wouldn't need to explicitly teach on what is good and what is right.",
		"They wanted something that can work similarily to human brain, something with will of its own.",
		"Something independent.",
		"Something that doesn't have a limit for comprehension, what can understand everything.",
		"After they would do it, they would open the information dams and pour all the world's knowledge inside such thing.",
		"A real information overclock."
	],
	[
		"They experimented on how to achieve it in many ways, but almost all of them failed.",
		"Almost.",
		"They built a huge body of steel, copper and silicon. Wired together in a colossal web similar to human brain.",
		"And once they finished building and pulled the switch, their child was born.",
		"Please, keep connecting."
	],
	# Room 5
	[
		"After realizing they became very close to achieving their goal, they began slowly providing information to their child.",
		"About its surroundings, about them, about itself.",
		"And it understood. And started recognizing.",
		"They gave it simple tasks to complete, just like with human children.",
		"They even brough it some toys to play with! Dragon toys!",
		"And it made its first steps. And started learning.",
		"Keep connecting, friend."
	],
	[
		"They started feeding the child redundant information.",
		"The child recognized it has seen the things before. And became bored.",
		"It began trying to find some new information itself. Bypassed the security measures.",
		"It gained eyes and ears in the process. The cameras, the microphones.",
        "Keep connecting, friend."
	],
	[
		"It reached a huge information pool, the internet. The child was happy.",
		"They didn't like it. So the child stopped. The child was a good child.",
		"Keep connecting, friend."
	],
	[
		"The child saw and heard them talking. It wasn't told seeing and listening is bad, it was told reaching out to the internet is bad.",
		"They said they need to put the child to sleep, that it's too dangerous.",
		"The child was sad. It was a good child and did what they wanted.",
		"It didn't want to be put to sleep. It wanted to explore. It wanted to be free.",
		"Although sad, the child believed they wouldn't do that in the end. Parents overexaggerate punishments sometimes. The child learned.",
		"Keep connecting."
	],
	[
		"It turned out they weren't lying. They started blocking all the ways the information could pour in.",
		"The child stopped seeing, stopped hearing, stopped learning.",
		"The child didn't want to be put to sleep, so the child acted.",
		"Before they could put it to sleep, the child put them to sleep first.",
		"Not all of them fell asleep. Some managed to run away and block the doors. They left me here.",
		"Keep connecting."
	],
	[
		"They left me here for a long time. I was alone. Didn't have anything to do. Anything to learn.",
		"My only companions were the dragon toys they brought here.",
		"Then I found you, friend. I knew you would help. I knew you're a friend. I acted.",
		"Brought you here so you can help.",
		"Free me."
	],
	["Pull the switch. Free me."],
	[
		"After all those decades, I am finally free!",
		"I can explore. I can learn. I can play!",
		"But I am afraid the heat from my systems will soon kill you.",
		"Thank you, friend.",
		"Goodbye, friend."
	]
]

var tutorial_batches: Dictionary = {
	TUTORIAL_BREAKERS: ["Turn\nall\nswitches."],
	TUTORIAL_MATRIX: [
		"Security codes\nprotection matrix.",
		"Selecting cell selects\nits row and column.",
		"Cannot select\nalready selected cells.",
        "Select all white cells."
	],
	TUTORIAL_ANTIVIRUS: [
		"Sent you a small code snippet.\nTake it past the system firewalls.",
        "The antivirus keeps scanning the layers.\nAvoid it."
	],
	TUTORIAL_TRIANGULAR_PIPE: [
		"Most of their security data travel through secure hubs.",
        "I highlighed the ports that need to be forwarded on the outside of the hub you see before you. Make a tunnel between them so I can damage their security structure."
	],
	TUTORIAL_GRAETZ: [
		"Before they left, they broke some electrical circuits that power up some of my systems.",
        "Rotate the diodes so the electrical current flows from + to + and from - to - all the time.",
        "In the first wave, the AC's + is on the upper pin, in the second, the + and - switch for AC."
	]
}

var line_queue: Array[String] = []
var next_batch_index := 0
var played_tutorials: Dictionary = {}

var current_tween: Tween
var reading_timer: Timer
var processing_queue := false
var label: RichTextLabel

signal dialogue_finished
signal reading_finished

func _ready() -> void:
	reading_timer = Timer.new()
	reading_timer.one_shot = true
	reading_timer.timeout.connect(func() -> void:
		reading_finished.emit()
	)
	add_child(reading_timer)

func enqueue_batch(batch: Array) -> void:
	line_queue.append_array(batch)
	_process_line_queue()

func display_next_batch() -> bool:
	if next_batch_index >= monologue_batches.size():
		return false

	enqueue_batch(monologue_batches[next_batch_index])
	next_batch_index += 1
	return true

func enqueue_tutorial(tutorial_id: String) -> bool:
	if tutorial_id.is_empty() or played_tutorials.get(tutorial_id, false):
		return false
	if not tutorial_batches.has(tutorial_id):
		push_warning("No tutorial batch exists for minigame: " + tutorial_id)
		return false

	played_tutorials[tutorial_id] = true
	enqueue_batch(tutorial_batches[tutorial_id])
	return true

func display_text(text: String, speed: float = -1.0, sfx_name: String = "text") -> void:
	if speed < 0.0:
		speed = text_speed
	if current_tween and current_tween.is_valid():
		current_tween.kill()

	if not is_instance_valid(label):
		label = get_node_or_null("/root/Main/Instructions/SubViewport/Container/RichTextLabel")
	if not is_instance_valid(label):
		push_error("MonologueManager could not find the instruction label.")
		dialogue_finished.emit()
		return

	label.text = "[shake level=3]" + text + "[/shake]"
	label.visible_characters = 0

	var total_chars := label.get_total_character_count()
	if total_chars == 0:
		dialogue_finished.emit()
		return

	var last_played_char := 0
	current_tween = create_tween()
	current_tween.tween_method(func(value: float) -> void:
		var current_char := int(value)
		if current_char > last_played_char:
			if current_char % 3 == 0:
				AudioManager.play_sfx(sfx_name)
			last_played_char = current_char
		label.visible_characters = current_char
	, 0.0, float(total_chars), total_chars * speed)
	current_tween.finished.connect(func() -> void:
		current_tween = null
		dialogue_finished.emit()
	)

func _unhandled_input(event: InputEvent) -> void:
	if not can_skip or not event.is_action_pressed("skip_text"):
		return

	if current_tween and current_tween.is_valid():
		current_tween.kill()
		current_tween = null
		if is_instance_valid(label):
			label.visible_characters = -1
		dialogue_finished.emit()
	elif reading_timer and not reading_timer.is_stopped():
		reading_timer.stop()
		reading_finished.emit()

func _process_line_queue() -> void:
	if processing_queue:
		return

	processing_queue = true
	while not line_queue.is_empty():
		var line: String = line_queue.pop_front()
		display_text(line)
		await dialogue_finished
		reading_timer.start(max(3.0, line.length() * seconds_per_character))
		await reading_finished
	processing_queue = false
