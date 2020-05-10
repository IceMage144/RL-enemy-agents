extends "res://UI/Popups/PopupBase.gd"

func _ready():
	get_tree().paused = true

func _process(_delta):
	if Input.is_action_just_pressed("pause"):
		get_tree().paused = false
		self.queue_free()

func _on_SaveData_pressed():
	for ai in get_tree().get_nodes_in_group("produce_analysis"):
		ai.save_analysis()
