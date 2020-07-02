extends Node

const AINode = preload("res://Characters/AIs/AI.tscn")
const ActionClass = preload("res://Characters/ActionBase.gd")
const Logger = preload("res://Structures/Logger.gd")

const AIEnums = preload("res://Characters/AIs/AIEnums.gd")
const AIType = AIEnums.AIType
const Feature = AIEnums.QLFeature
const Reward = AIEnums.Reward

const ai_path = {
	AIType.PERCEPTRON_QL: "res://Characters/AIs/PerceptronQLAI.gd",
	AIType.SINGLE_QL: "res://Characters/AIs/SingleQLAI.gd",
	AIType.MEMORY_QL: "res://Characters/AIs/MemoryQLAI.gd",
	AIType.MULTI_QL: "res://Characters/AIs/MultiQLAI.gd",
	AIType.BASIC_BT: "res://Characters/AIs/BasicBTAI.gd",
	AIType.IDLE_BT: "res://Characters/AIs/IdleBTAI.gd"
}

var ai
var parent
var reward_func

var velocity = Vector2()

onready var Action = ActionClass.new()
onready var logger = Logger.new()

func _is_aligned(act, vec):
	# TODO: Move this function to another place
	var dir = Action.get_direction(act)
	if vec.x < vec.y:
		if -vec.x < vec.y:
			return dir == Action.DOWN
		return dir == Action.LEFT
	if -vec.x > vec.y:
		return dir == Action.UP
	return dir == Action.RIGHT

func _ready():
	self.parent = self.get_parent()
	if GameConfig.get_debug_flag("character"):
		$DebugTimer.start()

func _exit_tree():
	self.logger.free()
	Action.free()

func init(params):
	self.reward_func = params.reward_func
	self.ai = AINode.instance()
	var ai_type = params.ai_type
	self.ai.set_script(load(ai_path[ai_type]))
	self.add_child(self.ai)
	var initial_state = self.get_state()
	self.ai.init({
		"learning_activated": params.learning_activated,
		"learning_rate": params.learning_rate,
		"learning_rate_decay_exponent": params.learning_rate_decay_exponent,
		"discount": params.discount,
		"max_exploration_rate": params.max_exploration_rate,
		"min_exploration_rate": params.min_exploration_rate,
		"exploration_rate_decay_time": params.exploration_rate_decay_time,
		"idle_time": params.idle_time,
		"experience_replay": params.experience_replay,
		"prioritization": params.prioritization,
		"experience_sample_size": params.experience_sample_size,
		"experience_size_limit": params.experience_size_limit,
		"priority_exponent": params.priority_exponent,
		"weight_exponent": params.weight_exponent,
		"num_freeze_iter": params.num_freeze_iter,
		"learn_time": params.learn_time,
		"features_size": Feature.FEATURES_SIZE,
		"initial_state": initial_state,
		"initial_action": Action.IDLE,
		"character_type": params.character_type,
		"network_id": params.network_id,
		"can_save": params.can_save
	})
	if params.think_time != 0.0:
		$ThinkTimer.wait_time = params.think_time
		$ThinkTimer.start()

func end():
	self.ai.end()

func get_loss():
	return self.ai.get_loss()

func get_state():
	var enemy_pos = Vector2()
	var enemy_life = 0
	var enemy_maxlife = 1
	var enemy_damage = 0
	var enemy_defense = 0
	var enemy_act = Action.IDLE
	var enemy = global.get_enemy(self.parent)
	var has_enemy = enemy != null
	if has_enemy:
		enemy_pos = enemy.position
		enemy_life = enemy.life
		enemy_maxlife = enemy.get_max_life()
		enemy_damage = enemy.get_damage()
		enemy_defense = enemy.get_defense()
		enemy_act = enemy.action
	return {
		"self_pos": self.parent.position,
		"self_life": self.parent.life,
		"self_maxlife": self.parent.get_max_life(),
		"self_damage": self.parent.get_damage(),
		"self_defense": self.parent.get_defense(),
		"self_act": self.parent.action,
		"enemy_pos": enemy_pos,
		"enemy_life": enemy_life,
		"enemy_maxlife": enemy_maxlife,
		"enemy_damage": enemy_damage,
		"enemy_defense": enemy_defense,
		"enemy_act": enemy_act,
		"has_enemy": has_enemy
	}

