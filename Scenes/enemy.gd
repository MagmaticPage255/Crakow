extends CharacterBody3D

@export var reaction_time : float = 0.5
@onready var animation_player: AnimationPlayer = $AuxScene/AnimationPlayer
@onready var timer: Timer = $Timer
var dead = false
func _ready():
	animation_player.play("SadIdle")
	timer.start()




func _on_timer_timeout() -> void:
	if dead:return
	animation_player.play("Shooting",reaction_time)
	await animation_player.animation_finished
	if dead:return
	animation_player.play("SadIdle",0.2)
	timer.wait_time = randi_range(1,3)
	timer.start()

func hit():
	timer.stop()
	dead = true
	animation_player.play("StandingReactDeathBackward")
