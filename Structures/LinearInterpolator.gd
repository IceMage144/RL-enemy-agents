extends "res://Structures/Interpolator.gd"

func _init(params).(params):
	pass

func get(x):
	var time_diff = self.end_time - self.beg_time
	if time_diff == 0.0:
		return self.end_val
	var time = clamp(x - self.beg_time, 0.0, time_diff)
	var factor = time / time_diff
	return lerp(self.beg_val, self.end_val, factor)