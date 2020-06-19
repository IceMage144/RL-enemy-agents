extends "res://Characters/AIs/BTAI.gd"

const IdleBT = preload("res://Characters/AIs/IdleBT.tscn")

func init(params):
	.init(params)
	self.bt = IdleBT.instance()
	self.add_child(self.bt)

# Print some variables for debug here
func _on_DebugTimer_timeout():
	._on_DebugTimer_timeout()