extends Node2D

const Logger = preload("res://Structures/Logger.gd")

const CONFIG_PATH = "res://assets/data/arena_config.json"

export(bool) var use_config = false
export(int) var num_rounds = 40
export(int) var num_runs = 10
export(float) var timeout_time = 20

var alive_characters
var char_infos

var experiment_id = "NoNameExperiment"
var tile_size = 32
var run = 1
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
	if params != null and params.has("num_rounds"):
		self.num_rounds = params["num_rounds"]
	var config_file = File.new()
	var display_characters = self.get_tree().get_nodes_in_group("character")
	if self.use_config and config_file.file_exists(CONFIG_PATH):
		var config = global.read_json(CONFIG_PATH)
		config = global.to_int_rec(config)
		self.num_rounds = config.rounds
		self.num_runs = config.runs
		self.char_infos = config.char_infos
		self.timeout_time = config.timeout_time
		self.experiment_id = config.experiment_id
		SaveManager.change_save_file(config.save_file)
	else:
		self.char_infos = []
		for character in display_characters:
			var char_info = character.get_info()
			self.char_infos.append(char_info)
	self.experiment_id = self._find_unused_dir_name(self.experiment_id)

	for character in display_characters:
		character.queue_free()
		yield(character, "tree_exited")
		yield(self.get_tree(), "idle_frame")
	
	$TimeoutTimer.wait_time = self.timeout_time
	$TimeoutTimer.start()

	NNParamsManager.clear_models()

	self.init_run()

func init_run():
	print("====================== Run %s ======================" % self.run)
	self.rounds = 0
	self.scores = {}
	var characters_info = {}
	self.characters = []
	self.logger.push("run_data", ["rounds", self.num_rounds])
	self.logger.push("run_data", ["timeout_time", self.timeout_time])
	self.logger.push("run_data", ["arena_size", [self.arena_width, self.arena_height]])
	for i in range(len(self.char_infos)):
		var info = self.char_infos[i].duplicate()
		var char_class = global.get_character_class(info.type)
		var character = char_class.instance()

		self.characters.append(character)
		character.name = "%s%d" % [info.type, i + 1]
		character.position = self._rand_pos()
		character.connect("character_death", self, "_on_character_death", [character])
		character.add_to_group(info.team)
		info.network_id = "%s_%d" % [character.name, self.run]
		
		self.wall.add_child(character)
		character.init(info)
		
		self.scores[character.name] = 0
		characters_info[character.name] = character.get_info()

	self.alive_characters = len(self.characters)
	self.logger.push("run_data", ["characters_info", characters_info])

func print_info():
	var loss_info = {}
	print("------------")
	for character in self.characters:
		var team = global.get_team(character)
		var pretty_name = character.get_full_name()
		print(pretty_name + ": " + str(character.life) + " (" + team + ")")
		loss_info[pretty_name] = character.controller.get_loss()

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

func finish_run():
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
	
	for character in self.characters:
		character.queue_free()
		yield(character, "tree_exited")
		yield(self.get_tree(), "idle_frame")

	self.logger.flush("run_data")
	self.logger.flush("winners")

	self.run += 1
	if self.run <= self.num_runs:
		self.init_run()
	else:
		self.get_tree().quit()

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

func _find_unused_dir_name(dir_name):
	var dir = Directory.new()
	dir.change_dir("res://assets/scripts/data")
	if dir.dir_exists(dir_name):
		var idx = 0
		var new_dir_name = dir_name
		while dir.dir_exists(new_dir_name):
			idx += 1
			new_dir_name = "%s(%d)" % [dir_name, idx]
		dir_name = new_dir_name
	dir.make_dir(dir_name)
	return dir_name

func _on_character_death(character):
	self.alive_characters -= 1
	if self.alive_characters <= 1:
		self.reset_round(false)

func _on_TimeoutTimer_timeout():
	self.reset_round(true)
