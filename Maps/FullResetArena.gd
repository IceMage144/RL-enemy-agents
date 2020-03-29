extends "res://Maps/Arena.gd"

func reset(timeout):
	.reset(timeout)
	var main = global.find_entity("main")
	main.change_map(load("res://Maps/PersistenceArena.tscn"))

func _on_character_death(character):
	print(character.name + " lost!")
	self.reset(false)
