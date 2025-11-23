extends MeshInstance3D

## Simple city representation as a cube on a hex tile
@export var hex_col: int = 5  ## Column position in hex grid
@export var hex_row: int = 5  ## Row position in hex grid
@export var city_size: float = 0.3  ## Size of the city cube
@export var city_color: Color = Color(0.7, 0.5, 0.3, 1.0)  ## Brownish city color

@onready var hex_grid: MeshInstance3D = get_node("../HexagonGrid")

func _ready():
	# Create a simple cube mesh
	var box_mesh = BoxMesh.new()
	box_mesh.size = Vector3(city_size, city_size, city_size)
	mesh = box_mesh
	
	# Create material
	var material = StandardMaterial3D.new()
	material.albedo_color = city_color
	material.metallic = 0.1
	material.roughness = 0.7
	material_override = material
	
	# Wait for hex grid to be ready, then position the city
	# Use call_deferred to ensure hex grid has finished generating
	call_deferred("_update_position")

func _update_position():
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
	
	# Position the city cube on top of the hex tile
	# Hex tiles have a height offset based on terrain type, so we'll place it slightly above
	# Assuming grassland height (y_offset = 0.08) + hex_height/2 + city_size/2
	# Also account for the hex grid's transform offset (0, 0.5, 0)
	var hex_height = hex_grid.hex_height
	var hex_grid_y_offset = hex_grid.position.y  # Should be 0.5
	var base_y = hex_grid_y_offset + 0.08 + hex_height * 0.5 + city_size * 0.5
	
	position = Vector3(center_x, base_y, center_z)

