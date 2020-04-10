extends "res://addons/godot-behavior-tree-plugin/condition.gd"

enum Conditional {
	EQUAL,
	LESS_THAN,
	GREATER_THAN,
	NOT_EQUAL,
	LESS_OR_EQUAL,
	GREATER_OR_EQUAL
}

export(Conditional) var conditional = Conditional.EQUAL

func tick(tick):
	var features = tick.blackboard.get("features")
	var left_val = self._get_left_value(features)
	var right_val = self._get_right_value(features)
	match (self.conditional):
		EQUAL:
			if left_val == right_val:
				return OK
		LESS_THAN:
			if left_val < right_val:
				return OK
		GREATER_THAN:
			if left_val > right_val:
				return OK
		NOT_EQUAL:
			if left_val != right_val:
				return OK
		LESS_OR_EQUAL:
			if left_val <= right_val:
				return OK
		GREATER_OR_EQUAL:
			if left_val >= right_val:
				return OK
	return FAILED

# Abstract
func _get_left_value(features):
	pass

# Abstract
func _get_right_value(features):
	pass