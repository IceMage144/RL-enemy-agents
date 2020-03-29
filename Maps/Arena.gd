extends Node2D

const GRAPH_FREQUENCY = 10

var tile_size = 32
var rounds = 0

onready var arena_width = 27 * self.tile_size
onready var arena_height = 13 * self.tile_size

func _ready():
	for character in self.get_tree().get_nodes_in_group("character"):
		character.position = self._rand_pos()
		character.connect("character_death", self, "_on_character_death", [character])
		character.init({
			"network_id": character.name
		})

func init(params):
	pass

func print_info():
	var loss_info = {}
	print("------------")
	for character in self.get_tree().get_nodes_in_group("robot"):
		var team = global.get_team(character)
		var pretty_name = character.get_pretty_name()
		print(pretty_name + ": " + str(character.life) + " (" + team + ")")
		loss_info[pretty_name] = character.controller.get_loss()

	# if self.rounds % GRAPH_FREQUENCY == 0:
		# Plot loss

func reset(timeout):
	self.rounds += 1
	if GameConfig.get_debug_flag("environment"):
		self.print_info()
	# self.get_parent().reset_game()
	var characters = self.get_tree().get_nodes_in_group("character")
	for character in characters:
		character.before_reset(timeout)
	for character in characters:
		character.position = self._rand_pos()
		character.reset(timeout)
	for character in characters:
		character.after_reset(timeout)
	for character in characters:
		character.end()

func _rand_pos():
	var off = 2 * self.tile_size
	var xPos = off + self.arena_width * randf()
	var yPos = off + self.arena_height * randf()
	return Vector2(xPos, yPos)

func _on_character_death(character):
	$TimeoutTimer.start()
	print(character.name + " lost!")
	self.reset(false)

func _on_TimeoutTimer_timeout():
	self.reset(true)
	print("Timeout!")
