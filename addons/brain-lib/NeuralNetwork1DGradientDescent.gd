extends "NeuralNetwork1D.gd"

const NNNative = preload("res://bin/neural_network_1d_gd.gdns")

export(float, 0.0, 1.0, 0.0001) var weight_decay = 0.0 setget set_wd

func _ready():
	self._nn = NNNative.new()
	self._nn.weight_decay = self.weight_decay
	self.init_nn()

func set_wd(new_wd):
	weight_decay = new_wd
	if self._nn:
		self._nn.wd = new_wd

func _has_props(props):
	return props.type == "gradient_descent"