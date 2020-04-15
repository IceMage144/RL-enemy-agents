extends "res://Characters/RobotControllerBase.gd"

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
	var self_dir_vec = Action.to_vec(action)
	var enemy_mov = Action.get_movement(state.enemy_act)
	var enemy_dir_vec = Action.to_vec(state.enemy_act)
	var pos_diff = state.enemy_pos - state.self_pos
	var out = []
	for i in range(Feature.FEATURES_SIZE):
		out.append(0.0)

	out[Feature.POS_X_DIFF] = pos_diff.x
	out[Feature.POS_Y_DIFF] = pos_diff.y
	out[Feature.ENEMY_DIST] = state.self_pos.distance_to(state.enemy_pos)
	out[Feature.SELF_LIFE] = state.self_life / state.self_maxlife
	out[Feature.ENEMY_LIFE] = state.enemy_life / state.enemy_maxlife
	out[Feature.ENEMY_ATTACKING] = 2.0 * float(enemy_mov == Action.ATTACK) - 1.0
	out[Feature.ENEMY_DIR_X] = enemy_dir_vec.x
	out[Feature.ENEMY_DIR_Y] = enemy_dir_vec.y
	out[Feature.BIAS] = 1.0

	var damage_chance = inverse_lerp(MIN_ATTACK_RANGE, MAX_ATTACK_RANGE,
									 out[Feature.ENEMY_DIST])
	damage_chance = clamp(0.0, 1.0, damage_chance)

	if self_mov == Action.WALK:
		var transform = Transform2D(0.0, state.self_pos)
		# COMMENT: Make this test at get_legal_actions?
		if not self.parent.test_move(transform, self_dir_vec):
			var new_dist = state.enemy_pos.distance_to(state.self_pos + self_dir_vec)
			out[Feature.ENEMY_DIST] = new_dist
	elif self_mov == Action.ATTACK:
		if self._is_aligned(state.self_act, pos_diff):
			out[Feature.ENEMY_LIFE] -= state.self_damage * damage_chance
	
	# CAUTION: DO NOT REMOVE THIS ATTACK_RANGE VERIFICATION, OTHERWISE IT WILL
	# ALWAYS PREFFER ATTACK THAN OTHER ACTIONS
	if enemy_mov == Action.ATTACK \
	   and self._is_aligned(state.enemy_act, -pos_diff):
		out[Feature.SELF_LIFE] -= state.enemy_damage * damage_chance

	var diag = self.get_viewport().size.length()
	out[Feature.POS_X_DIFF] = (out[Feature.POS_X_DIFF] - self_dir_vec.x) / diag
	out[Feature.POS_Y_DIFF] = (out[Feature.POS_Y_DIFF] - self_dir_vec.y) / diag
	out[Feature.ENEMY_DIST] /= diag

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

