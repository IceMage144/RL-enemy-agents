extends "res://Maps/InteractiveArena.gd"

const Logger = preload("res://Structures/Logger.gd")

var characters = []
var alive_characters = 0

onready var logger = Logger.new()

func _ready():
	self._toggle_buttons(true)

func _exit_tree():
	self.logger.free()

func _refresh():
	self._delete_characters()
	
	var params = {
		"team": "team1",
		"learning_activated": false,
		"experience_replay": false,
		"min_exploration_rate": 0.1,
		"max_exploration_rate": 0.1
	}
	var ai = self._create_ai_from_input(params)
	ai.connect("character_death", self, "_on_character_death", [ai])
	ai.position = self._rand_pos()
	self.characters.append(ai)

	params = {
		"team": "team2",
		"controller_type": 0
	}
	var player = self._create_character(character_types["Human"], params)
	player.connect("character_death", self, "_on_character_death", [player])
	player.position = self._rand_pos()
	self.characters.append(player)
	
	self.alive_characters = self.characters.size()

	self._toggle_buttons(false)

func _delete_characters():
	for character in self.characters:
		character.queue_free()
		yield(character, "tree_exited")
	self.characters = []

func _rand_pos():
	var off = 1 * self.tile_size
	var xPos = off + self.arena_width * randf()
	var yPos = off + self.arena_height * randf()
	return Vector2(xPos, yPos)

func _on_character_death(character):
	self.alive_characters -= 1
	if self.alive_characters <= 1:
		self._delete_characters()
		self._toggle_buttons(true)

func _toggle_buttons(state):
	CharacterType.disabled = not state
	AIType.disabled = not state
	SaveFile.disabled = not state
	NetworkID.disabled = not state
	Refresh.disabled = not state
	if not state:
		CharacterType.release_focus()
		AIType.release_focus()
		SaveFile.release_focus()
		NetworkID.release_focus()
		Refresh.release_focus()
	else:
		CharacterType.grab_focus()
