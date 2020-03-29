extends Object

const MOVEMENT_FILTER = 0x00ffffff
const DIRECTION_FILTER = 0xff000000
const DIAGONAL_FILTER = 0xaa000000

enum Movement {
	IDLE = 0,
	DEATH = 1 << 0,
	WALK = 1 << 1,
	ATTACK = 1 << 2
}

enum Direction {
	# NONE = 0,
	RIGHT = 1 << 24,
	UP_RIGHT = 1 << 25,
	UP = 1 << 26,
	UP_LEFT = 1 << 27,
	LEFT = 1 << 28,
	DOWN_LEFT = 1 << 29,
	DOWN = 1 << 30,
	DOWN_RIGHT = 1 << 31
}

var _dir_to_vec = {}
var _id_to_str = {}

func _init():
	var vec = Vector2(1, 0)
	for dir_id in Direction.values():
		self._dir_to_vec[dir_id] = vec
		vec = vec.rotated(- PI / 4)
	self._dir_to_vec[0] = Vector2()
	
	for mov in Movement.keys():
		self._id_to_str[Movement[mov]] = mov.to_lower()

	for dir in Direction.keys():
		self._id_to_str[Direction[dir]] = dir.to_lower()

# Check if the given number represents a valid action
func _check_valid_action(action):
	assert(typeof(action) == TYPE_INT)
	assert(action >= 0)
	var movement = self.get_movement(action)
	var direction = self.get_direction(action)
	# Obs: Checks if the number has only one set bit (is an integer
	# power of 2) using Brian Kernighan’s algorithm
	assert(((movement == 0) or (movement & (movement - 1) == 0)) and \
		   ((direction == 0) or (direction & (direction - 1) == 0)))

# Translate an action to a string
func to_string(action):
	self._check_valid_action(action)
	var movement = self.get_movement(action)
	var direction = self.get_direction(action)
	if direction:
		return "{0}_{1}".format([self._id_to_str[movement], self._id_to_str[direction]])
	return self._id_to_str[movement]

func from_string(string):
	var first_string_size = string.find("_")
	var mov_name = string.to_upper()
	if first_string_size != -1:
		mov_name = mov_name.substr(0, first_string_size)

	# Movement does not exists
	assert(Movement.has(mov_name))
	if first_string_size == -1:
		return Movement[mov_name]
	
	var dir_name = string.substr(first_string_size + 1, string.length()).to_upper()
	# Direction does not exists
	assert(Direction.has(dir_name))

	return self.compose(Movement[mov_name], Direction[dir_name])

# Get an action direction as vector
func to_vec(action):
	self._check_valid_action(action)
	var direction = self.get_direction(action)
	return self._dir_to_vec[direction]

func bits_are_equal_string(bits, string):
	var movement = self._id_to_str[self.get_movement(bits)]
	var direction_bits = self.get_direction(bits)
	var direction = movement if direction_bits == 0 else self._id_to_str[direction_bits]
	return string.begins_with(movement) and string.ends_with(direction)

static func get_direction(action):
	return action & DIRECTION_FILTER

static func get_movement(action):
	return action & MOVEMENT_FILTER

static func compose(movement, direction):
	return (movement & MOVEMENT_FILTER) | (direction & DIRECTION_FILTER)

func has(action1, action2):
	return action1 & action2 != 0

func directions(include_diagonals):
	var dirs = []
	for dir in Direction.values():
		if dir & DIAGONAL_FILTER:
			if include_diagonals:
				dirs.append(dir)
		else:
			dirs.append(dir)
	return dirs