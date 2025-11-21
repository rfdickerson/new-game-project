# Dynamic Subdivided Plane - Godot Project

This project demonstrates how to create a dynamically generated subdivided plane mesh in Godot 4.5.

## Features

- **Dynamic mesh generation**: Creates a plane mesh programmatically with customizable subdivisions
- **Adjustable parameters**: Control size and subdivision count via exported variables
- **Runtime modification**: Change the plane's properties during gameplay
- **Wave animation example**: Demonstrates real-time vertex manipulation

## Files

- `subdivided_plane.gd` - Core script that generates the subdivided plane mesh
- `plane_controller.gd` - Example controller showing runtime manipulation
- `node_3d.tscn` - Main scene with the plane, camera, and lighting

## Usage

### Basic Setup

The `SubdividedPlane` node is a `MeshInstance3D` with the `subdivided_plane.gd` script attached. It has these exported properties:

- **size**: `Vector2(10, 10)` - Size of the plane in world units (X and Z)
- **subdivisions**: `Vector2i(20, 20)` - Number of segments in each direction
- **auto_generate**: `bool = true` - Whether to generate the mesh automatically on ready

### Runtime Controls

When you run the scene, you can use these keyboard controls:

- **[1]** - Decrease subdivisions by 5
- **[2]** - Increase subdivisions by 5
- **[3]** - Make plane 20% smaller
- **[4]** - Make plane 25% larger
- **[R]** - Regenerate plane
- **[W]** - Toggle wave animation (demonstrates dynamic vertex manipulation)

### Using in Your Own Projects

1. Copy `subdivided_plane.gd` to your project
2. Create a `MeshInstance3D` node in your scene
3. Attach the `subdivided_plane.gd` script
4. Adjust the exported properties in the Inspector
5. Call `generate_plane()` to regenerate the mesh at runtime

Example code:

```gdscript
@onready var plane = $SubdividedPlane

func _ready():
    # Change properties
    plane.size = Vector2(20, 20)
    plane.subdivisions = Vector2i(50, 50)
    
    # Regenerate mesh
    plane.generate_plane()
```

## Technical Details

The script creates a mesh using Godot's `ArrayMesh` system:

- Generates vertices in a grid pattern
- Creates UV coordinates for texture mapping
- Generates normals (pointing upward by default)
- Creates triangle indices for the mesh faces
- Each quad is made of two triangles

The mesh is centered at the origin (0, 0, 0) and extends equally in positive and negative X and Z directions.

## Performance Notes

- Higher subdivision counts create more vertices and triangles
- For 20x20 subdivisions: 441 vertices and 800 triangles
- The wave animation regenerates the entire mesh each frame (for demonstration purposes)
- For production use, consider using a shader for animations instead of CPU-based vertex manipulation

## License

Free to use and modify for any purpose.

