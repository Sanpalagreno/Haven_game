class_name Rammer
extends CharacterBody2D

# The rammer's cycle:  APPROACH -> WAIT -> CHARGE -> (hits a wall) -> APPROACH -> ...
enum State{APPROACH,WAIT, CHARGE}
const apr_speed = 3.0
const chrg_speed = 5
const apr_dist = 450
const wait_time = 0

const WALL_LAYER = 2        # the walls live on physics layer 2 (see StaticBody2D in game_main)
const SPAWN_OUTSIDE = 60    # how far beyond the edge we start

var state = State.APPROACH
var waiting = wait_time
var entering = true         # true while sailing in from outside the arena
var bounce_sfx = AudioStreamPlayer.new()
var passed_shield = null    # set after we bounce off the shield; we ignore it until we hit a wall

func _ready() -> void:
	scale = Vector2.ONE * Game.enemy_scale   # "Bigger Enemies" upgrade
	position = random_edge_spawn()
	set_collision_mask_value(WALL_LAYER, false)  # ghost through the walls on the way in
	bounce_sfx.stream = preload("res://assets/ram_bounce.wav")
	add_child(bounce_sfx)


# Pick a random spot just off-screen.
#   Normal rounds: any of the 4 sides.
#   Boss time: only the left half (in front of the shield), since the player is on the right.
func random_edge_spawn() -> Vector2:
	var s = Arena.SIZE
	var boss = Arena.is_boss(get_tree())
	var max_x = Arena.PLAYER_X - 400 if boss else s.x   # boss: stay well left of the player
	var sides = 3 if boss else 4                         # boss: no right-side spawns
	match randi() % sides:
		0: return Vector2(randf_range(0, max_x), -SPAWN_OUTSIDE)        # top
		1: return Vector2(randf_range(0, max_x), s.y + SPAWN_OUTSIDE)   # bottom
		2: return Vector2(-SPAWN_OUTSIDE, randf_range(0, s.y))          # left
		_: return Vector2(s.x + SPAWN_OUTSIDE, randf_range(0, s.y))     # right


func _physics_process(delta: float) -> void:
	if is_queued_for_deletion():
		return  # already died this frame; don't move or die again
	# Once fully inside (30px clear of every wall), start colliding with walls.
	if entering and Rect2(Vector2.ZERO, Arena.SIZE).grow(-30).has_point(global_position):
		entering = false
		set_collision_mask_value(WALL_LAYER, true)

	# 1. Decide how to move based on the current state.
	var player_spot = Arena.player_pos(get_tree())  # the player moves, so check every tick
	match state:
		State.APPROACH:
			velocity = global_position.direction_to(player_spot) * apr_speed * Game.enemy_speed
			if global_position.distance_to(player_spot) < apr_dist:
				state = State.WAIT
				waiting = wait_time  # reset the timer every cycle
		State.WAIT:
			velocity = Vector2.ZERO
			waiting -= delta
			if waiting <= 0:
				state = State.CHARGE
				# Aim once, at the start of the charge; it then flies straight.
				velocity = global_position.direction_to(player_spot) * chrg_speed * Game.enemy_speed
		State.CHARGE:
			pass  # keep the velocity we launched with (or bounced into)

	# Point the boat picture the way we're moving (its front is at the BOTTOM of the image).
	if velocity != Vector2.ZERO:
		$Sprite2D.rotation = velocity.angle() - PI / 2

	# 2. Move, and react to whatever we hit.
	var collision = move_and_collide(velocity)
	if collision:
		var hit = collision.get_collider()
		if hit is Rammer:
			hit.die()
			die()
			return
		bounce_sfx.play()  # hit a wall, the shield or the player
		if hit is Player:
			hit.hit()  # ram the player (the player's i-frames stop repeat hits)
		if hit is Shield:
			# Bounce off the shield once, then pass through it until we touch a wall again.
			add_collision_exception_with(hit)
			passed_shield = hit
		if hit is StaticBody2D and passed_shield and is_instance_valid(passed_shield):
			remove_collision_exception_with(passed_shield)   # touched a wall: the shield can hit us again
			passed_shield = null
		if hit is StaticBody2D and state == State.CHARGE:
			state = State.APPROACH  # hit a wall: start the cycle over
		else:
			velocity = velocity.bounce(collision.get_normal())  # e.g. glance off the shield


func die():
	if is_queued_for_deletion():
		return  # already dead: don't score twice
	print("rammer died")
	Game.score += 2
	# Let the crash sound finish after we're gone: hand the sound player to our parent.
	bounce_sfx.reparent(get_parent())
	bounce_sfx.play()
	bounce_sfx.finished.connect(bounce_sfx.queue_free)
	queue_free()
