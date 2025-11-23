extends Node3D

## Manages multiple trees across the map using instanced rendering
@export var tree_count: int = 300  ## Number of trees to spawn (increased for instanced rendering)
@export var trunk_height: float = 0.3  ## Height of tree trunk
@export var trunk_width: float = 0.05  ## Width of tree trunk
@export var leaves_size: float = 0.2  ## Size of leaves/foliage
@export var trunk_color: Color = Color(0.4, 0.25, 0.15, 1.0)  ## Brown trunk color
@export var leaves_color: Color = Color(0.2, 0.6, 0.2, 1.0)  ## Green leaves color
@export var size_variation: float = 0.3  ## Variation in tree sizes

@onready var hex_grid: MeshInstance3D = get_node("../HexagonGrid")

var trunk_multimesh: MultiMeshInstance3D
var leaves_multimesh: MultiMeshInstance3D

func _ready():
	# Wait for hex grid to be ready, then create trees
	call_deferred("_create_trees")

func _create_trees():
	if not hex_grid:
		print("ForestManager: Hex grid not found!")
		return
	
	# Wait a frame to ensure hex grid has finished generating
	await get_tree().process_frame
	
	# Ensure hex grid has a mesh (meaning it's been generated)
	if not hex_grid.mesh:
		print("ForestManager: Waiting for hex grid to generate...")
		await get_tree().process_frame
		if not hex_grid.mesh:
			print("ForestManager: Hex grid still not ready!")
			return
	
	print("ForestManager: Starting tree creation...")
	print("ForestManager: Grid size: %dx%d" % [hex_grid.grid_width, hex_grid.grid_height])
	
	# Create MultiMeshInstance3D nodes for efficient instanced rendering
	_setup_multimesh()
	
	# Collect all valid tree positions
	var tree_positions: Array[Dictionary] = []
	var attempts = 0
	var max_attempts = tree_count * 20  # Try many times to find land tiles
	
	while tree_positions.size() < tree_count and attempts < max_attempts:
		attempts += 1
		
		# Pick a random hex coordinate
		var col = randi_range(0, hex_grid.grid_width - 1)
		var row = randi_range(0, hex_grid.grid_height - 1)
		
		# Check if this hex is land
		if hex_grid.is_hex_land(col, row):
			var tree_data = _calculate_tree_position(col, row)
			tree_positions.append(tree_data)
	
	print("ForestManager: Found %d land tiles for trees (attempts: %d)" % [tree_positions.size(), attempts])
	
	# Set up the multimesh with all tree instances
	_setup_tree_instances(tree_positions)

func _setup_multimesh():
	# Create trunk multimesh
	trunk_multimesh = MultiMeshInstance3D.new()
	trunk_multimesh.name = "TrunkMultimesh"
	trunk_multimesh.visible = true
	
	var trunk_mesh = BoxMesh.new()
	trunk_mesh.size = Vector3(trunk_width, trunk_height, trunk_width)
	
	var multimesh = MultiMesh.new()
	multimesh.mesh = trunk_mesh
	multimesh.instance_count = 0  # Start with 0, will be set when trees are placed
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	
	var trunk_material = StandardMaterial3D.new()
	trunk_material.albedo_color = trunk_color
	trunk_material.metallic = 0.0
	trunk_material.roughness = 0.9
	
	trunk_multimesh.multimesh = multimesh
	trunk_multimesh.material_override = trunk_material
	add_child(trunk_multimesh)
	
	# Create leaves multimesh
	leaves_multimesh = MultiMeshInstance3D.new()
	leaves_multimesh.name = "LeavesMultimesh"
	leaves_multimesh.visible = true
	
	var leaves_mesh = BoxMesh.new()
	leaves_mesh.size = Vector3(leaves_size, leaves_size, leaves_size)
	
	var leaves_multimesh_resource = MultiMesh.new()
	leaves_multimesh_resource.mesh = leaves_mesh
	leaves_multimesh_resource.instance_count = 0  # Start with 0, will be set when trees are placed
	leaves_multimesh_resource.transform_format = MultiMesh.TRANSFORM_3D
	
	var leaves_material = StandardMaterial3D.new()
	leaves_material.albedo_color = leaves_color
	leaves_material.metallic = 0.0
	leaves_material.roughness = 0.8
	
	leaves_multimesh.multimesh = leaves_multimesh_resource
	leaves_multimesh.material_override = leaves_material
	add_child(leaves_multimesh)
	
	print("ForestManager: MultiMesh nodes created")

