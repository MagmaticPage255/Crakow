extends Area3D

const ROTSPEED = deg_to_rad(5)

func _ready():
	pass



func _process(delta):
	rotate_y(ROTSPEED)


func _on_body_entered(body: Node3D) -> void:
	pass # Replace with function body.
