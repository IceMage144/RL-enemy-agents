extends "Layer.gd"

const FullyConnected = preload("res://bin/fully_connected.gdns")

var Util = preload("Util.gd").new()

export(int, 1, 10000) var size = 1
export(bool) var has_bias = true

func _ready():
	self._layer = FullyConnected.new()
	self._layer.has_bias = self.has_bias
	self._layer.size = self.size

func _has_props(props_list, pos):
	var props = props_list[pos]
	if props.type != "fully_connected":
		return false
	var prop1 = (props.out_size == self.size)
	var prop2 = (props.has_bias == self.has_bias)
	return prop1 and prop2