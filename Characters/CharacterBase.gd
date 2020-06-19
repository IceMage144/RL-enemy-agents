extends KinematicBody2D

const PlayerController = preload("res://Characters/Player/PlayerController.gd")
const ControllerNode = preload("res://Characters/Controller.tscn")

const ActionClass = preload("res://Characters/ActionBase.gd")
const AIEnums = preload("res://Characters/AIs/AIEnums.gd")
const AIType = AIEnums.AIType
const Reward = AIEnums.Reward

signal character_death # begin death animation
signal character_died # end death animation

enum Controller { PLAYER, AI }

const KNOCKBACK_INITIAL_SPEED = 800
const KNOCKBACK_DECAY_RATE = 0.6
const KNOCKBACK_MIN = Vector2(20, 20)

const ai_name = {
	AIType.PERCEPTRON_QL: "Perceptron QL",
	AIType.SINGLE_QL: "Single QL",
	AIType.MEMORY_QL: "Memory QL",
	AIType.MULTI_QL: "Multi QL",
	AIType.BASIC_BT: "Basic BT",
	AIType.IDLE_BT: "Idle BT"
}

const ai_color = {
	AIType.PERCEPTRON_QL: Color(0.2, 1.0, 0.2, 1.0),
	AIType.SINGLE_QL: Color(1.0, 0.2, 0.2, 1.0),
	AIType.MEMORY_QL: Color(0.2, 0.2, 1.0, 1.0),
	AIType.MULTI_QL: Color(0.0, 1.0, 1.0, 1.0),
	AIType.BASIC_BT: Color(1.0, 0.0, 1.0, 1.0),
	AIType.IDLE_BT: Color(1.0, 1.0, 1.0, 1.0)
}

const reward_func_repr = {
	Reward.SELF_LIFE: "-(s_{n-1}-s_{n})/s_{n-1}",
	Reward.ALL_LIFE: "(e_{n-1}-e_{n})/e_{n-1}-(s_{n-1}-s_{n})/s_{n-1}",
	Reward.ALL_LIFE_SIGN: "sign((e_{n-1}-e_{n})/e_{n-1}-(s_{n-1}-s_{n})/s_{n-1})",
	Reward.ENEMY_LIFE_SIGN: "sign((e_{n-1}-e_{n})/e_{n-1})",
	Reward.ALL_LIFE_SIGN_PLUS: "(sign((e_{n-1}-e_{n})/e_{n-1}-(s_{n-1}-s_{n})/s_{n-1})+1)/2"
}

export(int) var speed = 120
export(float) var weight = 1
export(int) var max_life = 3
export(int) var damage = 1
export(int) var defense = 0
export(Controller) var controller_type = Controller.PLAYER
export(AIType) var ai_type = AIType.PERCEPTRON_QL
export(Reward) var reward_func = Reward.SELF_LIFE
export(bool) var learning_activated = true
export(float, 0.0, 1.0, 0.0001) var learning_rate = 0.0
export(float, 0.5, 1.0, 0.001) var learning_rate_decay_exponent = 0.0
export(float, 0.0, 1.0, 0.001) var discount = 0.0
export(float, 0.0, 1.0, 0.001) var max_exploration_rate = 1.0
export(float, 0.0, 1.0, 0.001) var min_exploration_rate = 0.0
export(float) var exploration_rate_decay_time = 0.0
export(float) var idle_time = 0.0
export(bool) var experience_replay = false
export(bool) var prioritization = false
export(float, 0.0, 1.0) var priority_exponent = 0.0
export(float, 0.0, 1.0) var weight_exponent = 0.0
export(int) var experience_sample_size = 40
export(int) var experience_size_limit = 400
export(int) var num_freeze_iter = 1
export(float) var think_time = 0.1
export(float) var learn_time = 0.1

var already_hit = []
var velocity = Vector2()
var action = ActionClass.compose(ActionClass.IDLE, ActionClass.DOWN)
var can_act = true
var controller
var controller_name
var can_save = true
var network_id = null
var knockback = Vector2()
var invulnerable = false

onready var Action = ActionClass.new()
onready var anim_node = $Sprite/AnimationPlayer
onready var life = self.max_life
onready var character_type = self.get_script().get_path().get_file().get_basename()
onready var team = global.get_team(self)

func _ready():
	self.anim_node.play(Action.to_string(self.action))
	self.controller = ControllerNode.instance()
	self.set_max_life(self.max_life)
	$LifeBar.value = self.life

func _exit_tree():
	Action.free()

