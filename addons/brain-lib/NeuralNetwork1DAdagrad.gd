extends "NeuralNetwork1D.gd"

const NNNative = preload("res://bin/neural_network_1d_adagrad.gdns")

func _ready():
	self._nn = NNNative.new()
	self.init_nn()

func _has_props(props):
	return props.type == "adagrad"