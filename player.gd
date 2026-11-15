class_name Player
extends CharacterBody2D
@onready var sprite: Sprite2D = $Sprite2D
# Other nodes (like the HUD) can listen for this instead of checking health every frame.
signal health_changed(new_health)

const MAX_HEALTH =5
const IFRAME_TIME = 2   # seconds of invincibility after taking a hit
const BLINK_RATE = 0.1      # how fast the sprite flickers while invincible

const MOVE_SPEED = 1200.0    # boss time: max pixels per second
const EDGE_GAP = 80         # boss time: keep the shield (149 tall) fully inside the arena

var max_health = MAX_HEALTH + Game.extra_hearts   # "+2 Hearts" upgrades add to this
var health = max_health
var invincible = 0.0        # time left on the i-frames; 0 = can be hit
var boss_mode = false       # game_main turns this on when boss time starts
func change_sprite_po() -> void:
	var new_texture = load("res://assets/po.jpeg")
	var rand = randi_range(1,100)
	if rand == 100:
		$Sprite2D.texture = new_texture
			
			
func _ready() -> void:
	add_to_group("player")  # lets enemies find us with get_first_node_in_group("player")
	position = Arena.CENTER
	change_sprite_po()

		

func _process(delta: float) -> void:
	if invincible > 0:
		invincible -= delta
		# Flicker: visible for one BLINK_RATE slice, hidden for the next.
		$Sprite2D.visible = int(invincible / BLINK_RATE) % 2 == 0
	else:
		$Sprite2D.visible = true

func _physics_process(delta: float) -> void:
	if not boss_mode:
		return  # normal rounds: stay put in the middle
	# Boss time: slide over to the right side, then only follow the mouse up and down.
	position.x = move_toward(position.x, Arena.PLAYER_X, MOVE_SPEED * delta)
	var target_y = clamp(get_global_mouse_position().y, EDGE_GAP, Arena.SIZE.y - EDGE_GAP)
	position.y = move_toward(position.y, target_y, MOVE_SPEED * delta)

func hit() -> void:
	if Game.tutorial:
		return  # can't lose hearts in the tutorial
	if invincible > 0:
		return  # still flashing from the last hit: ignore this one
	health -= 1
	invincible = IFRAME_TIME
	health_changed.emit(health)
	print("player hit! health: ", health)
	if health <= 0:
		print("game over")
		# Deferred = "do this after the current physics step"; changing scenes mid-collision is not allowed.
		get_tree().change_scene_to_file.call_deferred("res://game_over.tscn")
