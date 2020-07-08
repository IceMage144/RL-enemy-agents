extends "res://Structures/Interpolator.gd"

var exponent

func _init(params).(params):
	var time_diff = self.end_time - self.beg_time
	self.exponent = (log(self.beg_val) - log(self.end_val)) / log(time_diff + 1)

func get(x):
	var time = max(0.0, x - self.beg_time)
	return self.beg_val * pow(time + 1.0, -self.exponent)