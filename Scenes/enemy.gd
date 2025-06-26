extends CharacterBody3D

@export var reaction_time : float = 0.5
@onready var animation_player: AnimationPlayer = $AuxScene/AnimationPlayer
@onready var timer: Timer = $Timer

func _ready():
	animation_player.play("SadIdle")
	timer.start()




func _on_timer_timeout() -> void:
	animation_player.play("Shooting",reaction_time)
	await animation_player.animation_finished
	animation_player.play("SadIdle",0.2)
	timer.wait_time = randi_range(1,3)
	timer.start()

func hit():
	timer.stop()
	animation.play
