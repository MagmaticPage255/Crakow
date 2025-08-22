extends CharacterBody3D

@export var reaction_time : float = 0.5
@onready var animation_player: AnimationPlayer = $AuxScene/AnimationPlayer
@onready var timer: Timer = $Timer
var dead = false
var gravity = 9.8
var speed = 3.5
@onready var nav = $NavigationAgent3D

func _process(delta):
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y -= 2
	var next_location = nav.get_next_path_position()
	var current_location = global_transform.origin
	var new_velocity = (next_location - current_location).normalized() * speed
	
	velocity = velocity.move_toward(new_velocity,0.25)
	move_and_slide()
	
func target_position(target):
	nav.target_position = target

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
	if dead:return
	timer.stop()
	dead = true
	animation_player.play("StandingReactDeathBackward")
