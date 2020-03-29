extends Node

export(PackedScene) var type
export(String, MULTILINE) var description = ""
export(int) var max_life = 1
export(int) var damage = 1
export(int) var defense = 0

func _ready():
	self.add_to_group("monster")