extends Node2D

signal character_reset

const ActionClass = preload("res://Characters/ActionBase.gd")
const AIEnums = preload("res://Characters/AIs/AIEnums.gd")

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

const character_types = {
	"Goblin": preload("res://Characters/Goblin/Goblin.tscn"),
	"Spider": preload("res://Characters/Spider/Spider.tscn"),
	"Slime": preload("res://Characters/Slime/Slime.tscn"),
	"Human": preload("res://Characters/Human/Human.tscn")
}

const ai_types = {
	"SingleQLAI": AIEnums.SINGLE_QL,
	"PerceptronQLAI": AIEnums.PERCEPTRON_QL,
	"MemoryQLAI": AIEnums.MEMORY_QL,
	"MultiQLAI": AIEnums.MULTI_QL
}

const max_life = 30

var char_type
var ai_type

var tile_size = 32
var self_action = 0
var enemy_action = 0
var self_life = 0
var enemy_life = 0
var character = null

onready var Action = ActionClass.new()
onready var CharacterType = $CanvasLayer/MarginContainer/VBoxContainer/CharacterType
onready var AIType = $CanvasLayer/MarginContainer/VBoxContainer/AIType
onready var NetworkID = $CanvasLayer/MarginContainer/VBoxContainer/NetworkID
onready var SelfLife = $CanvasLayer/MarginContainer/VBoxContainer/SelfLife
onready var SelfMovement = $CanvasLayer/MarginContainer/VBoxContainer/SelfMovement
onready var SelfDirection = $CanvasLayer/MarginContainer/VBoxContainer/SelfDirection
onready var EnemyLife = $CanvasLayer/MarginContainer/VBoxContainer/EnemyLife
onready var EnemyMovement = $CanvasLayer/MarginContainer/VBoxContainer/EnemyMovement
onready var EnemyDirection = $CanvasLayer/MarginContainer/VBoxContainer/EnemyDirection
onready var Loading = $CanvasLayer/MarginContainer/VBoxContainer/Loading
onready var DrawActions = $CanvasLayer/DrawActions

onready var arena_width = 26 * self.tile_size
onready var arena_height = 18 * self.tile_size

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
	for type in character_types:
		CharacterType.add_item(type)
	for type in ai_types.keys():
		AIType.add_item(type)
	self._update_network_ids()

func init(params):
	pass

func _process(delta):
	if Input.is_action_just_pressed("refresh"):
		self._refresh()

func reset_character():
	if self.character != null:
		self.character.queue_free()
		yield(self.character, "tree_exited")
	
	self.character = self.char_type.instance()
	$Wall.add_child(self.character)
	var params = {
		"ai_type": self.ai_type,
		"learning_activated": false,
		"experience_replay": false,
		"min_exploration_rate": 0.0,
		"max_exploration_rate": 0.0,
		"think_time": 0.0
	}
	var network_id = self._get_option(NetworkID)
	if network_id != "":
		params.network_id = network_id
	character.position = Vector2(arena_width / 2, arena_height / 2)
	character.init(params)
	
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

func _get_option(option_button):
	var option_id = option_button.selected
	return option_button.get_item_text(option_id)

func _refresh():
	Loading.visible = true
	yield(self.get_tree(), "idle_frame")
	yield(self.get_tree(), "idle_frame")

	var self_mov = self._get_option(SelfMovement)
	var self_dir = self._get_option(SelfDirection)
	var self_action_str = self_mov
	if self_dir != "":
		self_action_str = self_action_str + "_" + self_dir
	self.self_action = Action.from_string(self_action_str)
	self.self_life = SelfLife.value
	
	var enemy_mov = self._get_option(EnemyMovement)
	var enemy_dir = self._get_option(EnemyDirection)
	var enemy_action_str = enemy_mov
	if enemy_dir != "":
		enemy_action_str = enemy_action_str + "_" + enemy_dir
	self.enemy_action = Action.from_string(enemy_action_str)
	self.enemy_life = EnemyLife.value

	self.reset_character()

	Loading.visible = false

func _update_network_ids(_dummy=null):
	var char_name = self._get_option(CharacterType)
	self.char_type = character_types[char_name]
	var ai_name = self._get_option(AIType)
	self.ai_type = ai_types[ai_name]
	var key_begin = char_name + "_" + ai_name + "_"
	NetworkID.clear()
	NetworkID.add_item("")
	for key in NNParamsManager.get_keys_list():
		if key.begins_with(key_begin):
			var split = key.split(key_begin, false)
			NetworkID.add_item(split[0])
