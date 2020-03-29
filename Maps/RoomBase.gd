extends Node2D

const Hud = preload("res://UI/HUD/Hud.tscn")


func _ready():
	if global.has_entity("camera"):
		var camera = global.find_entity("camera")
		camera.limit_left = $CameraLimits/TopLeftCorner.position.x
		camera.limit_top = $CameraLimits/TopLeftCorner.position.y
		camera.limit_right = $CameraLimits/BottomRightCorner.position.x
		camera.limit_bottom = $CameraLimits/BottomRightCorner.position.y
	if global.has_entity("player"):
		self.add_child_below_node($Ceil, Hud.instance())

func init(params):
	# Room has player and does not received player starting position
	assert(not global.has_entity("player") or params.has("player_pos"))
	if global.has_entity("player"):
		var player = global.find_entity("player")
		if $PlayerSpawners.has_node(params.player_pos):
			var node = $PlayerSpawners.get_node(params.player_pos)
			player.position = node.position
		else:
			# Player spawn position does not exists
			assert(false)