extends "res://Characters/AIs/QLAI.gd"

# Features -> Array
# Reward   -> float
# State    -> Dict
# Action   -> int
# Model    -> NeuralNetwork1D

const Feature = preload("res://Characters/AIs/AIEnums.gd").QLFeature
const Experience = preload("res://Characters/AIs/Experience.gd")
const NeuralNetwork = preload("res://Characters/AIs/MultiNN.tscn")

var ep
var learning_model
var freezed_model

var action_to_id = {}
var id_to_action = {}

onready var AVAILABLE_ACTIONS = [
	Action.from_string("idle"),
	Action.from_string("attack"),
	Action.from_string("walk_right"),
	Action.from_string("walk_up_right"),
	Action.from_string("walk_up"),
	Action.from_string("walk_up_left"),
	Action.from_string("walk_left"),
	Action.from_string("walk_down_left"),
	Action.from_string("walk_down"),
	Action.from_string("walk_down_right")
]

func _ready():
	self.add_to_group("produce_analysis")
	for i in range(AVAILABLE_ACTIONS.size()):
		self.action_to_id[AVAILABLE_ACTIONS[i]] = i
		self.id_to_action[i] = AVAILABLE_ACTIONS[i]

func _exit_tree():
	self.ep.free()

# Dict -> void
func init(params):
	.init(params)
	self.ep = Experience.new(self.experience_sample_size,
							 self.weight_exponent,
							 self.experience_size_limit)
	if params.has("network_id") and params.network_id != null:
		var character_type = params.character_type
		var network_id = params.network_id
		self.network_key = character_type + "_MultiQLAI_" + str(network_id)

	self.learning_model = NeuralNetwork.instance()
	self._init_model(self.learning_model)
	self.add_child(self.learning_model)

	self.freezed_model = NeuralNetwork.instance()
	self._init_model(self.freezed_model)
	self.add_child(self.freezed_model)

	var persisted_params = self.load_params()
	if persisted_params != null:
		self.learning_model.load(persisted_params.model)
		self.time = persisted_params.time
	self._freeze_weights()

# -> void
func end():
	self.save_params({
		"model": self.learning_model.save(),
		"time": self.time
	})

# -> void
func save_analysis(dir_base):
	var file_path = "%s/%s" % [dir_base, self.network_key]
	self.parent.logger.save_to_csv("analysis", file_path)

# bool -> void
func reset(timeout):
	.reset(timeout)
	if self.use_experience_replay and self.learning_activated:
		var exp_sample = self.ep.sample(200)
		var pos_list = exp_sample[0]
		var feat_sample = exp_sample[1]
		var reward_sample = exp_sample[2]
		var next_sample = exp_sample[3]
		var action_sample = exp_sample[4]
		var exp_ids = exp_sample[5]
		for i in range(feat_sample.size()):
			var next_val = self._compute_value_from_q_values(next_sample[i])
			var label = reward_sample[i] + self.discount * next_val
			var action_id = action_sample[i]
			var q_val = self.learning_model.predict_one(feat_sample[i])[action_id]
			var priority = self._get_priority(q_val, label)
			var exp_id = 0
			if exp_ids != null:
				exp_id = exp_ids[i]
			self._create_csv_entry(feat_sample[i], q_val, reward_sample[i],
								   next_sample[i], next_val, priority, exp_id, "test")
		# self._update_weights_experience(exp_sample[1], exp_sample[2],
		# 								exp_sample[3], exp_sample[4],
		# 								exp_sample[0], exp_sample[5])

# -> Array[String]
func get_features_names():
	return Feature.keys()

# NeuralNetwork -> void
func _init_model(model):
	model.input_size = self.features_size
	var output_layer = model.get_children().back()
	output_layer.size = self.action_to_id.size()

# State, Array[Action], Model -> Array[float]
func _get_q_values(state, action_list, model):
	var features = self._get_features(state)
	var output = model.predict_one(features)
	var q_values = []
	for action in action_list:
		q_values.append(output[self.action_to_id[action]])
	return q_values

# State -> float
func _compute_value_from_q_values(state):
	if state == null:
		# next_state is terminal
		return 0.0
	var legal_actions = self.parent.get_legal_actions(state)
	var q_values = self._get_q_values(state, legal_actions, self.learning_model)
	if not self._is_freezing_weights():
		return global.max(q_values)
	var max_action = legal_actions[global.argmax(q_values)]
	return self._get_q_values(state, [max_action], self.freezed_model)[0]

# State -> Action
func _compute_action_from_q_values(state):
	var legal_actions = self.parent.get_legal_actions(state)
	if randf() < self.get_epsilon():
		return global.choose_one(legal_actions)
	var prediction = self._get_q_values(state, legal_actions, self.learning_model)
	return legal_actions[global.argmax(prediction)]

