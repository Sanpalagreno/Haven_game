extends Node
# Autoload: survives scene changes, so it holds the current run's progress.
var level = 1
var score = 0   # cannon +1, rammer +2, boss +5
var tutorial = false   # true while playing the tutorial (no rounds, can't lose hearts)

# Upgrades picked after each boss. They stack, and last until the run ends.
var enemy_scale = 1.0    # "Bigger Enemies": +10% size each pick
var extra_hearts = 0     # "+1 Heart": +1 max health each pick
var shield_scale = 1.0   # "Bigger Shield": +10% size each pick
var parry_bonus = 0.0    # "Longer Parry": +0.1s parry window each pick
var enemy_speed = 1.0    # "Slower Enemies": x0.9 rammer + cannonball speed each pick


# Start a brand-new run (called by the Play / Play Again buttons).
func reset() -> void:
	level = 1
	score = 0
	tutorial = false
	enemy_scale = 1.0
	extra_hearts = 0
	shield_scale = 1.0
	parry_bonus = 0.0
	enemy_speed = 1.0
