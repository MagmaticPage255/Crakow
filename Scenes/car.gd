extends RigidBody3D

@onready var speed_label = $CanvasLayer/Label

# Movement parameters for acceleration and speed
@export_group("Movement")
@export var acceleration: float = 300.0  # Forward acceleration force (N)
@export var brake_acceleration: float = 450.0  # Braking/reverse force (N)
@export var max_speed: float = 40.0  # Maximum forward speed (m/s)
@export var reverse_speed: float = 20.0  # Maximum reverse speed (m/s)
@export var traction: float = 4.0  # Ground traction multiplier for snappy handling

# Steering parameters for turning and visual tilt
@export_group("Steering")
@export var steering: float = 25.0  # Steering angle (degrees)
@export var turn_speed: float = 6.0  # Turning speed (rad/s)
@export var turn_stop_limit: float = 0.5  # Minimum speed for turning (m/s)
@export var body_tilt: float = 200.0  # Maximum body tilt during turns (degrees)
@export var drift_boost: float = 0.2  # Upward force during sharp turns for arcade feel

# Drift parameters for sliding in tight turns
@export_group("Drift")
@export var drift_turn_threshold: float = 0.8  # Min turn_input for drift (0 to 1)
@export var drift_time_threshold: float = 0.3  # Min turn duration for drift (s)
@export var drift_lateral_damping: float = 2.0  # Reduced lateral damping during drift
@export var drift_tilt_multiplier: float = 1.5  # Extra body tilt during drift

# Jump parameters for aerial mechanics
@export_group("Jump")
@export var jump_force: float = 500.0  # Upward impulse for jumps (N)
@export var jump_cooldown: float = 0.5  # Cooldown between jumps (seconds)

# Physics parameters for mass and damping
@export_group("Physics")
@export var sphere_offset: Vector3 = Vector3(0, -1, 0)  # Offset for CarMesh relative to sphere
@export var custom_mass: float = 75.0  # Mass of the vehicle (kg)
@export var custom_drag: float = 0.15  # Linear damping for air resistance
@export var custom_angular_damping: float = 0.5  # Angular damping for rotation
@export var lateral_damping: float = 10.0  # Normal lateral velocity damping
@export var collision_damping: float = 5.0  # Damping for collision impulses

# Ground detection settings
@export_group("Ground")
@export var ground_layer: int = 1  # Collision layer for ground detection

# Node references for car components
@export_group("Meshes")
@export var car_mesh: Node3D  # Node for car orientation
@export var body_mesh: Node3D # Car body mesh
@export var left_wheel: Node3D  # Left front wheel mesh
@export var right_wheel:  Node3D  # Right front wheel mesh
@export var ground_ray: RayCast3D  # Raycast for ground detection

var speed_input: float = 0.0  # Current acceleration input
var turn_input: float = 0.0  # Current steering input
var jump_timer: float = 0.0  # Cooldown timer for jumps
var is_grounded: bool = false  # Whether the car is on the ground
var is_drifting: bool = false  # Whether the car is drifting
var turn_duration: float = 0.0  # Duration of current turn (s)

# Initialize physics properties and check node assignments
func _ready() -> void:
	mass = custom_mass
	linear_damp = custom_drag
	angular_damp = custom_angular_damping
	# Set physics material with low bounce and moderate friction
	physics_material_override = PhysicsMaterial.new()
	physics_material_override.friction = 0.5
	physics_material_override.bounce = 0.0
	
	# Validate node assignments
	if not car_mesh:
		push_error("Error: car_mesh not assigned!")
	if not body_mesh:
		push_error("Error: body_mesh not assigned!")
	if not ground_ray:
		push_error("Error: ground_ray not assigned!")
	if not right_wheel:
		push_error("Error: right_wheel not assigned!")
	if not left_wheel:
		push_error("Error: left_wheel not assigned!")
	
	# Configure ground ray to ignore the car
	if ground_ray:
		ground_ray.add_exception(self)
	
	# Connect collision signal
	body_entered.connect(_on_body_entered)

