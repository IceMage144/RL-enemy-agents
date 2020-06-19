extends "res://Maps/InteractiveArena.gd"

const max_life = 30

var character = null
var self_action = 0
var enemy_action = 0
var self_life = max_life
var enemy_life = max_life

onready var SelfLife = $CanvasLayer/MarginContainer/VBoxContainer/SelfLife
onready var SelfMovement = $CanvasLayer/MarginContainer/VBoxContainer/SelfMovement
onready var SelfDirection = $CanvasLayer/MarginContainer/VBoxContainer/SelfDirection
onready var EnemyLife = $CanvasLayer/MarginContainer/VBoxContainer/EnemyLife
onready var EnemyMovement = $CanvasLayer/MarginContainer/VBoxContainer/EnemyMovement
onready var EnemyDirection = $CanvasLayer/MarginContainer/VBoxContainer/EnemyDirection
onready var DrawActions = $CanvasLayer/DrawActions

func _ready():
	for movement in movements:
		SelfMovement.add_item(movement)
		EnemyMovement.add_item(movement)
	for direction in directions:
		SelfDirection.add_item(direction)
		EnemyDirection.add_item(direction)
	SelfLife.value = max_life
	SelfLife.max_value = max_life
	EnemyLife.value = max_life
	EnemyLife.max_value = max_life

func _refresh():
	if self.character != null:
		self.character.queue_free()
		yield(self.character, "tree_exited")

	var params = {
		"team": "team1",
		"learning_activated": false,
		"experience_replay": false,
		"min_exploration_rate": 0.0,
		"max_exploration_rate": 0.0,
		"think_time": 0.0
	}
	self.character = self._create_ai_from_input(params)
	self.character.position = Vector2(arena_width / 2, arena_height / 2)

	var ai = self.character.get_node("Controller/AI")
	DrawActions.set_ai(ai)
	
	var state = self._get_state()
	DrawActions.set_state(state)

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

func _on_SelfLife_value_changed(value):
	self.self_life = value

func _on_SelfMovement_item_selected(ID):
	var self_mov_name = SelfMovement.get_item_text(ID)
	var self_mov = Action.from_string(self_mov_name)
	var self_dir = Action.get_direction(self.self_action)
	self.self_action = Action.compose(self_mov, self_dir)

func _on_SelfDirection_item_selected(ID):
	var self_mov = Action.get_movement(self.self_action)
	var self_dir_name = SelfDirection.get_item_text(ID)
	var self_dir = Action.from_string(self_dir_name)
	self.self_action = Action.compose(self_mov, self_dir)

func _on_EnemyLife_value_changed(value):
	self.enemy_life = value

func _on_EnemyMovement_item_selected(ID):
	var enemy_mov_name = EnemyMovement.get_item_text(ID)
	var enemy_mov = Action.from_string(enemy_mov_name)
	var enemy_dir = Action.get_direction(self.enemy_action)
	self.enemy_action = Action.compose(enemy_mov, enemy_dir)

func _on_EnemyDirection_item_selected(ID):
	var enemy_mov = Action.get_movement(self.enemy_action)
	var enemy_dir_name = EnemyDirection.get_item_text(ID)
	var enemy_dir = Action.from_string(enemy_dir_name)
	self.enemy_action = Action.compose(enemy_mov, enemy_dir)
