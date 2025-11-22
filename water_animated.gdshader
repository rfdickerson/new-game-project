shader_type spatial;
render_mode cull_disabled, depth_draw_always, blend_mix;

// Water colors
uniform vec3 shallow_color = vec3(0.2, 0.6, 0.8);
uniform vec3 deep_color = vec3(0.05, 0.2, 0.4);
uniform vec3 sky_color = vec3(0.4, 0.65, 0.9);
uniform float reflection_strength : hint_range(0.0, 1.0) = 0.5;
uniform float fresnel_power : hint_range(0.5, 5.0) = 2.0;
uniform float alpha : hint_range(0.0, 1.0) = 0.9;

// Wave parameters
uniform float wave_speed : hint_range(0.0, 5.0) = 1.5;
uniform float wave_amplitude : hint_range(0.0, 2.0) = 0.3;
uniform float wave_frequency : hint_range(0.0, 10.0) = 2.0;
uniform float wave_scale : hint_range(0.0, 1.0) = 0.5;

// Foam parameters
uniform float foam_threshold : hint_range(0.0, 1.0) = 0.7;
uniform float foam_intensity : hint_range(0.0, 1.0) = 0.3;

// Normal map
uniform sampler2D normal_map : hint_normal;
uniform float normal_scale : hint_range(0.0, 2.0) = 1.0;
uniform float normal_speed : hint_range(0.0, 5.0) = 0.5;
uniform vec2 normal_tiling = vec2(2.0, 2.0);

varying vec3 world_position;
varying vec3 world_normal;
varying vec2 uv_coords;

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
	uv_coords = UV;
	
	// Keep the water surface flat (no animated waves) to avoid distracting moving highlights.
	// Geometry stays still; reflections are handled entirely in the fragment shader.
	NORMAL = vec3(0.0, 1.0, 0.0);
}

void fragment() {
	// Sample normal map with tiled UV coordinates (no animation)
	vec2 normal_uv = uv_coords * normal_tiling;
	vec3 normal_map_sample = texture(normal_map, normal_uv).rgb;
	
	// Convert normal map from [0,1] to [-1,1] range
	vec3 normal_map_normal = normalize(normal_map_sample * 2.0 - 1.0);
	
	// Create tangent space basis
	vec3 N = normalize(NORMAL);
	vec3 T = normalize(cross(N, vec3(0.0, 0.0, 1.0)));
	if (length(T) < 0.01) {
		T = normalize(cross(N, vec3(1.0, 0.0, 0.0)));
	}
	vec3 B = normalize(cross(N, T));
	mat3 TBN = mat3(T, B, N);
	
	// Transform normal map to world space and blend with base normal
	vec3 perturbed_normal = normalize(TBN * normal_map_normal);
	vec3 normal = normalize(mix(N, perturbed_normal, normal_scale));
	
	vec3 view_dir = normalize(-VIEW);
	
	// Calculate fresnel for edge reflection using perturbed normal
	float fresnel = pow(clamp(1.0 - dot(view_dir, normal), 0.0, 1.0), fresnel_power);
	
	// Depth-based coloring (simulate shallow/deep water)
	// In a real implementation, you'd sample depth texture
	// For now, use distance from center or UV-based approximation
	float depth_factor = clamp(length(UV - vec2(0.5)) * 2.0, 0.0, 1.0);
	vec3 water_color = mix(shallow_color, deep_color, depth_factor);
	
	// Calculate reflection vector using perturbed normal for more realistic reflections
	vec3 reflect_dir = reflect(-view_dir, normal);
	
	// Make the base albedo darker so reflections show through better
	// The PBR system will add reflections on top based on METALLIC/ROUGHNESS
	ALBEDO = water_color * 0.5;  // Darken significantly to let reflections dominate
	
	// Set very high metallic and very low roughness for strong reflections
	// This should make the reflection probe's sky reflection very visible
	// Use perturbed normal for realistic reflections and lighting
	NORMAL = normal;
	METALLIC = 0.9;  // Very high metallic for mirror-like reflections
	ROUGHNESS = 0.01;  // Extremely smooth surface for clear sky reflections
	
	// Use fresnel to control reflection strength via specular
	SPECULAR = fresnel * reflection_strength;
	
	ALPHA = alpha;
}

