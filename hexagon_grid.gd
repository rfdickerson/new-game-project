extends MeshInstance3D

## Hexagonal grid mesh generator (Civilization-style)
@export var hex_radius: float = 0.5  ## Radius of each hexagon
@export var grid_width: int = 10  ## Number of hexagons in width
@export var grid_height: int = 10  ## Number of hexagons in height
@export var hex_height: float = 0.15  ## Height/thickness of hexagon tiles
@export var gap_size: float = 0.02  ## Gap between hexagons
@export var auto_generate: bool = true

## Simple baked-in ambient occlusion for the hex tiles (vertex color darkening)
@export var ao_enabled: bool = true
@export var ao_edge_intensity: float = 0.3  ## How dark the outer rim of the top face becomes (0–1)
@export var ao_bottom_intensity: float = 0.6  ## How dark the underside becomes (0–1)

## Colors for different terrain types (enhanced for strategy game)
@export var color_water: Color = Color(0.2, 0.4, 0.8, 0.7)
@export var color_grass: Color = Color(0.4, 0.75, 0.35, 1.0)  # Brighter, more vibrant
@export var color_sand: Color = Color(0.95, 0.85, 0.6, 1.0)  # Warmer sand
@export var color_forest: Color = Color(0.2, 0.55, 0.25, 1.0)  # Deeper green
@export var color_mountain: Color = Color(0.6, 0.6, 0.65, 1.0)  # Slightly lighter for visibility

## Terrain generation settings
@export var land_percentage: float = 0.4  ## Percentage of map that should be land (0.0 to 1.0)
@export var noise_scale: float = 0.15  ## Scale of terrain noise (lower = larger land masses)
@export var noise_seed: int = 0  ## Seed for random generation (0 = random)

func _ready():
	if auto_generate:
		generate_hex_grid()

func generate_hex_grid():
	"""Generate a hexagonal grid mesh"""
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	
	var vertices = PackedVector3Array()
	var normals = PackedVector3Array()
	var colors = PackedColorArray()
	var indices = PackedInt32Array()
	
	var vertex_offset = 0
	
	# Hexagon dimensions for FLAT-TOP layout (angle starts at 30°):
	# - Radius = distance from center to VERTEX
	# - Width  = sqrt(3) * r
	# - Height = 2 * r
	var hex_width = sqrt(3.0) * hex_radius
	var hex_height_2d = 2.0 * hex_radius
	
	# Center-to-center spacing between hexes (odd-r offset layout):
	# - Horizontal: full width
	# - Vertical:   3/4 of height
	var horizontal_spacing = hex_width
	var vertical_spacing = hex_height_2d * 0.75
	
	# Adjust for gap
	var adjusted_radius = hex_radius - gap_size
	
	# Setup noise for procedural terrain generation
	var noise = FastNoiseLite.new()
	if noise_seed == 0:
		noise.seed = randi()
	else:
		noise.seed = noise_seed
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	noise.frequency = noise_scale
	
	# Generate terrain height map
	var terrain_map = []
	for row in range(grid_height):
		terrain_map.append([])
		for col in range(grid_width):
			var noise_value = noise.get_noise_2d(float(col), float(row))
			# Normalize from [-1, 1] to [0, 1]
			var height_value = (noise_value + 1.0) * 0.5
			terrain_map[row].append(height_value)
	
	# Generate each hexagon in the grid
	for row in range(grid_height):
		for col in range(grid_width):
			# Calculate hexagon center position
			var x_offset = 0.0
			if row % 2 == 1:  # Offset odd rows for hexagonal pattern
				x_offset = horizontal_spacing * 0.5
			
			var center_x = col * horizontal_spacing + x_offset
			var center_z = row * vertical_spacing
			
			# Center the entire grid
			center_x -= (grid_width * horizontal_spacing) * 0.5
			center_z -= (grid_height * vertical_spacing) * 0.5
			
			# Get terrain type based on noise value
			var height = terrain_map[row][col]
			var hex_color: Color
			var y_offset = 0.0
			var is_water = false
			
			if height < (1.0 - land_percentage):
				# Deep water - skip hexagon, show water plane instead
				is_water = true
			elif height < (1.0 - land_percentage + 0.05):
				# Shallow water / coast - skip hexagon, show water plane
				is_water = true
			elif height < (1.0 - land_percentage + 0.15):
				# Beach / sand
				hex_color = color_sand
				y_offset = 0.0
			elif height < (1.0 - land_percentage + 0.45):
				# Grassland
				hex_color = color_grass
				y_offset = 0.08
			elif height < (1.0 - land_percentage + 0.7):
				# Forest
				hex_color = color_forest
				y_offset = 0.22
			else:
				# Mountains
				hex_color = color_mountain
				y_offset = 0.35
			
			# Only create hexagon for land tiles (skip water)
			if not is_water:
				# Create hexagon at this position
				add_hexagon(vertices, normals, colors, indices, 
							Vector3(center_x, y_offset, center_z), 
							adjusted_radius, hex_color, vertex_offset)
				
				vertex_offset += 14  # 7 vertices top + 7 vertices bottom

	# Assign arrays to mesh
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_INDEX] = indices
	
	# Create the mesh
	var array_mesh = ArrayMesh.new()
	array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	
	# Create material with better properties for strategy game
	var material = StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.transparency = 1  # Use alpha from vertex colors
	material.metallic = 0.05
	material.roughness = 0.85  # More matte, less shiny for better readability
	material.cull_mode = BaseMaterial3D.CULL_BACK  # Standard back-face culling
	material.albedo_color = Color(1.0, 1.0, 1.0, 1.0)  # White base for vertex colors to show through
	# Note: specular is controlled via metallic and roughness in Godot 4
	
	array_mesh.surface_set_material(0, material)
	
	# Assign mesh to MeshInstance3D
	mesh = array_mesh
	
	var hex_count = vertices.size() / 14  # 14 vertices per hexagon
	print("Generated hexagonal grid: %dx%d (%d land hexagons, %d vertices)" % 
		  [grid_width, grid_height, hex_count, vertices.size()])

