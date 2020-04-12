extends "Layer.gd"

const Tanh = preload("res://bin/tanh.gdns")

func _ready():
	self._layer = Tanh.new()

func _has_props(props_list, pos):
	var props = props_list[pos]
	return (props.type == "tanh")