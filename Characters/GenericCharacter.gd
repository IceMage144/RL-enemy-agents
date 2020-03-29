extends "res://Characters/CharacterBase.gd"

func _process_action(action):
	var mov = Action.get_movement(action)
	if mov == Action.ATTACK or mov == Action.DEATH:
		self.velocity = Vector2()
	else:
		self.velocity = Vector2() if not self.can_act else self.controller.velocity
		if not self.velocity:
			self.set_movement(Action.IDLE, true)
		else:
			if self.velocity.x < self.velocity.y:
				if -self.velocity.x < self.velocity.y:
					self.set_action(Action.compose(Action.WALK, Action.DOWN))
				else:
					self.set_action(Action.compose(Action.WALK, Action.LEFT))
			else:
				if -self.velocity.x > self.velocity.y:
					self.set_action(Action.compose(Action.WALK, Action.UP))
				else:
					self.set_action(Action.compose(Action.WALK, Action.RIGHT))

func _on_AnimationPlayer_animation_finished(anim_name):
	var attack = Action.to_string(Action.ATTACK)
	if anim_name.begins_with(attack):
		self.set_movement(Action.IDLE, true)
		self.already_hit = []
	else:
		._on_AnimationPlayer_animation_finished(anim_name)