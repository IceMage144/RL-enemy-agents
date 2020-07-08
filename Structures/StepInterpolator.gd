extends "res://Structures/Interpolator.gd"

func _init(params).(params):
	pass

func get(x):
	if x < self.end_time:
		return self.beg_val
	return self.end_val