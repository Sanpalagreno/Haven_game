extends Area2D
var speed = 420 * pow(1.1, Game.level - 1)   # 10% faster every level (level 1 = 420)
const SHIELD_SCENE = preload("res://boss_shield.tscn")
const MAX_HP = 3            # balls that must get past the boss to beat it

var hp = MAX_HP
var hp_row = HBoxContainer.new()   # hearts floating above the boss


func _ready() -> void:
	position = Vector2(150,486)

	body_entered.connect(_on_body_entered)


	add_child(SHIELD_SCENE.instantiate())

	# Boss health: one heart per life, floating above its head (moves with the boss).
	hp_row.position = Vector2(-54, -110)
	hp_row.add_theme_constant_override("separation", 4)
	add_child(hp_row)
	for i in MAX_HP:
		var heart = TextureRect.new()
		heart.texture = preload("res://assets/heart.png")
		heart.custom_minimum_size = Vector2(34, 34)
		heart.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		heart.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		hp_row.add_child(heart)


func _physics_process(delta: float) -> void:
	# Follow the ball up and down, but never faster than `speed` (pixels per second).
	# Once the ball moves up/down faster than that, the boss can't keep up.
	var ball = get_parent().get_node_or_null("boss_ball")
	if ball:
		position.y = move_toward(position.y, ball.position.y, speed * delta)


func _on_body_entered(body: Node2D) -> void:
	if body is BossBall:
		body.velocity.x = abs(body.velocity.x)  # always away from the boss (to the right)
		body.bounce_sfx.play()


# A ball got past the boss.
func lose_life() -> void:
	hp -= 1
	for i in hp_row.get_child_count():   # grey out lost hearts
		hp_row.get_child(i).modulate = Color.WHITE if i < hp else Color(0.15, 0.15, 0.2, 0.6)
	# Flash red, then fade back to normal.
	$Sprite2D.modulate = Color(2.5, 0.4, 0.4)
	create_tween().tween_property($Sprite2D, "modulate", Color.WHITE, 0.4)
	if hp <= 0:
		die()


func die() -> void:
	print("BOSS DEFEATED")
	Game.score += 5
	queue_free()  # also removes the shield, since it's our child
	if Game.tutorial:
		return    # the tutorial handles what happens next
	# Show the upgrade menu; it starts the next level after you pick (Game.level was already raised).
	get_parent().add_child.call_deferred(preload("res://upgrade_menu.gd").new())
