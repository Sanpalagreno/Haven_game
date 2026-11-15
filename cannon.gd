class_name Cannon
extends Area2D

const BULLET_SCENE = preload("res://bullet.tscn")
const FIRE_RATE = 1.5         # seconds between shots
const MIN_PLAYER_DIST = 250   # don't spawn right on top of the player
const EDGE_MARGIN = 50
const SCREEN = Arena.SIZE
const BARREL_LENGTH = 50      # distance from the boat's center to the barrel tip

var cooldown = FIRE_RATE
var fire_sfx = AudioStreamPlayer.new()


func _ready() -> void:
	scale = Vector2.ONE * Game.enemy_scale   # "Bigger Enemies" upgrade
	fire_sfx.stream = preload("res://assets/cannon_fire.wav")
	add_child(fire_sfx)
	var player_spot = Arena.player_pos(get_tree())
	if Arena.is_boss(get_tree()):
		# Boss time: only on the left part of the map, in front of the player's shield.
		position = Vector2(
			randf_range(EDGE_MARGIN, Arena.PLAYER_X - MIN_PLAYER_DIST * 2),
			randf_range(EDGE_MARGIN, SCREEN.y - EDGE_MARGIN))
	else:
		# Normal rounds: anywhere, as long as it's far enough from the player.
		position = player_spot
		while position.distance_to(player_spot) < MIN_PLAYER_DIST:
			position = Vector2(
				randf_range(EDGE_MARGIN, SCREEN.x - EDGE_MARGIN),
				randf_range(EDGE_MARGIN, SCREEN.y - EDGE_MARGIN))
	face_player()


# Turn to face the player. The boat image has its barrel pointing DOWN, but Godot's
# "forward" is RIGHT, so subtract a quarter turn (PI/2 radians = 90 degrees).
func face_player() -> void:
	rotation = global_position.direction_to(Arena.player_pos(get_tree())).angle() - PI / 2


func _physics_process(delta: float) -> void:
	cooldown -= delta
	if cooldown <= 0:
		cooldown = FIRE_RATE
		shoot()


func shoot() -> void:
	face_player()  # the player may have moved since the last shot
	var bullet = BULLET_SCENE.instantiate()
	var aim = global_position.direction_to(Arena.player_pos(get_tree()))
	bullet.position = global_position + aim * BARREL_LENGTH  # fire from the barrel tip
	bullet.direction = aim
	bullet.shooter = self
	# Add to the cannon's parent (game_main), NOT the cannon itself; otherwise the
	# bullet would move with the cannon and vanish when the cannon dies.
	get_parent().add_child(bullet)
	fire_sfx.play()


func die() -> void:
	if is_queued_for_deletion():
		return  # already dead: don't score twice
	print("cannon destroyed")
	Game.score += 1
	queue_free()
