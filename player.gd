extends CharacterBody3D

@onready var target=$Player

func _process(delta):
	get_tree().call_group("Enemy", "target_position", target.global_transform.origin)
