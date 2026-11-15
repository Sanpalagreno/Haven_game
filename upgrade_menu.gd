extends CanvasLayer
# Shown after a boss dies: pauses the game and offers 3 upgrades.
# Picking one saves it in the Game autoload, then the next level starts.


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS   # keep working while the game is paused
	get_tree().paused = true

	var dim = ColorRect.new()                 # darken the frozen level behind the menu
	dim.color = Color(0, 0, 0, 0.6)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var column = VBoxContainer.new()
	column.add_theme_constant_override("separation", 40)
	center.add_child(column)

	var title = Label.new()
	title.text = "Boss defeated! Pick an upgrade"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 64)
	title.add_theme_constant_override("outline_size", 12)
	title.add_theme_color_override("font_outline_color", Color.BLACK)
	column.add_child(title)

	var row = HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 40)
	column.add_child(row)

	# Every possible upgrade: [card text, icon, name used by pick()]
	var all_upgrades = [
		["Bigger Enemies\n+10%", preload("res://assets/upgrade_enemies.png"), "enemies"],
		["+1 Heart", preload("res://assets/upgrade_extra_life.png"), "hearts"],
		["Bigger Shield\n+10%", preload("res://assets/upgrade_shield.png"), "shield"],
		["Longer Parry\n+0.1s", preload("res://assets/upgrade_parry.png"), "parry"],
		["Slower Enemies\n-10%", preload("res://assets/upgrade_slow.png"), "slow"],
	]
	all_upgrades.shuffle()            # random order...
	for u in all_upgrades.slice(0, 3):  # ...then offer the first 3
		row.add_child(make_card(u[0], u[1], u[2]))


# One upgrade "card": a big button with a picture on top and text underneath.
func make_card(text: String, icon: Texture2D, upgrade: String) -> Button:
	var card = Button.new()
	card.text = text
	card.icon = icon
	card.expand_icon = true
	card.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
	card.custom_minimum_size = Vector2(320, 380)
	card.add_theme_font_size_override("font_size", 40)
	# Solid card backgrounds, so the frozen game doesn't show through transparent icons.
	for state in ["normal", "hover", "pressed", "focus"]:
		var box = StyleBoxFlat.new()
		box.bg_color = Color(0.22, 0.26, 0.32) if state == "hover" else Color(0.12, 0.15, 0.2)
		box.set_corner_radius_all(14)
		box.set_content_margin_all(12)
		card.add_theme_stylebox_override(state, box)
	card.pressed.connect(pick.bind(upgrade))   # bind = remember which upgrade this card is
	return card


func pick(upgrade: String) -> void:
	match upgrade:
		"enemies":
			Game.enemy_scale += 0.1
		"hearts":
			Game.extra_hearts += 1
		"shield":
			Game.shield_scale += 0.1
		"parry":
			Game.parry_bonus += 0.1
		"slow":
			Game.enemy_speed *= 0.9
	get_tree().paused = false
	get_tree().reload_current_scene()   # next level, with the upgrade applied
