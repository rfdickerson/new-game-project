extends Node3D

## Example controller to demonstrate dynamic plane manipulation

const WATER_SHADER := preload("res://water_reflection.gdshader")
const WATER_ANIMATED_SHADER := preload("res://water_animated.gdshader")

@onready var plane = $SubdividedPlane
@onready var hex_grid = $HexagonGrid
@onready var game_ui = $UILayer/GameUI
@onready var watermill_panel = $UILayer/WatermillPanel

func _ready():
	_apply_water_shader()
	print("=== CONTROLS ===")
	print("Water Plane:")
	print("  [1] - Decrease subdivisions")
	print("  [2] - Increase subdivisions")
	print("  [3] - Make plane smaller")
	print("  [4] - Make plane larger")
	print("  [R] - Regenerate plane")
	print("  [W] - Animate with waves")
	print("")
	print("Hexagon Grid:")
	print("  [H] - Toggle hexagon grid visibility")
	print("  [G] - Regenerate terrain (new random seed)")
	print("  [+] - Increase hex grid size")
	print("  [-] - Decrease hex grid size")
	print("  [I] - Increase hex radius")
	print("  [O] - Decrease hex radius")
	print("  [L] - More land")
	print("  [P] - More ocean")
	print("  [N] - Adjust noise scale (terrain size)")
	print("  [Enter] - Next Turn")
	print("  [F] - Show Watermill Information")

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
			
			# Hexagon grid controls
			KEY_H:
				hex_grid.visible = !hex_grid.visible
				print("Hexagon grid visibility: ", hex_grid.visible)
			
			KEY_G:
				hex_grid.noise_seed = 0  # Random seed
				hex_grid.generate_hex_grid()
				print("New terrain generated!")
			
			KEY_EQUAL, KEY_KP_ADD:  # + key
				hex_grid.grid_width += 2
				hex_grid.grid_height += 2
				hex_grid.generate_hex_grid()
				print("Grid size: %dx%d" % [hex_grid.grid_width, hex_grid.grid_height])
			
			KEY_MINUS, KEY_KP_SUBTRACT:  # - key
				hex_grid.grid_width = max(2, hex_grid.grid_width - 2)
				hex_grid.grid_height = max(2, hex_grid.grid_height - 2)
				hex_grid.generate_hex_grid()
				print("Grid size: %dx%d" % [hex_grid.grid_width, hex_grid.grid_height])
			
			KEY_I:
				hex_grid.hex_radius += 0.05
				hex_grid.generate_hex_grid()
				print("Hex radius: %.2f" % hex_grid.hex_radius)
			
			KEY_O:
				hex_grid.hex_radius = max(0.1, hex_grid.hex_radius - 0.05)
				hex_grid.generate_hex_grid()
				print("Hex radius: %.2f" % hex_grid.hex_radius)
			
			KEY_L:
				hex_grid.land_percentage = min(0.9, hex_grid.land_percentage + 0.1)
				hex_grid.generate_hex_grid()
				print("Land percentage: %.1f%%" % (hex_grid.land_percentage * 100))
			
			KEY_P:
				hex_grid.land_percentage = max(0.1, hex_grid.land_percentage - 0.1)
				hex_grid.generate_hex_grid()
				print("Land percentage: %.1f%%" % (hex_grid.land_percentage * 100))
			
			KEY_N:
				hex_grid.noise_scale += 0.05
				if hex_grid.noise_scale > 0.5:
					hex_grid.noise_scale = 0.05
				hex_grid.generate_hex_grid()
				print("Noise scale: %.2f (lower = larger landmasses)" % hex_grid.noise_scale)
			
			KEY_ENTER:
				if game_ui:
					game_ui.next_turn()
					print("Turn ended. New Year: ", game_ui.year)

func _get_sky_color() -> Color:
	var env = get_world_3d().environment
	if env and env.sky and env.sky is PhysicalSkyMaterial:
		return env.sky.sky_top_color
	return Color(0.38, 0.65, 0.88)

func _apply_water_shader():
	var shader_material = ShaderMaterial.new()
	shader_material.shader = WATER_ANIMATED_SHADER

	var sky_color = _get_sky_color()
	
	# Set water colors for depth-based rendering
	shader_material.set_shader_parameter("shallow_color", Vector3(0.2, 0.6, 0.8))
	shader_material.set_shader_parameter("deep_color", Vector3(0.05, 0.2, 0.4))
	shader_material.set_shader_parameter("sky_color", Vector3(sky_color.r, sky_color.g, sky_color.b))
	
	# Wave parameters
	shader_material.set_shader_parameter("wave_speed", 1.2)
	shader_material.set_shader_parameter("wave_amplitude", 0.25)
	shader_material.set_shader_parameter("wave_frequency", 2.5)
	shader_material.set_shader_parameter("wave_scale", 0.4)
	
	# Reflection and appearance
	shader_material.set_shader_parameter("reflection_strength", 0.4)
	shader_material.set_shader_parameter("fresnel_power", 2.0)
	shader_material.set_shader_parameter("alpha", 0.9)
	
	# Foam
	shader_material.set_shader_parameter("foam_threshold", 0.75)
	shader_material.set_shader_parameter("foam_intensity", 0.25)

	plane.material_override = shader_material
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