func _darken_color(base_color: Color, intensity: float) -> Color:
	"""Darken a color by a given intensity (0 = no darkening, 1 = fully black)"""
	var factor = clamp(1.0 - intensity, 0.0, 1.0)
	return Color(base_color.r * factor, base_color.g * factor, base_color.b * factor, base_color.a)

func add_hexagon(vertices: PackedVector3Array, normals: PackedVector3Array, 
				 colors: PackedColorArray, indices: PackedInt32Array,
				 center: Vector3, radius: float, color: Color, vertex_offset: int):
	"""Add a single solid hexagon (top cap, bottom cap, and sides) to the mesh arrays."""
	
	# Generate 6 vertices around the hexagon (flat-top orientation)
	var hex_vertices_top: Array[Vector3] = []
	var hex_vertices_bottom: Array[Vector3] = []
	
	for i in range(6):
		# For flat-top hexagons, start at 30° and increment by 60°
		var angle_deg = 30.0 + (60.0 * i)
		var angle_rad = deg_to_rad(angle_deg)
		
		var x = center.x + radius * cos(angle_rad)
		var z = center.z + radius * sin(angle_rad)
		
		# Top surface
		hex_vertices_top.append(Vector3(x, center.y + hex_height * 0.5, z))
		# Bottom surface
		hex_vertices_bottom.append(Vector3(x, center.y - hex_height * 0.5, z))
	
	# ----- TOP CAP -----
	# Center vertex for top
	var center_top = Vector3(center.x, center.y + hex_height * 0.5, center.z)
	vertices.append(center_top)
	normals.append(Vector3(0, 1, 0))
	colors.append(color)
	
	# Outer ring vertices for top
	for i in range(6):
		vertices.append(hex_vertices_top[i])
		normals.append(Vector3(0, 1, 0))
		if ao_enabled and ao_edge_intensity > 0.0:
			colors.append(_darken_color(color, ao_edge_intensity))
		else:
			colors.append(color)
	
	# ----- BOTTOM CAP -----
	# Center vertex for bottom
	var center_bottom = Vector3(center.x, center.y - hex_height * 0.5, center.z)
	vertices.append(center_bottom)
	normals.append(Vector3(0, -1, 0))
	if ao_enabled and ao_bottom_intensity > 0.0:
		colors.append(_darken_color(color, ao_bottom_intensity))
	else:
		colors.append(color)
	
	# Outer ring vertices for bottom
	for i in range(6):
		vertices.append(hex_vertices_bottom[i])
		normals.append(Vector3(0, -1, 0))
		if ao_enabled and ao_bottom_intensity > 0.0:
			colors.append(_darken_color(color, ao_bottom_intensity))
		else:
			colors.append(color)
	
	# ----- INDICES -----
	# Top fan (counter-clockwise when viewed from above)
	for i in range(6):
		var next_i = (i + 1) % 6
		indices.append(vertex_offset)  # Center top
		indices.append(vertex_offset + i + 1)  # Vertex i
		indices.append(vertex_offset + next_i + 1)  # Vertex next_i
	
	# Bottom fan (reverse of top)
	var bottom_center = vertex_offset + 7
	for i in range(6):
		var next_i = (i + 1) % 6
		indices.append(bottom_center)  # Center bottom
		indices.append(bottom_center + next_i + 1)  # Vertex next_i
		indices.append(bottom_center + i + 1)  # Vertex i
	
	# Side faces (use shared top/bottom ring vertices)
	for i in range(6):
		var next_i = (i + 1) % 6
		
		var top1 = vertex_offset + i + 1
		var top2 = vertex_offset + next_i + 1
		var bottom1 = bottom_center + i + 1
		var bottom2 = bottom_center + next_i + 1
		
		# First triangle
		indices.append(top1)
		indices.append(bottom1)
		indices.append(top2)
		
		# Second triangle
		indices.append(top2)
		indices.append(bottom1)
		indices.append(bottom2)

func get_hex_at_world_position(world_pos: Vector3) -> Vector2i:
	"""Convert world position to hex grid coordinates (approximate)"""
	# Use the same layout math as in generate_hex_grid()
	var hex_width = sqrt(3.0) * hex_radius
	var hex_height_2d = 2.0 * hex_radius
	var horizontal_spacing = hex_width
	var vertical_spacing = hex_height_2d * 0.75
	
	# Undo centering offset
	var adjusted_x = world_pos.x + (grid_width * horizontal_spacing) * 0.5
	var adjusted_z = world_pos.z + (grid_height * vertical_spacing) * 0.5
	
	# Approximate row
	var row = int(round(adjusted_z / vertical_spacing))
	
	# Column depends on whether this is an offset row
	var x_offset = 0.0
	if row % 2 == 1:
		x_offset = hex_width * 0.5
	
	var col = int(round((adjusted_x - x_offset) / horizontal_spacing))
	
	return Vector2i(col, row)
