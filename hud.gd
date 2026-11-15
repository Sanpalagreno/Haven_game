extends CanvasLayer
# Health display. A CanvasLayer draws on top of the game and ignores the camera,
# so the hearts stay pinned to the corner of the screen.

const HEART = preload("res://assets/heart.png")
const HEART_SIZE = 48
const FULL = Color(1, 1, 1)               # no tint: the heart's own red
const EMPTY = Color(0.15, 0.15, 0.2, 0.6) # dark, see-through: a lost heart

var row: HBoxContainer
var info = Label.new()     # "Level 1   Score 0" under the hearts


func _ready() -> void:
	# A row container lines its children up side by side automatically.
	row = HBoxContainer.new()
	row.position = Vector2(20, 20)
	row.add_theme_constant_override("separation", 6)
	add_child(row)

	var player = get_parent().get_node("player")
	for i in player.max_health:
		var heart = TextureRect.new()
		heart.texture = HEART
		heart.custom_minimum_size = Vector2(HEART_SIZE, HEART_SIZE)
		heart.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		heart.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		row.add_child(heart)

	# Listen for the player's signal; Godot calls update_hearts each time it fires.
	player.health_changed.connect(update_hearts)
	update_hearts(player.health)

	info.position = Vector2(20, 76)
	info.add_theme_font_size_override("font_size", 36)
	info.add_theme_constant_override("outline_size", 10)
	info.add_theme_color_override("font_outline_color", Color.BLACK)
	add_child(info)


func _process(delta: float) -> void:
	info.text = "Level %d   Score %d" % [Game.level, Game.score]


func update_hearts(health: int) -> void:
	for i in row.get_child_count():
		row.get_child(i).modulate = FULL if i < health else EMPTY