# Update input, visuals, and car orientation
func _process(delta: float) -> void:
	if not car_mesh:
		return
	
	# Check if grounded
	is_grounded = ground_ray.is_colliding() if ground_ray else false
	
	# Process input when grounded
	if is_grounded:
		var accel_axis = Input.get_axis("up", "down")
		speed_input = accel_axis * (acceleration if accel_axis >= 0 else brake_acceleration)
		turn_input = Input.get_axis("right", "left") * deg_to_rad(steering)
		
		# Update drift state
		if abs(turn_input) > drift_turn_threshold * deg_to_rad(steering) and linear_velocity.length() > turn_stop_limit:
			turn_duration += delta
			if turn_duration >= drift_time_threshold:
				is_drifting = true
		else:
			turn_duration = 0.0
			is_drifting = false
		
		# Rotate wheel visuals
		if right_wheel:
			right_wheel.rotation.y = turn_input
		if left_wheel:
			left_wheel.rotation.y = turn_input
		
		# Handle jump input
		if Input.is_action_just_pressed("jump") and jump_timer <= 0.0:
			apply_central_impulse(Vector3.UP * jump_force)
			jump_timer = jump_cooldown
	
	# Update jump cooldown
	if jump_timer > 0.0:
		jump_timer -= delta
	
	# Position car mesh relative to sphere
	car_mesh.position = position + sphere_offset
	
	# Apply steering and body tilt when moving
	if is_grounded and linear_velocity.length() > turn_stop_limit:
		var new_basis = car_mesh.global_transform.basis.rotated(car_mesh.global_transform.basis.y, turn_input)
		car_mesh.global_transform.basis = car_mesh.global_transform.basis.slerp(new_basis, turn_speed * delta)
		car_mesh.global_transform = car_mesh.global_transform.orthonormalized()
		if body_mesh:
			var tilt = turn_input * linear_velocity.length() / body_tilt
			if is_drifting:
				tilt *= drift_tilt_multiplier  # Extra tilt for drift
			body_mesh.rotation.z = lerp(body_mesh.rotation.z, tilt, 5.0 * delta)
	
	# Align car mesh with ground normal
	if is_grounded and ground_ray:
		var normal = ground_ray.get_collision_normal()
		var xform = align_with_y(car_mesh.global_transform, normal)
		car_mesh.global_transform = car_mesh.global_transform.interpolate_with(xform, 10.0 * delta)
		

	var speed = linear_velocity.length()
	speed_label.text = "Speed: %.2f m/s" % speed

	#car_mesh.scale = Vector3(1.4,1.4,1.4)
# Apply physics forces for movement and drift
func _physics_process(delta: float) -> void:
	if not car_mesh:
		return
	
	# Calculate forward direction and velocity
	var forward = -car_mesh.global_transform.basis.z.normalized()
	var right = car_mesh.global_transform.basis.x.normalized()
	var up = car_mesh.global_transform.basis.y.normalized()
	var forward_velocity = linear_velocity.dot(forward)
	var lateral_velocity = linear_velocity.dot(right)
	var vertical_velocity = linear_velocity.dot(up)
	
	# Apply movement force with proportional speed cap
	var force = forward * speed_input * traction
	if speed_input > 0 and forward_velocity > max_speed:
		var excess_speed = forward_velocity - max_speed
		force *= clamp(1.0 - excess_speed / max_speed, 0.0, 1.0)
	elif speed_input < 0 and forward_velocity < -reverse_speed:
		var excess_speed = -forward_velocity - reverse_speed
		force *= clamp(1.0 - excess_speed / reverse_speed, 0.0, 1.0)
	
	# Apply lateral damping, reduced during drift
	if is_grounded:
		var current_lateral_damping = drift_lateral_damping if is_drifting else lateral_damping
		var lateral_force = -right * lateral_velocity * current_lateral_damping * mass
		apply_central_force(lateral_force)
	
	# Debug prints to verify drift and physics
	#ww
	
	apply_central_force(force)
	
	# Apply upward drift boost during sharp turns or drifting
	if is_grounded and abs(turn_input) > 0.1 and linear_velocity.length() > turn_stop_limit:
		apply_central_force(Vector3.UP * drift_boost * abs(turn_input) * mass)
		
	#car_mesh.scale = Vector3(1.4,1.4,1.4)

# Handle collisions to reduce bounciness
func _on_body_entered(body: Node) -> void:
	if body.is_in_group("environment"):
		var up = car_mesh.global_transform.basis.y.normalized()
		var vertical_velocity = linear_velocity.dot(up)
		var damping_force = -linear_velocity * collision_damping * mass
		apply_central_force(damping_force)
		#print("Collision with: ", body.name, " Vertical Velocity: ", vertical_velocity)

# Align transform's Y-axis with a given normal
func align_with_y(xform: Transform3D, new_y: Vector3) -> Transform3D:
	xform.basis.y = new_y
	xform.basis.x = -xform.basis.z.cross(new_y)
	return xform.orthonormalized()