func get_reward(last_state, new_state, timeout):
	# "As a general rule, it is better to design performance measures according
	# to what one actually wants in the environment, rather than according to
	# how one thinks the agent should behave"
	if timeout:
		match self.reward_func:
			Reward.ALL_LIFE_SIGN_PLUS:
				return 0.5
			_:
				return 0.0
	
	if not new_state.has_enemy or new_state.enemy_life == 0:
		match self.reward_func:
			Reward.SELF_LIFE:
				return 0.0
			_:
				return 1.0

	if new_state.self_life == 0:
		match self.reward_func:
			Reward.ENEMY_LIFE_SIGN, Reward.ALL_LIFE_SIGN_PLUS:
				return 0.0
			_:
				return -1.0

	var self_life_dif = float(last_state.self_life - new_state.self_life)
	var enemy_life_dif = float(last_state.enemy_life - new_state.enemy_life)
	var self_life_dif_norm = self_life_dif / last_state.self_life
	var enemy_life_dif_norm = enemy_life_dif / last_state.enemy_life

	match self.reward_func:
		Reward.SELF_LIFE:
			# Range: [-1.0, 0.0]
			return - self_life_dif_norm
		Reward.ALL_LIFE:
			# Range: [-1.0, 1.0]
			return enemy_life_dif_norm - self_life_dif_norm
		Reward.ALL_LIFE_SIGN:
			# Range: {-1.0, 0.0, 1.0}
			return sign(enemy_life_dif_norm - self_life_dif_norm)
		Reward.ENEMY_LIFE_SIGN:
			# Range: {0.0, 1.0}
			return sign(enemy_life_dif_norm)
		Reward.ALL_LIFE_SIGN_PLUS:
			# Range: {0.0, 0.5, 1.0}
			return 0.5 * (sign(enemy_life_dif_norm - self_life_dif_norm) + 1)

# Abstract
func get_legal_actions(state):
	pass

# Abstract
func get_features_after_action(state, action):
	pass

func get_features(state):
	return self.get_features_after_action(state, Action.IDLE)
	# var enemy_mov = Action.get_movement(state.enemy_act)
	# var enemy_dir_vec = Action.to_vec(state.enemy_act)
	# var pos_diff = state.enemy_pos - state.self_pos
	# var diag = self.get_viewport().size.length()
	# var char_dist = state.self_pos.distance_to(state.enemy_pos)

	# var out = global.create_array(Feature.FEATURES_SIZE, 0.0)
	# out[Feature.POS_X_DIFF] = pos_diff.x / diag
	# out[Feature.POS_Y_DIFF] = pos_diff.y / diag
	# out[Feature.ENEMY_DIST] = char_dist / diag
	# out[Feature.SELF_LIFE] = state.self_life / state.self_maxlife
	# out[Feature.ENEMY_LIFE] = state.enemy_life / state.enemy_maxlife
	# out[Feature.ENEMY_ATTACKING] = 2.0 * float(enemy_mov == Action.ATTACK) - 1.0
	# out[Feature.ENEMY_DIR_X] = enemy_dir_vec.x
	# out[Feature.ENEMY_DIR_Y] = enemy_dir_vec.y
	# out[Feature.BIAS] = 1.0

	# return out

func get_features_names():
	return self.ai.get_features_names()

func can_think():
	# TODO: Is this the right way to do it?
	return self.parent.is_process_action(self.parent.action)

func before_reset(timeout):
	self.ai.update_state_action(self.get_state(), true, timeout)

# Abstract
func reset(timeout):
	pass

func after_reset(timeout):
	self.ai.reset(timeout)

func _on_ThinkTimer_timeout():
	if self.can_think():
		self.ai.update_state_action(self.get_state(), false, false)

# Print some variables for debug here
func _on_DebugTimer_timeout():
	print("======== " + self.parent.get_full_name() + " ========")
	var stats = ["max", "min", "avg"]
	# self.logger.print_stats("max_q_val", stats)
	# self.logger.print_stats("reward", stats)
	# self.logger.flush("max_q_val")
	# self.logger.flush("reward")
	# print("epsilon: {}".format(self.epsilon))
	self.ai._on_DebugTimer_timeout()
