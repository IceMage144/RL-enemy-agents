extends Object

const DATA_BASE_PATH = "res://assets/scripts/data/"

var table = {}
var meta_table = {}

func push(name, val):
	if not self.table.has(name):
		self.table[name] = []
	self.table[name].append(val)

func push_metadata(name, key, data):
	if not self.meta_table.has(name):
		self.meta_table[name] = {}
	self.meta_table[name][key] = data

func avg(name):
	if not self.table.has(name) or self.table[name].size() == 0:
		return 0.0
	return global.sum(self.table[name]) / self.table[name].size()

func max(name):
	if not self.table.has(name):
		return 0.0
	return global.max(self.table[name])

func min(name):
	if not self.table.has(name):
		return 0.0
	return global.min(self.table[name])

func sum(name):
	if not self.table.has(name) or self.table[name].size() == 0:
		return 0.0
	return global.sum(self.table[name])

func flush(name):
	self.table[name] = []

func size(name):
	return self.table[name].size()

func print_stats(name, stats_list):
	if not self.table.has(name):
		return
	print(name + " (" + str(self.size(name)) + " values):")
	for stat in stats_list:
		if self.has_method(stat):
			print("\t" + stat + ": " + str(callv(stat, [name])))

func get_stored(name):
	if not self.table.has(name):
		return []
	return self.table[name]

func get_metadata(name, key, default=null):
	if not self.meta_table.has(name) or not self.meta_table[name].has(key):
		return default
	return self.meta_table[name][key]

func save_to_csv(name, file_name):
	var save_file = File.new()
	file_name = DATA_BASE_PATH + file_name
	file_name = self.find_unused_file_name(file_name, ".csv")

	save_file.open(file_name, File.WRITE)
	var data = self.get_stored(name)

	var order = self.get_metadata(name, "order", [])
	if data.size() != 0 and order.size() != data[0].size():
		order = data[0].keys()

	var header = ""
	for i in range(order.size()):
		header = header + str(order[i])
		if i != order.size() - 1:
			header = header + ","
	save_file.store_line(header)

	for el in data:
		# Assert that values are dictionaries
		assert(typeof(el) == TYPE_DICTIONARY)
		var line = ""
		for i in range(order.size()):
			var str_var
			if typeof(el[order[i]]) == TYPE_REAL:
				str_var = "%.12f" % el[order[i]]
			else:
				str_var = str(el[order[i]])
			line = line + str_var
			if i != order.size() - 1:
				line = line + ","
		save_file.store_line(line)
	save_file.close()

	if GameConfig.get_debug_flag("persistence"):
		print("Saved " + name + " values into file " + file_name)

func save_to_json(name, file_name):
	var save_file = File.new()
	file_name = DATA_BASE_PATH + file_name
	file_name = self.find_unused_file_name(file_name, ".json")
	save_file.open(file_name, File.WRITE)

	var table = {}
	for el in self.get_stored(name):
		# Assert that values are arrays
		assert(typeof(el) == TYPE_ARRAY)
		# Assert that first elements are strings
		assert(typeof(el[0]) == TYPE_STRING)
		table[el[0]] = el[1]

	save_file.store_string(JSON.print(table, " "))
	save_file.close()

	if GameConfig.get_debug_flag("persistence"):
		print("Saved " + name + " values into file " + file_name)

func find_unused_file_name(file_name, extension):
	var save_file = File.new()
	if save_file.file_exists(file_name + extension):
		var idx = 0
		var new_file_name = file_name
		while save_file.file_exists(new_file_name + extension):
			idx += 1
			new_file_name = file_name + "(" + str(idx) + ")"
		file_name = new_file_name
	return file_name + extension