extends Node3D

## Example controller to demonstrate dynamic plane manipulation

@onready var plane = $SubdividedPlane

func _ready():
	print("Press keys to modify the plane:")
	print("  [1] - Decrease subdivisions")
	print("  [2] - Increase subdivisions")
	print("  [3] - Make plane smaller")
	print("  [4] - Make plane larger")
	print("  [R] - Regenerate plane")
	print("  [W] - Animate with waves")

var wave_enabled = false
var time_elapsed = 0.0

func _process(delta):
	time_elapsed += delta
	
	if wave_enabled:
		animate_waves()

func _input(event):
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_1:
				plane.subdivisions = Vector2i(
					max(1, plane.subdivisions.x - 5),
					max(1, plane.subdivisions.y - 5)
				)
				plane.generate_plane()
				print("Subdivisions: ", plane.subdivisions)
			
			KEY_2:
				plane.subdivisions = Vector2i(
					plane.subdivisions.x + 5,
					plane.subdivisions.y + 5
				)
				plane.generate_plane()
				print("Subdivisions: ", plane.subdivisions)
			
			KEY_3:
				plane.size *= 0.8
				plane.generate_plane()
				print("Size: ", plane.size)
			
			KEY_4:
				plane.size *= 1.25
				plane.generate_plane()
				print("Size: ", plane.size)
			
			KEY_R:
				plane.generate_plane()
				print("Plane regenerated!")
			
			KEY_W:
				wave_enabled = !wave_enabled
				if wave_enabled:
					print("Wave animation enabled")
				else:
					print("Wave animation disabled - regenerating flat plane")
					plane.generate_plane()

func animate_waves():
	"""Example of animating the plane vertices with a wave effect"""
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	
	var vertices = PackedVector3Array()
	var normals = PackedVector3Array()
	var uvs = PackedVector2Array()
	var indices = PackedInt32Array()
	
	var x_step = plane.size.x / float(plane.subdivisions.x)
	var z_step = plane.size.y / float(plane.subdivisions.y)
	
	# Generate vertices with wave animation
	for z in range(plane.subdivisions.y + 1):
		for x in range(plane.subdivisions.x + 1):
			var x_pos = (x * x_step) - (plane.size.x * 0.5)
			var z_pos = (z * z_step) - (plane.size.y * 0.5)
			
			# Calculate wave height
			var wave_height = sin(x_pos * 0.5 + time_elapsed * 2.0) * cos(z_pos * 0.5 + time_elapsed * 1.5) * 0.5
			
			vertices.append(Vector3(x_pos, wave_height, z_pos))
			
			# Calculate normal for proper lighting (simplified)
			var normal = Vector3(0, 1, 0)
			normals.append(normal)
			
			var u = float(x) / float(plane.subdivisions.x)
			var v = float(z) / float(plane.subdivisions.y)
			uvs.append(Vector2(u, v))
	
	# Generate indices (same as before)
	for z in range(plane.subdivisions.y):
		for x in range(plane.subdivisions.x):
			var top_left = z * (plane.subdivisions.x + 1) + x
			var top_right = top_left + 1
			var bottom_left = (z + 1) * (plane.subdivisions.x + 1) + x
			var bottom_right = bottom_left + 1
			
			indices.append(top_left)
			indices.append(top_right)
			indices.append(bottom_left)
			
			indices.append(top_right)
			indices.append(bottom_right)
			indices.append(bottom_left)
	
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	
	var array_mesh = ArrayMesh.new()
	array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	
	if plane.material_override != null:
		array_mesh.surface_set_material(0, plane.material_override)
	
	plane.mesh = array_mesh
