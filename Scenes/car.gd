extends CharacterBody3D

# Exported variables for easy tweaking in the editor
@export var acceleration: float = 10.0  # Reduced to prevent runaway speed
@export var max_speed: float = 20.0
@export var rotation_speed: float = 2.0
@export var tilt_angle: float = 15.0
@export var tilt_speed: float = 5.0
@export var drift_factor: float = 0.9  # Controls how much the car slides
@export var traction: float = 0.1     # How quickly the car corrects lateral slide

# Reference to the mesh for tilting
@onready var car_mesh: Node3D= $CarMesh

# Current movement variables
var current_speed: float = 0.0
var tilt_target: float = 0.0
var lateral_velocity: Vector3 = Vector3.ZERO

func _ready() -> void:
	# Ensure physics properties are set to allow movement
	floor_snap_length = 0.1
	floor_stop_on_slope = false
	if not car_mesh:
		push_warning("CarMesh node not found. Please assign a MeshInstance3D node named 'CarMesh'.")
	print("Car initialized. Position: ", global_position, " Forward: ", -global_transform.basis.z)

func _physics_process(delta: float) -> void:
	# Handle input
	var input_dir: float = Input.get_axis("ui_right", "ui_left")
	var accel_input: float = Input.get_axis("ui_down", "ui_up")

	# Handle rotation
	if input_dir != 0:
		rotate_y(input_dir * rotation_speed * delta)
		tilt_target = -input_dir * tilt_angle
	else:
		tilt_target = 0.0

	# Handle acceleration
	if accel_input > 0:
		current_speed += acceleration * delta
		current_speed = min(current_speed, max_speed)
	else:
		current_speed -= acceleration * delta * 0.5
		current_speed = max(current_speed, 0.0)

	# Calculate forward velocity
	var forward_direction = global_transform.basis.z.normalized()
	var forward_velocity = forward_direction * current_speed

	# Apply drift
	lateral_velocity = lerp(lateral_velocity, Vector3.ZERO, traction * delta)
	velocity = forward_velocity * (1.0 - drift_factor) + lateral_velocity * drift_factor

	# Add small upward velocity to prevent sticking
	velocity.y = 0.1 if is_on_floor() else velocity.y

	# Update lateral velocity for drift
	var local_velocity = global_transform.basis.inverse() * velocity
	lateral_velocity = global_transform.basis * Vector3(local_velocity.x, 0, 0)

	# Debug print
	print("Input: ", accel_input, " Speed: ", current_speed, " Velocity: ", velocity, " Position: ", global_position)

	# Apply movement
	var prev_position = global_position
	move_and_slide()
	if global_position.distance_to(prev_position) < 0.01 and velocity.length() > 0:
		print("Warning: Car not moving! Velocity: ", velocity, " Collisions: ", get_slide_collision_count())

	# Handle mesh tilting
	if car_mesh:
		var current_tilt = car_mesh.rotation_degrees.z
		var new_tilt = lerp(current_tilt, tilt_target, tilt_speed * delta)
		car_mesh.rotation_degrees.z = new_tilt

# Scene setup for export
func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray = []
	if not car_mesh:
		warnings.append("CarMesh node not found. Please assign a MeshInstance3D node named 'CarMesh'.")
	return warnings
