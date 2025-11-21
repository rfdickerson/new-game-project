# Hexagonal Grid Water World - Godot Project

This project demonstrates dynamic mesh generation in Godot 4.5, featuring a Civilization-style hexagonal tile grid on top of animated water.

## Features

- **Hexagonal Grid System**: Civilization-style hex tiles with customizable size, colors, and spacing
- **Procedural Terrain Generation**: Realistic land/water maps using Perlin noise
- **Multiple Terrain Types**: Water (deep/shallow), sand, grass, forest, and mountains
- **Dynamic Water Plane**: Animated water with wave effects
- **Elevation System**: Different hex heights based on terrain type
- **Runtime Modification**: Adjust properties during gameplay with keyboard controls

## Files

- `hexagon_grid.gd` - Hexagonal grid mesh generator (Civilization-style)
- `subdivided_plane.gd` - Water plane mesh generator with subdivision support
- `plane_controller.gd` - Main controller for both water and hex grid
- `node_3d.tscn` - Main scene with water, hex grid, camera, and lighting

## Usage

### Basic Setup

The `SubdividedPlane` node is a `MeshInstance3D` with the `subdivided_plane.gd` script attached. It has these exported properties:

- **size**: `Vector2(10, 10)` - Size of the plane in world units (X and Z)
- **subdivisions**: `Vector2i(20, 20)` - Number of segments in each direction
- **auto_generate**: `bool = true` - Whether to generate the mesh automatically on ready

### Runtime Controls

When you run the scene, you can use these keyboard controls:

**Water Plane:**
- **[1]** - Decrease subdivisions
- **[2]** - Increase subdivisions
- **[3]** - Make plane smaller
- **[4]** - Make plane larger
- **[R]** - Regenerate plane
- **[W]** - Toggle wave animation

**Hexagon Grid:**
- **[H]** - Toggle hexagon grid visibility
- **[G]** - Generate new random terrain (new seed)
- **[+]** - Increase hex grid size
- **[-]** - Decrease hex grid size
- **[Q]** - Increase hex radius (bigger tiles)
- **[A]** - Decrease hex radius (smaller tiles)
- **[L]** - More land (less ocean)
- **[O]** - More ocean (less land)
- **[N]** - Cycle noise scale (changes landmass size)

### Using the Hexagon Grid

The `HexagonGrid` has these exported properties:

**Grid Properties:**
- **hex_radius**: Size of each hexagon
- **grid_width**: Number of hexagons horizontally
- **grid_height**: Number of hexagons vertically
- **hex_height**: Thickness of hex tiles
- **gap_size**: Space between hexagons

**Terrain Generation:**
- **land_percentage**: How much of the map is land vs water (0.0 to 1.0)
- **noise_scale**: Size of landmasses (lower = bigger continents)
- **noise_seed**: Random seed for generation (0 = random each time)

**Colors:**
- **color_water**: Deep water color
- **color_sand**: Beach/sand color
- **color_grass**: Grassland color
- **color_forest**: Forest color
- **color_mountain**: Mountain/high elevation color

Example code:

```gdscript
@onready var hex_grid = $HexagonGrid

func _ready():
    # Customize the grid
    hex_grid.hex_radius = 0.5
    hex_grid.grid_width = 20
    hex_grid.grid_height = 20
    hex_grid.gap_size = 0.05
    
    # Adjust terrain generation
    hex_grid.land_percentage = 0.5  # 50% land
    hex_grid.noise_scale = 0.1  # Large continents
    hex_grid.noise_seed = 12345  # Fixed seed for reproducible maps
    
    # Regenerate with new settings
    hex_grid.generate_hex_grid()
    
    # Convert world position to hex coordinates
    var hex_coords = hex_grid.get_hex_at_world_position(Vector3(1.0, 0, 1.0))
    print("Hex at position: ", hex_coords)
```

## Technical Details

### Hexagon Grid System

The hexagonal grid uses **flat-top orientation** (like Civilization games):

- Each hexagon has 6 vertices arranged at 60° intervals (starting at 30°)
- Odd rows are offset horizontally by half-width to create interlocking pattern
- Hexagons have thickness (top + bottom + side faces)
- Uses vertex colors for terrain variety
- Elevation varies by terrain type for visual depth
- Grid coordinates can be converted from world position

**Procedural Terrain Generation:**
- Uses FastNoiseLite (Perlin noise) for natural-looking landmasses
- Terrain types assigned based on noise height values
- Water tiles positioned lower, mountains higher for realistic elevation
- Smooth transitions between biomes (shallow water, beaches, etc.)

### Water Plane

Creates a subdivided plane mesh using Godot's `ArrayMesh`:

- Grid-based vertex generation
- UV coordinates for texture mapping
- Upward-pointing normals
- Triangle indices (2 triangles per quad)
- Centered at origin

## Performance Notes

**Hexagon Grid:**
- 12x12 grid = 144 hexagons with ~2,000 vertices
- All hexagons are in a single mesh for optimal rendering
- Regenerating the mesh is fast enough for gameplay adjustments
- For clicking individual hexagons, implement raycasting

**Water Plane:**
- Higher subdivisions = more vertices and triangles
- 20x20 subdivisions = 441 vertices and 800 triangles
- Wave animation regenerates mesh each frame (demonstration only)
- For production, use a shader for water animation instead

## License

Free to use and modify for any purpose.

