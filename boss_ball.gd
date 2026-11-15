class_name BossBall
extends CharacterBody2D

const RADIUS = 64                  # matches the collision circle in boss_ball.tscn
const START_VELOCITY = Vector2(7, 3.5)
const MAX_AIM_DEGREES = 55         # steepest angle you can send the ball off the edge of your shield

var serve_pos: Vector2             # where we started, so we can re-serve after a miss
var bounce_sfx = AudioStreamPlayer.new()


func _ready() -> void:
	# game_main sets our position before adding us, so we remember it as the serve spot.
	serve_pos = position
	velocity = START_VELOCITY
	bounce_sfx.stream = preload("res://assets/pong_bullet_bounce.wav")
	add_child(bounce_sfx)
	# Note: NO wall layer in the mask. We handle the top and bottom ourselves below.


func _physics_process(delta: float) -> void:
	# Shield / player are on layer 1, so physics still bounces us off them.
	# (The boss is an Area2D; it bounces us itself, in boss.gd.)
	var collision = move_and_collide(velocity)
	if collision:
		velocity = velocity.bounce(collision.get_normal())
		bounce_sfx.play()
		var hit = collision.get_collider()
		if hit is Shield or hit is Player:
			# Pong aiming: where the ball hits your shield sets its angle.
			# Middle = straight across, edges = up to 55 degrees (steep shots beat the boss).
			var speed = velocity.length() * 1.15   # +15% every time WE return it
			var half_length = 75.0 * Game.shield_scale
			var off = clamp((position.y - hit.global_position.y) / half_length, -1.0, 1.0)
			var angle = off * deg_to_rad(MAX_AIM_DEGREES)
			velocity = Vector2(sign(velocity.x) * cos(angle), sin(angle)) * speed

	# Top and bottom: bounce.
	if position.y < RADIUS or position.y > Arena.SIZE.y - RADIUS:
		velocity.y = -velocity.y
		position.y = clamp(position.y, RADIUS, Arena.SIZE.y - RADIUS)
		bounce_sfx.play()

	# Out the right (past the player): we lose a life, then serve again.
	if position.x > Arena.SIZE.x + RADIUS:
		get_tree().get_first_node_in_group("player").hit()
		position = serve_pos
		velocity = START_VELOCITY

	# Out the left (past the boss): the boss loses a life. Serve again, unless that was its last.
	elif position.x < -RADIUS:
		var boss = get_parent().get_node_or_null("boss")
		if boss:
			boss.lose_life()
			if boss.hp <= 0:
				Game.level+=1
				queue_free()
				return
		position = serve_pos
		velocity = START_VELOCITY   # back to starting speed for the next rally
