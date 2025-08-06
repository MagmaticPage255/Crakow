extends Control

@onready var Music = $AudioStreamPlayer2D




func _on_button_2_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/options.tscn")
	pass
	



func _on_button_3_pressed() -> void:
	#get_tree().quit()
	pass


func _on_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/TestFPS.tscn")


func _on_play_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/DrivingTestWorld.tscn")
	pass # Replace with function body.
