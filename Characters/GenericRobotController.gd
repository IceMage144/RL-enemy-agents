extends "res://Characters/BaseRobotController.gd"

const MAX_ATTACK_RANGE = 40
const MIN_ATTACK_RANGE = 30

func get_legal_actions(state):
	var legal_actions = [Action.IDLE, Action.ATTACK]
	for dir in Action.directions(true):
		var cell = self.tm.get_cellv(self.tm.world_to_map(state.self_pos) + Action.to_vec(dir))
		if cell != 1:
			legal_actions.append(Action.compose(Action.WALK, dir))

	return legal_actions

func get_features_after_action(state, action):
	var self_mov = Action.get_movement(action)
	var enemy_mov = Action.get_movement(state.enemy_act)
	var enemy_dir_vec = Action.to_vec(state.enemy_act)
	var out = []
	for i in range(FEATURES_SIZE):
		out.append(0.0)

	out[ENEMY_DIST] = state.self_pos.distance_to(state.enemy_pos)
	out[SELF_LIFE] = state.self_life / state.self_maxlife
	out[ENEMY_LIFE] = state.enemy_life / state.enemy_maxlife
	out[ENEMY_ATTACKING] = 2.0 * float(enemy_mov == Action.ATTACK) - 1.0
	out[ENEMY_DIR_X] = enemy_dir_vec.x
	out[ENEMY_DIR_Y] = enemy_dir_vec.y
	out[BIAS] = 1.0

	var damage_chance = (MAX_ATTACK_RANGE - out[ENEMY_DIST]) / (MAX_ATTACK_RANGE - MIN_ATTACK_RANGE)

	if self_mov == Action.WALK:
		var dir_vec = Action.to_vec(action)
		var transform = Transform2D(0.0, state.self_pos)
		# COMMENT: Make this test at get_legal_actions?
		if not self.parent.test_move(transform, dir_vec):
			out[ENEMY_DIST] = state.enemy_pos.distance_to(state.self_pos + dir_vec)
	elif self_mov == Action.ATTACK:
		if self._is_aligned(state.self_act, state.enemy_pos - state.self_pos):
			out[ENEMY_LIFE] -= state.self_damage * min(1.0, max(0.0, damage_chance))
	
	# CAUTION: DO NOT REMOVE THIS ATTACK_RANGE VERIFICATION, OTHERWISE IT WILL ALWAYS PREFFER
	# ATTACK THAN OTHER ACTIONS
	if enemy_mov == Action.ATTACK \
	   and self._is_aligned(state.enemy_act, state.self_pos - state.enemy_pos):
		out[SELF_LIFE] -= state.enemy_damage * min(1.0, max(0.0, damage_chance))

	out[ENEMY_DIST] /= self.get_viewport().size.length()

	return out

func _on_ThinkTimer_timeout():
	._on_ThinkTimer_timeout()

	if self.can_think():
		var ai_action = self.ai.get_action()
		match Action.get_movement(ai_action):
			Action.ATTACK:
				# COMMENT: Is it good to set parent's action?
				self.parent.attack()
				self.velocity = Vector2() # Leave this here for consistency
			Action.WALK:
				self.velocity = Action.to_vec(ai_action)
			Action.IDLE:
				self.velocity = Vector2()

