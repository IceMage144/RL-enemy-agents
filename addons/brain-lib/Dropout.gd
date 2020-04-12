extends "Layer.gd"

const Dropout = preload("res://bin/dropout.gdns")

var Util = preload("Util.gd").new()

export(float, 0.0, 1.0, 0.0001) var dropout_rate = 0.0

func _ready():
	self._layer = Dropout.new()
	self._layer.dropout_rate = self.dropout_rate

func _has_props(props_list, pos):
	var props = props_list[pos]
	if props.type != "dropout":
		return false
	return (props.dropout_rate == self.dropout_rate)