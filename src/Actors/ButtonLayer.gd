extends CanvasLayer

func _ready() -> void:
	if OS.get_name() == "Android":
		for i in get_children():
			i.visible = true
	else:
		for i in get_children():
			i.visible = false
