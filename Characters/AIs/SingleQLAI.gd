extends "res://Characters/AIs/QLAI.gd"

# Features -> Array
# Reward   -> float
# State    -> Dict
# Action   -> int
# Model    -> NeuralNetwork1D

const Experience = preload("res://Characters/AIs/Experience.gd")
const NeuralNetwork = preload("res://Characters/AIs/SingleNN.tscn")

var ep
var learning_model
var freezed_model

# Dict -> void
func init(params):
	.init(params)
	self.ep = Experience.new(self.experience_pool_size)
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
func get_info():
	return []

# bool -> void
func reset(timeout):
	.reset(timeout)
	if self.use_experience_replay and self.learning_activated:
		var exp_sample = self.ep.sample()
		self._update_weights_experience(exp_sample[0], exp_sample[1], exp_sample[2])

func _init_model(model):
	model.learning_rate = self.alpha
	model.input_size = self.features_size

# State, Action, Model -> float
func _get_q_value(state, action, model):
	var features = self._get_features_after_action(state, action)
	return model.predict_one(features)[0]

# State -> float
func _compute_value_from_q_values(state):
	if state == null:
		return 0.0
	var legal_actions = self.parent.get_legal_actions(state)
	var q_values_list = []
	var model = self.freezed_model
	if not self._is_freezing_weights():
		model = self.learning_model
	for a in legal_actions:
		q_values_list.append(self._get_q_value(state, a, model))
	return global.max(q_values_list)

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

# State, Action, State, Reward, bool -> void
func _update_weights(state, action, next_state, reward, last):
	var features = self._get_features(next_state)
	self.ep.push(features, reward, next_state)

	var exp_sample = self.ep.simple_sample()
	self._update_weights_experience(exp_sample[0], exp_sample[1], exp_sample[2])

# Array[Features], Array[Reward], Array[State] -> void
func _update_weights_experience(feat_sample, reward_sample, next_sample):
	var label_vec = []

	for i in range(feat_sample.size()):
		var next_val = self._compute_value_from_q_values(next_sample[i])
		var label = [reward_sample[i] + self.discount * next_val]
		label_vec.append(label)
	
	self.learning_model.train(feat_sample, label_vec)

# Print some variables for debug here
func _on_DebugTimer_timeout():
	print("------ SingleQLAI ------")
	._on_DebugTimer_timeout()
