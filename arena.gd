class_name Arena
# The one place that knows how big the play area is.
# If you change SIZE, also change: the walls in game_main.tscn and
# display/window/size/viewport_width/height in Project Settings.

const SIZE = Vector2(1728, 972)
const CENTER = Vector2(864, 486)  # SIZE / 2
# Boss time: the player's spot on the right; enemies stay left of this.
# 1670 = right edge (1728) - half the player sprite (~50) - a small gap (8).
const PLAYER_X = 1670


# Where the player is right now, so enemies can aim at a moving target.
# Static = call it as Arena.player_pos(tree) without creating an Arena object.
static func player_pos(tree: SceneTree) -> Vector2:
	var p = tree.get_first_node_in_group("player")
	return p.global_position if p else CENTER


# True once boss time has started (the player owns the switch; game_main flips it).
static func is_boss(tree: SceneTree) -> bool:
	var p = tree.get_first_node_in_group("player")
	return p != null and p.boss_mode
