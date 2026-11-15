extends Node
# Tutorial: added to game_main when Game.tutorial is true. Walks through each mechanic one step
# at a time, spawning just the enemies that step needs and waiting until the player has done it.

enum Step {BLOCK, CRASH, PARRY, GOOD_TO_KNOW, BOSS_INFO, BOSS_FIGHT, DONE}

const BOSS_PAGES = [
	"5/5 - THE BOSS\nAfter 3 rounds, the boss arrives. You slide to the right edge\nand move up and down with your mouse.",
	"5/5 - THE BOSS\nIt's Pong! Knock the ball past the boss 3 times to win.\nIf the ball gets past YOU, you lose a heart.",
	"5/5 - THE BOSS\nEvery time you return the ball, it gets 15% faster.\nHit it with the EDGE of your shield to send it off steep -\nthe boss can't keep up with fast, steep shots!",
]
const PAGE_TIME = 5.5

@onready var main = get_parent()
var step = Step.BLOCK
var step_time = 0.0
var label = Label.new()
var blocks = 0
var counted = {}            # rammers already counted for the current shield bounce
var score_at_step_start = 0


func _ready() -> void:
	var layer = CanvasLayer.new()   # draws on top of the game, like the HUD
	add_child(layer)
	label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	label.offset_top = 150
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 40)
	label.add_theme_constant_override("outline_size", 12)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	layer.add_child(label)
	go_to(Step.BLOCK)


func go_to(new_step) -> void:
	step = new_step
	step_time = 0.0
	score_at_step_start = Game.score
	if step != Step.BOSS_FIGHT and step != Step.DONE:
		main.clear_enemies()   # fresh start for each lesson


func count_of(type) -> int:
	var n = 0
	for c in main.get_children():
		if is_instance_of(c, type) and not c.is_queued_for_deletion():
			n += 1
	return n


func _physics_process(delta: float) -> void:
	step_time += delta
	match step:
		Step.BLOCK:
			label.text = "1/5 - BLOCKING\nMove your mouse to aim your shield.\nBlock 2 rammer charges with it.   (%d/2)" % blocks
			if count_of(Rammer) == 0:
				main.spawn(main.RAM_SCENE)
			# A rammer that just bounced off the shield has `passed_shield` set.
			for c in main.get_children():
				if c is Rammer:
					var id = c.get_instance_id()
					if c.passed_shield and not counted.has(id):
						counted[id] = true
						blocks += 1
					elif not c.passed_shield:
						counted.erase(id)
			if blocks >= 2:
				go_to(Step.CRASH)

		Step.CRASH:
			label.text = "2/5 - MAKE RAMMERS CRASH\nYour shield can't sink rammers - but rammers sink each other!\nBounce one rammer into another."
			if count_of(Rammer) < 3 and int(step_time * 10) % 20 == 0:
				main.spawn(main.RAM_SCENE)
			if Game.score > score_at_step_start:   # a rammer died (+2)
				go_to(Step.PARRY)

		Step.PARRY:
			label.text = "3/5 - PARRYING\nCannonballs go straight THROUGH your shield!\nLEFT-CLICK just as a ball touches your shield to parry it back and sink the cannon."
			if count_of(Cannon) == 0:
				main.spawn(main.CANNON_SCENE)
			if Game.score > score_at_step_start:   # a cannon sank (+1)
				go_to(Step.GOOD_TO_KNOW)

		Step.GOOD_TO_KNOW:
			label.text = "4/5 - GOOD TO KNOW\nBalls from a sunk cannon are blocked by your shield automatically.\nParrying has a short cooldown - time your clicks, don't spam.\nYour shield bounces a rammer once; it must hit a wall before it can be bounced again."
			if step_time > 7:
				go_to(Step.BOSS_INFO)

		Step.BOSS_INFO:
			var page = int(step_time / PAGE_TIME)
			if page < BOSS_PAGES.size():
				label.text = BOSS_PAGES[page]
			else:
				main.start_boss()
				go_to(Step.BOSS_FIGHT)

		Step.BOSS_FIGHT:
			label.text = "PRACTICE: beat the boss!\nAim with the edges of your shield." if step_time < 8 else ""
			if main.get_node_or_null("boss") == null and step_time > 1:
				go_to(Step.DONE)

		Step.DONE:
			label.text = "Tutorial complete!\nGood luck out there."
			if step_time > 4:
				Game.reset()
				get_tree().change_scene_to_file("res://start_screen.tscn")
