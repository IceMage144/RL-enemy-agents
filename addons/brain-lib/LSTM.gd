extends "Layer.gd"

const LSTM = preload("res://bin/lstm.gdns")

export(int, 1, 10000) var size = 1
export(int, 1, 10000) var depth = 2
export(int, 1, 10000) var num_layers = 1
export(float, 0.0, 1.0, 0.0001) var dropout_rate = 0.0
export(bool) var has_bias = true

func _ready():
	self._layer = LSTM.new()
	self._layer.has_bias = self.has_bias
	self._layer.num_layers = self.num_layers
	self._layer.dropout_rate = self.dropout_rate
	self._layer.depth = self.depth
	self._layer.size = self.size

func _has_props(props_list, pos):
	var size = self._internal_size()
	for i in range(size):
		var props = props_list[pos + i]
		if (i % 2 == 1 and props.type != "dropout") or \
		   (i % 2 == 0 and (props.type != "recurrent_layer" or \
		   not props.has("lstm_cell"))):
			return false
	var res = true
	for i in range(size):
		var props = props_list[pos + i]
		if i % 2 == 0:
			res = res and (props.seq_len == self.depth)
			res = res and (props.lstm_cell.out_size == self.size)
			res = res and (props.lstm_cell.has_bias == self.has_bias)
		else:
			res = res and (props.dropout_rate == self.dropout_rate)
	return res

func _internal_size():
	return 2 * self.num_layers - 1