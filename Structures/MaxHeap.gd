extends Object

enum Side {
	LEFT = 0,
	RIGHT = 1
}

var heap = [-1]
var priorities = []
var reverse = []

func _init():
	pass

# float -> HeapId
func insert(pri):
	var heap_id = self.priorities.size()
	self.heap.append(heap_id)
	self.priorities.append(pri)
	self.reverse.append(heap_id + 1)
	self._float(heap_id + 1)
	return heap_id

# HeapID, float -> void
func update(heap_id, pri):
	self.priorities[heap_id] = pri
	var pos = self.reverse[heap_id]
	var parent_pos = self._get_parent(pos)
	var parent_pri = self._get_priority(parent_pos)
	if self._has_parent(pos) and pri > parent_pri:
		self._float(pos)
	else:
		self._sink(pos)

# -> float
func get_max():
	if self.heap.size() == 1:
		return -INF
	return self._get_priority(1)

# int -> void
func _sink(pos):
	var pri = self.priorities[self.heap[pos]]
	while not self._is_leaf(pos):
		var child_pos = self._get_child(pos, LEFT)
		var child_pri = self._get_priority(child_pos)
		if pri < child_pri:
			self._swap(pos, child_pos)
			pos = child_pos
			continue
		child_pos = self._get_child(pos, RIGHT)
		child_pri = self._get_priority(child_pos)
		if pri < child_pri:
			self._swap(pos, child_pos)
			pos = child_pos
			continue
		break

# int -> void
func _float(pos):
	var pri = self._get_priority(pos)
	var parent_pos = self._get_parent(pos)
	var parent_pri = self._get_priority(parent_pos)
	while self._has_parent(pos) and pri > parent_pri:
		self._swap(pos, parent_pos)
		pos = parent_pos
		parent_pos = self._get_parent(pos)
		parent_pri = self._get_priority(parent_pos)

# int, int -> void
func _swap(pos1, pos2):
	global.swap(self.heap, pos1, pos2)
	global.swap(self.reverse, self.heap[pos1], self.heap[pos2])

# int -> float
func _get_priority(pos):
	return self.priorities[self.heap[pos]]

# int -> int
func _get_parent(pos):
	return int(pos / 2)

# int, Side -> int
func _get_child(pos, side):
	if not self._has_child(pos, side):
		return 0
	return 2 * pos + side

# int -> bool
func _has_parent(pos):
	return self._get_parent(pos) != 0

# int, Side -> bool
func _has_child(pos, side):
	return 2 * pos + side < self.heap.size()

# int -> bool
func _is_leaf(pos):
	return not self._has_child(pos, LEFT) and not self._has_child(pos, RIGHT)

# -> void
func _test():
	var zero = self.insert(1)
	print(self.heap)
	print(self.priorities)
	print(self.reverse)
	assert(zero == 0)
	var one = self.insert(5)
	print(self.heap)
	print(self.priorities)
	print(self.reverse)
	assert(one == 1)
	var two = self.insert(2)
	print(self.heap)
	print(self.priorities)
	print(self.reverse)
	assert(two == 2)
	var three = self.insert(3)
	print(self.heap)
	print(self.priorities)
	print(self.reverse)
	assert(three == 3)
	assert(self.get_max() == 5)
	self.update(one, 0)
	assert(self.get_max() == 3)
	assert(self.heap[0] == -1)