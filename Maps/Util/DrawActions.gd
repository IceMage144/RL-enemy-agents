extends Control

const dir_to_vec = {
	"up": Vector2(0, -1),
	"left": Vector2(-1, 0),
	"down": Vector2(0, 1),
	"right": Vector2(1, 0)
}

var player
var robot
var botAI

func _ready():
	player = global.find_entity("team1")
	robot = global.find_entity("team2")
	botAI = robot.get_node("AI")

func _process(delta):
	update()

func _draw():
	var state = {
		"self_pos": Vector2(),
		"self_life": robot.life,
		"self_maxlife": robot.max_life,
		"self_damage": robot.damage,
		"self_action": robot.action,
		"self_dir": robot.direction,
		"player_pos": player.position,
		"player_life": player.life,
		"player_maxlife": player.max_life,
		"player_damage": player.damage,
		"player_action": player.action,
		"player_dir": player.direction
	}
	for i in range(16, get_viewport().size.x, 64):
		for j in range(16, get_viewport().size.y, 64):
			var pos = Vector2(i, j)
			state["self_pos"] = pos
			var action = botAI._compute_action_from_q_values(state)
			if "walk" in action:
				draw_rect(Rect2(pos - Vector2(2, 2), Vector2(4, 4)), Color(1, 0, 0))
				draw_line(pos, pos + 16*dir_to_vec[action[1]], Color(1, 0, 0))
			elif "attack" in action:
				draw_rect(Rect2(pos - Vector2(4, 4), Vector2(8, 8)), Color(1, 1, 0))
			elif "idle" in action:
				draw_circle(pos, 8, Color(0, 0, 1))
				
		