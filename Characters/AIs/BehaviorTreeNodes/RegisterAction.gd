extends "res://addons/godot-behavior-tree-plugin/action.gd"

const ActionClass = preload("res://Characters/ActionBase.gd")

export(ActionClass.Movement) var movement = ActionClass.IDLE
export(ActionClass.Direction) var direction = 0

onready var Action = ActionClass.new()

func tick(tick):
	var action = Action.compose(self.movement, self.direction)
	var legal_actions = tick.blackboard.get("legal_actions")
	if not (action in legal_actions):
		return FAILED
	var result = tick.blackboard.get("result")
	result["action"] = action
	return OK