func init(params):
	self.network_id = global.dict_get(params, "network_id", null)
	self.can_save = global.dict_get(params, "can_save", true)
	if params.has("damage"):
		# Assert damage is positive
		assert(params.damage >= 0)
		self.damage = params.damage
	if params.has("defense"):
		# Assert defense is positive
		assert(params.defense >= 0)
		self.defense = params.defense
	if params.has("speed"):
		# Assert speed is positive and non-zero
		assert(params.speed > 0)
		self.speed = params.speed
	if params.has("ai_type"):
		if typeof(params.ai_type) == TYPE_STRING:
			# Assert AI type exists
			assert(AIType.has(params.ai_type))
			self.ai_type = AIType[params.ai_type]
			params.ai_type = self.ai_type
		else:
			# Assert AI type exists
			assert(params.ai_type < AIType.size() and params.ai_type >= 0)
			self.ai_type = params.ai_type
	if params.has("reward_func"):
		if typeof(params.reward_func) == TYPE_STRING:
			# Assert reward type exists
			assert(Reward.has(params.reward_func))
			self.reward_func = Reward[params.reward_func]
			params.reward_func = self.reward_func
		else:
			# Assert reward type exists
			assert(params.reward_func < Reward.size() and params.reward_func >= 0)
			self.reward_func = params.reward_func
	if params.has("controller_type"):
		if typeof(params.controller_type) == TYPE_STRING:
			# Assert controller type exists
			assert(Controller.has(params.controller_type))
			self.controller_type = Controller[params.controller_type]
			params.controller_type = self.controller_type
		else:
			# Assert controller type exists
			assert(params.controller_type < Controller.size() and params.controller_type >= 0)
			self.controller_type = params.controller_type
	if params.has("max_life"):
		# Assert that character will have life
		assert(params.max_life > 0)
		self.set_max_life(params.max_life)
	if params.has("life"):
		self.set_life(int(clamp(params.life, 0, self.get_max_life())))
	else:
		self.set_life(self.max_life)

	var params_keys = ["learning_activated", "learning_rate", "discount",
					   "max_exploration_rate", "min_exploration_rate",
					   "exploration_rate_decay_time", "experience_replay",
					   "prioritization", "experience_sample_size",
					   "experience_size_limit", "priority_exponent",
					   "weight_exponent", "num_freeze_iter", "think_time",
					   "learn_time", "learning_rate_decay_exponent",
					   "idle_time"]
	for key in params_keys:
		if params.has(key):
			self[key] = params[key]

	match self.controller_type:
		Controller.PLAYER:
			self.controller.set_script(PlayerController)
			self.add_child(self.controller)
			self.controller_name = "Player"
			self.add_to_group("player")
		Controller.AI:
			self.controller_name = ai_name[self.ai_type]
			self.add_to_group("robot")
			self._init_ai_controller(params)

func end():
	self.controller.end()

func _process(delta):
	self._process_action(self.action)

func _physics_process(delta):
	if self.knockback:
		self.move_and_slide(self.knockback)
		self.knockback *= KNOCKBACK_DECAY_RATE
		if self.knockback < KNOCKBACK_MIN:
			self.knockback = Vector2()
	else:
		self.move_and_slide(self.speed * self.velocity)

func _init_ai_controller(params):
	var AIControllerScript = self._get_ai_controller_script()
	self.controller.set_script(AIControllerScript)
	self.add_child(self.controller)
	var default_params = {
		"ai_type": self.ai_type,
		"learning_activated": self.learning_activated,
		"learning_rate": self.learning_rate,
		"learning_rate_decay_exponent": self.learning_rate_decay_exponent,
		"discount": self.discount,
		"max_exploration_rate": self.max_exploration_rate,
		"min_exploration_rate": self.min_exploration_rate,
		"exploration_rate_decay_time": self.exploration_rate_decay_time,
		"idle_time": self.idle_time,
		"experience_replay": self.experience_replay,
		"prioritization": self.prioritization,
		"experience_sample_size": self.experience_sample_size,
		"experience_size_limit": self.experience_size_limit,
		"priority_exponent": self.priority_exponent,
		"weight_exponent": self.weight_exponent,
		"num_freeze_iter": self.num_freeze_iter,
		"think_time": self.think_time,
		"learn_time": self.learn_time,
		"character_type": self.character_type,
		"network_id": self.network_id,
		"can_save": self.can_save,
		"reward_func": self.reward_func
	}
	global.insert_default_keys(params, default_params)
	self.controller.init(params)
	if GameConfig.get_debug_flag("character") and \
	  self.controller_type == Controller.AI:
		$Sprite.modulate = ai_color[self.ai_type]

func _get_ai_controller_script():
	var filepath = self.get_script().get_path().get_basename()
	return load(filepath + "RobotController.gd")

func is_ai():
	return self.controller_type == Controller.AI

