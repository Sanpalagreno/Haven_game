extends Control
# Game over screen: shows the score from the Game autoload, then lets you play again.


func _ready() -> void:
	var bg = TextureRect.new()
	bg.texture = preload("res://assets/ocean.png")
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	bg.set_anchors_preset(PRESET_FULL_RECT)
	add_child(bg)

	var center = CenterContainer.new()
	center.set_anchors_preset(PRESET_FULL_RECT)
	add_child(center)

	var column = VBoxContainer.new()          # stacks its children top to bottom
	column.add_theme_constant_override("separation", 24)
	center.add_child(column)

	column.add_child(make_label("GAME OVER", 96))
	column.add_child(make_label("Score: %d" % Game.score, 64))
	column.add_child(make_label("Reached level %d" % Game.level, 40))

	var again = Button.new()
	again.text = "Play Again"
	again.add_theme_font_size_override("font_size", 48)
	again.pressed.connect(_on_play_again_pressed)
	column.add_child(again)

	var menu = Button.new()
	menu.text = "Main Menu"
	menu.add_theme_font_size_override("font_size", 48)
	menu.pressed.connect(_on_menu_pressed)
	column.add_child(menu)


func make_label(text: String, size: int) -> Label:
	var label = Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_constant_override("outline_size", 12)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	return label


func _on_play_again_pressed() -> void:
	Game.reset()
	get_tree().change_scene_to_file("res://game_main.tscn")


func _on_menu_pressed() -> void:
	get_tree().change_scene_to_file("res://start_screen.tscn")
