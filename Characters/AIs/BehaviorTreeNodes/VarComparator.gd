extends "res://Characters/AIs/BehaviorTreeNodes/ComparatorBase.gd"

const AIEnums = preload("res://Characters/AIs/AIEnums.gd")
const Feature = AIEnums.BTFeature

export(Feature) var left_variable = 0
export(float) var left_coefficient = 1.0
export(float) var left_const = 0.0
export(Feature) var right_variable = 0
export(float) var right_coefficient = 1.0
export(float) var right_const = 0.0

func _get_left_value(features):
	return self.left_coefficient * features[self.left_variable] + self.left_const
	
func _get_right_value(features):
	return self.right_coefficient * features[self.right_variable] + self.right_const