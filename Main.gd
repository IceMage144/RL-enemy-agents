extends Node

const PauseMenu = preload("res://UI/Menus/PauseMenu.tscn")

enum Scene { ROBOT_ROBOT, PLAYER_ROBOT, PERSISTENCE }

const scene_path = {
	Scene.ROBOT_ROBOT: "res://Maps/RobotRobotArena.tscn",
	Scene.PLAYER_ROBOT: "res://Maps/PlayerRobotArena.tscn",
	Scene.PERSISTENCE: "res://Maps/PersistenceArena.tscn"
}

export(int, "Robot vs Robot test", "Player vs Robot test", "Persistence test") var first_scene = Scene.ROBOT_ROBOT
export(bool) var character_debug = false
export(bool) var environment_debug = false
export(bool) var popup_debug = false
export(bool) var persistence_debug = false

var FirstSceneClass
var current_scene = null
var current_popup = null

func _ready():
	randomize()
	self.FirstSceneClass = load(scene_path[first_scene])
	self._init_debug_flags()
	self.reset_game()
	self._check_persistence_tags()

func _process(_delta):
	if Input.is_action_just_pressed("pause"):
		if self.current_popup != null:
			self.close_popup()
		else:
			var pause_menu = PauseMenu.instance()
			self.add_child(pause_menu)
	# if Input.is_action_just_pressed("rewind"):
	# 	self.reset_game()
	if Input.is_action_just_pressed("test"):
		pass

func _check_persistence_tags():
	var tag_memo = {}
	for node in get_tree().get_nodes_in_group("persistence"):
		var tag = node._get_tag()
		# Assert that no two persistence tags are the same
		assert(not tag_memo.has(tag))
		tag_memo[tag] = true

func _init_debug_flags():
	GameConfig.set_debug_flag("character", self.character_debug)
	GameConfig.set_debug_flag("popup", self.popup_debug)
	GameConfig.set_debug_flag("environment", self.environment_debug)
	GameConfig.set_debug_flag("persistence", self.persistence_debug)

func reset_game():
	self.change_map(self.FirstSceneClass)

func change_map(scene, params=null):
	if self.current_scene:
		self.current_scene.queue_free()
		yield(self.current_scene, "tree_exited")
	self.current_scene = scene.instance()
	self.add_child(self.current_scene)
	self.current_scene.init(params)

func show_popup(popup, params=null):
	if self.current_popup:
		self.current_popup.queue_free()
		yield(self.current_popup, "tree_exited")
	self.current_popup = popup.instance()
	self.current_popup.connect("popup_closed", self, "close_popup")
	self.add_child(self.current_popup)
	self.current_popup.init(params)
	if global.has_entity("player"):
		var player = global.find_entity("player")
		player.block_action()

func close_popup():
	self.current_popup.queue_free()
	self.current_popup = null
	if global.has_entity("player"):
		var player = global.find_entity("player")
		player.unblock_action()