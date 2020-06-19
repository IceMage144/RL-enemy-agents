extends Node

signal reloaded_save

const base_dir = "user://"
const ext = ".json"

var cached_data = {}
var save_file = "save_data"

func _ready():
	self.reload_save()

func change_save_file(new_file):
	self.save_file = new_file
	self.reload_save()

func reload_save():
	var loaded = false
	var save_path = self.get_full_save_path()
	var save_file = File.new()
	if save_file.file_exists(save_path):
		save_file.open(save_path, File.READ)
		var parse_res = JSON.parse(save_file.get_as_text())
		# Assert that the JSON is not corrupted
		assert(parse_res.error == OK)
		self.cached_data = parse_res.result
		loaded = true
	save_file.close()
	if GameConfig.get_debug_flag("persistence"):
		if loaded:
			print("Loaded save from %s" % self.save_path)
		else:
			print("Failed to load save from %s" % self.save_path)
	self.emit_signal("reloaded_save")

func delete_data():
	self.cached_data = {}
	self.commit_data()
	if GameConfig.get_debug_flag("persistence"):
		print("Deleted save")

func save_data(key, value):
	self.cached_data[key] = value
	self.commit_data()

func load_data(key):
	if not self.cached_data.has(key):
		return {}
	return self.cached_data[key]

func commit_data():
	var save_path = self.get_full_save_path()
	var save_file = File.new()
	save_file.open(save_path, File.WRITE)
	save_file.store_string(JSON.print(self.cached_data, " "))
	save_file.close()
	if GameConfig.get_debug_flag("persistence"):
		print("Commited changes")

func get_full_save_path():
	return "%s%s%s" % [base_dir, self.save_file, ext]

func has_save():
	return File.new().file_exists(self.get_full_save_path())

func get_save_files_list():
	var dir = Directory.new()
	dir.open(base_dir)
	dir.list_dir_begin(true, true)
	var save_files = []
	var file_name = dir.get_next()
	while file_name != "":
		if file_name.ends_with(ext):
			save_files.append(file_name.get_basename())
		file_name = dir.get_next()
	dir.list_dir_end()
	return save_files