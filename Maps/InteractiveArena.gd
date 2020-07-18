extends Node2D

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

var char_name
var ai_name

var tile_size = 32
var save_file = "save_data"
var network_id = ""

onready var Action = ActionClass.new()
onready var CharacterType = $CanvasLayer/MarginContainer/VBoxContainer/CharacterType
onready var AIType = $CanvasLayer/MarginContainer/VBoxContainer/AIType
onready var SaveFile = $CanvasLayer/MarginContainer/VBoxContainer/SaveFile
onready var NetworkID = $CanvasLayer/MarginContainer/VBoxContainer/NetworkID
onready var Refresh = $CanvasLayer/MarginContainer/VBoxContainer/Refresh
onready var Loading = $CanvasLayer/MarginContainer/VBoxContainer/Loading

onready var arena_width = 26 * self.tile_size
onready var arena_height = 18 * self.tile_size

func _ready():
	for type in character_types:
		CharacterType.add_item(type)
	for type in ai_types.keys():
		AIType.add_item(type)
	var default_idx = 0
	var save_files = SaveManager.get_save_files_list()
	save_files.sort()
	for i in range(save_files.size()):
		var file_name = save_files[i]
		SaveFile.add_item(file_name)
		if file_name == self.save_file:
			default_idx = i
	SaveFile.select(default_idx)
	self.char_name = character_types.keys()[0]
	self.ai_name = ai_types.keys()[0]
	self._update_network_ids()

func init(params):
	pass

func _process(delta):
	if Input.is_action_just_pressed("refresh"):
		self._refresh_arena()

func _refresh_arena():
	Loading.visible = true
	yield(self.get_tree(), "idle_frame")
	yield(self.get_tree(), "idle_frame")

	self._refresh()

	Loading.visible = false

func _create_ai_from_input(params):
	print("%s %s %s %s" % [self.char_name, self.ai_name,
						   self.save_file , self.network_id])
	
	params.ai_type = ai_types[self.ai_name]
	if self.network_id != "":
		params.network_id = self.network_id
	
	var char_type = character_types[self.char_name]
	return self._create_character(char_type, params)

func _create_character(char_type, params):
	var extra_params = {
		"speed": 120,
		"weight": 1,
		"max_life": 30,
		"damage": 10,
		"defense": 0,
		"idle_interpolator": "STEP",
		"max_idle_rate": 0.0,
		"min_idle_rate": 0.0,
		"idle_rate_decay_time": 0.0,
		"exploration_interpolator": "STEP",
		"max_exploration_rate": 0.0,
		"min_exploration_rate": 0.0,
		"exploration_rate_decay_time": 0.0,
		"learning_interpolator": "STEP",
		"max_learning_rate": 0.0,
		"min_learning_rate": 0.0,
		"learning_rate_decay_time": 0.0
	}
	global.insert_default_keys(params, extra_params)
	var character = char_type.instance()
	character.add_to_group(params.team)
	$Wall.add_child(character)
	character.init(params)
	return character

func _update_network_ids():
	var key_begin = self.char_name + "_" + self.ai_name + "_"
	NetworkID.clear()
	NetworkID.add_item("")
	for key in NNParamsManager.get_keys_list():
		if key.begins_with(key_begin):
			var split = key.split(key_begin, false)
			NetworkID.add_item(split[0])

# Abstract
func _refresh():
	pass

func _on_CharacterType_item_selected(ID):
	self.char_name = CharacterType.get_item_text(ID)
	self._update_network_ids()

func _on_AIType_item_selected(ID):
	self.ai_name = AIType.get_item_text(ID)
	self._update_network_ids()

func _on_SaveFile_item_selected(ID):
	self.save_file = SaveFile.get_item_text(ID)
	SaveManager.change_save_file(self.save_file)
	self._update_network_ids()

func _on_NetworkID_item_selected(ID):
	self.network_id = NetworkID.get_item_text(ID)