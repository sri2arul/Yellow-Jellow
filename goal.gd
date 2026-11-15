extends Area2D

# leave EMPTY on the last level
@export var next_level = ""

var used = false


func _ready():
	body_entered.connect(on_enter)


func on_enter(body):
	if used:
		return
	if not body.has_method("take_hit"):
		return
	used = true
	body.dead = true

	if next_level == "":
		go_to("res://win.tscn")
		return

	show_message("KEEP ON GOING")
	await get_tree().create_timer(1.5).timeout
	go_to(next_level)


func show_message(text):
	var layer = CanvasLayer.new()
	var label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 64)
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	layer.add_child(label)
	add_child(layer)


func go_to(path):
	if not ResourceLoader.exists(path):
		print("Missing scene: ", path)
		return
	get_tree().call_deferred("change_scene_to_file", path)
