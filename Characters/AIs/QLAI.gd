extends Node

signal overflow_alert

const ActionClass = preload("res://Characters/ActionBase.gd")

var learning_activated
var alpha                    # learning rate
var discount                 # reward discount over time
var epsilon                  # exploration rate
var idle_rate                # forced idle action execution rate
var use_experience_replay
var use_prioritization
var experience_sample_size
var experience_size_limit
var priority_exponent        # prioritized replay priority exponent
var weight_exponent          # prioritized replay weight negative exponent
var num_freeze_iter          # number of iterations before freezing target function weights
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
		["exp_id", "time", "pos_x_diff", "pos_y_diff", "enemy_dist",
		 "self_life", "enemy_life", "enemy_attacking", "enemy_dir_x",
		 "enemy_dir_y", "terminal", "idle_q", "attack_q",
		 "walk_right_q", "walk_up_right_q", "walk_up_q",
		 "walk_up_left_q", "walk_left_q", "walk_down_left_q",
		 "walk_down_q", "walk_down_right_q", "reward",
		 "next_val", "priority", "purpuse", "idle_rate",
		 "exploration_rate", "learning_rate"])

func _process(delta):
	self.time += delta

func init(params):
	self.learning_activated = params.learning_activated
	self.discount = params.discount
	self.use_experience_replay = params.experience_replay
	self.use_prioritization = params.prioritization
	self.experience_sample_size = params.experience_sample_size
	self.experience_size_limit = params.experience_size_limit
	self.priority_exponent = params.priority_exponent
	self.weight_exponent = params.weight_exponent
	self.num_freeze_iter = params.num_freeze_iter
	self.features_size = params.features_size
	self.last_state = params.initial_state
	self.last_action = params.initial_action
	self.can_save = params.can_save

	var interp_class = load(params.idle_interpolator)
	self.idle_rate = interp_class.new({
		"beg_val": params.max_idle_rate,
		"end_val": params.min_idle_rate,
		"end_time": params.idle_rate_decay_time
	})

	interp_class = load(params.exploration_interpolator)
	self.epsilon = interp_class.new({
		"beg_val": params.max_exploration_rate,
		"end_val": params.min_exploration_rate,
		"beg_time": params.idle_rate_decay_time,
		"end_time": params.idle_rate_decay_time + params.exploration_rate_decay_time
	})

	interp_class = load(params.learning_interpolator)
	self.alpha = interp_class.new({
		"beg_val": params.max_learning_rate,
		"end_val": params.min_learning_rate,
		"beg_time": params.idle_rate_decay_time,
		"end_time": params.idle_rate_decay_time + params.learning_rate_decay_time
	})

	if self.learning_activated:
		$LearnTimer.connect("timeout", self, "_on_LearnTimer_timeout")
		$LearnTimer.wait_time = params.learn_time
		$LearnTimer.start()

func reset(timeout):
	self.epsilon.reset()
	self.alpha.reset()
	self.idle_rate.reset()
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

func get_epsilon():
	return self.epsilon.get(self.time)

func get_alpha():
	return self.alpha.get(self.time)

func get_idle_rate():
	return self.idle_rate.get(self.time)

func update_state_action(state, last=false, timeout=false):
	if self.learning_activated and self.last_state.has_enemy:
		var reward = self.parent.get_reward(self.last_state, state, timeout)
		self._update_state(self.last_state, self.last_action, state, reward, last)

	self.last_action = Action.compose(Action.IDLE, self.last_action)
	if state.has_enemy:
		self.last_action = self._compute_action_from_q_values(state)
	self.last_state = state

# Abstract
func get_features_names():
	pass

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

func _on_LearnTimer_timeout():
	if self.parent.can_think() and self.learning_activated and self.last_state.has_enemy:
		var ts = OS.get_ticks_msec()

		self._update_weights()
		self.iter = (self.iter + 1) % self.num_freeze_iter
		if self.iter == 0 and self._is_freezing_weights():
			self._freeze_weights()

		var te = OS.get_ticks_msec()
		self.parent.logger.push("update_state", te - ts)

# Print some variables for debug here
func _on_DebugTimer_timeout():
	var stats = ["max", "min", "avg"]
	self.parent.logger.print_stats("update_state", stats)
	self.parent.logger.flush("update_state")
