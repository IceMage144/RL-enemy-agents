extends CanvasLayer

signal popup_closed

func init(params):
	pass

func close_popup():
	emit_signal("popup_closed")