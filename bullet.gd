class_name Bullet
extends Area2D

const SPEED = 375.0         # pixels per second on the way to the player
const RETURN_SPEED = 450.0  # faster on the way back after a parry
const OUT_COLOR = Color(1, 1, 1)             # white = no tint: the cannonball's own colors
const PARRIED_COLOR = Color(0.6, 2.5, 2.5)   # values above 1 brighten: a glowing cyan ball

var direction = Vector2.ZERO  # set by the cannon that fires us
var shooter: Node2D = null    # the cannon that fired us; we home back to it when parried
var parried = false
var on_shield: Shield = null  # the shield we're touching right now (null = not touching)


func _ready() -> void:
	scale = Vector2.ONE * Game.enemy_scale   # "Bigger Enemies" upgrade makes cannonballs bigger too
	# Signals: Godot calls these functions automatically when something touches us.
	body_entered.connect(_on_body_entered)  # CharacterBody2D things: shield, player, rammers
	body_exited.connect(_on_body_exited)
	area_entered.connect(_on_area_entered)  # Area2D things: cannons
	$Sprite2D.modulate = OUT_COLOR


func _physics_process(delta: float) -> void:
	if parried:
		# The shooter might already be gone (another bullet killed it).
		if not is_instance_valid(shooter):
			queue_free()
			return
		# Re-aim every tick so we always hit the shooter.
		direction = global_position.direction_to(shooter.global_position)
		position += direction * RETURN_SPEED * delta
	else:
		position += direction * SPEED * Game.enemy_speed * delta   # "Slower Enemies" upgrade
		if on_shield:
			if not is_instance_valid(shooter):
				queue_free()   # its cannon is dead: the shield just blocks it, no click needed
				return
			if on_shield.parry_timer > 0:
				on_shield.parry_timer = 0   # one click parries one bullet
				parried = true
				$Sprite2D.modulate = PARRIED_COLOR
			# no click: we pass straight through the shield and on to the player

	# Clean up bullets that leave the screen so they don't pile up forever.
	if not Rect2(Vector2.ZERO, Arena.SIZE).grow(50).has_point(global_position):
		queue_free()


func _on_body_entered(body: Node2D) -> void:
	if parried:
		return  # a parried bullet ignores everything except its shooter
	if body is Shield:
		on_shield = body   # touching the shield: _physics_process decides parry / block / pass through
	elif body is Player:
		body.hit()
		queue_free()


func _on_body_exited(body: Node2D) -> void:
	if body == on_shield:
		on_shield = null


func _on_area_entered(area: Area2D) -> void:
	if parried and area == shooter:
		shooter.die()
		queue_free()
