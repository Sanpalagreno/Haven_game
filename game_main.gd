extends Node2D


const RAM_SCENE = preload("res://ram.tscn")
const CANNON_SCENE = preload("res://cannon.tscn")
const BOSS_BALL_SCENE = preload("res://boss_ball.tscn")
const BOSS_SCENE = preload("res://boss.tscn")
const LEVEL_MUSIC = preload("res://assets/level_music.ogg")
const BOSS_MUSIC = preload("res://assets/boss_music.ogg")
var diff = 1+Game.level   # Game = the autoload (game.gd); level is a variable, so no ()
var ram_spn_rate = 5.0/diff      # .0 so it divides with decimals instead of rounding down to 0
var cannon_spn_rate = 8.0/diff
const round_len = 1
const BOSS_ROUND = 4        # boss time = after the round timer has finished 3 times


var ram_time = ram_spn_rate
var cannon_time = cannon_spn_rate
var round_time = round_len
var current_round = 1
var only_rammers_time = 0.0           # boss round: how long only rammers have been left
var music = AudioStreamPlayer.new()   # plays one track at a time


func _ready() -> void:
	print("level ", Game.level, "  round ", current_round, " start")
	add_child(music)
	play_music(LEVEL_MUSIC)
	if Game.tutorial:
		add_child(preload("res://tutorial.gd").new())   # the tutorial runs the level instead of rounds


func play_music(track) -> void:
	track.loop = true     # start over when it reaches the end
	music.stream = track
	music.play()


func _physics_process(delta: float) -> void:
	if $player.boss_mode:
		return  # boss time: no more rounds and no more regular spawns
	if Game.tutorial:
		return  # tutorial.gd does its own spawning

	# Advance to the next round when the round timer runs out (rounds stop at the boss round).
	if current_round < BOSS_ROUND:
		round_time -= delta
		if round_time <= 0:
			current_round += 1
			round_time = round_len
			print("round ", current_round, " start")

	# Boss round: no more spawning. The boss comes when:
	#   - every enemy is dead, or
	#   - only 2 (or fewer) rammers have been left for more than 5 seconds
	if current_round >= BOSS_ROUND:
		if cannons_left() == 0 and enemies_left() <= 2:
			only_rammers_time += delta
		else:
			only_rammers_time = 0
		if enemies_left() == 0 or only_rammers_time > 5:
			start_boss()
		return

	# Spawn whatever this round calls for, each type on its own timer.
	ram_time -= delta
	cannon_time -= delta
	match current_round:
		1:
			spawn_cannon()
		2:
			spawn_ram()
		_:   # round 3 and beyond
			spawn_ram()
			spawn_cannon()


func spawn_ram():
	if ram_time <= 0:
		ram_time = ram_spn_rate
		spawn(RAM_SCENE)


func spawn_cannon():
	if cannon_time <= 0:
		cannon_time = cannon_spn_rate
		spawn(CANNON_SCENE)


func start_boss() -> void:
	print("BOSS TIME")
	$player.boss_mode = true  # player slides right; shield (which reads this) locks left
	clear_enemies()           # clear first, so the new ball isn't removed with the old enemies
	play_music(BOSS_MUSIC)

	var boss = BOSS_SCENE.instantiate()
	boss.name = "boss"        # the ball finds the boss by this name
	add_child(boss)

	var ball = BOSS_BALL_SCENE.instantiate()
	ball.position = Vector2(500, 486)  # serve from in front of the boss, clear of the player
	add_child(ball)


# How many rammers and cannons are still alive.
func enemies_left() -> int:
	var count = 0
	for child in get_children():
		if child is Rammer or child is Cannon:
			count += 1
	return count


# How many cannons are still alive.
func cannons_left() -> int:
	var count = 0
	for child in get_children():
		if child is Cannon:
			count += 1
	return count


# Remove every rammer, cannon and cannonball currently in the game.
func clear_enemies() -> void:
	for child in get_children():
		if child is Rammer or child is Cannon or child is Bullet:
			child.queue_free()


func spawn(enm_type):
	var enm = enm_type.instantiate()
	add_child(enm)
