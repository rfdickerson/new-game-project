extends Node3D

## City representation with multiple buildings on a hex tile
@export var hex_col: int = 5  ## Column position in hex grid
@export var hex_row: int = 5  ## Row position in hex grid
@export var building_count: int = 6  ## Number of buildings in the city
@export var base_building_size: float = 0.15  ## Base size of buildings
@export var city_color: Color = Color(0.7, 0.5, 0.3, 1.0)  ## Brownish city color
@export var color_variation: float = 0.2  ## Color variation between buildings

@onready var hex_grid: MeshInstance3D = get_node("../HexagonGrid")

func _ready():
	# Wait for hex grid to be ready, then create and position the city
	# Use call_deferred to ensure hex grid has finished generating
	call_deferred("_create_city")

func _create_city():
	if not hex_grid:
		return
	
	# Ensure the city is placed on land, not water
	var land_hex = hex_grid.find_nearby_land_hex(hex_col, hex_row)
	hex_col = land_hex.x
	hex_row = land_hex.y
	
	# Use the same positioning math as hexagon_grid.gd
	var hex_radius = hex_grid.hex_radius
	var hex_width = sqrt(3.0) * hex_radius
	var hex_height_2d = 2.0 * hex_radius
	var horizontal_spacing = hex_width
	var vertical_spacing = hex_height_2d * 0.75
	
	# Calculate hexagon center position
	var x_offset = 0.0
	if hex_row % 2 == 1:  # Offset odd rows for hexagonal pattern
		x_offset = horizontal_spacing * 0.5
	
	var center_x = hex_col * horizontal_spacing + x_offset
	var center_z = hex_row * vertical_spacing
	
	# Center the position (same as hex grid does)
	center_x -= (hex_grid.grid_width * horizontal_spacing) * 0.5
	center_z -= (hex_grid.grid_height * vertical_spacing) * 0.5
	
	# Calculate base Y position (on top of hex tile)
	var hex_height = hex_grid.hex_height
	var hex_grid_y_offset = hex_grid.position.y  # Should be 0.5
	var base_y = hex_grid_y_offset + 0.08 + hex_height * 0.5
	
	# Position the city node at the hex center
	position = Vector3(center_x, base_y, center_z)
	
	# Create multiple buildings
	_create_buildings()

func _create_buildings():
	# Create buildings arranged in a city-like pattern
	var hex_radius = hex_grid.hex_radius
	var max_offset = hex_radius * 0.6  # Keep buildings within hex bounds
	
	# Create buildings with varying sizes and positions
	for i in range(building_count):
		var building = MeshInstance3D.new()
		
		# Vary building size (some taller, some wider)
		var size_variation = randf_range(0.7, 1.4)
		var width = base_building_size * randf_range(0.8, 1.2) * size_variation
		var depth = base_building_size * randf_range(0.8, 1.2) * size_variation
		var height = base_building_size * randf_range(1.0, 2.5) * size_variation
		
		# Create box mesh
		var box_mesh = BoxMesh.new()
		box_mesh.size = Vector3(width, height, depth)
		building.mesh = box_mesh
		
		# Create material with slight color variation
		var material = StandardMaterial3D.new()
		var color_variation_amount = randf_range(-color_variation, color_variation)
		var building_color = Color(
			clamp(city_color.r + color_variation_amount, 0.0, 1.0),
			clamp(city_color.g + color_variation_amount, 0.0, 1.0),
			clamp(city_color.b + color_variation_amount, 0.0, 1.0),
			city_color.a
		)
		material.albedo_color = building_color
		material.metallic = 0.1
		material.roughness = 0.7
		building.material_override = material
		
		# Position building randomly within hex bounds
		var angle = randf() * TAU  # Random angle
		var distance = randf_range(0.0, max_offset)  # Random distance from center
		var x_pos = cos(angle) * distance
		var z_pos = sin(angle) * distance
		
		# Position building so it sits on the hex tile
		var y_pos = height * 0.5
		building.position = Vector3(x_pos, y_pos, z_pos)
		
		# Add slight random rotation for variety
		building.rotation.y = randf_range(-0.1, 0.1)
		
		add_child(building)

