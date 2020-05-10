extends "res://Characters/AIs/QLAI.gd"

# Features -> Array
# Reward   -> float
# State    -> Dict
# Action   -> int
# Model    -> NeuralNetwork1D

const Feature = preload("res://Characters/AIs/AIEnums.gd").QLFeature
const Experience = preload("res://Characters/AIs/Experience.gd")
const NeuralNetwork = preload("res://Characters/AIs/SingleNN.tscn")

var ep
var learning_model
var freezed_model

func _ready():
	self.add_to_group("produce_analysis")

# Dict -> void
func init(params):
	.init(params)
	self.ep = Experience.new(self.experience_sample_size,
							 self.weight_exponent,
							 self.experience_size_limit)
	if params.has("network_id") and params.network_id != null:
		var character_type = params.character_type
		var network_id = params.network_id
		self.network_key = character_type + "_SingleQLAI_" + str(network_id)

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
func save_analysis():
	self.parent.logger.save_to_csv("analysis", self.network_key)

# -> void
func get_info():
	return []

# bool -> void
func reset(timeout):
	.reset(timeout)
	if self.use_experience_replay and self.learning_activated:
		var exp_sample = self.ep.sample()
		self._update_weights_experience(exp_sample[1], exp_sample[2],
										exp_sample[3], exp_sample[0],
										exp_sample[5])

# NeuralNetwork -> void
func _init_model(model):
	model.learning_rate = self.alpha
	model.input_size = self.features_size

# State, Action, Model -> float
func _get_q_value(state, action, model):
	var features = self._get_features_after_action(state, action)
	return model.predict_one(features)[0]

# State -> Array{ Array[float], float }
func _compute_value_from_q_values(next_state):
	if next_state == null:
		# next_state is terminal
		return 0.0
	var legal_actions = self.parent.get_legal_actions(next_state)
	var q_values = []
	for a in legal_actions:
		q_values.append(self._get_q_value(next_state, a, self.learning_model))
	if not self._is_freezing_weights():
		return global.max(q_values)
	var max_action = legal_actions[global.argmax(q_values)]
	return self._get_q_value(next_state, max_action, self.freezed_model)

# State -> Action
func _compute_action_from_q_values(state):
	var legal_actions = self.parent.get_legal_actions(state)
	if randf() < self.epsilon:
		return global.choose_one(legal_actions)
	var q_values_list = []
	for a in legal_actions:
		var q_value = self._get_q_value(state, a, self.learning_model)
		q_values_list.append(q_value)
	return legal_actions[global.argmax(q_values_list)]

# -> void
func _freeze_weights():
	self.freezed_model.load(self.learning_model.save())

func _get_priority(q_val, label):
	var td_error = abs(label - q_val) + global.EPS
	return pow(td_error, self.priority_exponent)

# State, Action, State, Reward, bool -> void
func _update_weights(state, action, next_state, reward, last):
	var features = self._get_features(state)
	if last:
		next_state = null
	var exp_id = self.ep.push(features, reward, next_state)

	var next_val = self._compute_value_from_q_values(next_state)
	var label = reward + self.discount * next_val
	var q_val = self.learning_model.predict_one(features)[0]
	var priority = self._get_priority(q_val, label)
	self._create_csv_entry(features, q_val, reward, next_state, next_val,
						   priority, exp_id, false)

# Array[Features], Array[Reward], Array[State], Array[int] -> void
func _update_weights_experience(feat_sample, reward_sample, next_sample, pos_list, exp_ids=null):
	var label_vec = []
	var priorities = []

	for i in range(feat_sample.size()):
		var next_val = self._compute_value_from_q_values(next_sample[i])
		var label = reward_sample[i] + self.discount * next_val
		var q_val = self.learning_model.predict_one(feat_sample[i])[0]
		var priority = self._get_priority(q_val, label)
		priorities.append(priority)
		label_vec.append([label])
		var exp_id = 0
		if exp_ids != null:
			exp_id = exp_ids[i]
		self._create_csv_entry(feat_sample[i], q_val, reward_sample[i],
							   next_sample[i], next_val, priority, exp_id, true)
	
	var weights = []
	if self.use_prioritization:
		weights = self.ep.update(pos_list, priorities)
	self.learning_model.train(feat_sample, label_vec, -1, 1, weights)

func _create_csv_entry(feat, q_val, reward, next_state, next_val, priority, exp_id, replay):
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
		"epsilon": self.epsilon,
		"experience_size": self.ep.get_size(),
		"time": self.time,
		"exp_id": exp_id,
		"replay": replay
	}
	if next_state != null:
		entry["terminal"] = false
		entry["idle_q"] = self._get_q_value(next_state, Action.IDLE, self.learning_model)
		entry["attack_q"] = self._get_q_value(next_state, Action.ATTACK, self.learning_model)
		entry["walk_right_q"] = self._get_q_value(next_state, Action.compose(Action.WALK, Action.RIGHT), self.learning_model)
		entry["walk_up_right_q"] = self._get_q_value(next_state, Action.compose(Action.WALK, Action.UP_RIGHT), self.learning_model)
		entry["walk_up_q"] = self._get_q_value(next_state, Action.compose(Action.WALK, Action.UP), self.learning_model)
		entry["walk_up_left_q"] = self._get_q_value(next_state, Action.compose(Action.WALK, Action.UP_LEFT), self.learning_model)
		entry["walk_left_q"] = self._get_q_value(next_state, Action.compose(Action.WALK, Action.LEFT), self.learning_model)
		entry["walk_down_left_q"] = self._get_q_value(next_state, Action.compose(Action.WALK, Action.DOWN_LEFT), self.learning_model)
		entry["walk_down_q"] = self._get_q_value(next_state, Action.compose(Action.WALK, Action.DOWN), self.learning_model)
		entry["walk_down_right_q"] = self._get_q_value(next_state, Action.compose(Action.WALK, Action.DOWN_RIGHT), self.learning_model)
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
