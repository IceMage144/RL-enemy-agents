extends "Layer.gd"

const ReLU = preload("res://bin/relu.gdns")

func _ready():
	self._layer = ReLU.new()

func _has_props(props_list, pos):
	var props = props_list[pos]
	return (props.type == "relu")