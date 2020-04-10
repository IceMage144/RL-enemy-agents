extends Node2D

signal finished(winner)

const GRAPH_FREQUENCY = 10

var alive_characters

var tile_size = 32
var rounds = 0
var last_round = 11
var scores = {}

onready var arena_width = 27 * self.tile_size
onready var arena_height = 13 * self.tile_size

func _ready():
	var characters = self.get_tree().get_nodes_in_group("character")
	self.alive_characters = len(characters)
	for character in characters:
		self.scores[character.name] = 0
		character.position = self._rand_pos()
		character.connect("character_death", self, "_on_character_death", [character])
		character.init({
			"network_id": character.name
		})

func init(params):
	if params != null and params.has("last_round"):
		self.last_round = params["last_round"]

func print_info():
	var loss_info = {}
	print("------------")
	for character in self.get_tree().get_nodes_in_group("character"):
		var team = global.get_team(character)
		var pretty_name = character.get_full_name()
		print(pretty_name + ": " + str(character.life) + " (" + team + ")")
		loss_info[pretty_name] = character.controller.get_loss()

	# if self.rounds % GRAPH_FREQUENCY == 0:
		# Plot loss

func reset(timeout):
	self.rounds += 1
	if GameConfig.get_debug_flag("environment"):
		self.print_info()
	# self.get_parent().reset_game()

	$TimeoutTimer.start()
	var characters = self.get_tree().get_nodes_in_group("character")
	self.alive_characters = len(characters)
	var winner = self._get_last_alive()
	if winner != null and not timeout:
		print(winner.get_full_name() + " won!")
		self.scores[winner.name] += 1
	
	for character in characters:
		character.before_reset(timeout)
	for character in characters:
		character.position = self._rand_pos()
		character.reset(timeout)
	for character in characters:
		character.after_reset(timeout)
	for character in characters:
		character.end()
	if self.rounds == self.last_round:
		self.finish()

func finish():
	var winner = self._get_winner()
	emit_signal("finished", winner)

func _rand_pos():
	var off = 2 * self.tile_size
	var xPos = off + self.arena_width * randf()
	var yPos = off + self.arena_height * randf()
	return Vector2(xPos, yPos)

func _leader_compare(char1, char2):
	return self.scores[char1.name] < self.scores[char2.name]

func _get_winner():
	var characters = self.get_tree().get_nodes_in_group("character")
	characters.sort_custom(self, "_leader_compare")
	return characters.back()

func _get_last_alive():
	for character in self.get_tree().get_nodes_in_group("character"):
		if not character.is_dead():
			return character
	return null

func _on_character_death(character):
	self.alive_characters -= 1
	if self.alive_characters <= 1:
		self.reset(false)

func _on_TimeoutTimer_timeout():
	self.reset(true)
	print("Timeout!")
