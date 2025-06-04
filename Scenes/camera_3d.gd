extends Camera3D

@export var sensitivity: float = 0.003
@export var smoothing: float = 0.1
@export var max_pitch: float = 90.0
@export var min_pitch: float = -90.0

var target_rotation := Vector2.ZERO  # x = yaw, y = pitch
var current_rotation := Vector2.ZERO

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _input(event):
	print("mouse move")
	if event is InputEventMouseMotion:
		target_rotation.x -= event.relative.x * sensitivity
		target_rotation.y -= event.relative.y * sensitivity
		target_rotation.y = clamp(target_rotation.y, deg_to_rad(min_pitch), deg_to_rad(max_pitch))


func _process(delta):
	# Smoothly interpolate to target rotation
	current_rotation = lerp(current_rotation, target_rotation, smoothing)

	# Apply pitch to camera (up/down)
	rotation.x = current_rotation.y
	if Input.is_action_just_pressed("hide"):
		$AnimationPlayer.play("duck")
	if Input.is_action_just_released("hide"):
		$AnimationPlayer.play_backwards("duck")

	# Apply yaw to parent (left/right)
	if get_parent():
		get_parent().rotation.y = current_rotation.x
