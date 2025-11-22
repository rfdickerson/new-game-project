shader_type spatial;
render_mode cull_disabled, depth_draw_always, blend_mix;

uniform vec3 base_color = vec3(0.06, 0.35, 0.5);
uniform vec3 sky_color = vec3(0.38, 0.65, 0.88);
uniform float reflection_strength : hint_range(0.0, 1.0) = 0.65;
uniform float fresnel_power : hint_range(0.5, 5.0) = 2.5;
uniform float alpha : hint_range(0.0, 1.0) = 0.85;

// Normal map
uniform sampler2D normal_map : hint_normal;
uniform float normal_scale : hint_range(0.0, 2.0) = 1.0;
uniform float normal_speed : hint_range(0.0, 5.0) = 0.5;
uniform vec2 normal_tiling = vec2(2.0, 2.0);

void fragment() {
    // Sample normal map with tiled UV coordinates (no animation)
    vec2 normal_uv = UV * normal_tiling;
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
    
    // Use base color as foundation
    vec3 final_color = base_color;
    
    // Blend with sky color based on fresnel (this simulates sky reflection)
    final_color = mix(final_color, sky_color, fresnel * reflection_strength);
    
    ALBEDO = final_color;
    // Set metallic and roughness for PBR reflections to work
    // Lower roughness = more mirror-like, allowing reflection probes to show through
    // Use perturbed normal for more realistic reflections
    NORMAL = normal;
    METALLIC = 0.15;
    ROUGHNESS = 0.05;  // Very smooth surface for clear reflections
    ALPHA = alpha;
}

