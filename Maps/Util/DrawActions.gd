extends Control

const ActionClass = preload("res://Characters/ActionBase.gd")

const movements = [
	"idle",
	"death",
	"walk",
	"attack"
]

const directions = [
	"",
	"right",
	"up_right",
	"up",
	"up_left",
	"left",
	"down_left",
	"down",
	"down_right"
]

var char_ai

var tile_size = 32
var state = {}

onready var Action = ActionClass.new()
onready var arena_width = 26 * self.tile_size
onready var arena_height = 18 * self.tile_size

func set_state(state):
	self.state = state
	self.update()

func set_ai(ai):
	self.char_ai = ai

func _draw():
	if self.char_ai == null or self.state.size() == 0:
		return
	var state = self.state
	for i in range(3 * tile_size / 2, arena_width, tile_size):
		for j in range(3 * tile_size / 2, arena_height, tile_size):
			var pos = Vector2(i, j)
			state["enemy_pos"] = pos
			var action = char_ai._compute_action_from_q_values(state)
			if Action.has(action, Action.WALK):
				var vec = Action.to_vec(action)
				draw_rect(Rect2(pos - Vector2(2, 2), Vector2(4, 4)), Color(1, 0, 0))
				draw_line(pos, pos + 16 * vec, Color(1, 0, 0))
			elif Action.get_movement(action) == Action.ATTACK:
				draw_rect(Rect2(pos - Vector2(4, 4), Vector2(8, 8)), Color(1, 1, 0))
			elif Action.get_movement(action) == Action.IDLE:
				draw_circle(pos, 8, Color(0, 0, 1))