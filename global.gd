extends Node

const SAVE_PATH = "user://save.save"

const TEAMS = [
	"team1",
	"team2",
	"team3",
	"team4"
]

const EPS = 1e-12

func has_entity(entity_name):
	return len(get_tree().get_nodes_in_group(entity_name)) != 0

func find_entity(entity_name):
	if not has_entity(entity_name):
		return null
	var entity_list = get_tree().get_nodes_in_group(entity_name)
	return entity_list[0]

func get_team(entity):
	for team in TEAMS:
		if entity.is_in_group(team):
			return team
	return ""

func get_enemy(entity):
	var entity_team = self.get_team(entity)
	var enemies = []
	for team in TEAMS:
		if team != entity_team:
			for enemy in get_tree().get_nodes_in_group(team):
				if not enemy.is_dead():
					enemies.append(enemy)
	var closest_enemy = null
	var min_dist = INF
	for enemy in enemies:
		var dist = enemy.position.distance_to(entity.position)
		if dist < min_dist:
			closest_enemy = enemy
			min_dist = dist
	return closest_enemy

# Random integer in the interval [start, end] (including both ends)
func randi_range(start, end):
	return int(start + floor(randf() * (end - start + 1)))

func sample_from_normal(mean, std):
	var U = randf()
	var V
	for i in range(5):
		V = randf()
	var X = sqrt(-2 * log(U)) * cos(2 * PI * V)
	return mean + std * X

func sample_from_normal_limited(mean, std, limits=[-INF, INF]):
	var X = self.sample_from_normal(mean, std)
	while X <= limits[0] or X >= limits[1]:
		X = self.sample_from_normal(mean, std)
	return X

func choose_one(array, include_null=false, a=-1, b=-1):
	if a == -1:
		a = 0
	if b == -1:
		b = array.size() - 1
	b += int(include_null)
	var rand_num = global.randi_range(a, b)
	if include_null and rand_num == b:
		return null
	return array[rand_num]

func sample(array, num, include_null=false, a=0, b=-1):
	if b == -1:
		b = array.size()
	var ret = []
	for i in range(num):
		ret.append(self.choose_one(array, include_null, a, b))
	return ret

func sample_range(a=0.0, b=1.0, num=1):
	var ret = []
	for i in range(num):
		ret.append((b - a) * randf() + a)
	return ret

func choose(array, num):
	if num == len(array):
		return array.copy()
	var ret = []
	var used = {}
	while len(ret) != num:
		var rand_num = self.randi_range(0, len(array) - 1)
		if not used.has(rand_num):
			used[rand_num] = true
			ret.append(array[rand_num])
	return ret

func shuffle_array(array):
	var n = len(array)
	for i in range(n - 1):
		var pos = self.randi_range(i, n - 1)
		var tmp = array[pos]
		array[pos] = array[i]
		array[i] = tmp
	return array

func dict_get(dict, key, default):
	if key == null:
		return null
	if not dict.has(key):
		return default
	return dict[key]

func obj_get(obj, key, default):
	if key == null:
		return null
	if not obj.has_meta(key):
		return default
	return obj[key]

func insert_default_keys(dict, default):
	for key in default.keys():
		if not dict.has(key):
			dict[key] = default[key]

func create_array(size, fill=null):
	var array = []
	for i in range(size):
		array.append(fill)
	return array

func create_matrix(height, width, fill=null):
	var matrix = []
	for i in range(height):
		matrix.append([])
		for j in range(width):
			matrix[i].append(fill)
	return matrix

func swap(array, pos1, pos2):
	var tmp = array[pos1]
	array[pos1] = array[pos2]
	array[pos2] = tmp

func max(array):
	if array.size() == 0:
		return null
	var mx = array[0]
	for el in array:
		mx = max(el, mx)
	return mx

func min(array):
	if array.size() == 0:
		return null
	var mn = array[0]
	for el in array:
		mn = min(el, mn)
	return mn

# Returns the first index with the maximum value
func argmax(array):
	if array.size() == 0:
		return null
	var mx = array[0]
	var idx = 0
	for i in range(1, array.size()):
		if mx < array[i]:
			mx = array[i]
			idx = i
	return idx

# Returns the last index with the maximum value
func torch_argmax(array):
	if array.size() == 0:
		return null
	var mx = array[0]
	var idx = 0
	for i in range(1, array.size()):
		if mx <= array[i]:
			mx = array[i]
			idx = i
	return idx

# Like argmax, but randomizes the result index if there are more than one
# max value at the array
func rand_argmax(array):
	if array.size() == 0:
		return null
	var mx = array[0]
	var idxs = [0]
	for i in range(1, array.size()):
		if mx < array[i]:
			mx = array[i]
			idxs = [i]
		elif mx == array[i]:
			idxs.append(i)
	return idxs[randi_range(0, len(idxs) - 1)]

func can_be_int(num):
	return int(num) == num

func to_int_rec(el):
	if typeof(el) == TYPE_REAL and self.can_be_int(el):
		return int(el)
	elif typeof(el) == TYPE_ARRAY:
		for i in range(el.size()):
			el[i] = self.to_int_rec(el[i])
	elif typeof(el) == TYPE_DICTIONARY:
		for k in el.keys():
			el[k] = self.to_int_rec(el[k])
	return el

func read_json(file_path, default={}):
	var file = File.new()
	var data = default
	if file.file_exists(file_path):
		file.open(file_path, file.READ)
		var ret = JSON.parse(file.get_as_text())
		if ret.error == OK:
			data = ret.result
		file.close()
	return data

func save_info(nodes):
	var saveFile = File.new()
	var saveInfo = self.read_json(SAVE_PATH, [])

	var newInfos = {}
	for node in nodes:
		var name = node.get_name()
		var info = node.get_info()
		newInfos[name] = info
	
	saveInfo.append(newInfos)

	saveFile.open(SAVE_PATH, saveFile.WRITE)
	saveFile.store_string(JSON.print(saveInfo))
	saveFile.close()

func sum(array):
	var sum = 0.0
	for el in array:
		sum += el
	return sum

func norm(array):
	var sum = 0.0
	for el in array:
		sum += el * el
	return sqrt(sum)

func normalize(array):
	var norm = self.norm(array)
	for i in range(array.size()):
		array[i] /= norm

func get_character_class(char_name):
	return load("res://Characters/%s/%s.tscn" % [char_name, char_name])