func _calculate_tree_position(col: int, row: int) -> Dictionary:
	# Use the same positioning math as hexagon_grid.gd
	var hex_radius = hex_grid.hex_radius
	var hex_width = sqrt(3.0) * hex_radius
	var hex_height_2d = 2.0 * hex_radius
	var horizontal_spacing = hex_width
	var vertical_spacing = hex_height_2d * 0.75
	
	# Calculate hexagon center position
	var x_offset = 0.0
	if row % 2 == 1:  # Offset odd rows for hexagonal pattern
		x_offset = horizontal_spacing * 0.5
	
	var center_x = col * horizontal_spacing + x_offset
	var center_z = row * vertical_spacing
	
	# Center the position (same as hex grid does)
	center_x -= (hex_grid.grid_width * horizontal_spacing) * 0.5
	center_z -= (hex_grid.grid_height * vertical_spacing) * 0.5
	
	# Calculate base Y position (on top of hex tile)
	var hex_height = hex_grid.hex_height
	var hex_grid_y_offset = hex_grid.position.y  # Should be 0.5
	var base_y = hex_grid_y_offset + 0.08 + hex_height * 0.5
	
	# Add random offset within hex for variety
	var hex_radius_for_offset = hex_radius * 0.6
	var angle = randf() * TAU
	var distance = randf_range(0.0, hex_radius_for_offset)
	var x_pos = center_x + cos(angle) * distance
	var z_pos = center_z + sin(angle) * distance
	
	# Calculate size variation
	var size_mult = 1.0 + randf_range(-size_variation, size_variation)
	var tree_trunk_height = trunk_height * size_mult
	var tree_leaves_size = leaves_size * size_mult
	
	# Random rotation
	var rotation_y = randf_range(0.0, TAU)
	
	return {
		"position": Vector3(x_pos, base_y, z_pos),
		"trunk_height": tree_trunk_height,
		"leaves_size": tree_leaves_size,
		"rotation": rotation_y,
		"size_mult": size_mult
	}

func _setup_tree_instances(tree_positions: Array[Dictionary]):
	var actual_count = min(tree_positions.size(), tree_count)
	
	if actual_count == 0:
		print("ForestManager: No trees to create!")
		return
	
	print("ForestManager: Setting up %d tree instances..." % actual_count)
	
	# Update instance count to match actual trees placed
	# This must be done BEFORE setting transforms
	# Create new MultiMesh resources with the correct instance count
	var new_trunk_multimesh = MultiMesh.new()
	new_trunk_multimesh.mesh = trunk_multimesh.multimesh.mesh
	new_trunk_multimesh.instance_count = actual_count
	new_trunk_multimesh.transform_format = MultiMesh.TRANSFORM_3D
	trunk_multimesh.multimesh = new_trunk_multimesh
	
	var new_leaves_multimesh = MultiMesh.new()
	new_leaves_multimesh.mesh = leaves_multimesh.multimesh.mesh
	new_leaves_multimesh.instance_count = actual_count
	new_leaves_multimesh.transform_format = MultiMesh.TRANSFORM_3D
	leaves_multimesh.multimesh = new_leaves_multimesh
	
	# Set transforms for each tree instance
	for i in range(actual_count):
		var tree_data = tree_positions[i]
		var pos = tree_data.position
		var trunk_h = tree_data.trunk_height
		var leaves_s = tree_data.leaves_size
		var rot_y = tree_data.rotation
		var size_mult = tree_data.size_mult
		
		# Trunk transform - positioned so bottom sits on ground
		# Create transform: rotate, scale, then translate
		var trunk_transform = Transform3D.IDENTITY
		trunk_transform = trunk_transform.rotated(Vector3.UP, rot_y)
		trunk_transform = trunk_transform.scaled(Vector3(size_mult, size_mult, size_mult))
		# Position trunk so bottom sits on ground (mesh is centered at origin, so offset by half scaled height)
		trunk_transform.origin = pos + Vector3(0, trunk_h * 0.5, 0)
		trunk_multimesh.multimesh.set_instance_transform(i, trunk_transform)
		
		# Leaves transform - positioned on top of trunk
		var leaves_transform = Transform3D.IDENTITY
		leaves_transform = leaves_transform.rotated(Vector3.UP, rot_y)
		leaves_transform = leaves_transform.scaled(Vector3(size_mult, size_mult, size_mult))
		# Position leaves on top of trunk (mesh is centered at origin, so offset by trunk height + half leaves height)
		leaves_transform.origin = pos + Vector3(0, trunk_h + leaves_s * 0.5, 0)
		leaves_multimesh.multimesh.set_instance_transform(i, leaves_transform)
	
	# Force update the multimesh
	trunk_multimesh.multimesh = trunk_multimesh.multimesh  # Force refresh
	leaves_multimesh.multimesh = leaves_multimesh.multimesh  # Force refresh
	
	print("ForestManager: Created %d trees using instanced rendering" % actual_count)
	if tree_positions.size() > 0:
		print("ForestManager: First tree position: %s" % tree_positions[0].position)
		print("ForestManager: Trunk multimesh visible: %s, instance_count: %d" % [trunk_multimesh.visible, trunk_multimesh.multimesh.instance_count])
		print("ForestManager: Leaves multimesh visible: %s, instance_count: %d" % [leaves_multimesh.visible, leaves_multimesh.multimesh.instance_count])
