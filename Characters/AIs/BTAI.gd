extends Node

const BasicBT = preload("res://Characters/AIs/BasicBT.tscn")

const ActionClass = preload("res://Characters/ActionBase.gd")
const AIEnums = preload("res://Characters/AIs/AIEnums.gd")
const Feature = AIEnums.BTFeature

var epsilon
var idle_rate
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

func end():
	pass

func reset(timeout):
	self.epsilon.reset()
	self.idle_rate.reset()
	self.last_state = self.parent.get_state()

func get_name():
	return self.parent.name

func get_action():
	return self.last_action

func get_features_names():
	return Feature.keys()

func update_state_action(state, last=false, timeout=false):
	if randf() < self.get_idle_rate():
		return Action.IDLE
	var features = self._get_features(state)
	var legal_actions = self.parent.get_legal_actions(state)
	if randf() < self.get_epsilon():
		self.last_action = global.choose_one(legal_actions)
	else:
		self.last_action = self.bt.get_action(features, legal_actions)
	self.last_state = state

func get_epsilon():
	return self.epsilon.get(self.time)

func get_idle_rate():
	return self.idle_rate.get(self.time)

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