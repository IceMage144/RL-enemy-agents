extends Object

const SumTree = preload("res://Structures/SumTree.gd")
const MaxHeap = preload("res://Structures/MaxHeap.gd")

const MINIMUM_SIZE_FACTOR = 2
const INIT_WEIGHT = 1.0
const NO_SIZE_LIMIT = -1

var sample_size
var size_limit
var weight_exponent
var st
var weight_heap

var features = []
var rewards = []
var next_states = []
var actions = []
var experience_ids = []
var id_counter = 0
var max_priority = 1.0
var pos_counter = 0

# int, int -> void
func _init(sample_size, weight_exponent, size_limit = NO_SIZE_LIMIT):
	self.sample_size = sample_size
	self.weight_exponent = weight_exponent
	self.size_limit = size_limit
	self.st = SumTree.new()
	self.weight_heap = MaxHeap.new()
	# Assert size limit is big enough for sampling
	assert(not self._has_size_limit() or \
		   self.size_limit > MINIMUM_SIZE_FACTOR * self.sample_size)

# Features, Reward, State, Action, -> void
func push(features, reward, next_state, action = null):
	if not self._has_size_limit() or self.features.size() < self.size_limit:
		self.features.append(features)
		self.rewards.append(reward)
		self.next_states.append(next_state)
		self.actions.append(action)
		self.experience_ids.append(self.id_counter)
		self.st.insert(max_priority)
		self.weight_heap.insert(INIT_WEIGHT)
	else:
		self.features[self.pos_counter] = features
		self.rewards[self.pos_counter] = reward
		self.next_states[self.pos_counter] = next_state
		self.actions[self.pos_counter] = action
		self.experience_ids[self.pos_counter] = self.id_counter
		self.st.update(self.pos_counter, max_priority)
		self.weight_heap.update(self.pos_counter, INIT_WEIGHT)
	self.pos_counter = (self.pos_counter + 1) % self.size_limit
	self.id_counter += 1
	return self.id_counter - 1

# Array[LeafID], Array[float] -> Array[float]
func update(pos_list, new_priorities):
	var batch_size = pos_list.size()
	var weights = []
	var max_weight
	for i in range(batch_size):
		var sum = self.st.get_sum()
		var el_prob = self.st.get_priority(pos_list[i]) / sum
		max_weight = self.weight_heap.get_max()
		var weight = pow(batch_size * el_prob, -self.weight_exponent) / max_weight
		weights.append(weight)
		self.weight_heap.update(pos_list[i], weight)
		self.st.update(pos_list[i], new_priorities[i])
		if new_priorities[i] > self.max_priority:
			self.max_priority = new_priorities[i]
	return weights

# bool -> Array{ Array[LeafID], Array[Features], Array[Reward], Array[State], Array[Action] }
func sample():
	var ret = [[], [], [], [], [], []]
	if self.st.get_size() > MINIMUM_SIZE_FACTOR * self.sample_size:
		var sum = self.st.get_sum()
		var priorities_sample = global.sample_range(0.0, sum, self.sample_size)
		for priority in priorities_sample:
			var key = self.st.find(priority)
			ret[0].append(key)
			ret[1].append(self.features[key])
			ret[2].append(self.rewards[key])
			ret[3].append(self.next_states[key])
			ret[4].append(self.actions[key])
			ret[5].append(self.experience_ids[key])
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
	ret[5].append(self.experience_ids[key])
	return ret

func get_size():
	return self.st.get_size()

func _has_size_limit():
	return self.size_limit != NO_SIZE_LIMIT