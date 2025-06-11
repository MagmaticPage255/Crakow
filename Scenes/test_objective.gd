extends Area3D

@onready var Vehicle_controller = $Car

func _on_area_entered(area: Area3D) -> void:
	if Vehicle_controller:
		show_objective_complete()
