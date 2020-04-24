extends Object

const SumTree = preload("res://Structures/SumTree.gd")
const MaxHeap = preload("res://Structures/MaxHeap.gd")

const MINIMUM_SIZE_FACTOR = 2

var sample_size
var weight_exponent
var st
var weight_heap

var features = []
var rewards = []
var next_states = []
var actions = []
var max_priority = 1.0

# int, int -> void
func _init(sample_size, weight_exponent):
	self.sample_size = sample_size
	self.weight_exponent = weight_exponent
	self.st = SumTree.new()
	self.weight_heap = MaxHeap.new()

# Features, Reward, State, Action, -> void
func push(feat, reward, next_state, action = null):
	self.features.append(feat)
	self.rewards.append(reward)
	self.next_states.append(next_state)
	self.actions.append(action)
	self.st.insert(max_priority)
	self.weight_heap.insert(1.0)

# Array[LeafID], Array[float] -> Array[float]
func update(pos_list, new_priorities):
	var batch_size = pos_list.size()
	var weights = []
	for i in range(batch_size):
		var el_prob = self.st.get_priority(pos_list[i]) / self.st.get_sum()
		var max_weight = self.weight_heap.get_max()
		var weight = pow(batch_size * el_prob, -self.weight_exponent) / max_weight
		weights.append(weight)
		self.weight_heap.update(pos_list[i], weight)
		self.st.update(pos_list[i], new_priorities[i])
		if new_priorities[i] > self.max_priority:
			self.max_priority = new_priorities[i]
	return weights

# -> Array{ Array[LeafID], Array[Features], Array[Reward], Array[State], Array[Action] }
func sample():
	var ret = [[], [], [], [], []]
	if self.st.get_size() > MINIMUM_SIZE_FACTOR * self.sample_size:
		var sum = self.st.get_sum()
		var priorities_sample = []
		var part = sum / self.sample_size
		for i in range(self.sample_size):
			var priority = global.sample_range(i * part, (i + 1) * part)
			priorities_sample.append(priority[0])
		for priority in priorities_sample:
			var key = self.st.find(priority)
			ret[0].append(key)
			ret[1].append(self.features[key])
			ret[2].append(self.rewards[key])
			ret[3].append(self.next_states[key])
			ret[4].append(self.actions[key])
	return ret

# -> Array{ Array[LeafID], Array[Features], Array[Reward], Array[State], Array[Action] }
func simple_sample():
	var ret = [[], [], [], [], []]
	var sum = self.st.get_sum()
	var priorities_sample = global.sample_range(0.0, sum)
	var key = self.st.find(priorities_sample[0])
	ret[0].append(key)
	ret[1].append(self.features[key])
	ret[2].append(self.rewards[key])
	ret[3].append(self.next_states[key])
	ret[4].append(self.actions[key])
	return ret