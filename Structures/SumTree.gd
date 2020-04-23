extends Object

enum Side {
	LEFT = 0,
	RIGHT = 1
}

var tree = [-1]
var max_size = 1
var size = 0

func _init():
	pass

# float -> LeafID
func insert(priority):
	if self.size == self.max_size:
		self._resize()
	self.tree.append(priority)
	self.size += 1
	self._updateLeaf(self.size - 1)
	return self.size - 1

# LeafID, float -> void
func update(pos, priority):
	if pos >= self.size or pos < 0 or typeof(pos) == TYPE_REAL:
		print("WARNING: SumTree.update received invalid position.")
		return
	self.tree[self.max_size + pos] = priority
	self._updateLeaf(pos)

# float -> LeafID
func find(val):
	var pos = 1
	var acc = 0
	while pos < self.max_size:
		var left = self._get_child(pos, LEFT)
		pos *= 2
		if val > acc + left:
			pos += 1
			acc += left
	return pos - self.max_size

# LeafID -> float
func get_priority(pos):
	return self.tree[self.max_size + pos]

# -> float
func get_sum():
	if self.size == 0:
		return 0.0
	return self.tree[1]

func get_size():
	return self.size

# int, Side -> bool
func _has_child(pos, side):
	return 2 * pos + side < self.tree.size()

# int, Side -> float
func _get_child(pos, side):
	if not self._has_child(pos, side):
		return 0.0
	return self.tree[2 * pos + side]

# -> void
func _resize():
	for i in range(self.max_size, 2 * self.max_size):
		self.tree.append(self.tree[i])
	self.max_size = 2 * self.max_size
	for i in range(self.max_size - 1, 0, -1):
		self._updateInner(i)

# int -> void
func _updateInner(pos):
	var left = self._get_child(pos, LEFT)
	var right = self._get_child(pos, RIGHT)
	self.tree[pos] = left + right

# int -> void
func _updateLeaf(pos):
	var tree_pos = self.max_size + pos
	while tree_pos > 1:
		tree_pos = int(tree_pos / 2)
		self._updateInner(tree_pos)

# -> void
func _test():
	var zero = self.insert(1)
	assert(zero == 0)
	assert(self.get_sum() == 1)
	var one = self.insert(2)
	assert(one == 1)
	assert(self.get_sum() == 3)
	var two = self.insert(4)
	assert(two == 2)
	assert(self.get_sum() == 7)
	var three = self.insert(8)
	assert(three == 3)
	assert(self.get_sum() == 15)
	var four = self.insert(16)
	assert(four == 4)
	assert(self.get_sum() == 31)
	var five = self.insert(32)
	assert(five == 5)
	assert(self.get_sum() == 63)
	var six = self.insert(64)
	assert(six == 6)
	assert(self.get_sum() == 127)
	var seven = self.insert(128)
	assert(seven == 7)
	assert(self.get_sum() == 255)
	self.update(seven, 256)
	assert(self.get_sum() == 383)
	self.update(zero, 2)
	assert(self.get_sum() == 384)
	assert(self.get_priority(seven) == 256)
	assert(self.get_priority(one) == 2)
	assert(self.get_priority(four) == 16)
	assert(self.find(9) == three)
	assert(self.find(40) == five)
	assert(self.find(16) == three)
	assert(self.find(384) == seven)
	assert(self.find(0) == zero)
	assert(self.find(385) == seven)
	assert(self.find(-1) == zero)
	assert(self.tree[0] == -1)