extends Node

signal reloaded_save

var cached_data = {}
var save_path = "user://save_data.json"

func _ready():
	self.reload_save()

func change_save_file(new_file):
	self.save_path = "user://%s.json" % new_file
	self.reload_save()

func reload_save():
	var save_file = File.new()
	if save_file.file_exists(save_path):
		save_file.open(save_path, File.READ)
		var parse_res = JSON.parse(save_file.get_as_text())
		# Assert that the JSON is not corrupted
		assert(parse_res.error == OK)
		self.cached_data = parse_res.result
	save_file.close()
	if GameConfig.get_debug_flag("persistence"):
		print("Loaded save from %s" % self.save_path)
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
	var save_file = File.new()
	save_file.open(save_path, File.WRITE)
	save_file.store_string(JSON.print(self.cached_data, " "))
	save_file.close()
	if GameConfig.get_debug_flag("persistence"):
		print("Commited changes")

func has_save():
	return File.new().file_exists(save_path)