extends Control



func _on_volume_value_changed(value: float) -> void:
	pass # Replace with function body.



func _on_resolution_item_selected(index: int) -> void:
	match index:
		0:
			DisplayServer.window_set_size(Vector2i(1920,1080))
		1:
			DisplayServer.window_set_size(Vector2i(1152,648))
