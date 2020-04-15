extends "res://Characters/AIs/BTAI.gd"

const BasicBT = preload("res://Characters/AIs/BasicBT.tscn")

func init(params):
	.init(params)
	self.bt = BasicBT.instance()
	self.add_child(self.bt)

# Print some variables for debug here
func _on_DebugTimer_timeout():
	._on_DebugTimer_timeout()