# -> void
func _freeze_weights():
	self.freezed_model.load(self.learning_model.save())

func _get_priority(q_val, label):
	var td_error = abs(label - q_val) + global.EPS
	return pow(td_error, self.priority_exponent)
	
# State, Action, State, Reward, bool -> void
func _update_state(state, action, next_state, reward, last):
	var features = self._get_features(state)
	var action_id = self.action_to_id[action]
	if last:
		next_state = null
	var exp_id = self.ep.push(features, reward, next_state, action_id)

	var next_val = self._compute_value_from_q_values(next_state)
	var label = reward + self.discount * next_val
	var q_val = self.learning_model.predict_one(features)[action_id]
	var priority = self._get_priority(q_val, label)
	self._create_csv_entry(features, q_val, reward, next_state,
						   next_val, priority, exp_id, "update")

# -> void
func _update_weights():
	var exp_sample
	if self.use_experience_replay:
		exp_sample = self.ep.sample()
	else:
		exp_sample = self.ep.get_last()
	self._update_weights_experience(exp_sample[1], exp_sample[2],
									exp_sample[3], exp_sample[4],
									exp_sample[0], exp_sample[5],
									"replay")

# Array[Features], Array[Reward], Array[State], Array[Action], Array[int], Array[int], String -> void
func _update_weights_experience(feat_sample, reward_sample, next_sample, action_sample, pos_list, exp_ids=null, purpuse="update"):
	var label_vec = []
	var priorities = []

	for i in range(feat_sample.size()):
		var action_id = action_sample[i]
		var next_val = self._compute_value_from_q_values(next_sample[i])
		var label = reward_sample[i] + self.discount * next_val
		var q_vals = self.learning_model.predict_one(feat_sample[i])
		var q_val = q_vals[action_id]
		var priority = self._get_priority(q_val, label)
		q_vals[action_id] = label
		priorities.append(priority)
		label_vec.append(q_vals)
		var exp_id = 0
		if exp_ids != null:
			exp_id = exp_ids[i]
		self._create_csv_entry(feat_sample[i], q_val, reward_sample[i],
							   next_sample[i], next_val, priority, exp_id,
							   purpuse)

	var weights = []
	if self.use_prioritization and pos_list.size() != 0:
		weights = self.ep.update(pos_list, priorities)
	self.learning_model.learning_rate = self.get_alpha()
	self.learning_model.train(feat_sample, label_vec, -1, 1, weights)

func _create_csv_entry(feat, q_val, reward, next_state, next_val, priority, exp_id, purpuse):
	var entry = {
		"pos_x_diff": feat[Feature.POS_X_DIFF],
		"pos_y_diff": feat[Feature.POS_Y_DIFF],
		"enemy_dist": feat[Feature.ENEMY_DIST],
		"self_life": feat[Feature.SELF_LIFE],
		"enemy_life": feat[Feature.ENEMY_LIFE],
		"enemy_attacking": feat[Feature.ENEMY_ATTACKING],
		"enemy_dir_x": feat[Feature.ENEMY_DIR_X],
		"enemy_dir_y": feat[Feature.ENEMY_DIR_Y],
		"q_val": q_val,
		"reward": reward,
		"next_val": next_val,
		"priority": priority,
		"exploration_rate": self.get_epsilon(),
		"learning_rate": self.get_alpha(),
		"experience_size": self.ep.get_size(),
		"time": self.time,
		"exp_id": exp_id,
		"purpuse": purpuse
	}
	if next_state != null:
		var q_values = self._get_q_values(next_state, AVAILABLE_ACTIONS, self.learning_model)
		entry["terminal"] = false
		entry["idle_q"] = q_values[0]
		entry["attack_q"] = q_values[1]
		entry["walk_right_q"] = q_values[2]
		entry["walk_up_right_q"] = q_values[3]
		entry["walk_up_q"] = q_values[4]
		entry["walk_up_left_q"] = q_values[5]
		entry["walk_left_q"] = q_values[6]
		entry["walk_down_left_q"] = q_values[7]
		entry["walk_down_q"] = q_values[8]
		entry["walk_down_right_q"] = q_values[9]
	else:
		entry["terminal"] = true
		entry["idle_q"] = 0.0
		entry["attack_q"] = 0.0
		entry["walk_right_q"] = 0.0
		entry["walk_up_right_q"] = 0.0
		entry["walk_up_q"] = 0.0
		entry["walk_up_left_q"] = 0.0
		entry["walk_left_q"] = 0.0
		entry["walk_down_left_q"] = 0.0
		entry["walk_down_q"] = 0.0
		entry["walk_down_right_q"] = 0.0
	self.parent.logger.push("analysis", entry)

# Print some variables for debug here
func _on_DebugTimer_timeout():
	._on_DebugTimer_timeout()
