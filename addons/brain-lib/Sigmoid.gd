extends "Layer.gd"

const Sigmoid = preload("res://bin/sigmoid.gdns")

func _ready():
	self._layer = Sigmoid.new()

func _has_props(props_list, pos):
	var props = props_list[pos]
	return (props.type == "sigmoid")