func get_full_name():
	return "%s (%s)" % [self.name, self.controller_name]

func get_team():
	return self.team

func set_max_life(new_max_life):
	self.max_life = new_max_life
	$LifeBar.max_value = new_max_life
	# - [max life] * ([FG margin] + 2) / [rect width]
	$LifeBar.min_value = -new_max_life * 8 / 40

func get_max_life():
	return self.max_life

func get_damage():
	return self.damage

func get_defense():
	return self.defense

func set_life(new_life):
	self.life = clamp(new_life, 0, self.max_life)
	$LifeBar.value = self.life
	if self.life == 0:
		self.set_action(Action.DEATH)
		$CollisionPolygon2D.disabled = true
		self.emit_signal("character_death")

func add_life(amount):
	self.set_life(self.life + amount)

func take_damage(damage, knockback=false):
	self.set_life(self.life - max(0.0, damage - self.get_defense()))
	$Sprite.material.set_shader_param("active", true)
	$DamageBlinkTimer.start()
	self.invulnerable = true

func set_movement(new_movement, force=false):
	if (self.action != Action.DEATH and self.can_act or force) and \
	  new_movement != Action.get_movement(self.action):
		self.action = Action.compose(new_movement, self.action)
		self.anim_node.play(Action.to_string(self.action))

func set_action(new_action, force=false):
	if (self.action != Action.DEATH and self.can_act or force) and \
	  new_action != self.action:
		self.action = new_action
		self.anim_node.play(Action.to_string(self.action))

func attack():
	self.set_movement(Action.ATTACK)

func is_process_action(action):
	return Action.get_movement(action) == Action.IDLE or \
		   Action.get_movement(action) == Action.WALK

func die():
	self.end()
	self.emit_signal("character_died")

func is_dead():
	return Action.get_movement(self.action) == Action.DEATH

func get_knocked_back(other):
	var dir = (self.position - other.position).normalized()
	self.knockback = dir * KNOCKBACK_INITIAL_SPEED / self.weight

func block_action():
	self.can_act = false

func unblock_action():
	self.can_act = true

func before_reset(timeout):
	self.controller.before_reset(timeout)
	
func reset(timeout):
	self.set_life(self.max_life)
	self.set_action(Action.compose(Action.IDLE, Action.DOWN), true)
	$CollisionPolygon2D.disabled = false
	self.controller.reset(timeout)
	
func after_reset(timeout):
	self.controller.after_reset(timeout)

func _is_entity_attackable(entity):
	return entity.is_in_group("damageble") and \
	  not global.obj_get(entity, "invulnerable", false) and \
	  not (entity in self.already_hit) and \
	  Action.get_movement(entity.action) != Action.DEATH

func _on_AnimationPlayer_animation_finished(anim_name):
	var death = Action.to_string(Action.DEATH)
	if anim_name.begins_with(death):
		self.die()

func _on_AttackArea_area_entered(area):
	var entity = area.get_parent()
	if self._is_entity_attackable(entity) and \
	  entity.get_team() != self.get_team() and \
	  $AttackArea/AttackAreaPolygon.polygon.size() > 1 and \
	  (entity.position - self.position).dot(Action.to_vec(self.action)) >= 0 and \
	  Action.has(self.action, Action.ATTACK):
		entity.take_damage(self.get_damage())
		entity.get_knocked_back(self)
		self.already_hit.append(entity)

func _on_DamageBlinkTimer_timeout():
	$Sprite.material.set_shader_param("active", false)
	self.invulnerable = false

func get_info():
	return {
		"type": self.character_type,
		"network_id": self.network_id,
		"team": self.team,
		"speed": self.speed,
		"weight": self.weight,
		"max_life": self.max_life,
		"damage": self.damage,
		"defense": self.defense,
		"controller_type": self.controller_type,
		"controller_name": self.controller_name,
		"ai_type": self.ai_type,
		"reward_func": reward_func_repr[self.reward_func],
		"learning_activated": self.learning_activated,
		"learning_rate": self.learning_rate,
		"discount": self.discount,
		"max_exploration_rate": self.max_exploration_rate,
		"min_exploration_rate": self.min_exploration_rate,
		"exploration_rate_decay_time": self.exploration_rate_decay_time,
		"idle_time": self.idle_time,
		"experience_replay": self.experience_replay,
		"prioritization": self.prioritization,
		"priority_exponent": self.priority_exponent,
		"weight_exponent": self.weight_exponent,
		"experience_sample_size": self.experience_sample_size,
		"experience_size_limit": self.experience_size_limit,
		"num_freeze_iter": self.num_freeze_iter,
		"think_time": self.think_time,
		"learn_time": self.learn_time,
		"features": self.controller.get_features_names()
	}