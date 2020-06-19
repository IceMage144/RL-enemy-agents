extends Node2D

signal finished_test

const Logger = preload("res://Structures/Logger.gd")

var alive_characters
var num_rounds
var experiment_id
var run

var tile_size = 32
var rounds = 0
var scores = {}
var characters = []

onready var logger = Logger.new()
onready var wall = $Wall
onready var arena_width = 5 * self.tile_size # 28 * self.tile_size
onready var arena_height = 5 * self.tile_size # 15 * self.tile_size

func _exit_tree():
	self.logger.free()

func init(params):
	params = params.duplicate()
	self.num_rounds = params.rounds
	self.experiment_id = params.experiment_id
	self.run = params.run
	var timeout_time = params.timeout_time
	var characters_info = params.char_infos
	var extra_char_info = {}

	self.logger.push("run_data", ["rounds", self.num_rounds])
	self.logger.push("run_data", ["timeout_time", timeout_time])
	self.logger.push("run_data", ["arena_size", [self.arena_width, self.arena_height]])
	for i in range(len(characters_info)):
		var info = characters_info[i]
		var char_class = global.get_character_class(info.type)
		var character = char_class.instance()

		self.characters.append(character)
		if info.has("name"):
			character.name = info.name
		else:
			character.name = "%s%d" % [info.type, i + 1]
		character.position = self._rand_pos()
		character.connect("character_death", self, "_on_character_death", [character])
		character.add_to_group(info.team)
		info.network_id = "%s_%d" % [character.name, self.run]
		
		self.wall.add_child(character)
		character.init(info)
		
		self.scores[character.name] = 0
		extra_char_info[character.name] = character.get_info()
	
	for ai in self.get_tree().get_nodes_in_group("has_arch"):
		ai.connect("overflow_alert", self, "finish_run", ["Overflow"])

	self.alive_characters = len(self.characters)
	self.logger.push("run_data", ["characters_info", extra_char_info])

	$TimeoutTimer.wait_time = timeout_time
	$TimeoutTimer.start()

func print_info():
#	var loss_info = {}
#	print("------------")
	for character in self.characters:
		var team = global.get_team(character)
		var pretty_name = character.get_full_name()
		print(pretty_name + ": " + str(character.life) + " (" + team + ")")
#		loss_info[pretty_name] = character.controller.get_loss()

func reset_round(timeout):
	self.rounds += 1
	if GameConfig.get_debug_flag("environment"):
		self.print_info()

	$TimeoutTimer.start()
	self.alive_characters = len(self.characters)
	var winner = self._get_last_alive()
	if winner != null and not timeout:
		var winner_name = winner.get_full_name()
		print(self.rounds, ": " + winner_name + " won!")
		self.logger.push("winners", winner.name)
		self.scores[winner.name] += 1
	elif timeout:
		print(self.rounds, ": Timeout!")
		self.logger.push("winners", "timeout")
	
	for character in self.characters:
		character.before_reset(timeout)
	for character in self.characters:
		character.position = self._rand_pos()
		character.reset(timeout)
	for character in self.characters:
		character.after_reset(timeout)
	for character in self.characters:
		character.end()
	if self.rounds == self.num_rounds:
		self.finish_run()

func finish_run(force_finish_message=""):
	if force_finish_message != "":
		print("Forced finish. Cause: ", force_finish_message)
	var params_table = {}
	for ai in get_tree().get_nodes_in_group("produce_analysis"):
		ai.save_analysis(self.experiment_id)
		var params = NNParamsManager.get_params(ai.network_key)
		params_table[ai.parent.parent.name] = params
	self.logger.push("run_data", ["params", params_table])

	var winners = self.logger.get_stored("winners")
	self.logger.push("run_data", ["winners", winners])
	
	var run_file = "%s/RunData_%d" % [self.experiment_id, self.run]
	self.logger.save_to_json("run_data", run_file)
	
	self.emit_signal("finished_test")

func _rand_pos():
	var off = 2 * self.tile_size
	var xPos = off + self.arena_width * randf()
	var yPos = off + self.arena_height * randf()
	return Vector2(xPos, yPos)

func _leader_compare(char1, char2):
	return self.scores[char1.name] < self.scores[char2.name]

func _get_winner():
	var characters = self.characters.duplicate()
	characters.sort_custom(self, "_leader_compare")
	return characters.back()

func _get_last_alive():
	for character in self.characters:
		if not character.is_dead():
			return character
	return null

func _on_character_death(character):
	self.alive_characters -= 1
	if self.alive_characters <= 1:
		self.reset_round(false)

func _on_TimeoutTimer_timeout():
	self.reset_round(true)
