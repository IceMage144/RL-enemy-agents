extends "res://Persistence/ModelBase.gd"

const DEFAULT_PARAMS_PATH = "res://assets/data/default_ais.json"

const PARAMS = "params"

func _get_tag():
	return "ia"

func _get_model():
	var model_file = File.new()
	model_file.open(DEFAULT_PARAMS_PATH, File.READ)
	var parse_res = JSON.parse(model_file.get_as_text())
	var default_params = {}
	if parse_res.error == OK:
		default_params = parse_res.result
	model_file.close()

	return {
		PARAMS: {
			"type": TYPE_DICTIONARY,
			"default": default_params
		}
	}

func get_params(key):
	var params_dict = self.get_data(PARAMS)
	if GameConfig.get_debug_flag("persistence"):
		print("Loaded " + key + " params")
	if not params_dict.has(key):
		return null
	return params_dict[key]

func set_params(key, value):
	var params_dict = self.get_data(PARAMS)
	params_dict[key] = value
	self.set_data(PARAMS, params_dict)
	if GameConfig.get_debug_flag("persistence"):
		print("Saved " + key + " params")

func get_keys_list():
	var params_dict = self.get_data(PARAMS)
	return params_dict.keys()

func clear_models():
	self.set_data(PARAMS, {})
