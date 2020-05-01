extends "res://Characters/AIs/QLAI.gd"

# Features -> Array
# Reward   -> float
# State    -> Dict
# Action   -> int
# Model    -> NeuralNetwork1D

var Action = preload("res://Characters/ActionBase.gd").new()
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
	for i in range(AVAILABLE_ACTIONS.size()):
		self.action_to_id[AVAILABLE_ACTIONS[i]] = i
		self.id_to_action[i] = AVAILABLE_ACTIONS[i]

# Dict -> void
func init(params):
	.init(params)
	self.ep = Experience.new(self.experience_sample_size, self.weight_exponent)
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
func get_info():
	return []

# bool -> void
func reset(timeout):
	.reset(timeout)
	if self.use_experience_replay and self.learning_activated:
		var exp_sample = self.ep.sample(self.use_prioritization)
		self._update_weights_experience(exp_sample[1], exp_sample[2], exp_sample[3], exp_sample[4], exp_sample[0])

func _init_model(model):
	model.learning_rate = self.alpha
	model.input_size = self.features_size
	model.get_node("FullyConnected2").size = self.action_to_id.size()

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
	if randf() < self.epsilon:
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
func _update_weights(state, action, next_state, reward, last):
	var features = self._get_features(state)
	var action_id = self.action_to_id[action]
	self.ep.push(features, reward, next_state, action_id)

# Array[Features], Array[Reward], Array[State], Array[Action], Array[int] -> void
func _update_weights_experience(feat_sample, reward_sample, next_sample, action_sample, pos_list):
	var label_vec = []
	var priorities = []

	for i in range(feat_sample.size()):
		var action = action_sample[i]
		var next_val = self._compute_value_from_q_values(next_sample[i])
		var label = reward_sample[i] + self.discount * next_val
		var q_values = self.learning_model.predict_one(feat_sample[i])
		var priority = self._get_priority(q_values[action], label)
		q_values[action] = label
		priorities.append(priority)
		label_vec.append(q_values)

	var weights = []
	if self.use_prioritization:
		weights = self.ep.update(pos_list, priorities)
	self.learning_model.train(feat_sample, label_vec, -1, 1, weights)

# Print some variables for debug here
func _on_DebugTimer_timeout():
	._on_DebugTimer_timeout()
