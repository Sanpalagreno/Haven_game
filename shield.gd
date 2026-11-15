class_name Shield
extends CharacterBody2D
# Normal rounds: sits on the player and points at the mouse.
# Boss time: locked to the player's LEFT. The wall sits 90px along the shield's local +X,
# so a rotation of PI (180 degrees) puts it on the left.

@onready var player = get_parent().get_node("player")

const PARRY_WINDOW = 0.2   # a left click counts as a parry for this many seconds
const PARRY_COOLDOWN = 0.8 # after a click, you can't start another parry for this long (no spamming)
var parry_timer = 0.0      # > 0 means "the player just clicked": bullets touching us get reflected
var parry_cooldown = 0.0   # > 0 means clicks are ignored


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if parry_cooldown > 0:
			return   # too soon since the last parry click
		parry_timer = PARRY_WINDOW + Game.parry_bonus   # "Longer Parry" upgrade adds to this
		parry_cooldown = PARRY_COOLDOWN


func _ready() -> void:
	# "Bigger Shield" upgrade: grow the wall itself (not the whole node, so it stays 90px from you).
	$Sprite2D.scale *= Game.shield_scale
	$CollisionShape2D.scale *= Game.shield_scale


func _physics_process(delta: float) -> void:
	parry_timer -= delta
	parry_cooldown -= delta
	# The player node comes before us in the scene tree, so it has already moved this tick.
	global_position = player.global_position
	if player.boss_mode:
		rotation = PI
	else:
		look_at(get_global_mouse_position())
	# Turn the player's picture with us. It's drawn facing UP, so add a quarter turn.
	player.get_node("Sprite2D").rotation = rotation + PI / 2
