extends Node

const AINode = preload("res://Characters/AIs/AI.tscn")
const ActionClass = preload("res://Characters/ActionBase.gd")
const Logger = preload("res://Structures/Logger.gd")

const AIEnums = preload("res://Characters/AIs/AIEnums.gd")
const AIType = AIEnums.AIType
const Feature = AIEnums.QLFeature

const ai_path = {
	AIType.PERCEPTRON_QL: "res://Characters/AIs/PerceptronQLAI.gd",
	AIType.SINGLE_QL: "res://Characters/AIs/SingleQLAI.gd",
	AIType.MEMORY_QL: "res://Characters/AIs/MemoryQLAI.gd",
	AIType.MULTI_QL: "res://Characters/AIs/MultiQLAI.gd",
	AIType.BASIC_BT: "res://Characters/AIs/BasicBTAI.gd"
}

var ai
var enemy
var tm
var parent
var velocity = Vector2()

onready var logger = Logger.new()
onready var Action = ActionClass.new()

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
	self.enemy = global.get_enemy(self.parent)
	self.tm = global.find_entity("floor")
	if GameConfig.get_debug_flag("character"):
		$DebugTimer.start()

func init(params):
	self.ai = AINode.instance()
	self.ai.set_script(load(ai_path[params.ai_type]))
	self.add_child(self.ai)
	var initial_state = {}
	if params.think_time != 0:
		initial_state = self.get_state()
	self.ai.init({
		"learning_activated": params.learning_activated,
		"learning_rate": params.learning_rate,
		"discount": params.discount,
		"max_exploration_rate": params.max_exploration_rate,
		"min_exploration_rate": params.min_exploration_rate,
		"exploration_rate_decay_time": params.exploration_rate_decay_time,
		"experience_replay": params.experience_replay,
		"experience_pool_size": params.experience_pool_size,
		"priority_exponent": params.priority_exponent,
		"weight_exponent": params.weight_exponent,
		"num_freeze_iter": params.num_freeze_iter,
		"think_time": params.think_time,
		"features_size": Feature.FEATURES_SIZE,
		"initial_state": initial_state,
		"initial_action": Action.IDLE,
		"character_type": params.character_type,
		"network_id": params.network_id,
		"can_save": params.can_save
	})
	if params.think_time != 0:
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
	if self.enemy != null:
		enemy_pos = self.enemy.position
		enemy_life = self.enemy.life
		enemy_maxlife = self.enemy.get_max_life()
		enemy_damage = self.enemy.get_damage()
		enemy_defense = self.enemy.get_defense()
		enemy_act = self.enemy.action
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
		"enemy_act": enemy_act
	}

func get_reward(last_state, new_state, timeout):
	# "As a general rule, it is better to design performance measures according
	# to what one actually wants in the environment, rather than according to
	# how one thinks the agent should behave"
	if Action.get_movement(last_state.enemy_act) == Action.DEATH or \
	   new_state.enemy_life == 0:
		return 1.0

	if Action.get_movement(last_state.self_act) == Action.DEATH or \
	   new_state.self_life == 0 or timeout:
		return -1.0

	# CAUTION: Needs normalization if damage per think is too high
	var self_life_dif = last_state.self_life - new_state.self_life
	var enemy_life_dif = last_state.enemy_life - new_state.enemy_life

	# Range: [-1.0, 0.0]
	# return - float(self_life_dif) / last_state.self_life
	# Range: [-1.0, 1.0]
	return float(enemy_life_dif) / last_state.enemy_life - float(self_life_dif) / last_state.self_life
	# Range: [-7.5, 2.5]
	# return 0.5 * (enemy_life_dif - self_life_dif) - 0.25

# Abstract
func get_legal_actions(state):
	pass

# Abstract
func get_features_after_action(state, action):
	pass

func get_features(state):
	return self.get_features_after_action(state, Action.IDLE)

func can_think():
	# TODO: Is this the right way to do it?
	return self.parent.is_process_action(self.parent.action)

func before_reset(timeout):
	self.ai.update_state(self.get_state(), true, timeout)

# Abstract
func reset(timeout):
	pass

func after_reset(timeout):
	self.ai.reset(timeout)

func _on_ThinkTimer_timeout():
	if self.can_think():
		var ts = OS.get_ticks_msec()

		self.ai.update_state(self.get_state(), false, false)

		var te = OS.get_ticks_msec()
		self.logger.push("update_state", te - ts)

# Print some variables for debug here
func _on_DebugTimer_timeout():
	print("======== " + self.parent.get_full_name() + " ========")
	var stats = ["max", "min", "avg"]
	self.logger.print_stats("update_state", stats)
	# self.logger.print_stats("max_q_val", stats)
	# self.logger.print_stats("reward", stats)
	self.logger.flush("update_state")
	# self.logger.flush("max_q_val")
	# self.logger.flush("reward")
	# print("epsilon: {}".format(self.epsilon))
	self.ai._on_DebugTimer_timeout()
