extends Node3D

## Simple tree representation on a hex tile
@export var hex_col: int = 0  ## Column position in hex grid
@export var hex_row: int = 0  ## Row position in hex grid
@export var trunk_height: float = 0.3  ## Height of tree trunk
@export var trunk_width: float = 0.05  ## Width of tree trunk
@export var leaves_size: float = 0.2  ## Size of leaves/foliage
@export var trunk_color: Color = Color(0.4, 0.25, 0.15, 1.0)  ## Brown trunk color
@export var leaves_color: Color = Color(0.2, 0.6, 0.2, 1.0)  ## Green leaves color

@onready var hex_grid: MeshInstance3D = get_node("../HexagonGrid")

func _ready():
	# Wait for hex grid to be ready, then create and position the tree
	call_deferred("_create_tree")

func _create_tree():
	if not hex_grid:
		return
	
	# Ensure the tree is placed on land, not water
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
	
	# Position the tree node at the hex center
	position = Vector3(center_x, base_y, center_z)
	
	# Create tree components
	_create_tree_mesh()

func _create_tree_mesh():
	# Create trunk
	var trunk = MeshInstance3D.new()
	var trunk_mesh = BoxMesh.new()
	trunk_mesh.size = Vector3(trunk_width, trunk_height, trunk_width)
	trunk.mesh = trunk_mesh
	
	var trunk_material = StandardMaterial3D.new()
	trunk_material.albedo_color = trunk_color
	trunk_material.metallic = 0.0
	trunk_material.roughness = 0.9
	trunk.material_override = trunk_material
	
	# Position trunk so it sits on the hex tile
	trunk.position = Vector3(0, trunk_height * 0.5, 0)
	add_child(trunk)
	
	# Create leaves (simple sphere or box on top)
	var leaves = MeshInstance3D.new()
	var leaves_mesh = BoxMesh.new()
	leaves_mesh.size = Vector3(leaves_size, leaves_size, leaves_size)
	leaves.mesh = leaves_mesh
	
	var leaves_material = StandardMaterial3D.new()
	leaves_material.albedo_color = leaves_color
	leaves_material.metallic = 0.0
	leaves_material.roughness = 0.8
	leaves.material_override = leaves_material
	
	# Position leaves on top of trunk
	leaves.position = Vector3(0, trunk_height + leaves_size * 0.5, 0)
	add_child(leaves)
	
	# Add slight random rotation for variety
	rotation.y = randf_range(0.0, TAU)

