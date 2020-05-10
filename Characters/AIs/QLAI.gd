extends Node

const ActionClass = preload("res://Characters/ActionBase.gd")

var learning_activated
var alpha
var discount
var epsilon
var max_epsilon
var min_epsilon
var epsilon_decay_time
var use_experience_replay
var use_prioritization
var experience_sample_size
var experience_size_limit
var priority_exponent
var weight_exponent
var num_freeze_iter
var think_time
var features_size
var last_state
var last_action
var can_save

var network_key = null
var iter = 0
var time = 0.0

onready var Action = ActionClass.new()
onready var parent = self.get_parent()

func _ready():
	self.add_to_group("has_arch")
	self.parent.logger.push_metadata("analysis", "order",
		["pos_x_diff", "pos_y_diff", "enemy_dist", "self_life",
		 "enemy_life", "enemy_attacking", "enemy_dir_x",
		 "enemy_dir_y", "terminal", "idle_q", "attack_q",
		 "walk_right_q", "walk_up_right_q", "walk_up_q",
		 "walk_up_left_q", "walk_left_q", "walk_down_left_q",
		 "walk_down_q", "walk_down_right_q", "reward",
		 "next_val", "priority", "time", "exp_id", "replay"])

func init(params):
	self.learning_activated = params["learning_activated"]
	self.alpha = params["learning_rate"]
	self.discount = params["discount"]
	self.max_epsilon = params["max_exploration_rate"]
	self.min_epsilon = params["min_exploration_rate"]
	self.epsilon_decay_time = params["exploration_rate_decay_time"]
	self.use_experience_replay = params["experience_replay"]
	self.use_prioritization = params["prioritization"]
	self.experience_sample_size = params["experience_sample_size"]
	self.experience_size_limit = params["experience_size_limit"]
	self.priority_exponent = params["priority_exponent"]
	self.weight_exponent = params["weight_exponent"]
	self.num_freeze_iter = params["num_freeze_iter"]
	self.think_time = params["think_time"]
	self.features_size = params["features_size"]
	self.last_state = params["initial_state"]
	self.last_action = params["initial_action"]
	self.can_save = params["can_save"]
	self.epsilon = self.max_epsilon

func reset(timeout):
	self.last_state = self.parent.get_state()

# Abstract
func end():
	pass

func load_params():
	if self.network_key == null:
		return null
	var data = NNParamsManager.get_params(self.network_key)
	if data == null:
		return null
	return Marshalls.base64_to_variant(data)

func save_params(params):
	if self.network_key == null or not self.can_save:
		return
	var data = Marshalls.variant_to_base64(params)
	NNParamsManager.set_params(self.network_key, data)

func get_loss():
	# return util.py2gdArray(self.logger.get_stored("loss"))
	pass

func get_name():
	return self.parent.name

func get_action():
	return self.last_action

func update_state(state, last=false, timeout=false):
	if self.learning_activated and self.last_state.has_enemy:
		self.time += self.think_time
		var reward = self.parent.get_reward(self.last_state, state, timeout)
		self._update_weights(self.last_state, self.last_action, state, reward, last)
		self.iter = (self.iter + 1) % self.num_freeze_iter
		if self.iter == 0 and self._is_freezing_weights():
			self._freeze_weights()

	self.last_action = Action.compose(Action.IDLE, self.last_action)
	if state.has_enemy:
		self.last_action = self._compute_action_from_q_values(state)
	self.last_state = state
	
	self._update_epsilon()

# Abstract
func _compute_action_from_q_values(state):
	pass

# Abstract
func _freeze_weights():
	pass

# Abstract
func _update_weights(actual_state, action, next_state, reward, last):
	pass

func _get_features_after_action(state, action):
	return self.parent.get_features_after_action(state, action)

func _get_features(state):
	return self.parent.get_features(state)

func _is_freezing_weights():
	return self.num_freeze_iter > 1

func _update_epsilon():
	if self.epsilon_decay_time == 0.0:
		self.epsilon = self.min_epsilon
	else:
		var factor = min(self.time, self.epsilon_decay_time) / self.epsilon_decay_time
		self.epsilon = factor * self.min_epsilon + (1.0 - factor) * self.max_epsilon

# Print some variables for debug here
func _on_DebugTimer_timeout():
	pass
