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

varying vec3 world_position;
varying vec3 world_normal;

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
	
	// Animate waves using multiple sine waves for more natural look
	float time = TIME * wave_speed;
	vec2 wave_uv = UV * wave_scale;
	
	// Primary wave
	float wave1 = sin(wave_uv.x * wave_frequency + time) * cos(wave_uv.y * wave_frequency * 0.7 + time * 0.8);
	
	// Secondary wave for complexity
	float wave2 = sin(wave_uv.x * wave_frequency * 1.3 + time * 1.1) * cos(wave_uv.y * wave_frequency * 0.9 + time * 0.9);
	
	// Combine waves
	float wave_height = (wave1 * 0.7 + wave2 * 0.3) * wave_amplitude;
	
	// Apply wave displacement
	VERTEX.y += wave_height;
	
	// Calculate normal for proper lighting (simplified)
	NORMAL = normalize(vec3(
		-cos(wave_uv.x * wave_frequency + time) * sin(wave_uv.y * wave_frequency * 0.7 + time * 0.8) * wave_amplitude * wave_frequency,
		1.0,
		-sin(wave_uv.x * wave_frequency + time) * cos(wave_uv.y * wave_frequency * 0.7 + time * 0.8) * wave_amplitude * wave_frequency
	));
}

void fragment() {
	vec3 normal = normalize(NORMAL);
	vec3 view_dir = normalize(-VIEW);
	
	// Calculate fresnel for edge reflection
	float fresnel = pow(clamp(1.0 - dot(view_dir, normal), 0.0, 1.0), fresnel_power);
	
	// Depth-based coloring (simulate shallow/deep water)
	// In a real implementation, you'd sample depth texture
	// For now, use distance from center or UV-based approximation
	float depth_factor = clamp(length(UV - vec2(0.5)) * 2.0, 0.0, 1.0);
	vec3 water_color = mix(shallow_color, deep_color, depth_factor);
	
	// Add sky reflection
	vec3 final_color = mix(water_color, sky_color, fresnel * reflection_strength);
	
	// Add foam effect at wave peaks
	float time = TIME * wave_speed;
	vec2 wave_uv = UV * wave_scale;
	float wave_value = sin(wave_uv.x * wave_frequency + time) * cos(wave_uv.y * wave_frequency * 0.7 + time * 0.8);
	float foam = smoothstep(foam_threshold, 1.0, wave_value) * foam_intensity;
	final_color = mix(final_color, vec3(1.0), foam);
	
	ALBEDO = final_color;
	METALLIC = 0.2;
	ROUGHNESS = 0.1;  // Smooth but not perfectly mirror-like
	ALPHA = alpha;
}

