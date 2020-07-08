extends Object

var beg_val
var end_val
var beg_time
var end_time

func _init(params):
	self.beg_val = params.beg_val
	self.end_val = params.end_val
	self.beg_time = 0.0
	self.end_time = 0.0
	if params.has("end_time"):
		self.end_time = params.end_time
	if params.has("beg_time"):
		self.beg_time = params.beg_time

# Abstract
func get(x):
	pass

# Abstract
func reset():
	pass