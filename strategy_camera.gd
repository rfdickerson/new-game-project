extends Camera3D

## Camera controller optimized for strategy tile games like Civilization or Settlers of Catan
## Provides smooth isometric-style camera controls

@export var camera_distance: float = 5.0  ## Distance from target
@export var camera_height: float = 4.0  ## Height above ground
@export var camera_angle: float = 45.0  ## Angle from horizontal (degrees)
@export var rotation_speed: float = 60.0  ## Degrees per second
@export var pan_speed: float = 10.0  ## Units per second
@export var zoom_speed: float = 5.0  ## Units per second
@export var min_distance: float = 2.0
@export var max_distance: float = 40.0
@export var min_height: float = 2.0
@export var max_height: float = 25.0

var target_position: Vector3 = Vector3.ZERO
var current_rotation: float = 0.0  # Rotation around Y axis (degrees)
var is_dragging: bool = false
var last_mouse_position: Vector2 = Vector2.ZERO

func _ready():
	_update_camera_position()

func _input(event):
	# Handle mouse wheel zoom
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			camera_distance = clamp(camera_distance - zoom_speed * 0.5, min_distance, max_distance)
			camera_height = clamp(camera_height - zoom_speed * 0.3, min_height, max_height)
			_update_camera_position()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			camera_distance = clamp(camera_distance + zoom_speed * 0.5, min_distance, max_distance)
			camera_height = clamp(camera_height + zoom_speed * 0.3, min_height, max_height)
			_update_camera_position()
		# Handle mouse button press/release for drag panning
		elif event.button_index == MOUSE_BUTTON_LEFT or event.button_index == MOUSE_BUTTON_MIDDLE:
			if event.pressed:
				is_dragging = true
				last_mouse_position = event.position
			else:
				is_dragging = false
	
	# Handle mouse movement for drag panning
	if event is InputEventMouseMotion:
		if is_dragging:
			var mouse_delta = last_mouse_position - event.position
			# Convert mouse movement to pan direction
			var pan_direction = Vector2(mouse_delta.x, mouse_delta.y)
			# Rotate pan direction based on camera rotation
			var rotation_rad = deg_to_rad(current_rotation)
			var rotated_pan = Vector3(
				pan_direction.x * cos(rotation_rad) - pan_direction.y * sin(rotation_rad),
				0,
				pan_direction.x * sin(rotation_rad) + pan_direction.y * cos(rotation_rad)
			)
			# Apply panning with sensitivity
			var pan_sensitivity = pan_speed * 0.01  # Adjust sensitivity as needed
			target_position += rotated_pan * pan_sensitivity
			_update_camera_position()
			last_mouse_position = event.position

func _process(delta):
	var input_rotation = 0.0
	var input_pan = Vector2.ZERO
	var input_zoom = 0.0
	
	# Rotation (Q/E keys or mouse drag)
	if Input.is_action_pressed("ui_left") or Input.is_key_pressed(KEY_Q):
		input_rotation = -1.0
	if Input.is_action_pressed("ui_right") or Input.is_key_pressed(KEY_E):
		input_rotation = 1.0
	
	# Panning (WASD or arrow keys)
	if Input.is_action_pressed("ui_up") or Input.is_key_pressed(KEY_W):
		input_pan.y = -1.0
	if Input.is_action_pressed("ui_down") or Input.is_key_pressed(KEY_S):
		input_pan.y = 1.0
	if Input.is_key_pressed(KEY_A):
		input_pan.x = -1.0
	if Input.is_key_pressed(KEY_D):
		input_pan.x = 1.0
	
	# Zoom (keyboard +/- keys)
	if Input.is_key_pressed(KEY_KP_ADD) or Input.is_key_pressed(KEY_EQUAL):
		input_zoom = 1.0
	if Input.is_key_pressed(KEY_KP_SUBTRACT) or Input.is_key_pressed(KEY_MINUS):
		input_zoom = -1.0
	
	# Apply rotation
	if input_rotation != 0.0:
		current_rotation += input_rotation * rotation_speed * delta
	
	# Apply panning
	if input_pan.length() > 0.0:
		var pan_direction = Vector3(input_pan.x, 0, input_pan.y)
		# Rotate pan direction based on camera rotation
		var rotation_rad = deg_to_rad(current_rotation)
		var rotated_pan = Vector3(
			pan_direction.x * cos(rotation_rad) - pan_direction.z * sin(rotation_rad),
			0,
			pan_direction.x * sin(rotation_rad) + pan_direction.z * cos(rotation_rad)
		)
		target_position += rotated_pan * pan_speed * delta
	
	# Apply zoom
	if input_zoom != 0.0:
		camera_distance = clamp(camera_distance + input_zoom * zoom_speed * delta, min_distance, max_distance)
		camera_height = clamp(camera_height + input_zoom * zoom_speed * delta * 0.6, min_height, max_height)
	
	_update_camera_position()

func _update_camera_position():
	# Calculate camera position based on target, distance, height, and angle
	var angle_rad = deg_to_rad(camera_angle)
	var rotation_rad = deg_to_rad(current_rotation)
	
	# Calculate horizontal distance from target
	var horizontal_distance = camera_distance * cos(angle_rad)
	var vertical_offset = camera_distance * sin(angle_rad)
	
	# Calculate position
	var camera_pos = Vector3(
		target_position.x + horizontal_distance * sin(rotation_rad),
		target_position.y + camera_height + vertical_offset,
		target_position.z + horizontal_distance * cos(rotation_rad)
	)
	
	global_position = camera_pos
	look_at(target_position, Vector3.UP)

func set_target(new_target: Vector3):
	"""Set the camera target position"""
	target_position = new_target
	_update_camera_position()
