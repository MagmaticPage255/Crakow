extends Label

@onready var objective_label = $CanvasLayer/ObjectiveLabel

func show_objective_complete():
	objective_label.visible = true
	
	await get_tree().create_timer(3.0).timeout
	objective_label.visible = false
