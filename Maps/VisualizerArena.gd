extends Node2D

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

export(String) var network_id = ""

var char_ai

var tile_size = 32
var self_action = 0
var enemy_action = 0
var self_life = 0
var enemy_life = 0

onready var Action = ActionClass.new()
onready var arena_width = 27 * self.tile_size
onready var arena_height = 13 * self.tile_size
onready var character = $Wall/Goblin

func _ready():
	if self.network_id == "":
		character.init({})
	else:
		character.init({
			"network_id": character.name
		})
	for movement in movements:
		$CanvasLayer/SelfMovement.add_item(movement)
		$CanvasLayer/EnemyMovement.add_item(movement)
	for direction in directions:
		$CanvasLayer/SelfDirection.add_item(direction)
		$CanvasLayer/EnemyDirection.add_item(direction)
	var max_life = self.character.get_max_life()
	$CanvasLayer/SelfLife.value = max_life
	$CanvasLayer/SelfLife.max_value = max_life
	$CanvasLayer/EnemyLife.value = max_life
	$CanvasLayer/EnemyLife.max_value = max_life

func init(params):
	$CanvasLayer2/DrawActions.init({
		"ai": self.character.get_node("Controller/AI")
	})

func _get_state():
	return {
		"self_pos": self.character.position,
		"self_life": self.self_life,
		"self_maxlife": self.character.get_max_life(),
		"self_damage": self.character.get_damage(),
		"self_defense": self.character.get_defense(),
		"self_act": self.self_action,
		"enemy_pos": Vector2(),
		"enemy_life": self.enemy_life,
		"enemy_maxlife": self.character.get_max_life(),
		"enemy_damage": self.character.get_damage(),
		"enemy_defense": self.character.get_defense(),
		"enemy_act": self.enemy_action
	}

func _on_Refresh_pressed():
	var self_mov_id = $CanvasLayer/SelfMovement.selected
	var self_mov = $CanvasLayer/SelfMovement.get_item_text(self_mov_id)
	var self_dir_id = $CanvasLayer/SelfDirection.selected
	var self_dir = $CanvasLayer/SelfDirection.get_item_text(self_dir_id)
	var self_action_str = self_mov
	if self_dir != "":
		self_action_str = self_action_str + "_" + self_dir
	self.self_action = Action.from_string(self_action_str)
	self.self_life = $CanvasLayer/SelfLife.value
	
	var enemy_mov_id = $CanvasLayer/EnemyMovement.selected
	var enemy_mov = $CanvasLayer/EnemyMovement.get_item_text(enemy_mov_id)
	var enemy_dir_id = $CanvasLayer/EnemyDirection.selected
	var enemy_dir = $CanvasLayer/EnemyDirection.get_item_text(enemy_dir_id)
	var enemy_action_str = enemy_mov
	if enemy_dir != "":
		enemy_action_str = enemy_action_str + "_" + enemy_dir
	self.enemy_action = Action.from_string(enemy_action_str)
	self.enemy_life = $CanvasLayer/EnemyLife.value
	
	var state = self._get_state()
	$CanvasLayer2/DrawActions.set_state(state)
