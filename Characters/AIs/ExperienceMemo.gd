extends "res://Characters/AIs/Experience.gd"

var max_depth

var depth = 0

func _init(sample_size, max_depth).(sample_size):
	self.max_depth = max_depth
	self._push_clean()

# Features, Reward, State, Action -> void
func push(feat, reward, next_state, action = null):
	self.features.back().append(feat)
	self.rewards.back().append(reward)
	self.next_states.back().append(next_state)
	self.actions.back().append(action)
	self.depth += 1
	if self._is_full():
		self._push_clean()

# -> void
func pop():
	self.features.pop_back()
	self.rewards.pop_back()
	self.next_states.pop_back()
	self.actions.pop_back()
	self.depth = 0
	self._push_clean()

# -> Array{ Array[Array[LeafID]], Array[Array[Features]], Array[Array[Reward]], Array[Array[State]], Array[Array[Action]] }
func sample():
	.sample()

# -> Array{ Array[Array[LeafID]], Array[Array[Features]], Array[Array[Reward]], Array[Array[State]], Array[Array[Action]] }
func simple_sample():
	.simple_sample()

# -> void
func clean_end():
	if self.depth > 0:
		self.pop()

# -> bool
func end_is_clean():
	return self.depth == 0

# -> void
func _push_clean():
	self.keys.append(self.keys.size())
	self.features.append([])
	self.rewards.append([])
	self.next_states.append([])
	self.actions.append([])
	self.depth = 0

func _is_full():
	return self.depth == self.max_depth