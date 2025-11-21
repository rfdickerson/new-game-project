extends MeshInstance3D

## Configuration
@export var size: Vector2 = Vector2(10.0, 10.0)  ## Size of the plane in world units
@export var subdivisions: Vector2i = Vector2i(10, 10)  ## Number of subdivisions (segments) in each direction
@export var auto_generate: bool = true  ## Generate mesh on ready

func _ready():
	if auto_generate:
		generate_plane()

func generate_plane():
	"""Generate a subdivided plane mesh dynamically"""
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	
	var vertices = PackedVector3Array()
	var normals = PackedVector3Array()
	var uvs = PackedVector2Array()
	var indices = PackedInt32Array()
	
	# Calculate step sizes
	var x_step = size.x / float(subdivisions.x)
	var z_step = size.y / float(subdivisions.y)
	
	# Generate vertices, normals, and UVs
	for z in range(subdivisions.y + 1):
		for x in range(subdivisions.x + 1):
			# Calculate position (centered at origin)
			var x_pos = (x * x_step) - (size.x * 0.5)
			var z_pos = (z * z_step) - (size.y * 0.5)
			
			# Add vertex
			vertices.append(Vector3(x_pos, 0.0, z_pos))
			
			# Add normal (pointing up)
			normals.append(Vector3(0, 1, 0))
			
			# Add UV coordinates
			var u = float(x) / float(subdivisions.x)
			var v = float(z) / float(subdivisions.y)
			uvs.append(Vector2(u, v))
	
	# Generate indices for triangles
	for z in range(subdivisions.y):
		for x in range(subdivisions.x):
			# Calculate vertex indices for this quad
			var top_left = z * (subdivisions.x + 1) + x
			var top_right = top_left + 1
			var bottom_left = (z + 1) * (subdivisions.x + 1) + x
			var bottom_right = bottom_left + 1
			
			# First triangle (top-left, top-right, bottom-left)
			indices.append(top_left)
			indices.append(top_right)
			indices.append(bottom_left)
			
			# Second triangle (top-right, bottom_right, bottom_left)
			indices.append(top_right)
			indices.append(bottom_right)
			indices.append(bottom_left)
	
	# Assign arrays to mesh
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	
	# Create the mesh
	var array_mesh = ArrayMesh.new()
	array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	
	# Apply material - use material_override if set, otherwise create default
	if material_override != null:
		array_mesh.surface_set_material(0, material_override)
	else:
		var material = StandardMaterial3D.new()
		material.albedo_color = Color(0.2, 0.6, 0.8, 1)
		material.metallic = 0.2
		material.roughness = 0.8
		material.wireframe = true
		array_mesh.surface_set_material(0, material)
	
	# Assign mesh to MeshInstance3D
	mesh = array_mesh
	
	print("Generated subdivided plane with %d vertices and %d triangles" % [vertices.size(), indices.size() / 3])
