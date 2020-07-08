extends "res://Structures/Interpolator.gd"

var rand_val

func _init(params).(params):
	self._randomize()

func get(x):
	return self.rand_val

func reset():
	self._randomize()

func _randomize():
	self.rand_val = lerp(self.beg_val, self.end_val, randf())