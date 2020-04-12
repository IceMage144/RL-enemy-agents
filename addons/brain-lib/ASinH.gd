extends "Layer.gd"

const ASinH = preload("res://bin/asinh.gdns")

func _ready():
	self._layer = ASinH.new()

func _has_props(props_list, pos):
	var props = props_list[pos]
	return (props.type == "asinh")