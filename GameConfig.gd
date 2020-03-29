extends Node

var debug_flags = {}

func set_debug_flag(flag_name, value):
	self.debug_flags[flag_name] = value

func get_debug_flag(flag_name):
	if not self.debug_flags.has(flag_name):
		return false
	return self.debug_flags[flag_name]