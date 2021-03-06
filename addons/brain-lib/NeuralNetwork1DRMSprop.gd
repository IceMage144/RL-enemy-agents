extends "NeuralNetwork1D.gd"

const NNNative = preload("res://bin/neural_network_1d_rmsprop.gdns")

export(float, 0.0, 1.0, 0.0001) var decay_term = 0.0 setget set_dt

func _ready():
	self._nn = NNNative.new()
	self._nn.decay_term = self.decay_term
	self.init_nn()

func set_dt(new_dt):
	decay_term = new_dt
	if self._nn:
		self._nn.dt = new_dt

func _has_props(props):
	return props.type == "rmsprop"