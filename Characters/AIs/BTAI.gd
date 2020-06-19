extends Node

const BasicBT = preload("res://Characters/AIs/BasicBT.tscn")

const ActionClass = preload("res://Characters/ActionBase.gd")
const AIEnums = preload("res://Characters/AIs/AIEnums.gd")
const Feature = AIEnums.BTFeature

var max_epsilon
var min_epsilon
var epsilon_decay_time
var idle_time
var last_action
var last_state
var bt

var time = 0.0

onready var Action = ActionClass.new()
onready var parent = self.get_parent()

func _exit_tree():
	Action.free()

func _process(delta):
	self.time += delta

func init(params):
	self.last_state = params.initial_state
	self.last_action = params.initial_action
	self.max_epsilon = params.max_exploration_rate
	self.min_epsilon = params.min_exploration_rate
	self.epsilon_decay_time = params.exploration_rate_decay_time
	self.idle_time = params.idle_time

func end():
	pass

func reset(timeout):
	self.last_state = self.parent.get_state()

func get_name():
	return self.parent.name

func get_action():
	return self.last_action

func get_features_names():
	return Feature.keys()

func update_state_action(state, last=false, timeout=false):
	if self.time < self.idle_time:
		return Action.IDLE
	var features = self._get_features(state)
	var legal_actions = self.parent.get_legal_actions(state)
	if randf() < self.get_epsilon():
		self.last_action = global.choose_one(legal_actions)
	else:
		self.last_action = self.bt.get_action(features, legal_actions)
	self.last_state = state

func get_epsilon():
	if self.epsilon_decay_time == 0.0:
		return self.min_epsilon
	var time = clamp(self.time - self.idle_time, 0.0, self.epsilon_decay_time)
	var factor = time / self.epsilon_decay_time
	return lerp(self.max_epsilon, self.min_epsilon, factor)

func _get_features(state):
	var self_dir = Action.to_vec(state.self_act)
	var enemy_dir = Action.to_vec(state.enemy_act)
	var dist = (state.enemy_pos - state.self_pos).length()
	var enemy_attacking = Action.has(state.enemy_act, Action.ATTACK)
	return {
		Feature.POS_X_DIFF: state.enemy_pos.x - state.self_pos.x,
		Feature.POS_Y_DIFF: state.enemy_pos.y - state.self_pos.y,
		Feature.SELF_X_DIR: self_dir.x,
		Feature.SELF_Y_DIR: self_dir.y,
		Feature.SELF_LIFE: state.self_life,
		Feature.SELF_MAXLIFE: state.self_maxlife,
		Feature.SELF_DAMAGE: state.self_damage,
		Feature.SELF_DEFENSE: state.self_defense,
		Feature.ENEMY_X_DIR: enemy_dir.x,
		Feature.ENEMY_Y_DIR: enemy_dir.y,
		Feature.ENEMY_LIFE: state.enemy_life,
		Feature.ENEMY_MAXLIFE: state.enemy_maxlife,
		Feature.ENEMY_DAMAGE: state.enemy_damage,
		Feature.ENEMY_DEFENSE: state.enemy_defense,
		Feature.ENEMY_DIST: dist,
		Feature.ENEMY_ATTACKING: enemy_attacking
	}

# Print some variables for debug here
func _on_DebugTimer_timeout():
	pass