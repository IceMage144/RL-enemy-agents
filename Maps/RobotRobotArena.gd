extends Node

const ActionClass = preload("res://Characters/ActionBase.gd")
const Logger = preload("res://Structures/Logger.gd")

const Arena = preload("res://Maps/TestArena.tscn")

const CONFIG_PATH = "res://assets/data/arena_config.json"
const DATA_PATH = "res://assets/scripts/data"

var train_config
var test_configs
var fingerprint_config
var num_runs
var experiment_id

var arena = null
var run = 1
var test = 1

onready var Action = ActionClass.new()
onready var logger = Logger.new()

func init(params):
	var config_file = File.new()
	var config = global.read_json(CONFIG_PATH)
	config = global.to_int_rec(config)

	self.experiment_id = self._find_unused_dir_name(config.experiment_id)
	self.num_runs = config.runs
	var num_chars = config.ais_config.size()
	for k in range(config.ais_config.size()):
		var ai_config = config.ais_config[k]
		ai_config.name = "%s%d" % [ai_config.type, k + 1]

	var train_chars = config.train_config.enemies_list
	var train_enemy_id = num_chars
	for enemy in train_chars:
		enemy.name = "%s%d" % [enemy.type, train_enemy_id + 1]
		train_enemy_id += 1
	for ai_config in global.deep_copy(config.ais_config):
		train_chars.append(ai_config)
	self.train_config = {
		"experiment_id": self.experiment_id,
		"save_file": config.save_file,
		"rounds": config.train_config.rounds,
		"timeout_time": config.train_config.timeout_time,
		"arena_size": config.train_config.arena_size,
		"char_infos": train_chars
	}

	self.test_configs = []
	for test in config.test_configs:
		var enemies_list = test.enemies_list
		var test_enemy_id = num_chars
		for enemy in enemies_list:
			enemy.name = "%s%d" % [enemy.type, test_enemy_id + 1]
			test_enemy_id += 1
		for ai_config in global.deep_copy(config.ais_config):
			var test_chars = global.deep_copy(enemies_list)
			ai_config.learning_activated = false
			ai_config.exploration_rate_decay_time = 0.0
			test_chars.append(ai_config)
			var test_config = {
				"experiment_id": self.experiment_id,
				"save_file": config.save_file,
				"rounds": test.rounds,
				"timeout_time": test.timeout_time,
				"arena_size": test.arena_size,
				"char_infos": test_chars
			}
			self.test_configs.append(test_config)

	self.fingerprint_config = global.deep_copy(config.ais_config)
	for ai_config in self.fingerprint_config:
		ai_config.learning_activated = false
		ai_config.min_exploration_rate = 0.0
		ai_config.max_exploration_rate = 0.0
		ai_config.exploration_rate_decay_time = 0.0
		ai_config.think_time = 0.0

	SaveManager.change_save_file(config.save_file)
	NNParamsManager.clear_models()

	print("Beginning experiment '%s'" % self.experiment_id)

	self.init_run()

func init_run():
	print("====================== Run %s ======================" % self.run)
	self.train_config["run"] = self.run

	self.arena = Arena.instance()
	self.add_child(self.arena)
	self.arena.init(self.train_config)
	self.arena.connect("finished_test", self, "finish_run")

func finish_run():
	self.arena.queue_free()
	yield(self.arena, "tree_exited")
	yield(self.get_tree(), "idle_frame")
	yield(self.get_tree(), "idle_frame")

	self.init_test()

func init_test():
	print("================== Run %s Test %d ==================" % [self.run, self.test])

	var test_config = self.test_configs[self.test - 1]
	test_config["run"] = self.run

	self.arena = Arena.instance()
	self.add_child(self.arena)
	self.arena.init(test_config)
	self.arena.connect("finished_test", self, "finish_test")

func finish_test():
	self.arena.queue_free()
	yield(self.arena, "tree_exited")
	yield(self.get_tree(), "idle_frame")
	yield(self.get_tree(), "idle_frame")

	self.test += 1
	if self.test <= self.test_configs.size():
		self.init_test()
	else:
		self.test = 1
		self.generate_fingerprints()

func generate_fingerprints():
	var characters_info = self.fingerprint_config

	for k in range(characters_info.size()):
		var fingerprint = []
		var info = characters_info[k].duplicate()
		var char_class = global.get_character_class(info.type)
		var character = char_class.instance()

		if info.has("name"):
			character.name = info.name
		else:
			character.name = "%s%d" % [info.type, k + 1]
		info.network_id = "%s_%d" % [character.name, self.run]
		
		self.add_child(character)
		character.init(info)
		
		var char_ai = character.get_node("Controller/AI")
		if char_ai.is_in_group("has_arch"):
			var state = self._get_state(character)
			for i in range(-9 * 16, 9 * 16 + 1, 32):
				var row = []
				for j in range(-9 * 16, 9 * 16 + 1, 32):
					var pos = Vector2(i, j)
					state["enemy_pos"] = pos
					var action = char_ai._compute_action_from_q_values(state)
					row.append(Action.to_string(action))
				fingerprint.append(row)
			self.logger.push("fingerprints", [character.name, fingerprint])

		character.queue_free()
		yield(character, "tree_exited")
		yield(self.get_tree(), "idle_frame")
		yield(self.get_tree(), "idle_frame")

	var file_name = "%s/Fingerprints_%d" % [self.experiment_id, self.run]
	self.logger.save_to_json("fingerprints", file_name)

	self.run += 1
	if self.run <= self.num_runs:
		self.init_run()
	else:
		self.get_tree().quit()

func _find_unused_dir_name(dir_name):
	var dir = Directory.new()
	dir.change_dir(DATA_PATH)
	if dir.dir_exists(dir_name):
		var idx = 0
		var new_dir_name = dir_name
		while dir.dir_exists(new_dir_name):
			idx += 1
			new_dir_name = "%s(%d)" % [dir_name, idx]
		dir_name = new_dir_name
	dir.make_dir(dir_name)
	return dir_name

func _get_state(character):
	var max_life = character.get_max_life()
	var damage = character.get_damage()
	var defense = character.get_defense()
	return {
		"self_pos": character.position,
		"self_life": max_life,
		"self_maxlife": max_life,
		"self_damage": damage,
		"self_defense": defense,
		"self_act": Action.IDLE,
		"enemy_pos": Vector2(),
		"enemy_life": max_life,
		"enemy_maxlife": max_life,
		"enemy_damage": damage,
		"enemy_defense": defense,
		"enemy_act": Action.IDLE
	}