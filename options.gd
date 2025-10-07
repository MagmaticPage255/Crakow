extends Control


# Reference to a global singleton to store sensitivity (set up in Project Settings > AutoLoad)
# Using "Sensitivity" as the variable name in GlobalSettings

func _ready():

	# Initialize slider value from global sensitivity (optional, for persistence)
	%Sensitivity2.value = GlobalSettings.Sensitivity

func _on_back_button_pressed() -> void:
	hide()
	%PauseMenu.show()

func _on_master_slider_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear_to_db(value))

func _on_music_slider_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), linear_to_db(value))

func _on_sensitivity_2_value_changed(value: float) -> void:
	# Store the sensitivity value in the global singleton
	GlobalSettings.Sensitivity = value
	# Optional: Print for debugging
	print("Mouse sensitivity set to: ", value)
