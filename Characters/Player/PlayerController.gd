extends Node

var color = Color(1.0, 1.0, 1.0, 1.0)
var velocity = Vector2()

onready var parent = self.get_parent()

func _process(delta):
	self.velocity = Vector2()
	if Input.is_action_pressed("ui_up"):
		self.velocity.y = -1
	if Input.is_action_pressed("ui_down"):
		self.velocity.y = 1
	if Input.is_action_pressed("ui_left"):
		self.velocity.x = -1
	if Input.is_action_pressed("ui_right"):
		self.velocity.x = 1
	self.velocity = self.velocity.normalized()
	
	if Input.is_action_just_pressed("ui_accept"):
		self.parent.attack()

func end():
	pass

func before_reset(timeout):
	pass

func reset(timeout):
	pass

func after_reset(timeout):
	pass