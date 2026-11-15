extends Control
# Start screen: the ocean background with a Play button in the middle.


func _ready() -> void:
	var bg = TextureRect.new()
	bg.texture = preload("res://assets/ocean.png")
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	bg.set_anchors_preset(PRESET_FULL_RECT)   # fill the whole screen
	add_child(bg)

	var center = CenterContainer.new()        # keeps its child in the middle of the screen
	center.set_anchors_preset(PRESET_FULL_RECT)
	add_child(center)

	var column = VBoxContainer.new()          # Play on top, Tutorial underneath
	column.add_theme_constant_override("separation", 30)
	center.add_child(column)

	var play = Button.new()
	play.text = "Play"
	play.add_theme_font_size_override("font_size", 64)
	play.custom_minimum_size = Vector2(320, 130)
	play.pressed.connect(_on_play_pressed)
	column.add_child(play)

	var tutorial = Button.new()
	tutorial.text = "Tutorial"
	tutorial.add_theme_font_size_override("font_size", 44)
	tutorial.custom_minimum_size = Vector2(320, 90)
	tutorial.pressed.connect(_on_tutorial_pressed)
	column.add_child(tutorial)


func _on_play_pressed() -> void:
	Game.reset()
	get_tree().change_scene_to_file("res://game_main.tscn")


func _on_tutorial_pressed() -> void:
	Game.reset()
	Game.tutorial = true
	get_tree().change_scene_to_file("res://game_main.tscn")
